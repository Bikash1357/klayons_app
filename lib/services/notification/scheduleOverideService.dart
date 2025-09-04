import 'dart:convert';
import 'package:http/http.dart' as http;

class ScheduleOverride {
  final int id;
  final int schedule;
  final String occurrenceDate;
  final bool cancelled;
  final String? rescheduledStartTime;
  final String? rescheduledEndTime;
  final String? remarks;

  ScheduleOverride({
    required this.id,
    required this.schedule,
    required this.occurrenceDate,
    required this.cancelled,
    this.rescheduledStartTime,
    this.rescheduledEndTime,
    this.remarks,
  });

  factory ScheduleOverride.fromJson(Map<String, dynamic> json) {
    return ScheduleOverride(
      id: json['id'] ?? 0,
      schedule: json['schedule'] ?? 0,
      occurrenceDate: json['occurrence_date'] ?? '',
      cancelled: json['cancelled'] ?? false,
      rescheduledStartTime: json['rescheduled_start_time'],
      rescheduledEndTime: json['rescheduled_end_time'],
      remarks: json['remarks'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'schedule': schedule,
      'occurrence_date': occurrenceDate,
      'cancelled': cancelled,
      'rescheduled_start_time': rescheduledStartTime,
      'rescheduled_end_time': rescheduledEndTime,
      'remarks': remarks,
    };
  }

  // Helper method to get formatted notification title
  String getNotificationTitle() {
    if (cancelled) {
      return 'Session Cancelled';
    } else if (rescheduledStartTime != null) {
      return 'Session Rescheduled';
    }
    return 'Schedule Update';
  }

  // Helper method to get notification description
  String getNotificationDescription() {
    if (cancelled) {
      return remarks ?? 'Your scheduled session has been cancelled';
    } else if (rescheduledStartTime != null) {
      return 'Your session has been rescheduled${remarks != null ? ': $remarks' : ''}';
    }
    return remarks ?? 'Schedule has been updated';
  }

  // Helper method to format time ago
  String getTimeAgo() {
    try {
      final DateTime scheduleDate = DateTime.parse(occurrenceDate);
      final DateTime now = DateTime.now();
      final Duration difference = now.difference(scheduleDate);

      if (difference.inDays > 0) {
        if (difference.inDays >= 7) {
          final weeks = (difference.inDays / 7).floor();
          return '${weeks}w';
        }
        return '${difference.inDays}d';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m';
      } else {
        return 'now';
      }
    } catch (e) {
      return '1d';
    }
  }

  // Check if this notification is viewed
  bool get isViewed => NotificationCountManager.isViewed(id);
}

class NotificationCountManager {
  static const String _key = 'viewed_notifications';
  static Set<int> _viewedNotifications = {};

  // Initialize viewed notifications (in a real app, you'd load this from SharedPreferences)
  static void init() {
    // Load viewed notifications from local storage
    // For now, we'll keep it in memory
  }

  // Mark notification as viewed
  static void markAsViewed(int notificationId) {
    _viewedNotifications.add(notificationId);
    // In a real app, save to SharedPreferences here
  }

  // Mark all notifications as viewed
  static void markAllAsViewed(List<ScheduleOverride> notifications) {
    for (var notification in notifications) {
      _viewedNotifications.add(notification.id);
    }
    // In a real app, save to SharedPreferences here
  }

  // Check if notification is viewed
  static bool isViewed(int notificationId) {
    return _viewedNotifications.contains(notificationId);
  }

  // Get count of unviewed notifications
  static int getUnviewedCount(List<ScheduleOverride> notifications) {
    return notifications
        .where((notification) => !isViewed(notification.id))
        .length;
  }

  // Clear all viewed notifications (for testing)
  static void clearAll() {
    _viewedNotifications.clear();
  }
}

class ScheduleOverridesService {
  static const String baseUrl = 'https://dev-klayonsapi.vercel.app';

  // Get all schedule overrides
  static Future<List<ScheduleOverride>> getScheduleOverrides({
    bool? cancelled,
    int? scheduleId,
  }) async {
    try {
      String url = '$baseUrl/api/activities/overrides/';

      // Build query parameters
      List<String> queryParams = [];
      if (cancelled != null) {
        queryParams.add('cancelled=$cancelled');
      }
      if (scheduleId != null) {
        queryParams.add('schedule=$scheduleId');
      }

      if (queryParams.isNotEmpty) {
        url += '?' + queryParams.join('&');
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          // Add authorization header if needed
          // 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        return jsonData.map((json) => ScheduleOverride.fromJson(json)).toList();
      } else {
        throw Exception(
          'Failed to load schedule overrides: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching schedule overrides: $e');
    }
  }

  // Get cancelled schedules only
  static Future<List<ScheduleOverride>> getCancelledSchedules() async {
    return await getScheduleOverrides(cancelled: true);
  }

  // Get rescheduled sessions only
  static Future<List<ScheduleOverride>> getRescheduledSchedules() async {
    final allOverrides = await getScheduleOverrides();
    return allOverrides
        .where(
          (override) =>
              !override.cancelled && override.rescheduledStartTime != null,
        )
        .toList();
  }

  // Get overrides for a specific schedule
  static Future<List<ScheduleOverride>> getOverridesForSchedule(
    int scheduleId,
  ) async {
    return await getScheduleOverrides(scheduleId: scheduleId);
  }
}
