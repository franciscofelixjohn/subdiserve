/// No-op stand-in used on platforms where `flutter_local_notifications`
/// isn't supported (currently: Flutter Web). Keeps the exact same method
/// shapes as the real mobile implementation so callers never need to
/// check the platform themselves.
class LocalNotificationsHelper {
  Future<void> initialize({required void Function() onTap}) async {
    // No system notifications on web — foreground pushes are shown as an
    // in-app banner instead (see PushNotificationService).
  }

  Future<void> show({required int id, String? title, String? body}) async {
    // Intentionally does nothing on web.
  }
}