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
  static Future<bool> getFCMTokenAndSendToBackend() async {
    try {
      print('🔄 Getting FCM token...');

      // Get FCM token from Firebase
      String? fcmToken = await _firebaseMessaging.getToken();

      if (fcmToken == null || fcmToken.isEmpty) {
        print('❌ Failed to get FCM token');
        return false;
      }

      print('✅ FCM Token obtained: ${fcmToken.substring(0, 20)}...');

      // Save token locally for reference
      await _saveFCMTokenLocally(fcmToken);

      // Send token to Django backend
      bool success = await sendFCMTokenToBackend(fcmToken);

      if (success) {
        print('✅ FCM token successfully sent to backend');
      } else {
        print('❌ Failed to send FCM token to backend');
      }

      return success;
    } catch (e) {
      print('❌ Error getting/sending FCM token: $e');
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
        return false;
      }

      final url = Uri.parse('$baseUrl/save-fcm-token/');

      print('🌐 Sending FCM token to: $url');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({
          'fcm_token': fcmToken,
          'device_type': 'android', // or 'ios' - you can detect this
        }),
      );

      print('📡 FCM token save response status: ${response.statusCode}');
      print('📄 FCM token save response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ FCM token saved successfully on backend');
        return true;
      } else {
        print('❌ Failed to save FCM token: ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Error sending FCM token to backend: $e');
      return false;
    }
  }

  /// Save FCM token locally for reference
  static Future<void> _saveFCMTokenLocally(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fcm_token', token);
      print('💾 FCM token saved locally');
    } catch (e) {
      print('❌ Error saving FCM token locally: $e');
    }
  }

  /// Get locally stored FCM token
  static Future<String?> getLocalFCMToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('fcm_token');
    } catch (e) {
      print('❌ Error getting local FCM token: $e');
      return null;
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
      print('🔄 FCM Token refreshed: ${newToken.substring(0, 20)}...');
      sendFCMTokenToBackend(newToken);
    });
  }

  /// Delete FCM token on logout
  static Future<void> deleteFCMToken() async {
    try {
      await _firebaseMessaging.deleteToken();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('fcm_token');
      print('🗑️ FCM token deleted');
    } catch (e) {
      print('❌ Error deleting FCM token: $e');
    }
  }
}
