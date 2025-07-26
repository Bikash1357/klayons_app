import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';
import 'package:klayons/auth/login_screen.dart';
import 'package:klayons/screens/splash_screen.dart';

void main() {
  runApp(Klayons());
}

class Klayons extends StatelessWidget {
  const Klayons({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Klayons',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orangeAccent),
      ),
      initialRoute: 'login',
      routes: {'/login': (context) => LoginPage()},
    );
  }
}
