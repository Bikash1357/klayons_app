import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:app_settings/app_settings.dart';
import 'dart:io' show Platform;

// Model classes for API response
class AnnouncementModel {
  final int id;
  final String title;
  final String content;
  final String scope;
  final int? activity;
  final String? activityName;
  final List<int>? batches;
  final List<String>? batchNames;
  final int? society;
  final String? societyName;
  final String? attachment;
  final DateTime? expiry;
  final bool isActive;
  final int createdBy;
  final String? createdByName;
  final DateTime createdAt;

  AnnouncementModel({
    required this.id,
    required this.title,
    required this.content,
    required this.scope,
    this.activity,
    this.activityName,
    this.batches,
    this.batchNames,
    this.society,
    this.societyName,
    this.attachment,
    this.expiry,
    required this.isActive,
    required this.createdBy,
    this.createdByName,
    required this.createdAt,
  });

  factory AnnouncementModel.fromJson(Map<String, dynamic> json) {
    return AnnouncementModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      scope: json['scope'] ?? 'GENERAL',
      activity: json['activity'],
      activityName: json['activity_name'],
      batches: json['batches'] != null ? List<int>.from(json['batches']) : null,
      batchNames: json['batch_names'] != null
          ? List<String>.from(json['batch_names'])
          : null,
      society: json['society'],
      societyName: json['society_name'],
      attachment: json['attachment'],
      expiry: json['expiry'] != null ? DateTime.parse(json['expiry']) : null,
      isActive: json['is_active'] ?? true,
      createdBy: json['created_by'] ?? 0,
      createdByName: json['created_by_name'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  // Helper method to get time ago string
  String getTimeAgo() {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()}w';
    } else {
      return '${(difference.inDays / 30).floor()}mo';
    }
  }

  // Helper method to check if announcement is recent (unread)
  bool get isUnread {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    return difference.inHours <
        24; // Consider announcements from last 24 hours as unread
  }
}

// Enhanced service class for handling API calls and notification permissions
class NotificationService {
  static const String baseUrl = 'https://dev-klayonsapi.vercel.app/api';
  static const String announcementsEndpoint = '/announcements';

  // Flutter Local Notifications instance
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static bool _isInitialized = false;

  // ========== EXISTING ANNOUNCEMENT METHODS ==========

  // Method to get all announcements
  static Future<List<AnnouncementModel>> getAnnouncements({
    int? activity,
    String? scope,
    String? search,
    int? society,
  }) async {
    try {
      // Build query parameters
      Map<String, String> queryParams = {};

      if (activity != null) {
        queryParams['activity'] = activity.toString();
      }
      if (scope != null) {
        queryParams['scope'] = scope;
      }
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (society != null) {
        queryParams['society'] = society.toString();
      }

      // Build URI with query parameters
      String url = baseUrl + announcementsEndpoint;
      if (queryParams.isNotEmpty) {
        url +=
            '?' +
            queryParams.entries
                .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
                .join('&');
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          // Add authentication headers if needed
          // 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        return jsonData
            .map((item) => AnnouncementModel.fromJson(item))
            .toList();
      } else {
        throw Exception('Failed to load announcements: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching announcements: $e');
    }
  }

  // Method to get announcements by specific scope
  static Future<List<AnnouncementModel>> getAnnouncementsByScope(String scope) {
    return getAnnouncements(scope: scope);
  }

  // Method to search announcements
  static Future<List<AnnouncementModel>> searchAnnouncements(String query) {
    return getAnnouncements(search: query);
  }

  // Method to get announcements for specific activity
  static Future<List<AnnouncementModel>> getActivityAnnouncements(
    int activityId,
  ) {
    return getAnnouncements(activity: activityId);
  }

  // Method to get announcements for specific society
  static Future<List<AnnouncementModel>> getSocietyAnnouncements(
    int societyId,
  ) {
    return getAnnouncements(society: societyId);
  }

  // ========== NEW NOTIFICATION PERMISSION METHODS ==========

  /// Initialize notification service
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings initializationSettingsDarwin =
          DarwinInitializationSettings(
            requestAlertPermission: false, // We'll request manually
            requestBadgePermission: false,
            requestSoundPermission: false,
          );

      const InitializationSettings initializationSettings =
          InitializationSettings(
            android: initializationSettingsAndroid,
            iOS: initializationSettingsDarwin,
          );

      await _notifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          // Handle notification tap
          _handleNotificationTap(response);
        },
      );

      _isInitialized = true;
    } catch (e) {
      print('Error initializing notifications: $e');
    }
  }

  /// Check if notifications are properly enabled (cross-platform)
  static Future<bool> areNotificationsEnabled() async {
    try {
      await initialize(); // Ensure initialization

      if (Platform.isIOS) {
        // For iOS, check multiple permission states for reliability
        final permissionStatus = await Permission.notification.status;

        // Also check with flutter_local_notifications for iOS
        final iosPlugin = _notifications
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >();

        if (iosPlugin != null) {
          final bool? isEnabled = (await iosPlugin.checkPermissions()) as bool?;
          return permissionStatus.isGranted || (isEnabled ?? false);
        }

        return permissionStatus.isGranted;
      } else {
        // For Android - check permission status
        final permissionStatus = await Permission.notification.status;
        return permissionStatus.isGranted;
      }
    } catch (e) {
      print('Error checking notification permissions: $e');
      return false;
    }
  }

  /// Request notification permissions (cross-platform)
  static Future<bool> requestNotificationPermission() async {
    try {
      await initialize(); // Ensure initialization

      if (Platform.isIOS) {
        // iOS specific request
        final iosPlugin = _notifications
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >();

        if (iosPlugin != null) {
          final bool? granted = await iosPlugin.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
          return granted ?? false;
        }

        // Fallback to permission_handler
        final status = await Permission.notification.request();
        return status.isGranted;
      } else {
        // Android request
        final status = await Permission.notification.request();
        return status.isGranted;
      }
    } catch (e) {
      print('Error requesting notification permission: $e');
      return false;
    }
  }

  /// Open app notification settings (works on both iOS and Android)
  static Future<bool> openAppSettings() async {
    try {
      // Use AppSettings.openAppSettings() - this opens the main app settings
      await AppSettings.openAppSettings();
      return true;
    } catch (e) {
      print('Error opening app settings: $e');
      return false;
    }
  }

  /// Get detailed notification permission status
  static Future<Map<String, dynamic>> getNotificationPermissionStatus() async {
    try {
      await initialize();

      final isEnabled = await areNotificationsEnabled();
      final permissionStatus = await Permission.notification.status;

      return {
        'isEnabled': isEnabled,
        'status': permissionStatus.toString(),
        'isPermanentlyDenied': permissionStatus.isPermanentlyDenied,
        'isDenied': permissionStatus.isDenied,
        'isGranted': permissionStatus.isGranted,
        'platform': Platform.operatingSystem,
      };
    } catch (e) {
      return {
        'isEnabled': false,
        'error': e.toString(),
        'platform': Platform.operatingSystem,
      };
    }
  }

  /// Show a local notification (for testing)
  static Future<void> showTestNotification() async {
    try {
      await initialize();

      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            'klayons_announcements',
            'Klayons Announcements',
            channelDescription: 'Notifications for Klayons app announcements',
            importance: Importance.max,
            priority: Priority.high,
          );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.show(
        0,
        'Notifications Enabled!',
        'You\'ll now receive important announcements from Klayons.',
        notificationDetails,
      );
    } catch (e) {
      print('Error showing test notification: $e');
    }
  }

  /// Handle notification tap
  static void _handleNotificationTap(NotificationResponse response) {
    // Handle notification tap - you can navigate to specific screens here
    print('Notification tapped: ${response.payload}');
  }

  /// Create notification channels (Android)
  static Future<void> createNotificationChannels() async {
    if (Platform.isAndroid) {
      try {
        await initialize();

        const AndroidNotificationChannel channel = AndroidNotificationChannel(
          'klayons_announcements',
          'Klayons Announcements',
          description: 'Notifications for Klayons app announcements',
          importance: Importance.max,
        );

        final plugin = _notifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
        await plugin?.createNotificationChannel(channel);
      } catch (e) {
        print('Error creating notification channels: $e');
      }
    }
  }

  /// Show notification for new announcement
  static Future<void> showAnnouncementNotification(
    AnnouncementModel announcement,
  ) async {
    try {
      await initialize();

      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            'klayons_announcements',
            'Klayons Announcements',
            channelDescription: 'Notifications for Klayons app announcements',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.show(
        announcement.id,
        announcement.title,
        announcement.content.length > 100
            ? '${announcement.content.substring(0, 100)}...'
            : announcement.content,
        notificationDetails,
        payload: announcement.id.toString(),
      );
    } catch (e) {
      print('Error showing announcement notification: $e');
    }
  }

  /// Clear all notifications
  static Future<void> clearAllNotifications() async {
    try {
      await _notifications.cancelAll();
    } catch (e) {
      print('Error clearing notifications: $e');
    }
  }

  /// Clear specific notification
  static Future<void> clearNotification(int notificationId) async {
    try {
      await _notifications.cancel(notificationId);
    } catch (e) {
      print('Error clearing notification: $e');
    }
  }
}
