import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:material_ui/material_ui.dart';

import '../screens/notifications/notification_screen.dart';
import 'local_notifications_helper.dart';

/// Must be a TOP-LEVEL (or static) function — this is what fires when a
/// push notification arrives while the app is fully closed or in the
/// background. It can't touch any UI, just light background work.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Nothing to do here for now — Android/iOS show the system notification
  // automatically for background/terminated messages. This handler exists
  // so FCM has somewhere to call, and so we could add background data
  // processing later if needed.
}

/// Sets up push notifications for the app: requests permission, grabs the
/// device's FCM token and saves it to Firestore, shows a notification
/// when a push arrives while the app is open (foreground), and opens the
/// Notifications screen when a push is tapped.
///
/// Foreground display is handled by [LocalNotificationsHelper], which is
/// a real system notification on Android/iOS/desktop and a harmless
/// no-op on web (where we show an in-app banner instead).
class PushNotificationService {
  PushNotificationService._();
  static final PushNotificationService instance = PushNotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final LocalNotificationsHelper _localNotifications =
      LocalNotificationsHelper();

  /// Global navigator key so we can push a screen (or show a banner) from
  /// outside the widget tree.
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    await _localNotifications.initialize(onTap: _openNotificationsScreen);

    if (defaultTargetPlatform == TargetPlatform.windows) return;

    // Ask the user for permission (required on iOS, Android 13+, and web).
    try {
      await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
    } catch (_) {
      // Non-fatal — some platforms/browsers may reject or not support this.
    }

    // Foreground messages.
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      if (notification == null) return;

      if (kIsWeb) {
        _showWebForegroundBanner(notification.title, notification.body);
      } else {
        _localNotifications.show(
          id: notification.hashCode,
          title: notification.title,
          body: notification.body,
        );
      }
    });

    // Tapped a notification while app was in the background.
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _openNotificationsScreen();
    });

    // App was fully closed and opened via a notification tap.
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _openNotificationsScreen();
    }
  }

  void _showWebForegroundBanner(String? title, String? body) {
    final context = navigatorKey.currentState?.overlay?.context;
    if (context == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            '${title ?? 'New notification'}${body != null ? ': $body' : ''}'),
        backgroundColor: const Color(0xFF0284C7),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'View',
          textColor: Colors.white,
          onPressed: _openNotificationsScreen,
        ),
      ),
    );
  }

  void _openNotificationsScreen() {
    final context = navigatorKey.currentState?.overlay?.context;
    if (context == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotificationScreen()),
    );
  }

  /// Fetches this device's FCM token and saves it on the user's Firestore
  /// doc. Call this right after a successful login. Also keeps saving
  /// automatically if the token ever refreshes (e.g. after a reinstall).
  Future<void> saveTokenForUser(String userId) async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        await _saveToken(userId, token);
      }

      _messaging.onTokenRefresh.listen((newToken) {
        _saveToken(userId, newToken);
      });
    } catch (_) {
      // Non-fatal: push notifications just won't work for this device
      // if the token can't be fetched (e.g. simulator without Google Play
      // services, or a browser blocking it). The rest of the app keeps
      // working normally.
    }
  }

  Future<void> _saveToken(String userId, String token) async {
    await FirebaseFirestore.instance.collection('users').doc(userId).set(
      {'fcmToken': token},
      SetOptions(merge: true),
    );
  }

  /// Call on logout so this device stops receiving pushes meant for the
  /// account that just signed out.
  Future<void> clearTokenForUser(String userId) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).set(
        {'fcmToken': FieldValue.delete()},
        SetOptions(merge: true),
      );
      await _messaging.deleteToken();
    } catch (_) {
      // Non-fatal.
    }
  }
}