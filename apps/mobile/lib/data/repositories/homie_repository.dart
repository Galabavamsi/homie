import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../domain/models/homie_models.dart';
import '../network/homie_api.dart';
import '../network/room_socket_client.dart';

class RestaurantResult {
  const RestaurantResult(this.restaurants, this.source);

  final List<Restaurant> restaurants;
  final String source;
}

class HomieRepository {
  HomieRepository({HomieApi? api, RoomSocketClient? socket})
      : _api = api ?? HomieApi(),
        _socket = socket ?? RoomSocketClient();

  static const _userKey = 'homie.current_user';
  static const _roomKey = 'homie.last_room';
  static const _uuid = Uuid();

  final HomieApi _api;
  final RoomSocketClient _socket;

  Stream<Map<String, dynamic>> get snapshots => _socket.snapshots;
  Stream<Map<String, dynamic>> get presence => _socket.presence;
  Stream<Map<String, dynamic>> get typing => _socket.typing;
  Stream<RealtimeStatus> get realtimeStatus => _socket.status;

  Future<String> healthSource() async {
    final health = await _api.health();
    return 'swiggy_mcp_${health['mcpMode'] ?? 'mock'}';
  }

  Future<Participant?> restoreUser() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_userKey);
    if (raw == null) return null;
    try {
      return Participant.fromJson(
          Map<String, dynamic>.from(jsonDecode(raw) as Map));
    } on Object {
      await preferences.remove(_userKey);
      return null;
    }
  }

  Future<String?> restoreRoomCode() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(_roomKey);
  }

  Future<Participant> createGuest(String name) async {
    final user = Participant.fromJson(await _api.createGuest(name));
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_userKey, jsonEncode(user.toJson()));
    return user;
  }

  Future<RestaurantResult> restaurants(
      {String? query, DietaryTag? filter}) async {
    final response = await _api.restaurants(query: query, tag: filter?.name);
    final values = (response['data'] as List? ?? const [])
        .map((value) =>
            Restaurant.fromJson(Map<String, dynamic>.from(value as Map)))
        .toList();
    return RestaurantResult(
        values, response['source']?.toString() ?? 'swiggy_mcp_mock');
  }

  Future<List<MenuItem>> menu(String restaurantId) async {
    final response = await _api.menu(restaurantId);
    return (response['data'] as List? ?? const [])
        .map((value) =>
            MenuItem.fromJson(Map<String, dynamic>.from(value as Map)))
        .toList();
  }

  Future<RoomSnapshot> createRoom({
    required String name,
    required int budget,
    required String hostUserId,
  }) async {
    final snapshot = RoomSnapshot.fromJson(await _api.createRoom(
      name: name,
      budget: budget,
      hostUserId: hostUserId,
    ));
    await _saveRoom(snapshot.room.code);
    await _connect(snapshot.room.code, hostUserId);
    return snapshot;
  }

  Future<RoomSnapshot> joinRoom(String code, String userId) async {
    final normalized = code.trim().toUpperCase();
    final operation = _uuid.v4();
    final snapshot = RoomSnapshot.fromJson(
      await _api.joinRoom(normalized, userId, operation),
    );
    await _saveRoom(snapshot.room.code);
    await _connect(snapshot.room.code, userId);
    return snapshot;
  }

  Future<RoomSnapshot> refreshRoom(String code) async {
    return RoomSnapshot.fromJson(await _api.getRoom(code.trim().toUpperCase()));
  }

  Future<RoomSnapshot> sendMessage({
    required String code,
    required String userId,
    required String message,
  }) async {
    final body = {
      'roomCode': code,
      'userId': userId,
      'message': message,
      'operationId': _uuid.v4(),
    };
    return RoomSnapshot.fromJson(await _socketOrHttp(
      event: 'chat:send',
      body: body,
      fallback: () => _api.sendMessage(code, body),
    ));
  }

  Future<RoomSnapshot> vote({
    required String code,
    required String userId,
    required String restaurantId,
  }) async {
    final body = {
      'roomCode': code,
      'userId': userId,
      'restaurantId': restaurantId,
      'operationId': _uuid.v4(),
    };
    return RoomSnapshot.fromJson(await _socketOrHttp(
      event: 'vote:cast',
      body: body,
      fallback: () => _api.vote(code, body),
    ));
  }

  Future<RoomSnapshot> setCartItem({
    required String code,
    required String userId,
    required MenuItem item,
    required int quantity,
    String customization = 'Regular',
  }) async {
    final body = {
      'roomCode': code,
      'userId': userId,
      'itemId': item.id,
      'restaurantId': item.restaurantId,
      'quantity': quantity,
      'customization': customization,
      'operationId': _uuid.v4(),
    };
    return RoomSnapshot.fromJson(await _socketOrHttp(
      event: 'cart:set',
      body: body,
      fallback: () => _api.setCartItem(code, item.id, body),
    ));
  }

  Future<RoomSnapshot> checkout({
    required String code,
    required String userId,
  }) async {
    return RoomSnapshot.fromJson(await _api.checkout(code, {
      'userId': userId,
      'confirmed': true,
      'operationId': _uuid.v4(),
    }));
  }

  void setTyping(bool value) => _socket.setTyping(value);

  Future<Map<String, dynamic>> _socketOrHttp({
    required String event,
    required Map<String, dynamic> body,
    required Future<Map<String, dynamic>> Function() fallback,
  }) async {
    if (_socket.isConnected) {
      try {
        return await _socket.emit(event, body);
      } on ApiException {
        return fallback();
      }
    }
    return fallback();
  }

  Future<void> _connect(String code, String userId) async {
    try {
      await _socket.connectAndJoin(
        roomCode: code,
        userId: userId,
        operationId: _uuid.v4(),
      );
    } on Object {
      // HTTP remains available; Socket.IO will keep reconnecting in the background.
    }
  }

  Future<void> _saveRoom(String code) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_roomKey, code);
  }

  Future<void> dispose() async {
    _api.close();
    await _socket.dispose();
  }
}
