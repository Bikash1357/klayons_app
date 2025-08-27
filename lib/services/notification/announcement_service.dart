import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class Announcement {
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
  final String createdByName;
  final DateTime createdAt;

  Announcement({
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
    required this.createdByName,
    required this.createdAt,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      scope: json['scope'] ?? 'GENERAL',
      activity: json['activity'],
      activityName: json['activity_name'],
      batches: json['batches']?.cast<int>(),
      batchNames: json['batch_names']?.cast<String>(),
      society: json['society'],
      societyName: json['society_name'],
      attachment: json['attachment'],
      expiry: json['expiry'] != null ? DateTime.parse(json['expiry']) : null,
      isActive: json['is_active'] ?? true,
      createdBy: json['created_by'] ?? 0,
      createdByName: json['created_by_name'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'scope': scope,
      'activity': activity,
      'activity_name': activityName,
      'batches': batches,
      'batch_names': batchNames,
      'society': society,
      'society_name': societyName,
      'attachment': attachment,
      'expiry': expiry?.toIso8601String(),
      'is_active': isActive,
      'created_by': createdBy,
      'created_by_name': createdByName,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

// enums/announcement_scope.dart
enum AnnouncementScope { ACTIVITY, BATCH, GENERAL, SOCIETY }

extension AnnouncementScopeExtension on AnnouncementScope {
  String get value {
    switch (this) {
      case AnnouncementScope.ACTIVITY:
        return 'ACTIVITY';
      case AnnouncementScope.BATCH:
        return 'BATCH';
      case AnnouncementScope.GENERAL:
        return 'GENERAL';
      case AnnouncementScope.SOCIETY:
        return 'SOCIETY';
    }
  }
}

// services/announcements_service.dart

class AnnouncementsService {
  static const String baseUrl = 'https://klayons-backend.vercel.app';
  static const String endpoint = '/api/announcements/';

  // Optional: Add authentication token if needed
  String? _authToken;

  AnnouncementsService({String? authToken}) : _authToken = authToken;

  void setAuthToken(String token) {
    _authToken = token;
  }

  Map<String, String> get _headers {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }

    return headers;
  }

  /// Get list of announcements with optional filters
  Future<List<Announcement>> getAnnouncements({
    int? activity,
    AnnouncementScope? scope,
    String? search,
    int? society,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');

      // Build query parameters
      final queryParams = <String, String>{};

      if (activity != null) {
        queryParams['activity'] = activity.toString();
      }

      if (scope != null) {
        queryParams['scope'] = scope.value;
      }

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      if (society != null) {
        queryParams['society'] = society.toString();
      }

      final finalUri = uri.replace(
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );

      final response = await http.get(finalUri, headers: _headers);

      return _handleResponse(response);
    } catch (e) {
      throw AnnouncementException('Failed to fetch announcements: $e');
    }
  }

  List<Announcement> _handleResponse(http.Response response) {
    switch (response.statusCode) {
      case 200:
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((json) => Announcement.fromJson(json)).toList();
      case 401:
        throw AnnouncementException('Unauthorized access');
      case 403:
        throw AnnouncementException('Access forbidden');
      case 404:
        throw AnnouncementException('Announcements not found');
      case 500:
        throw AnnouncementException('Server error');
      default:
        throw AnnouncementException('Unexpected error: ${response.statusCode}');
    }
  }
}

// exceptions/announcement_exception.dart
class AnnouncementException implements Exception {
  final String message;

  AnnouncementException(this.message);

  @override
  String toString() => 'AnnouncementException: $message';
}

// Example usage in a widget or controller:
/*
class AnnouncementsController {
  final AnnouncementsService _service = AnnouncementsService();

  Future<List<Announcement>> loadAnnouncements() async {
    try {
      return await _service.getAnnouncements();
    } catch (e) {
      print('Error loading announcements: $e');
      rethrow;
    }
  }

  Future<List<Announcement>> searchAnnouncements(String query) async {
    try {
      return await _service.getAnnouncements(search: query);
    } catch (e) {
      print('Error searching announcements: $e');
      rethrow;
    }
  }

  Future<List<Announcement>> getActivityAnnouncements(int activityId) async {
    try {
      return await _service.getAnnouncements(
        activity: activityId,
        scope: AnnouncementScope.ACTIVITY,
      );
    } catch (e) {
      print('Error loading activity announcements: $e');
      rethrow;
    }
  }
}
*/
