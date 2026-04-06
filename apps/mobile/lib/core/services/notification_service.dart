import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Handles FCM push notification registration and local notification display.
///
/// Setup required before production:
///  1. Add google-services.json to android/app/
///  2. Add GoogleService-Info.plist to ios/Runner/ for iOS
class NotificationService {
  static final _localNotifications = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  // Stream of route strings from notification taps, e.g. '/payments/success'
  static final _routeController = StreamController<String>.broadcast();
  static Stream<String> get routeStream => _routeController.stream;

  static const _androidChannelId = 'amixpay_transactions';

  /// Call once at app startup (after Firebase.initializeApp).
  static Future<void> init() async {
    if (_initialized || kIsWeb) return;

    final messaging = FirebaseMessaging.instance;

    // Request permission (iOS / Android 13+)
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    // Android notification channel
    const androidChannel = AndroidNotificationChannel(
      _androidChannelId,
      'Transaction Alerts',
      description: 'Payment sent, received, and transfer status updates',
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    // Init local notifications
    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        // Local notification tapped — parse payload as route
        final route = details.payload;
        if (route != null && route.isNotEmpty) {
          _routeController.add(route);
        }
      },
    );

    // Foreground message handler — show local notification
    FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;
      if (notification != null) {
        _localNotifications.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              _androidChannelId,
              'Transaction Alerts',
              channelDescription: 'Payment sent, received, and transfer status updates',
              importance: Importance.high,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
            ),
          ),
          payload: message.data['route'] as String?,
        );
      }
    });

    // Background message tap — app was in background, user tapped notification
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      final route = message.data['route'] as String?;
      if (route != null && route.isNotEmpty) {
        _routeController.add(route);
      }
    });

    // Cold start — app was terminated, opened via notification tap
    final initial = await messaging.getInitialMessage();
    if (initial != null) {
      final route = initial.data['route'] as String?;
      if (route != null && route.isNotEmpty) {
        // Slight delay to ensure GoRouter is ready
        Future.delayed(const Duration(milliseconds: 500), () {
          _routeController.add(route);
        });
      }
    }

    _initialized = true;
  }

  /// Returns the FCM registration token for this device.
  static Future<String?> getToken() async {
    if (kIsWeb) return null;
    try {
      return await FirebaseMessaging.instance.getToken();
    } catch (_) {
      return null;
    }
  }

  /// Subscribe to a named FCM topic.
  static Future<void> subscribeToTopic(String topic) async {
    if (kIsWeb) return;
    await FirebaseMessaging.instance.subscribeToTopic(topic);
  }

  static void dispose() {
    _routeController.close();
  }
}
