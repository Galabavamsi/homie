import 'dart:async';

import 'package:socket_io_client/socket_io_client.dart' as io;

import '../../core/api_config.dart';
import '../../domain/models/homie_models.dart';
import 'homie_api.dart';

class RoomSocketClient {
  RoomSocketClient() {
    _socket = io.io(
      ApiConfig.origin,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .enableReconnection()
          .setReconnectionAttempts(20)
          .setReconnectionDelay(700)
          .setReconnectionDelayMax(5000)
          .setTimeout(5000)
          .build(),
    );
    _socket.onConnect((_) {
      _status.add(RealtimeStatus.connected);
      if (_hasJoined && _roomCode != null && _userId != null) {
        unawaited(_joinCurrentRoom());
      }
    });
    _socket.onDisconnect((_) => _status.add(RealtimeStatus.reconnecting));
    _socket.onConnectError((_) => _status.add(RealtimeStatus.offline));
    _socket.on(
        'reconnect_attempt', (_) => _status.add(RealtimeStatus.reconnecting));
    _socket.on('room:snapshot', (value) {
      if (value is Map) _snapshots.add(Map<String, dynamic>.from(value));
    });
    _socket.on('room:presence', (value) {
      if (value is Map) _presence.add(Map<String, dynamic>.from(value));
    });
    _socket.on('typing:changed', (value) {
      if (value is Map) _typing.add(Map<String, dynamic>.from(value));
    });
  }

  late final io.Socket _socket;
  final _snapshots = StreamController<Map<String, dynamic>>.broadcast();
  final _presence = StreamController<Map<String, dynamic>>.broadcast();
  final _typing = StreamController<Map<String, dynamic>>.broadcast();
  final _status = StreamController<RealtimeStatus>.broadcast();
  String? _roomCode;
  String? _userId;
  String? _joinOperationId;
  bool _hasJoined = false;

  bool get isConnected => _socket.connected;
  Stream<Map<String, dynamic>> get snapshots => _snapshots.stream;
  Stream<Map<String, dynamic>> get presence => _presence.stream;
  Stream<Map<String, dynamic>> get typing => _typing.stream;
  Stream<RealtimeStatus> get status => _status.stream;

  Future<Map<String, dynamic>> connectAndJoin({
    required String roomCode,
    required String userId,
    required String operationId,
  }) async {
    _roomCode = roomCode;
    _userId = userId;
    _joinOperationId = operationId;
    _status.add(RealtimeStatus.connecting);
    if (!_socket.connected) {
      final connected = Completer<void>();
      late void Function(dynamic) onConnect;
      late void Function(dynamic) onError;
      onConnect = (_) {
        _socket.off('connect', onConnect);
        _socket.off('connect_error', onError);
        if (!connected.isCompleted) connected.complete();
      };
      onError = (_) {
        _socket.off('connect', onConnect);
        _socket.off('connect_error', onError);
        if (!connected.isCompleted) {
          connected.completeError(
            const ApiException(
                'socket_offline', 'Realtime connection is unavailable'),
          );
        }
      };
      _socket.on('connect', onConnect);
      _socket.on('connect_error', onError);
      _socket.connect();
      await connected.future.timeout(const Duration(seconds: 6));
    }
    final snapshot = await _joinCurrentRoom();
    _hasJoined = true;
    return snapshot;
  }

  Future<Map<String, dynamic>> _joinCurrentRoom() => emit(
        'room:join',
        {
          'roomCode': _roomCode,
          'userId': _userId,
          'operationId': _joinOperationId,
        },
      );

  Future<Map<String, dynamic>> emit(
    String event,
    Map<String, dynamic> payload,
  ) async {
    if (!_socket.connected) {
      throw const ApiException(
          'socket_offline', 'Realtime connection is unavailable');
    }
    final completer = Completer<Map<String, dynamic>>();
    final timer = Timer(const Duration(seconds: 6), () {
      if (!completer.isCompleted) {
        completer.completeError(
          const ApiException(
              'socket_timeout', 'Realtime update was not acknowledged'),
        );
      }
    });
    _socket.emitWithAck(event, payload, ack: (value) {
      if (completer.isCompleted) return;
      timer.cancel();
      final response =
          value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};
      if (response['ok'] == true && response['data'] is Map) {
        completer.complete(Map<String, dynamic>.from(response['data'] as Map));
        return;
      }
      final error = response['error'] is Map
          ? Map<String, dynamic>.from(response['error'] as Map)
          : <String, dynamic>{};
      completer.completeError(ApiException(
        error['code']?.toString() ?? 'socket_error',
        error['message']?.toString() ?? 'Realtime update failed',
        details: error['details'],
      ));
    });
    return completer.future;
  }

  void setTyping(bool value) {
    if (!_socket.connected || _roomCode == null || _userId == null) return;
    _socket.emit(value ? 'typing:start' : 'typing:stop', {
      'roomCode': _roomCode,
      'userId': _userId,
    });
  }

  Future<void> dispose() async {
    _socket.dispose();
    await Future.wait([
      _snapshots.close(),
      _presence.close(),
      _typing.close(),
      _status.close(),
    ]);
  }
}
