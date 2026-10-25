import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
  } catch (_) {}
  debugPrint('NotificationService: Background message received: ${message.messageId}');
}

/// Manages push notifications and real-time device alerts for couple events
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  /// Callback when a foreground notification is received
  Function(RemoteMessage message)? onMessageReceived;

  /// Called with the new token so it can be stored in the couple document
  /// (Cloud Functions send pushes to the partner's token).
  void Function(String token)? onTokenChanged;

  Future<void> init() async {
    if (Firebase.apps.isEmpty) {
      debugPrint('NotificationService: Firebase not initialized, skipping.');
      return;
    }

    try {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      final messaging = FirebaseMessaging.instance;

      // Request permissions (iOS and Android 13+)
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      debugPrint('NotificationService: Permission status: ${settings.authorizationStatus}');

      // Get FCM token
      _fcmToken = await messaging.getToken();
      debugPrint('NotificationService: FCM Token obtained: $_fcmToken');

      // Listen for token refreshes
      messaging.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        debugPrint('NotificationService: FCM Token refreshed: $newToken');
        onTokenChanged?.call(newToken);
      });

      // Handle foreground notifications
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('NotificationService: Foreground message: ${message.notification?.title}');
        onMessageReceived?.call(message);
      });

      // Handle notification opened app event
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('NotificationService: App opened via notification: ${message.messageId}');
      });
    } catch (e) {
      debugPrint('NotificationService: Init error: $e');
    }
  }
}
