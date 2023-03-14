import 'package:chat_app/provider/pass_data.dart';
import 'package:chat_app/screens/chat_screen.dart';
import 'package:chat_app/screens/home_screen.dart';
import 'package:chat_app/screens/login_and_register.dart';
import 'package:chat_app/screens/notifications_screen.dart';
import 'package:chat_app/screens/splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  print("Handling a background message: ${message.messageId}");
}

String? fcmToken;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseMessaging messaging = FirebaseMessaging.instance;

  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );

  print('User granted permission: ${settings.authorizationStatus}');

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await FirebaseMessaging.instance.subscribeToTopic("breaking_news");
  runApp(const FlashChat());
}

class FlashChat extends StatelessWidget {
  const FlashChat({super.key});

  void getFcm() async {
    fcmToken = await FirebaseMessaging.instance.getToken();
    print('fcm token: $fcmToken');
  }

  @override
  Widget build(BuildContext context) {
    getFcm();
    return ChangeNotifierProvider<PassAllData>(
        create: (_) => PassAllData(),
        child: MaterialApp(
          initialRoute: SplashPage.id,
          routes: {
            SplashPage.id: (context) => const SplashPage(),
            LoginAndRegisterPage.id: (context) => const LoginAndRegisterPage(),
            // WelcomeScreen.id: (context) => const WelcomeScreen(),
            // LoginScreen.id: (context) => LoginScreen(),
            // RegistrationScreen.id: (context) => const RegistrationScreen(),
            HomePage.id: (context) => const HomePage(),
            // ChatScreen.id: (context) => const ChatScreen(),
            NotificationsScreen.id: (context) => const NotificationsScreen(),
          },
        ));
  }
}
