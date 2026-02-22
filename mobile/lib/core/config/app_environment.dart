import 'dart:io';
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
  
  /// Google Web / Android OAuth 2.0 Client ID (126777889122-...).
  /// Used as serverClientId on Android so the ID token audience matches the backend.
  /// This is the canonical client ID going forward.
  static const String googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue: '126777889122-v87pps2i4i9m5m3p8r2infbvspjq62mg.apps.googleusercontent.com',
  );

  /// Google iOS OAuth 2.0 Client ID (104336380998-...) from GoogleService-Info.plist.
  /// Used as clientId on iOS — the plist drives the token audience on that platform.
  static const String googleIosClientId = String.fromEnvironment(
    'GOOGLE_CLIENT_ID',
    defaultValue: '104336380998-jenvsdcitnun7un5j00aqnoggnrefbaa.apps.googleusercontent.com',
  );

  /// The correct Google client ID for the current platform.
  /// - Android: web client ID (serverClientId) → tokens issued with 126... audience
  /// - iOS:     iOS client ID (from plist)     → tokens issued with 104... audience
  /// Both are accepted by the backend.
  static String get googleClientId {
    if (!kIsWeb && Platform.isAndroid) return googleWebClientId;
    return googleIosClientId;
  }

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
    defaultValue: 'https://paydome-9f9a7.firebaseapp.com/__/auth/handler',
  );
}
