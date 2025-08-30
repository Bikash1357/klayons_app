import 'package:flutter/material.dart';
import 'package:klayons/services/notification/local_notification_service.dart';
import 'package:klayons/services/notification/realtime_notif_service.dart';
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
        // This now works as a fallback to the real-time service
        await LocalNotificationService.checkForNewAnnouncements();
        break;
      case "realTimeCheck":
        // Additional background check for real-time service
        await RealTimeNotificationService.smartCheckForNewAnnouncements();
        break;
    }
    return Future.value(true);
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize local notifications
  await LocalNotificationService.initialize();

  // Initialize real-time notification service (no Firebase needed)
  await RealTimeNotificationService.initialize();

  // Initialize background task manager
  await Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: true, // Set to false in production
  );

  // Register multiple background tasks for better coverage

  // Primary real-time check (frequent)
  await Workmanager().registerPeriodicTask(
    "realTimeCheckTask",
    "realTimeCheck",
    frequency: Duration(minutes: 15), // Android minimum
    constraints: Constraints(
      networkType: NetworkType.connected,
      requiresBatteryNotLow:
          false, // Allow even on low battery for important notifications
    ),
  );

  // Fallback check (less frequent)
  await Workmanager().registerPeriodicTask(
    "fallbackCheckTask",
    "checkAnnouncements",
    frequency: Duration(hours: 1),
    constraints: Constraints(
      networkType: NetworkType.connected,
      requiresBatteryNotLow: true,
    ),
  );

  runApp(KlayonsApp());
}

class KlayonsApp extends StatefulWidget {
  const KlayonsApp({super.key});

  @override
  State<KlayonsApp> createState() => _KlayonsAppState();
}

class _KlayonsAppState extends State<KlayonsApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    // Add lifecycle observer to handle app state changes
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    // Clean up
    WidgetsBinding.instance.removeObserver(this);
    RealTimeNotificationService.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Handle app lifecycle changes for optimal polling
    switch (state) {
      case AppLifecycleState.resumed:
        print('App resumed - starting foreground polling');
        RealTimeNotificationService.onAppResumed();
        break;
      case AppLifecycleState.paused:
        print('App paused - switching to background polling');
        RealTimeNotificationService.onAppPaused();
        break;
      case AppLifecycleState.detached:
        print('App detached');
        RealTimeNotificationService.stopPolling();
        break;
      case AppLifecycleState.inactive:
        // App is transitioning between states
        break;
      case AppLifecycleState.hidden:
        // App is hidden (new in Flutter 3.13+)
        break;
    }
  }

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

// Optional: Global app state manager for notifications
class NotificationAppState {
  static bool _isInitialized = false;

  static Future<void> ensureInitialized() async {
    if (_isInitialized) return;

    await LocalNotificationService.initialize();
    await RealTimeNotificationService.initialize();

    _isInitialized = true;
  }

  static Future<void> refreshNotifications() async {
    await RealTimeNotificationService.manualRefresh();
  }

  static void startRealTimeService() {
    RealTimeNotificationService.startPolling();
  }

  static void stopRealTimeService() {
    RealTimeNotificationService.stopPolling();
  }

  static Map<String, dynamic> getServiceStatus() {
    return RealTimeNotificationService.getServiceStatus();
  }
}
