import 'package:flutter/foundation.dart';

class ApiConfig {
  ApiConfig._();

  static String get origin {
    const configured = String.fromEnvironment('API_BASE_URL');
    if (configured.isNotEmpty) return configured.replaceAll(RegExp(r'/$'), '');
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:4000';
    }
    return 'http://127.0.0.1:4000';
  }

  static String get apiBaseUrl => '$origin/api';
}
