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

  /// Subscribe to a couple-specific channel
  Future<void> subscribeToCouple(String coupleId) async {
    if (Firebase.apps.isEmpty) return;
    try {
      final safeTopic = 'couple_${coupleId.replaceAll(RegExp(r'[^a-zA-Z0-9-_.~%]'), '_')}';
      await FirebaseMessaging.instance.subscribeToTopic(safeTopic);
      debugPrint('NotificationService: Subscribed to topic $safeTopic');
    } catch (e) {
      debugPrint('NotificationService: Error subscribing to topic: $e');
    }
  }

  /// Unsubscribe from couple topic
  Future<void> unsubscribeFromCouple(String coupleId) async {
    if (Firebase.apps.isEmpty) return;
    try {
      final safeTopic = 'couple_${coupleId.replaceAll(RegExp(r'[^a-zA-Z0-9-_.~%]'), '_')}';
      await FirebaseMessaging.instance.unsubscribeFromTopic(safeTopic);
      debugPrint('NotificationService: Unsubscribed from topic $safeTopic');
    } catch (e) {
      debugPrint('NotificationService: Error unsubscribing from topic: $e');
    }
  }
}
