import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Shows real system-style notifications on Android/iOS/desktop while
/// the app is in the foreground. Only ever compiled in on platforms with
/// `dart:io` (i.e. never on web — see local_notifications_stub.dart).
class LocalNotificationsHelper {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel =
      AndroidNotificationChannel(
    'subdiserve_channel',
    'SubdiServe Notifications',
    description: 'Booking updates, messages, ratings, and account alerts.',
    importance: Importance.high,
  );

  Future<void> initialize({required void Function() onTap}) async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const windowsInit = WindowsInitializationSettings(
      appName: 'SubdiServe',
      appUserModelId: 'com.example.subdiserve',
      guid: '20f4c934-c2e4-4569-a9a8-d7c0e6b65a47',
    );
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
      windows: windowsInit,
    );

    // Idinagdag ang 'settings:' named parameter
    await _plugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (response) => onTap(),
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);
  }

  Future<void> show({required int id, String? title, String? body}) async {
    // Idinagdag ang named parameters (id:, title:, body:, notificationDetails:)
    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }
}