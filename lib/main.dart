import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:klayons/services/notification/fcmService.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
import 'firebase_options.dart';

// Background message handler must be top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('📩 Background message received: ${message.messageId}');
  print('Title: ${message.notification?.title}');
  print('Body: ${message.notification?.body}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialized');

    // Set background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Initialize FCM (permissions and handlers only - DON'T get token yet)
    await FCMService.initialize();
    print('✅ FCM initialized');
  } catch (e) {
    print('❌ Firebase/FCM initialization error: $e');
  }

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
    WidgetsBinding.instance.addObserver(this);

    // Initialize FCM token after app is fully loaded
    _initializeFCMTokenAfterDelay();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Initialize FCM token after app is loaded and APNs is ready
  /// Initialize FCM token after app is loaded and APNs is ready
  /// Initialize FCM token after app is loaded and APNs is ready
  Future<void> _initializeFCMTokenAfterDelay() async {
    try {
      // Wait longer for iOS APNs token to be fully registered
      await Future.delayed(Duration(seconds: 12)); // Increased from 3 to 12

      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('auth_token');

      if (authToken != null && authToken.isNotEmpty) {
        print('✅ User already authenticated, getting FCM token...');
        bool success = await FCMService.getFCMTokenAndSendToBackend();

        if (success) {
          print('🎉 FCM token retrieved and sent to backend');
        } else {
          print(
            '⚠️ FCM token retrieval/sending failed - will retry on token refresh',
          );
        }
      } else {
        print(
          'ℹ️ No auth token found - FCM token will be retrieved after login',
        );
      }
    } catch (e) {
      print('❌ Error initializing FCM token: $e');
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
        '/': (context) => KlayonsHomePage(key: homePageKey),
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
