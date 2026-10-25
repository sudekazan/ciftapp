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

  Future<void> _refreshToken() async {
    try {
      // Registration tokens are what the Admin SDK (Cloud Functions) sends to;
      // the newer FID-based register() API is not supported there yet.
      // ignore: deprecated_member_use
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null && token != _fcmToken) {
        _fcmToken = token;
        onTokenChanged?.call(token);
      }
    } catch (e) {
      // iOS: no APNs token yet (before permission / on simulator).
      debugPrint('NotificationService: token not available yet: $e');
    }
  }

  /// Whether the system permission prompt was already answered.
  Future<bool> hasAskedPermission() async {
    if (Firebase.apps.isEmpty) return true;
    try {
      final settings = await FirebaseMessaging.instance.getNotificationSettings();
      return settings.authorizationStatus != AuthorizationStatus.notDetermined;
    } catch (_) {
      return true;
    }
  }

  /// Shows the system prompt (iOS, Android 13+). Returns whether it was granted.
  Future<bool> requestPermission() async {
    if (Firebase.apps.isEmpty) return false;
    try {
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      debugPrint('NotificationService: Permission status: ${settings.authorizationStatus}');
      await _refreshToken();
      return settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    } catch (e) {
      debugPrint('NotificationService: requestPermission error: $e');
      return false;
    }
  }

  Future<void> init() async {
    if (Firebase.apps.isEmpty) {
      debugPrint('NotificationService: Firebase not initialized, skipping.');
      return;
    }

    try {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      final messaging = FirebaseMessaging.instance;

      // The permission prompt is NOT shown here: it is requested after pairing
      // with an explanation (see requestPermission), which gets far fewer denials.
      await _refreshToken();

      // Listen for token refreshes
      // ignore: deprecated_member_use
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
