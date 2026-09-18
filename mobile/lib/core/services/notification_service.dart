import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:dio/dio.dart';
import 'dart:io' show Platform;
import '../network/api_service.dart';
import 'device_token_sync.dart';

import 'package:firebase_messaging/firebase_messaging.dart';

/// Handles Firebase Cloud Messaging for push notifications.
class NotificationService with WidgetsBindingObserver {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  DeviceTokenSync? _tokenSync;
  StreamSubscription<String?>? _sessionSubscription;
  StreamSubscription<String>? _tokenSubscription;

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  final StreamController<RemoteMessage> _onMessageController =
      StreamController<RemoteMessage>.broadcast();
  Stream<RemoteMessage> get onMessage => _onMessageController.stream;

  final StreamController<RemoteMessage> _onMessageOpenedAppController =
      StreamController<RemoteMessage>.broadcast();
  Stream<RemoteMessage> get onMessageOpenedApp =>
      _onMessageOpenedAppController.stream;

  /// Initialize the notification service.
  /// Call this in main.dart after Firebase.initializeApp().
  Future<void> initialize() async {
    if (_tokenSync != null) return;
    final api = ApiService();
    _tokenSync = DeviceTokenSync(
      client: Dio(
        BaseOptions(
          baseUrl: ApiService.baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      ),
      platform: kIsWeb
          ? 'WEB'
          : Platform.isIOS
          ? 'IOS'
          : 'ANDROID',
    );
    _sessionSubscription = api.onTokenChanged.listen((session) {
      unawaited(_safelySync(_tokenSync!.updateSession(session)));
    });
    await _safelySync(_tokenSync!.updateSession(await api.getToken()));
    WidgetsBinding.instance.addObserver(this);
    // Request permission (iOS and Android 13+)
    await _requestPermission();

    // Get FCM token
    await _getToken();

    // Listen for token refresh
    _tokenSubscription = _messaging.onTokenRefresh.listen((newToken) {
      _fcmToken = newToken;
      unawaited(_safelySync(_tokenSync!.updateToken(newToken)));
    });

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Foreground message received: ${message.notification?.title}');
      _onMessageController.add(message);
    });

    // Handle when app is opened from a notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint(
        'App opened from notification: ${message.notification?.title}',
      );
      _onMessageOpenedAppController.add(message);
    });

    // Check if app was opened from a terminated state via notification
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint(
        'App opened from terminated state: ${initialMessage.notification?.title}',
      );
      _onMessageOpenedAppController.add(initialMessage);
    }
  }

  Future<void> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    debugPrint(
      'Notification permission status: ${settings.authorizationStatus}',
    );
  }

  Future<void> _getToken() async {
    try {
      // For iOS, get APNS token first
      if (!kIsWeb && Platform.isIOS) {
        await _messaging.getAPNSToken();
      }

      _fcmToken = await _messaging.getToken();
      unawaited(_safelySync(_tokenSync!.updateToken(_fcmToken)));
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
    }
  }

  Future<void> _safelySync(Future<void> operation) async {
    try {
      await operation;
    } catch (_) {
      // Do not expose device/session tokens or block login on network failure.
      debugPrint(
        'Push registration unavailable; will retry on resume or sign-in.',
      );
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _tokenSync != null) {
      unawaited(_getToken());
      unawaited(_safelySync(_tokenSync!.retry()));
    }
  }

  /// Subscribe to a topic for broadcast notifications.
  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
    debugPrint('Subscribed to topic: $topic');
  }

  /// Unsubscribe from a topic.
  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
    debugPrint('Unsubscribed from topic: $topic');
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sessionSubscription?.cancel();
    _tokenSubscription?.cancel();
    _onMessageController.close();
    _onMessageOpenedAppController.close();
  }
}

/// Background message handler - must be top-level function.
/// Register this in main.dart: FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Background message received: ${message.notification?.title}');
  // Handle background message if needed
}
