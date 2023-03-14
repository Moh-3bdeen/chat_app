import 'dart:async';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../provider/pass_data.dart';
import 'home_screen.dart';
import 'login_and_register.dart';

class SplashPage extends StatefulWidget {
  static const String id = "SplashPage";

  const SplashPage({Key? key}) : super(key: key);

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;
  Duration duration = const Duration(seconds: 2);
  bool isUserLogin = false;

  void isLogin(){
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        Provider.of<PassAllData>(context, listen: false).setUserId(user.uid);
        isUserLogin = true;
      }
      // return false;
    });
  }

  @override
  void initState() {
    super.initState();
    isLogin();
    controller = AnimationController(vsync: this, duration: duration);
    controller.forward();
    controller.addListener(() {
      setState(() {});
    });
    Timer(
      const Duration(milliseconds: 3000),
          () => isUserLogin ? Navigator.pushReplacementNamed(context, HomePage.id)
          : Navigator.pushReplacementNamed(context, LoginAndRegisterPage.id),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Hero(
                  tag: 'logo',
                  child: SizedBox(
                    height: controller.value * 200,
                    width: controller.value * 200,
                    child: Image.asset('images/logo.png'),
                  ),
                ),
                const SizedBox(height: 16),
                AnimatedTextKit(
                  repeatForever: true,
                  animatedTexts: [
                    TypewriterAnimatedText(
                      'Chat App',
                      textStyle: const TextStyle(
                        fontSize: 45.0,
                        fontWeight: FontWeight.w900,
                      ),
                      speed: const Duration(milliseconds: 200),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
