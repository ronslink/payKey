import 'package:flutter/foundation.dart';

class ApiConstants {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000';
    }
    // Android Emulator uses 10.0.2.2 to reach host machine
    return 'http://10.0.2.2:3000';
  }
  static const String loginEndpoint = '/auth/login';
  static const String registerEndpoint = '/auth/register';
}
