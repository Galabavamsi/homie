import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/api_config.dart';

class ApiException implements Exception {
  const ApiException(this.code, this.message, {this.status, this.details});

  final String code;
  final String message;
  final int? status;
  final Object? details;

  @override
  String toString() => message;
}

class HomieApi {
  HomieApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<Map<String, dynamic>> health() => _get('/health');

  Future<Map<String, dynamic>> swiggyAuthStart(String userId) =>
      _get('/auth/swiggy/start', {'userId': userId});

  Future<Map<String, dynamic>> swiggyAuthStatus(String userId) =>
      _get('/auth/swiggy/status', {'userId': userId});

  Future<Map<String, dynamic>> addresses(String userId) =>
      _get('/mcp/addresses', {'userId': userId});

  Future<Map<String, dynamic>> selectAddress({
    required String userId,
    required String addressId,
  }) =>
      _post('/mcp/addresses/select', {
        'userId': userId,
        'addressId': addressId,
      });

  Future<Map<String, dynamic>> createGuest(String name) =>
      _post('/users/guest', {'name': name});

  Future<Map<String, dynamic>> createRoom({
    required String name,
    required int budget,
    required String hostUserId,
  }) =>
      _post(
          '/rooms', {'name': name, 'budget': budget, 'hostUserId': hostUserId});

  Future<Map<String, dynamic>> getRoom(String code) => _get('/rooms/$code');

  Future<Map<String, dynamic>> joinRoom(
    String code,
    String userId,
    String operationId,
  ) =>
      _post(
          '/rooms/$code/join', {'userId': userId, 'operationId': operationId});

  Future<Map<String, dynamic>> restaurants({
    String? query,
    String? tag,
    String? userId,
    String? addressId,
  }) {
    final parameters = <String, String>{
      if (query != null && query.isNotEmpty) 'q': query,
      if (tag != null && tag.isNotEmpty) 'tag': tag,
      if (userId != null && userId.isNotEmpty) 'userId': userId,
      if (addressId != null && addressId.isNotEmpty) 'addressId': addressId,
    };
    return _get('/mcp/restaurants', parameters);
  }

  Future<Map<String, dynamic>> menu(
    String restaurantId, {
    String? userId,
    String? addressId,
  }) =>
      _get('/mcp/menu/$restaurantId', {
        if (userId != null && userId.isNotEmpty) 'userId': userId,
        if (addressId != null && addressId.isNotEmpty) 'addressId': addressId,
      });

  Future<Map<String, dynamic>> sendMessage(
    String code,
    Map<String, dynamic> body,
  ) =>
      _post('/rooms/$code/messages', body);

  Future<Map<String, dynamic>> vote(
    String code,
    Map<String, dynamic> body,
  ) =>
      _put('/rooms/$code/vote', body);

  Future<Map<String, dynamic>> setCartItem(
    String code,
    String itemId,
    Map<String, dynamic> body,
  ) =>
      _put('/rooms/$code/cart/items/$itemId', body);

  Future<Map<String, dynamic>> checkout(
    String code,
    Map<String, dynamic> body,
  ) =>
      _post('/rooms/$code/checkout', body);

  Future<Map<String, dynamic>> _get(
    String path, [
    Map<String, String>? query,
  ]) async {
    final uri = Uri.parse('${ApiConfig.apiBaseUrl}$path')
        .replace(queryParameters: query);
    return _decode(await _withTimeout(_client.get(uri)));
  }

  Future<Map<String, dynamic>> _post(
      String path, Map<String, dynamic> body) async {
    return _decode(await _withTimeout(_client.post(
      Uri.parse('${ApiConfig.apiBaseUrl}$path'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    )));
  }

  Future<Map<String, dynamic>> _put(
      String path, Map<String, dynamic> body) async {
    return _decode(await _withTimeout(_client.put(
      Uri.parse('${ApiConfig.apiBaseUrl}$path'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    )));
  }

  Future<http.Response> _withTimeout(Future<http.Response> request) async {
    try {
      return await request.timeout(const Duration(seconds: 8));
    } on TimeoutException {
      throw const ApiException(
          'timeout', 'The local API took too long to respond');
    } on http.ClientException {
      throw const ApiException(
        'offline',
        'Cannot reach the Homie API. Start the backend and try again.',
      );
    }
  }

  Map<String, dynamic> _decode(http.Response response) {
    final decoded =
        response.body.isEmpty ? <String, dynamic>{} : jsonDecode(response.body);
    final payload = decoded is Map
        ? Map<String, dynamic>.from(decoded)
        : <String, dynamic>{'data': decoded};
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final error = payload['error'] is Map
          ? Map<String, dynamic>.from(payload['error'] as Map)
          : <String, dynamic>{};
      throw ApiException(
        error['code']?.toString() ?? 'http_${response.statusCode}',
        error['message']?.toString() ?? 'Request failed',
        status: response.statusCode,
        details: error['details'],
      );
    }
    return payload;
  }

  void close() => _client.close();
}
