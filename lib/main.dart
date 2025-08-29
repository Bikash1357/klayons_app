import 'package:flutter/material.dart';
import 'package:klayons/services/notification/local_notification_service.dart';
import 'package:workmanager/workmanager.dart';
import 'package:klayons/auth/login_screen.dart';
import 'package:klayons/auth/signupPage.dart';
import 'package:klayons/screens/bottom_screens/enrolledpage.dart';
import 'package:klayons/screens/bottom_screens/uesr_profile/Childs/add_child.dart';
import 'package:klayons/screens/bottom_screens/uesr_profile/profile_page.dart';
import 'package:klayons/screens/bottom_screens/uesr_profile/user_settings_page.dart';
import 'package:klayons/screens/home_screen.dart';
import 'package:klayons/screens/notification.dart';
import 'package:klayons/screens/splash_screen.dart';
import 'package:klayons/services/get_societyname.dart';

// Background task dispatcher
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    switch (task) {
      case "checkAnnouncements":
        await LocalNotificationService.checkForNewAnnouncements();
        break;
    }
    return Future.value(true);
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize local notifications
  await LocalNotificationService.initialize();

  // Initialize background task manager
  await Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: true, // Set to false in production
  );

  // Register periodic task to check for new announcements every 15 minutes
  await Workmanager().registerPeriodicTask(
    "checkAnnouncementsTask",
    "checkAnnouncements",
    frequency: Duration(minutes: 1),
    constraints: Constraints(
      networkType: NetworkType.connected, // Only run when connected to internet
      requiresBatteryNotLow: true,
    ),
  );

  runApp(Klayons());
}

class Klayons extends StatelessWidget {
  const Klayons({super.key});

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
        '/demo_registration': (context) => SignUnPage(),
        '/home': (context) => KlayonsHomePage(),
        '/user_setting': (context) => SettingsPage(),
        '/notification': (context) => NotificationsPage(),
        '/activity_booking_page': (context) => EnrolledPage(),
        '/user_profile_page': (context) => UserProfilePage(),
        '/add_child': (context) => AddChildPage(),
        '/get_society_name': (context) => GetSocietyname(),
      },
    );
  }
}
