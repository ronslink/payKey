import 'package:flutter/foundation.dart';

/// Application Environment Configuration
/// 
/// Reads values injected at build time via --dart-define.
/// Defaults to Dev/Sandbox values if not provided.
class AppEnvironment {
  AppEnvironment._();

  /// Environment Name ("dev", "prod")
  static const String env = String.fromEnvironment('APP_ENV', defaultValue: 'dev');

  /// Is Production Build
  static const bool isProduction = env == 'prod';

  /// Backend API Base URL
  static const String apiUrl = String.fromEnvironment(
    'API_URL', 
    defaultValue: kReleaseMode 
        ? 'https://api.paydome.co' 
        : 'http://10.0.2.2:3000'
  );

  /// IntaSend Live Mode Flag
  static const bool intasendIsLive = bool.fromEnvironment('INTASEND_IS_LIVE', defaultValue: false);

  /// IntaSend Publishable Key
  static const String intasendPubKey = String.fromEnvironment('INTASEND_PUB_KEY', defaultValue: '');

  /// IntaSend Secret Key
  static const String intasendSecretKey = String.fromEnvironment('INTASEND_SECRET_KEY', defaultValue: '');
}
