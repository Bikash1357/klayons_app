// // notification_service.dart
// import 'dart:convert';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
//
// class NotificationService {
//   static final FlutterLocalNotificationsPlugin _localNotifications =
//       FlutterLocalNotificationsPlugin();
//
//   static Future<void> initialize() async {
//     const AndroidInitializationSettings initializationSettingsAndroid =
//         AndroidInitializationSettings('@mipmap/ic_launcher');
//
//     const DarwinInitializationSettings initializationSettingsIOS =
//         DarwinInitializationSettings();
//
//     const InitializationSettings initializationSettings =
//         InitializationSettings(
//       android: initializationSettingsAndroid,
//       iOS: initializationSettingsIOS,
//     );
//
//     await _localNotifications.initialize(
//       initializationSettings,
//       onDidReceiveNotificationResponse: _onNotificationTap,
//     );
//
//     // Create notification channel for Android
//     const AndroidNotificationChannel channel = AndroidNotificationChannel(
//       'announcement_channel',
//       'Announcements',
//       description: 'Channel for announcement notifications',
//       importance: Importance.max,
//     );
//
//     await _localNotifications
//         .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
//         ?.createNotificationChannel(channel);
//   }
//
//   static Future<void> _onNotificationTap(NotificationResponse response) async {
//     // Handle notification tap - navigate to announcement screen
//     print('Notification tapped: ${response.payload}');
//   }
//
//   static Future<void> showNotification({
//     required int id,
//     required String title,
//     required String body,
//     String? payload,
//   }) async {
//     const AndroidNotificationDetails androidPlatformChannelSpecifics =
//         AndroidNotificationDetails(
//       'announcement_channel',
//       'Announcements',
//       channelDescription: 'Channel for announcement notifications',
//       importance: Importance.max,
//       priority: Priority.high,
//       showWhen: false,
//     );
//
//     const NotificationDetails platformChannelSpecifics =
//         NotificationDetails(android: androidPlatformChannelSpecifics);
//
//     await _localNotifications.show(
//       id,
//       title,
//       body,
//       platformChannelSpecifics,
//       payload: payload,
//     );
//   }
//
//   static Future<void> checkForNewAnnouncements() async {
//     try {
//       final response = await http.get(
//         Uri.parse('https://klayons-backend.vercel.app/api/announcement/'),
//         headers: {'Content-Type': 'application/json'},
//       );
//
//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
//         await _processAnnouncements(data);
//       }
//     } catch (e) {
//       print('Error checking announcements: $e');
//     }
//   }
//
//   static Future<void> _processAnnouncements(dynamic data) async {
//     final prefs = await SharedPreferences.getInstance();
//     final lastChecked = prefs.getInt('last_announcement_id') ?? 0;
//
//     // Assuming your API returns a list of announcements with id field
//     if (data is Map && data.containsKey('announcements')) {
//       final announcements = data['announcements'] as List;
//
//       for (var announcement in announcements) {
//         final announcementId = announcement['id'] ?? 0;
//
//         if (announcementId > lastChecked) {
//           await showNotification(
//             id: announcementId,
//             title: announcement['title'] ?? 'New Announcement',
//             body: announcement['message'] ?? 'Check out the latest announcement',
//             payload: jsonEncode(announcement),
//           );
//         }
//       }
//
//       // Update last checked ID
//       if (announcements.isNotEmpty) {
//         final latestId = announcements.first['id'] ?? lastChecked;
//         await prefs.setInt('last_announcement_id', latestId);
//       }
//     }
//   }
// }
