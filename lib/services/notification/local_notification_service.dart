import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'notification_service.dart';

class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: false, // Request later for better UX
          requestBadgePermission: false,
          requestSoundPermission: false,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Request notification permissions
    await requestNotificationPermissions();
  }

  @pragma('vm:entry-point')
  static void _onNotificationTapped(NotificationResponse details) {
    print('Notification tapped: ${details.payload}');
    // You can use a navigation service or global navigator key to navigate
  }

  /// Request notification permissions for Android 13+ and iOS
  static Future<bool> requestNotificationPermissions() async {
    try {
      // Android 13+ permission handling
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notificationsPlugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();

      if (androidImplementation != null) {
        // Check current permission status
        final bool? isGranted = await androidImplementation
            .areNotificationsEnabled();
        print('Current notification permission status: ${isGranted ?? false}');

        if (isGranted != null && !isGranted) {
          // Request permission using flutter_local_notifications
          final bool? granted = await androidImplementation
              .requestNotificationsPermission();
          print(
            'Notification permission granted via plugin: ${granted ?? false}',
          );

          // Fallback to permission_handler if needed
          if (granted != true) {
            final PermissionStatus status = await Permission.notification
                .request();
            final bool permissionGranted = status == PermissionStatus.granted;
            print(
              'Notification permission granted via permission_handler: $permissionGranted',
            );
            return permissionGranted;
          }

          return granted ?? false;
        }

        return isGranted ?? false;
      }

      // iOS permission handling
      final IOSFlutterLocalNotificationsPlugin? iosImplementation =
          _notificationsPlugin
              .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin
              >();

      if (iosImplementation != null) {
        final bool? result = await iosImplementation.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        print('iOS notification permission granted: ${result ?? false}');
        return result ?? false;
      }

      return false;
    } catch (e) {
      print('Error requesting notification permissions: $e');
      return false;
    }
  }

  /// Check if notifications are currently enabled
  static Future<bool> areNotificationsEnabled() async {
    try {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notificationsPlugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();

      if (androidImplementation != null) {
        final bool? result = await androidImplementation
            .areNotificationsEnabled();
        return result ?? false;
      }

      // For iOS, check via permission_handler
      final PermissionStatus status = await Permission.notification.status;
      return status == PermissionStatus.granted;
    } catch (e) {
      print('Error checking notification status: $e');
      return false;
    }
  }

  /// Open app settings if permission is permanently denied
  static Future<void> openNotificationSettings() async {
    try {
      await openAppSettings();
    } catch (e) {
      print('Error opening app settings: $e');
    }
  }

  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      // Check if notifications are enabled before showing
      final bool enabled = await areNotificationsEnabled();
      if (!enabled) {
        print('Notifications not enabled, skipping notification');
        return;
      }

      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            'klayons_announcements',
            'Klayons Announcements',
            channelDescription:
                'Notifications for new announcements in Klayons',
            importance: Importance.max,
            priority: Priority.high,
            showWhen: true,
            icon: '@mipmap/ic_launcher',
            enableVibration: true,
            playSound: true,
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

      await _notificationsPlugin.show(
        id,
        title,
        body,
        notificationDetails,
        payload: payload,
      );

      print('Notification shown: ID=$id, Title=$title');
    } catch (e) {
      print('Error showing notification: $e');
    }
  }

  @pragma('vm:entry-point')
  static Future<void> checkForNewAnnouncements() async {
    try {
      print('Checking for new announcements...');

      final announcements = await NotificationService.getAnnouncements();

      if (announcements.isEmpty) {
        print('No announcements found');
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final lastAnnouncementId = prefs.getInt('last_announcement_id') ?? 0;

      // Find new announcements
      final newAnnouncements = announcements
          .where((announcement) => announcement.id > lastAnnouncementId)
          .toList();

      print('Found ${newAnnouncements.length} new announcements');

      if (newAnnouncements.isNotEmpty) {
        // Show notification for each new announcement (limit to 3)
        for (int i = 0; i < newAnnouncements.length && i < 3; i++) {
          final announcement = newAnnouncements[i];
          await showNotification(
            id: announcement.id,
            title: 'New: ${announcement.title}',
            body: announcement.content.length > 100
                ? '${announcement.content.substring(0, 100)}...'
                : announcement.content,
            payload: 'announcement_${announcement.id}',
          );
        }

        // Update the last announcement ID to the most recent one
        final latestId = newAnnouncements
            .map((a) => a.id)
            .reduce((a, b) => a > b ? a : b);
        await prefs.setInt('last_announcement_id', latestId);

        print('Updated last announcement ID to: $latestId');
      }
    } catch (e) {
      print('Error checking for new announcements: $e');
    }
  }

  // ========== DEBUG METHODS ==========

  /// Test notification immediately
  static Future<void> testNotification() async {
    await showNotification(
      id: 999,
      title: 'Test Notification',
      body: 'This is a test notification to verify the system is working!',
      payload: 'test_payload',
    );
    print('Test notification sent');
  }

  /// Check current announcement count and last stored ID
  static Future<void> debugAnnouncementStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastId = prefs.getInt('last_announcement_id') ?? 0;
      final enabled = await areNotificationsEnabled();

      final announcements = await NotificationService.getAnnouncements();

      print('=== DEBUG INFO ===');
      print('Notifications enabled: $enabled');
      print('Last stored announcement ID: $lastId');
      print('Current announcements count: ${announcements.length}');

      if (announcements.isNotEmpty) {
        print('Latest announcement ID: ${announcements.first.id}');
        print('Latest announcement title: ${announcements.first.title}');
        print('Latest announcement created: ${announcements.first.createdAt}');
      }

      final newAnnouncements = announcements
          .where((announcement) => announcement.id > lastId)
          .toList();

      print('New announcements found: ${newAnnouncements.length}');
      print('==================');
    } catch (e) {
      print('Debug error: $e');
    }
  }

  /// Reset and force check for all announcements
  static Future<void> resetAndCheckAnnouncements() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('last_announcement_id');
    print('Reset last announcement ID');

    await checkForNewAnnouncements();
  }

  /// Method to manually check for announcements (can be called from UI)
  static Future<void> manualCheck() async {
    await checkForNewAnnouncements();
  }

  /// Method to reset notification tracking (useful for testing)
  static Future<void> resetNotificationTracking() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('last_announcement_id');
    print('Notification tracking reset');
  }

  /// Get permission status details
  static Future<Map<String, dynamic>> getPermissionStatus() async {
    try {
      final androidEnabled = await areNotificationsEnabled();
      final permissionStatus = await Permission.notification.status;

      return {
        'android_enabled': androidEnabled,
        'permission_status': permissionStatus.toString(),
        'is_granted': permissionStatus == PermissionStatus.granted,
        'is_denied': permissionStatus == PermissionStatus.denied,
        'is_permanently_denied':
            permissionStatus == PermissionStatus.permanentlyDenied,
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  /// Show comprehensive permission dialog
  static Future<bool> showPermissionDialog() async {
    try {
      final status = await Permission.notification.status;

      if (status == PermissionStatus.granted) {
        print('Notification permission already granted');
        return true;
      }

      if (status == PermissionStatus.permanentlyDenied) {
        print('Notification permission permanently denied - opening settings');
        await openNotificationSettings();
        return false;
      }

      // Request permission
      final result = await requestNotificationPermissions();
      print('Permission dialog result: $result');
      return result;
    } catch (e) {
      print('Error in permission dialog: $e');
      return false;
    }
  }
}
