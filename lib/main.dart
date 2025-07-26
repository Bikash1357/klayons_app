import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';
import 'package:klayons/auth/login_screen.dart';
import 'package:klayons/screens/bottom_screens/ticketbox_page.dart';
import 'package:klayons/screens/bottom_screens/uesr_profile/add_child.dart';
import 'package:klayons/screens/bottom_screens/uesr_profile/edit_profile_page.dart';
import 'package:klayons/screens/bottom_screens/uesr_profile/profile_page.dart';
import 'package:klayons/screens/bottom_screens/uesr_profile/user_settings_page.dart';
import 'package:klayons/screens/home_screen.dart';
import 'package:klayons/screens/notification.dart';
import 'package:klayons/screens/splash_screen.dart';

import 'auth/registration_screen.dart';

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
      initialRoute: '/',
      routes: {
        '/': (context) => KlayonsSplashScreen(),
        '/login': (context) => LoginPage(),
        '/register': (context) => RegistrationPage(),
        '/home': (context) => KlayonsHomePage(),
        '/user_edit_profile': (context) => EditProfilePage(),
        '/user_setting': (context) => SettingsPage(),
        '/notification': (context) => NotificationsPage(),
        '/activity_booking_page': (context) => ActivityBookingPage(),
        '/user_profile_page': (context) => UserProfilePage(),
        '/add_child': (context) => AddChildPage(),
      },
    );
  }
}
