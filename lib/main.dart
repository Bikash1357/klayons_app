import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';
import 'package:klayons/auth/login_screen.dart';
import 'package:klayons/screens/bottom_screens/ticketbox_page.dart';
import 'package:klayons/screens/bottom_screens/uesr_profile/Childs/add_child.dart';
import 'package:klayons/screens/bottom_screens/uesr_profile/Childs/child_intrest.dart';
import 'package:klayons/screens/bottom_screens/uesr_profile/profile_page.dart';
import 'package:klayons/screens/bottom_screens/uesr_profile/user_settings_page.dart';
import 'package:klayons/screens/course_details_page.dart';
import 'package:klayons/screens/home_screen.dart';
import 'package:klayons/screens/notification.dart';
import 'package:klayons/screens/splash_screen.dart';
import 'package:klayons/services/ActivitiedsServices.dart';
import 'package:klayons/services/get_ChildServices.dart';
import 'package:klayons/services/get_societyname.dart';
import 'package:klayons/services/notification/background_service.dart';
import 'package:klayons/services/notification/notification_service.dart';

import 'auth/registration_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize services
  //await NotificationService.initialize();
  //await BackgroundService.initialize();

  runApp(Klayons());
}

class Klayons extends StatelessWidget {
  const Klayons({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Klayons',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orangeAccent),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => KlayonsSplashScreen(),
        '/login': (context) => LoginPage(),
        '/signup': (context) => RegistrationPage(),
        '/home': (context) => KlayonsHomePage(),
        '/user_setting': (context) => SettingsPage(),
        '/notification': (context) => NotificationsPage(),
        '/activity_booking_page': (context) => ActivityBookingPage(),
        //'/course_detail_page': (context) => CourseDetailPage(),
        '/user_profile_page': (context) => UserProfilePage(),
        '/add_child': (context) => AddChildPage(),
        '/get_society_name': (context) => GetSocietyname(),
        //'/get_child_data': (context) => ChildrenListScreen(),
      },
    );
  }
}
