import 'package:flutter/foundation.dart';

class ApiConstants {
  static String? _baseUrlOverride;

  static void overrideBaseUrl(String url) {
    _baseUrlOverride = url;
  }

  static String get baseUrl {
    if (_baseUrlOverride != null) return _baseUrlOverride!;

    if (kReleaseMode) {
      return 'https://api.paydome.co';
    }
    if (kIsWeb) {
      return 'http://localhost:3000';
    }
    // Android Emulator uses 10.0.2.2 to reach host machine
    return 'http://10.0.2.2:3000';
  }
  static const String loginEndpoint = '/auth/login';
  static const String registerEndpoint = '/auth/register';
}
