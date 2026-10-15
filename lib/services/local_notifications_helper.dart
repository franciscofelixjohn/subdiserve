/// Picks the right LocalNotificationsHelper implementation at compile
/// time: the real one (using flutter_local_notifications) on any
/// platform with dart:io (Android, iOS, Windows, Linux, macOS), and a
/// harmless no-op stub everywhere else (Flutter Web).
///
/// This avoids ever compiling flutter_local_notifications-specific code
/// into the web build, which is what caused the "too many positional
/// arguments" build errors when running on Chrome.
library;
export 'local_notifications_stub.dart'
    if (dart.library.io) 'local_notifications_mobile.dart';