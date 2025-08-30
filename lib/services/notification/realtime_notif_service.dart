import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'notification_service.dart';
import 'local_notification_service.dart';

class RealTimeNotificationService {
  static Timer? _pollingTimer;
  static Timer? _backgroundTimer;
  static bool _isPolling = false;
  static bool _isAppInForeground = true;
  static DateTime? _lastCheckTime;

  // Polling intervals
  static const Duration _foregroundPollingInterval = Duration(seconds: 30);
  static const Duration _backgroundPollingInterval = Duration(minutes: 2);

  /// Initialize the real-time notification service
  static Future<void> initialize() async {
    await LocalNotificationService.initialize();
    await _loadLastCheckTime();
    startPolling();
    _setupAppLifecycleListener();
  }

  /// Start polling for new announcements
  static void startPolling() {
    if (_isPolling) return;

    _isPolling = true;
    print('Starting real-time polling...');

    // Initial check
    _checkForNewAnnouncements();

    // Start periodic checks based on app state
    _startPeriodicChecks();
  }

  /// Stop polling
  static void stopPolling() {
    _isPolling = false;
    _pollingTimer?.cancel();
    _backgroundTimer?.cancel();
    print('Stopped real-time polling');
  }

  /// Start periodic checks based on app state
  static void _startPeriodicChecks() {
    _pollingTimer?.cancel();
    _backgroundTimer?.cancel();

    if (_isAppInForeground) {
      // More frequent checks when app is active
      _pollingTimer = Timer.periodic(_foregroundPollingInterval, (timer) {
        _checkForNewAnnouncements();
      });
    } else {
      // Less frequent checks when app is in background
      _backgroundTimer = Timer.periodic(_backgroundPollingInterval, (timer) {
        _checkForNewAnnouncements();
      });
    }
  }

  /// Handle app lifecycle changes
  static void _setupAppLifecycleListener() {
    // You'll need to call these methods from your app's lifecycle
    // This is typically done in your main widget or app state
  }

  /// Call this when app comes to foreground
  static void onAppResumed() {
    _isAppInForeground = true;
    print('App resumed - switching to foreground polling');
    _startPeriodicChecks();
    _checkForNewAnnouncements(); // Immediate check
  }

  /// Call this when app goes to background
  static void onAppPaused() {
    _isAppInForeground = false;
    print('App paused - switching to background polling');
    _startPeriodicChecks();
  }

  /// Check for new announcements
  static Future<void> _checkForNewAnnouncements() async {
    try {
      print('Checking for new announcements at ${DateTime.now()}');

      // Get announcements from your Django API
      final announcements = await NotificationService.getAnnouncements();

      if (announcements.isEmpty) {
        print('No announcements found');
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final lastAnnouncementId = prefs.getInt('last_announcement_id') ?? 0;
      final lastCheckTime =
          _lastCheckTime ?? DateTime.now().subtract(Duration(days: 1));

      // Find new announcements (either by ID or by created_at time)
      final newAnnouncements = announcements.where((announcement) {
        return announcement.id > lastAnnouncementId ||
            announcement.createdAt.isAfter(lastCheckTime);
      }).toList();

      print('Found ${newAnnouncements.length} new announcements');

      if (newAnnouncements.isNotEmpty) {
        await _processNewAnnouncements(newAnnouncements);

        // Update tracking
        final latestId = announcements
            .map((a) => a.id)
            .reduce((a, b) => a > b ? a : b);
        await prefs.setInt('last_announcement_id', latestId);

        _lastCheckTime = DateTime.now();
        await _saveLastCheckTime();

        print('Updated last announcement ID to: $latestId');
      }
    } catch (e) {
      print('Error checking for new announcements: $e');
    }
  }

  /// Process and show new announcements
  static Future<void> _processNewAnnouncements(
    List<AnnouncementModel> newAnnouncements,
  ) async {
    // Sort by creation time (newest first) and limit to prevent spam
    newAnnouncements.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final limitedAnnouncements = newAnnouncements.take(5).toList();

    for (final announcement in limitedAnnouncements) {
      await LocalNotificationService.showNotification(
        id: announcement.id,
        title: 'New: ${announcement.title}',
        body: _truncateContent(announcement.content, 100),
        payload: 'announcement_${announcement.id}',
      );

      // Add small delay between notifications to avoid overwhelming
      await Future.delayed(Duration(milliseconds: 500));
    }

    // Show summary if there are too many announcements
    if (newAnnouncements.length > 5) {
      await LocalNotificationService.showNotification(
        id: 99999,
        title: 'Multiple New Announcements',
        body:
            '${newAnnouncements.length} new announcements received. Tap to view all.',
        payload: 'multiple_announcements',
      );
    }
  }

  /// Truncate content for notification body
  static String _truncateContent(String content, int maxLength) {
    if (content.length <= maxLength) return content;
    return '${content.substring(0, maxLength)}...';
  }

  /// Save last check time
  static Future<void> _saveLastCheckTime() async {
    if (_lastCheckTime != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'last_check_time',
        _lastCheckTime!.toIso8601String(),
      );
    }
  }

  /// Load last check time
  static Future<void> _loadLastCheckTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timeString = prefs.getString('last_check_time');
    if (timeString != null) {
      _lastCheckTime = DateTime.parse(timeString);
    }
  }

  // ========== ENHANCED POLLING WITH TIME-BASED FILTERING ==========

  /// Check for announcements created after specific time
  static Future<List<AnnouncementModel>> getAnnouncementsAfter(
    DateTime afterTime,
  ) async {
    try {
      final announcements = await NotificationService.getAnnouncements();

      return announcements.where((announcement) {
        return announcement.createdAt.isAfter(afterTime);
      }).toList();
    } catch (e) {
      print('Error getting announcements after time: $e');
      return [];
    }
  }

  /// Smart check - only get new announcements since last successful check
  static Future<void> smartCheckForNewAnnouncements() async {
    try {
      final lastCheckTime =
          _lastCheckTime ?? DateTime.now().subtract(Duration(hours: 1));

      final newAnnouncements = await getAnnouncementsAfter(lastCheckTime);

      if (newAnnouncements.isNotEmpty) {
        await _processNewAnnouncements(newAnnouncements);

        _lastCheckTime = DateTime.now();
        await _saveLastCheckTime();

        // Also update the last announcement ID
        final prefs = await SharedPreferences.getInstance();
        if (newAnnouncements.isNotEmpty) {
          final latestId = newAnnouncements
              .map((a) => a.id)
              .reduce((a, b) => a > b ? a : b);
          await prefs.setInt('last_announcement_id', latestId);
        }
      }
    } catch (e) {
      print('Error in smart check: $e');
    }
  }

  // ========== USER-SPECIFIC FILTERING ==========

  /// Get announcements filtered by user preferences
  static Future<List<AnnouncementModel>> getFilteredAnnouncements({
    List<int>? userActivityIds,
    List<int>? userBatchIds,
    int? userSocietyId,
  }) async {
    try {
      List<AnnouncementModel> allNew = [];

      // Get general announcements
      final generalAnnouncements =
          await NotificationService.getAnnouncementsByScope('GENERAL');
      allNew.addAll(generalAnnouncements);

      // Get activity-specific announcements
      if (userActivityIds != null) {
        for (int activityId in userActivityIds) {
          final activityAnnouncements =
              await NotificationService.getActivityAnnouncements(activityId);
          allNew.addAll(activityAnnouncements);
        }
      }

      // Get society-specific announcements
      if (userSocietyId != null) {
        final societyAnnouncements =
            await NotificationService.getSocietyAnnouncements(userSocietyId);
        allNew.addAll(societyAnnouncements);
      }

      // Remove duplicates and filter by time
      final uniqueAnnouncements = <int, AnnouncementModel>{};
      final lastCheckTime =
          _lastCheckTime ?? DateTime.now().subtract(Duration(hours: 1));

      for (final announcement in allNew) {
        if (announcement.createdAt.isAfter(lastCheckTime) &&
            !uniqueAnnouncements.containsKey(announcement.id)) {
          uniqueAnnouncements[announcement.id] = announcement;
        }
      }

      return uniqueAnnouncements.values.toList();
    } catch (e) {
      print('Error getting filtered announcements: $e');
      return [];
    }
  }

  // ========== MANUAL CONTROLS ==========

  /// Manual refresh - call this from UI
  static Future<void> manualRefresh() async {
    print('Manual refresh triggered');
    await _checkForNewAnnouncements();
  }

  /// Reset and get all announcements as new
  static Future<void> resetAndRefresh() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('last_announcement_id');
    await prefs.remove('last_check_time');
    _lastCheckTime = DateTime.now().subtract(Duration(minutes: 5));
    await manualRefresh();
  }

  // ========== DEBUG AND TESTING ==========

  /// Test immediate notification
  static Future<void> testRealTimeNotification() async {
    await LocalNotificationService.showNotification(
      id: 88888,
      title: 'Real-Time Test',
      body: 'Testing real-time notification system!',
      payload: 'test_realtime',
    );
  }

  /// Get current service status
  static Map<String, dynamic> getServiceStatus() {
    return {
      'is_polling': _isPolling,
      'is_foreground': _isAppInForeground,
      'last_check_time': _lastCheckTime?.toIso8601String(),
      'polling_interval': _isAppInForeground
          ? _foregroundPollingInterval.inSeconds
          : _backgroundPollingInterval.inSeconds,
      'timers_active': {
        'foreground_timer': _pollingTimer?.isActive ?? false,
        'background_timer': _backgroundTimer?.isActive ?? false,
      },
    };
  }

  /// Debug print current status
  static void debugPrintStatus() {
    final status = getServiceStatus();
    print('=== Real-Time Service Status ===');
    status.forEach((key, value) {
      print('$key: $value');
    });
    print('===============================');
  }

  // ========== CLEANUP ==========

  /// Dispose resources
  static void dispose() {
    stopPolling();
    _pollingTimer = null;
    _backgroundTimer = null;
  }
}
