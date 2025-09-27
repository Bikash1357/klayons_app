// File: lib/services/activity_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// Activity Data Models
class ActivityDetail {
  final int id;
  final String name;
  final String category;
  final String subcategory;
  final String batchName;
  final String description;
  final String bannerImageUrl;
  final Instructor instructor;
  final String society;
  final String venue;
  final String ageRange;
  final int capacity;
  final double price;
  final String paymentType;
  final int sessionCount;
  final int sessionDuration;
  final String startDate;
  final String endDate;
  final Schedule schedule;
  final List<ActivitySchedule> schedules;
  final bool isActive;

  ActivityDetail({
    required this.id,
    required this.name,
    required this.category,
    required this.subcategory,
    required this.batchName,
    required this.description,
    required this.bannerImageUrl,
    required this.instructor,
    required this.society,
    required this.venue,
    required this.ageRange,
    required this.capacity,
    required this.price,
    required this.paymentType,
    required this.sessionCount,
    required this.sessionDuration,
    required this.startDate,
    required this.endDate,
    required this.schedule,
    required this.schedules,
    required this.isActive,
  });

  factory ActivityDetail.fromJson(Map<String, dynamic> json) {
    return ActivityDetail(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      category: json['category'] ?? '',
      subcategory: json['subcategory'] ?? '',
      batchName: json['batch_name'] ?? '',
      description: json['description'] ?? '',
      bannerImageUrl: json['banner_image_url'] ?? '',
      instructor: Instructor.fromJson(json['instructor'] ?? {}),
      society: json['society'] ?? '',
      venue: json['venue'] ?? '',
      ageRange: json['age_range'] ?? '',
      capacity: json['capacity'] ?? 0,
      price: (json['price'] ?? 0).toDouble(),
      paymentType: json['payment_type'] ?? '',
      sessionCount: json['session_count'] ?? 0,
      sessionDuration: json['session_duration'] ?? 0,
      startDate: json['start_date'] ?? '',
      endDate: json['end_date'] ?? '',
      schedule: Schedule.fromJson(json['schedule'] ?? {}),
      schedules:
          (json['schedules'] as List?)
              ?.map((e) => ActivitySchedule.fromJson(e))
              .toList() ??
          [],
      isActive: json['is_active'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'subcategory': subcategory,
      'batch_name': batchName,
      'description': description,
      'banner_image_url': bannerImageUrl,
      'instructor': instructor.toJson(),
      'society': society,
      'venue': venue,
      'age_range': ageRange,
      'capacity': capacity,
      'price': price,
      'payment_type': paymentType,
      'session_count': sessionCount,
      'session_duration': sessionDuration,
      'start_date': startDate,
      'end_date': endDate,
      'schedule': schedule.toJson(),
      'schedules': schedules.map((e) => e.toJson()).toList(),
      'is_active': isActive,
    };
  }
}

class Instructor {
  final int id;
  final String name;
  final String phone;
  final String profile;
  final String? avatarUrl;
  final String? websiteUrl;
  final String? attachmentUrl;

  Instructor({
    required this.id,
    required this.name,
    required this.phone,
    required this.profile,
    this.avatarUrl,
    this.websiteUrl,
    this.attachmentUrl,
  });

  factory Instructor.fromJson(Map<String, dynamic> json) {
    return Instructor(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      profile: json['profile'] ?? '',
      avatarUrl: json['avatar_url'],
      websiteUrl: json['website_url'],
      attachmentUrl: json['attachment_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'profile': profile,
      'avatar_url': avatarUrl,
      'website_url': websiteUrl,
      'attachment_url': attachmentUrl,
    };
  }
}

class Schedule {
  final List<String> rrulePatterns;
  final List<String> rdatePatterns;
  final List<TimeSlot> timeSlots;

  Schedule({
    required this.rrulePatterns,
    required this.rdatePatterns,
    required this.timeSlots,
  });

  factory Schedule.fromJson(Map<String, dynamic> json) {
    return Schedule(
      rrulePatterns: List<String>.from(json['rrule_patterns'] ?? []),
      rdatePatterns: List<String>.from(json['rdate_patterns'] ?? []),
      timeSlots:
          (json['time_slots'] as List?)
              ?.map((e) => TimeSlot.fromJson(e))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rrule_patterns': rrulePatterns,
      'rdate_patterns': rdatePatterns,
      'time_slots': timeSlots.map((e) => e.toJson()).toList(),
    };
  }
}

class TimeSlot {
  final String startTime;
  final String endTime;
  final List<String> days;

  TimeSlot({
    required this.startTime,
    required this.endTime,
    required this.days,
  });

  factory TimeSlot.fromJson(Map<String, dynamic> json) {
    return TimeSlot(
      startTime: json['start_time'] ?? '',
      endTime: json['end_time'] ?? '',
      days: List<String>.from(json['days'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {'start_time': startTime, 'end_time': endTime, 'days': days};
  }
}

class ActivitySchedule {
  final int id;
  final String startTimeDisplay;
  final String endTimeDisplay;
  final List<NextOccurrence> nextOccurrences;
  final bool isActive;

  ActivitySchedule({
    required this.id,
    required this.startTimeDisplay,
    required this.endTimeDisplay,
    required this.nextOccurrences,
    required this.isActive,
  });

  factory ActivitySchedule.fromJson(Map<String, dynamic> json) {
    return ActivitySchedule(
      id: json['id'] ?? 0,
      startTimeDisplay: json['start_time_display'] ?? '',
      endTimeDisplay: json['end_time_display'] ?? '',
      nextOccurrences:
          (json['next_occurrences'] as List?)
              ?.map((e) => NextOccurrence.fromJson(e))
              .toList() ??
          [],
      isActive: json['is_active'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'start_time_display': startTimeDisplay,
      'end_time_display': endTimeDisplay,
      'next_occurrences': nextOccurrences.map((e) => e.toJson()).toList(),
      'is_active': isActive,
    };
  }
}

class NextOccurrence {
  final String date;
  final String day;
  final String fullDay;
  final String time;
  final String status;
  final String occurrenceId;
  final int scheduleId;
  final String type;

  NextOccurrence({
    required this.date,
    required this.day,
    required this.fullDay,
    required this.time,
    required this.status,
    required this.occurrenceId,
    required this.scheduleId,
    required this.type,
  });

  factory NextOccurrence.fromJson(Map<String, dynamic> json) {
    return NextOccurrence(
      date: json['date'] ?? '',
      day: json['day'] ?? '',
      fullDay: json['full_day'] ?? '',
      time: json['time'] ?? '',
      status: json['status'] ?? '',
      occurrenceId: json['occurrence_id'] ?? '',
      scheduleId: json['schedule_id'] ?? 0,
      type: json['type'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'day': day,
      'full_day': fullDay,
      'time': time,
      'status': status,
      'occurrence_id': occurrenceId,
      'schedule_id': scheduleId,
      'type': type,
    };
  }
}

// Activity Service Class
class ActivityService {
  static const String baseUrl =
      'https://dce6c40c-1aee-4939-b9fa-cf0144c03e80-00-awz9qsmkv8d2.pike.replit.dev/api';
  static const String _tokenKey = 'auth_token';

  // Get auth token from SharedPreferences (same as your login service)
  static Future<String?> _getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);
      print('Retrieved token: ${token != null ? "Found" : "Not found"}');
      return token;
    } catch (e) {
      print('Error getting token: $e');
      return null;
    }
  }

  // Get headers with authorization
  static Future<Map<String, String>> _getHeaders() async {
    final headers = {
      'accept': 'application/json',
      'Content-Type': 'application/json',
    };

    final token = await _getToken();
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  // Fetch activity details by ID
  static Future<ActivityDetail?> getActivityDetails(int activityId) async {
    try {
      print('🌐 Fetching activity details for ID: $activityId');

      final url = Uri.parse('$baseUrl/activities/$activityId/');
      final headers = await _getHeaders();

      print('📡 Making request to: $url');

      final response = await http.get(url, headers: headers);

      print('📡 Response status: ${response.statusCode}');
      print(
        '📄 Response body: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}...',
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final activity = ActivityDetail.fromJson(data);
        print('✅ Activity details loaded successfully: ${activity.name}');
        return activity;
      } else if (response.statusCode == 404) {
        print('❌ Activity not found');
        throw ActivityNotFoundException(
          'Activity with ID $activityId not found',
        );
      } else if (response.statusCode == 401) {
        print('❌ Unauthorized access');
        throw UnauthorizedException(
          'Authentication required. Please login again.',
        );
      } else {
        print('❌ Request failed with status: ${response.statusCode}');
        throw ActivityServiceException(
          'Failed to load activity details. Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('❌ Activity service error: $e');
      if (e is ActivityServiceException) {
        rethrow;
      }
      throw ActivityServiceException('Network error: ${e.toString()}');
    }
  }

  // Get multiple activities with filters
  static Future<List<ActivityDetail>> getActivities({
    int? limit,
    int? offset,
    String? category,
    String? society,
    String? search,
  }) async {
    try {
      print('🌐 Fetching activities with filters');

      var uri = Uri.parse('$baseUrl/activities/');

      // Add query parameters
      final queryParams = <String, String>{};
      if (limit != null) queryParams['limit'] = limit.toString();
      if (offset != null) queryParams['offset'] = offset.toString();
      if (category != null) queryParams['category'] = category;
      if (society != null) queryParams['society'] = society;
      if (search != null) queryParams['search'] = search;

      if (queryParams.isNotEmpty) {
        uri = uri.replace(queryParameters: queryParams);
      }

      final headers = await _getHeaders();
      final response = await http.get(uri, headers: headers);

      print('📡 Activities response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);

        List<dynamic> results;
        if (data is Map<String, dynamic> && data.containsKey('results')) {
          results = data['results'];
        } else if (data is List) {
          results = data;
        } else {
          results = [];
        }

        final activities = results
            .map((item) => ActivityDetail.fromJson(item))
            .toList();
        print('✅ Loaded ${activities.length} activities');
        return activities;
      } else if (response.statusCode == 401) {
        throw UnauthorizedException(
          'Authentication required. Please login again.',
        );
      } else {
        throw ActivityServiceException(
          'Failed to load activities. Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('❌ Activities fetch error: $e');
      if (e is ActivityServiceException) {
        rethrow;
      }
      throw ActivityServiceException('Network error: ${e.toString()}');
    }
  }

  // Search activities
  static Future<List<ActivityDetail>> searchActivities(String query) async {
    return getActivities(search: query);
  }

  // Get activities by category
  static Future<List<ActivityDetail>> getActivitiesByCategory(
    String category,
  ) async {
    return getActivities(category: category);
  }

  // Get activities by society
  static Future<List<ActivityDetail>> getActivitiesBySociety(
    String society,
  ) async {
    return getActivities(society: society);
  }

  // Check if user has valid authentication for API calls
  static Future<bool> hasValidAuth() async {
    final token = await _getToken();
    return token != null && token.isNotEmpty;
  }

  // Refresh activity data with retry logic
  static Future<ActivityDetail?> refreshActivityDetails(
    int activityId, {
    int maxRetries = 3,
  }) async {
    int attempts = 0;
    while (attempts < maxRetries) {
      try {
        return await getActivityDetails(activityId);
      } catch (e) {
        attempts++;
        if (attempts >= maxRetries) {
          print('❌ Max retry attempts reached for activity $activityId');
          rethrow;
        }
        print('⚠️ Retry attempt $attempts for activity $activityId');
        await Future.delayed(
          Duration(seconds: attempts * 2),
        ); // Exponential backoff
      }
    }
    return null;
  }
}

// Custom Exceptions
class ActivityServiceException implements Exception {
  final String message;
  ActivityServiceException(this.message);

  @override
  String toString() => 'ActivityServiceException: $message';
}

class ActivityNotFoundException extends ActivityServiceException {
  ActivityNotFoundException(String message) : super(message);
}

class UnauthorizedException extends ActivityServiceException {
  UnauthorizedException(String message) : super(message);
}

// Helper class for handling API responses with loading states
class ApiResponse<T> {
  final bool isLoading;
  final T? data;
  final String? error;
  final bool isSuccess;

  ApiResponse._({
    this.isLoading = false,
    this.data,
    this.error,
    this.isSuccess = false,
  });

  factory ApiResponse.loading() {
    return ApiResponse._(isLoading: true);
  }

  factory ApiResponse.success(T data) {
    return ApiResponse._(data: data, isSuccess: true);
  }

  factory ApiResponse.error(String error) {
    return ApiResponse._(error: error);
  }
}

// Repository class for better state management
class ActivityRepository {
  Future<ApiResponse<ActivityDetail>> getActivityDetails(int id) async {
    try {
      final activity = await ActivityService.getActivityDetails(id);
      if (activity != null) {
        return ApiResponse.success(activity);
      } else {
        return ApiResponse.error('Activity not found');
      }
    } on ActivityNotFoundException catch (e) {
      return ApiResponse.error(e.message);
    } on UnauthorizedException catch (e) {
      return ApiResponse.error('Please login to continue');
    } on ActivityServiceException catch (e) {
      return ApiResponse.error(e.message);
    } catch (e) {
      return ApiResponse.error('Unexpected error: ${e.toString()}');
    }
  }

  Future<ApiResponse<List<ActivityDetail>>> getActivities({
    int? limit,
    int? offset,
    String? category,
    String? society,
    String? search,
  }) async {
    try {
      final activities = await ActivityService.getActivities(
        limit: limit,
        offset: offset,
        category: category,
        society: society,
        search: search,
      );
      return ApiResponse.success(activities);
    } on UnauthorizedException catch (e) {
      return ApiResponse.error('Please login to continue');
    } on ActivityServiceException catch (e) {
      return ApiResponse.error(e.message);
    } catch (e) {
      return ApiResponse.error('Unexpected error: ${e.toString()}');
    }
  }
}
