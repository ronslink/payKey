import 'dart:async';
import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;

import 'package:firebase_messaging/firebase_messaging.dart';

/// Handles Firebase Cloud Messaging for push notifications.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  
  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  final StreamController<RemoteMessage> _onMessageController =
      StreamController<RemoteMessage>.broadcast();
  Stream<RemoteMessage> get onMessage => _onMessageController.stream;

  final StreamController<RemoteMessage> _onMessageOpenedAppController =
      StreamController<RemoteMessage>.broadcast();
  Stream<RemoteMessage> get onMessageOpenedApp => _onMessageOpenedAppController.stream;

  /// Initialize the notification service.
  /// Call this in main.dart after Firebase.initializeApp().
  Future<void> initialize() async {
    // Request permission (iOS and Android 13+)
    await _requestPermission();

    // Get FCM token
    await _getToken();

    // Listen for token refresh
    _messaging.onTokenRefresh.listen((newToken) {
      _fcmToken = newToken;
      debugPrint('FCM Token refreshed: $newToken');
      // TODO: Send new token to backend
    });

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Foreground message received: ${message.notification?.title}');
      _onMessageController.add(message);
    });

    // Handle when app is opened from a notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('App opened from notification: ${message.notification?.title}');
      _onMessageOpenedAppController.add(message);
    });

    // Check if app was opened from a terminated state via notification
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('App opened from terminated state: ${initialMessage.notification?.title}');
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

    debugPrint('Notification permission status: ${settings.authorizationStatus}');
  }

  Future<void> _getToken() async {
    try {
      // For iOS, get APNS token first
      if (!kIsWeb && Platform.isIOS) {
        final apnsToken = await _messaging.getAPNSToken();
        debugPrint('APNS Token: $apnsToken');
      }

      _fcmToken = await _messaging.getToken();
      debugPrint('FCM Token: $_fcmToken');
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
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
