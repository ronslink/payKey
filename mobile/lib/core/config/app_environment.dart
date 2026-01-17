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
  
  /// Google Client ID (Web)
  static const String googleClientId = String.fromEnvironment(
    'GOOGLE_CLIENT_ID',
    defaultValue: '654819674151-pthcgmk3kfu8jm224v1918dl6pm6djmv.apps.googleusercontent.com',
  );

  /// Apple Service ID (Web)
  static const String appleServiceId = String.fromEnvironment(
    'APPLE_SERVICE_ID',
    // Placeholder - User needs to configure this in Apple Developer Console
    defaultValue: 'com.paykey.app.service', 
  );

  /// Apple Redirect URI (Web)
  static const String appleRedirectUri = String.fromEnvironment(
    'APPLE_REDIRECT_URI',
    // Needs to match the one configured in Apple Developer Console
    // For localhost testing, this often requires tunneling or specific config
    defaultValue: 'https://paykey-2711d.firebaseapp.com/__/auth/handler',
  );
}
