import 'package:flutter/foundation.dart';

import '../config/app_environment.dart';

class ApiConstants {
  static String? _baseUrlOverride;

  static void overrideBaseUrl(String url) {
    _baseUrlOverride = url;
  }

  static String get baseUrl {
    if (_baseUrlOverride != null) return _baseUrlOverride!;

    // Use environment configuration
    String url = AppEnvironment.apiUrl;

    // Fix for Web if default emulator IP is returned
    if (kIsWeb && url == 'http://10.0.2.2:3000') {
      return 'http://localhost:3000';
    }
    
    return url;
  }
  static const String loginEndpoint = '/auth/login';
  static const String registerEndpoint = '/auth/register';
}
