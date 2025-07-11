import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';
import 'package:klayons/auth/login_screen.dart';
import 'package:klayons/screens/splash_screen.dart';

void main() {
  runApp(DevicePreview(builder: (contex) => (Klayons())));
}

class Klayons extends StatelessWidget {
  const Klayons({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orangeAccent),
      ),
      home: MinimalSplashScreen(),
    );
  }
}
