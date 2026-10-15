import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;
import 'package:material_ui/material_ui.dart';
import 'features/auth/presentation/pages/login_screen.dart';
import 'firebase_options.dart';
import 'services/push_notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Must be registered BEFORE runApp so FCM can call it even when the
  // app is fully closed or backgrounded.
  if (defaultTargetPlatform != TargetPlatform.windows) {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  await PushNotificationService.instance.initialize();

  runApp(const SubdiServeApp());
}

class SubdiServeApp extends StatelessWidget {
  const SubdiServeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: PushNotificationService.navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'SubdiServe',
      home: const LoginScreen(),
    );
  }
}