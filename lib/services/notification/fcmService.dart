import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class FCMService {
  static const String baseUrl = 'https://dev-klayons.onrender.com/api';
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;

  /// Initialize FCM and request permissions
  static Future<void> initialize() async {
    try {
      // Request notification permissions (iOS)
      NotificationSettings settings = await _firebaseMessaging
          .requestPermission(
            alert: true,
            badge: true,
            sound: true,
            provisional: false,
          );

      print('📱 FCM Permission status: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('✅ User granted permission');

        // IMPORTANT: Wait a bit for APNs token to be registered
        print('⏳ Waiting for APNs token registration...');
        await Future.delayed(Duration(seconds: 2));
      } else if (settings.authorizationStatus ==
          AuthorizationStatus.provisional) {
        print('⚠️ User granted provisional permission');
      } else {
        print('❌ User declined or has not accepted permission');
      }

      // Setup message handlers
      _setupMessageHandlers();
    } catch (e) {
      print('❌ FCM initialization error: $e');
    }
  }

  /// Get FCM token and send to backend
  /// Get FCM token and send to backend
  static Future<bool> getFCMTokenAndSendToBackend() async {
    try {
      print('🔄 Getting FCM token...');

      // Wait for APNs token first (iOS only)
      String? apnsToken = await _firebaseMessaging.getAPNSToken();

      // If APNs token is not available, wait and retry
      if (apnsToken == null) {
        print('⏳ APNs token not available yet, waiting 3 seconds...');
        await Future.delayed(Duration(seconds: 3));
        apnsToken = await _firebaseMessaging.getAPNSToken();

        if (apnsToken == null) {
          print('⏳ APNs token still not available, waiting 5 more seconds...');
          await Future.delayed(Duration(seconds: 5));
          apnsToken = await _firebaseMessaging.getAPNSToken();
        }
      }

      if (apnsToken != null) {
        print('✅ APNs Token obtained: $apnsToken');
      } else {
        print(
          '⚠️ APNs token still not available. This might be okay on Android.',
        );
      }

      // Now get FCM token from Firebase
      String? fcmToken = await _firebaseMessaging.getToken();

      if (fcmToken == null || fcmToken.isEmpty) {
        print('❌ Failed to get FCM token - token is null or empty');
        return false;
      }

      // Print FULL FCM token for debugging
      print('✅ FCM Token obtained successfully!');
      print('📋 FULL FCM TOKEN: $fcmToken');
      print('📏 Token length: ${fcmToken.length} characters');

      // Save token locally for reference
      await _saveFCMTokenLocally(fcmToken);

      // Send token to Django backend
      print('🚀 Sending FCM token to backend...');
      bool success = await sendFCMTokenToBackend(fcmToken);

      if (success) {
        print('✅ FCM token successfully sent to backend');
      } else {
        print('❌ Failed to send FCM token to backend');
      }

      return success;
    } catch (e, stackTrace) {
      print('❌ Error getting/sending FCM token: $e');
      print('📍 Stack trace: $stackTrace');
      return false;
    }
  }

  /// Send FCM token to Django backend
  static Future<bool> sendFCMTokenToBackend(String fcmToken) async {
    try {
      // Get auth token from storage
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('auth_token');

      if (authToken == null || authToken.isEmpty) {
        print('❌ No auth token found. Cannot send FCM token.');
        print('💡 Make sure user is logged in before registering FCM token');
        return false;
      }

      print('✅ Auth token found');

      final url = Uri.parse('$baseUrl/notifications/devices/register/');

      print('🌐 Sending FCM token to: $url');
      print('📦 Request body: {"device_token": "$fcmToken"}');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({'device_token': fcmToken}),
      );

      print('📡 Response status: ${response.statusCode}');
      print('📄 Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ FCM token saved successfully on backend');
        return true;
      } else {
        print('❌ Failed to save FCM token on backend');
        print('❌ Status code: ${response.statusCode}');
        print('❌ Error message: ${response.body}');
        return false;
      }
    } catch (e, stackTrace) {
      print('❌ Error sending FCM token to backend: $e');
      print('📍 Stack trace: $stackTrace');
      return false;
    }
  }

  /// Save FCM token locally for reference
  static Future<void> _saveFCMTokenLocally(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fcm_token', token);
      print('💾 FCM token saved locally in SharedPreferences');
    } catch (e) {
      print('❌ Error saving FCM token locally: $e');
    }
  }

  /// Get locally stored FCM token
  static Future<String?> getLocalFCMToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('fcm_token');
      if (token != null) {
        print('📋 Retrieved local FCM token: $token');
      } else {
        print('⚠️ No FCM token found in local storage');
      }
      return token;
    } catch (e) {
      print('❌ Error getting local FCM token: $e');
      return null;
    }
  }

  /// Get APNs token (iOS specific) - for debugging
  static Future<void> getAPNsToken() async {
    try {
      String? apnsToken = await _firebaseMessaging.getAPNSToken();
      if (apnsToken != null) {
        print('📱 APNs Token: $apnsToken');
      } else {
        print('⚠️ APNs token not available yet. Waiting...');
        // Sometimes APNs token takes a moment to be available
        await Future.delayed(Duration(seconds: 3));
        apnsToken = await _firebaseMessaging.getAPNSToken();
        if (apnsToken != null) {
          print('📱 APNs Token (after delay): $apnsToken');
        } else {
          print('❌ APNs token still not available');
        }
      }
    } catch (e) {
      print('❌ Error getting APNs token: $e');
    }
  }

  /// Setup message handlers for foreground/background notifications
  static void _setupMessageHandlers() {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📩 Foreground message received');
      print('Title: ${message.notification?.title}');
      print('Body: ${message.notification?.body}');
      print('Data: ${message.data}');

      // You can show a local notification here if needed
    });

    // Handle background messages (when app is in background but not terminated)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('📩 Background message opened');
      print('Title: ${message.notification?.title}');
      print('Data: ${message.data}');

      // Handle navigation based on notification data
    });

    // Handle token refresh
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      print('🔄 FCM Token refreshed!');
      print('📋 NEW FCM TOKEN: $newToken');
      sendFCMTokenToBackend(newToken);
    });
  }

  /// Delete FCM token on logout
  static Future<void> deleteFCMToken() async {
    try {
      await _firebaseMessaging.deleteToken();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('fcm_token');
      print('🗑️ FCM token deleted from Firebase and local storage');
    } catch (e) {
      print('❌ Error deleting FCM token: $e');
    }
  }
}
