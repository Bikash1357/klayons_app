import 'dart:convert';
import 'package:http/http.dart' as http;

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

// Service class for handling API calls
class NotificationService {
  static const String baseUrl = 'https://dev-klayonsapi.vercel.app//api';
  static const String announcementsEndpoint = '/announcements';

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
}
