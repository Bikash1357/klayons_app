import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// MODELS

class Activity {
  final int id;
  final String name;
  final String category;
  final String subcategory;
  final String batchName;
  final String bannerImageUrl;
  final Instructor instructor;
  final String society;
  final String venue;
  final String ageRange;
  final int capacity;
  final int price;
  final String paymentType;
  final bool isActive;

  Activity({
    required this.id,
    required this.name,
    required this.category,
    required this.subcategory,
    required this.batchName,
    required this.bannerImageUrl,
    required this.instructor,
    required this.society,
    required this.venue,
    required this.ageRange,
    required this.capacity,
    required this.price,
    required this.paymentType,
    required this.isActive,
  });

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      category: json['category'] ?? '',
      subcategory: json['subcategory'] ?? '',
      batchName: json['batch_name'] ?? '',
      bannerImageUrl: json['banner_image_url'] ?? '',
      instructor: Instructor.fromJson(json['instructor'] ?? {}),
      society: json['society'] ?? '',
      venue: json['venue'] ?? '',
      ageRange: json['age_range'] ?? '',
      capacity: json['capacity'] ?? 0,
      price: json['price'] ?? 0,
      paymentType: json['payment_type'] ?? '',
      isActive: json['is_active'] ?? false,
    );
  }

  String get displayName => name;
  String get priceDisplay => '₹$price';
  String get categoryDisplay => category;
  String get subcategoryDisplay => subcategory;
  String get instructorName => instructor.name;
  String get societyName => society;
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
}

// API Response wrapper for pagination
class ActivityListResponse {
  final int? count;
  final String? next;
  final String? previous;
  final List<Activity> results;

  ActivityListResponse({
    this.count,
    this.next,
    this.previous,
    required this.results,
  });

  factory ActivityListResponse.fromJson(Map<String, dynamic> json) {
    return ActivityListResponse(
      count: json['count'],
      next: json['next'],
      previous: json['previous'],
      results: (json['results'] as List<dynamic>? ?? json as List<dynamic>)
          .map((item) => Activity.fromJson(item))
          .toList(),
    );
  }

  // For backward compatibility when response is just a list
  factory ActivityListResponse.fromList(List<dynamic> jsonList) {
    return ActivityListResponse(
      results: jsonList.map((item) => Activity.fromJson(item)).toList(),
    );
  }
}

// SERVICE

class ActivityService {
  static const String baseUrl = 'https://dev-klayonsapi.vercel.app';

  static Future<String?> getAuthToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      print(
        '🔑 Token retrieved: ${token != null ? "Found (${token.length} chars)" : "Not found"}',
      );
      return token;
    } catch (e) {
      print('❌ Error getting token: $e');
      return null;
    }
  }

  static Future<ActivityListResponse> getActivities({
    String? activityName,
    String? category,
    String? subcategory,
    String? society,
    String? venue,
    String? search,
    String? ordering,
    int? page,
    int? pageSize,
  }) async {
    try {
      final token = await getAuthToken();
      if (token == null || token.isEmpty) {
        print('❌ No authentication token found');
        throw Exception('No authentication token found. Please login again.');
      }

      String url = '$baseUrl/api/activities/';
      List<String> queryParams = [];

      if (activityName != null && activityName.isNotEmpty) {
        queryParams.add('activity_name=$activityName');
      }
      if (category != null && category.isNotEmpty) {
        queryParams.add('category=$category');
      }
      if (subcategory != null && subcategory.isNotEmpty) {
        queryParams.add('subcategory=$subcategory');
      }
      if (society != null && society.isNotEmpty) {
        queryParams.add('society=$society');
      }
      if (venue != null && venue.isNotEmpty) {
        queryParams.add('venue=$venue');
      }
      if (search != null && search.isNotEmpty) {
        queryParams.add('search=$search');
      }
      if (ordering != null && ordering.isNotEmpty) {
        queryParams.add('ordering=$ordering');
      }
      if (page != null) {
        queryParams.add('page=$page');
      }
      if (pageSize != null) {
        queryParams.add('page_size=$pageSize');
      }

      if (queryParams.isNotEmpty) {
        url += '?' + queryParams.join('&');
      }

      print('🌐 Fetching activities from: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('📡 Response status: ${response.statusCode}');
      print('📄 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final dynamic jsonData = json.decode(response.body);

        // Check if response is paginated (has count, next, previous) or just a list
        if (jsonData is Map<String, dynamic> &&
            jsonData.containsKey('results')) {
          print(
            '✅ Successfully fetched paginated response with ${jsonData['results'].length} activities',
          );
          return ActivityListResponse.fromJson(jsonData);
        } else if (jsonData is List<dynamic>) {
          print('✅ Successfully fetched ${jsonData.length} activities');
          return ActivityListResponse.fromList(jsonData);
        } else {
          throw Exception('Unexpected response format');
        }
      } else if (response.statusCode == 401) {
        print('❌ Authentication failed - token may be expired');
        throw Exception('Authentication failed. Please login again.');
      } else {
        print('❌ API error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to load activities: ${response.statusCode}');
      }
    } catch (e) {
      print('💥 Error in getActivities: $e');
      if (e.toString().contains('No authentication token') ||
          e.toString().contains('Authentication failed')) {
        rethrow;
      }
      throw Exception('Error fetching activities: $e');
    }
  }

  static Future<List<Activity>> getActivitiesByCategory(
    String category, {
    int page = 1,
    int pageSize = 10,
  }) async {
    try {
      print('📂 Fetching activities for category: $category');
      final response = await getActivities(
        category: category,
        page: page,
        pageSize: pageSize,
      );
      return response.results;
    } catch (e) {
      print('❌ Error fetching activities by category: $e');
      rethrow;
    }
  }

  static Future<List<Activity>> searchActivities(
    String searchQuery, {
    int page = 1,
    int pageSize = 10,
  }) async {
    try {
      print('🔍 Searching activities with query: $searchQuery');
      final response = await getActivities(
        search: searchQuery,
        page: page,
        pageSize: pageSize,
      );
      return response.results;
    } catch (e) {
      print('❌ Error searching activities: $e');
      rethrow;
    }
  }

  static Future<List<Activity>> getAllActivities({
    int page = 1,
    int pageSize = 10,
    String? ordering,
  }) async {
    try {
      print('📋 Fetching all activities - Page: $page, Size: $pageSize');
      final response = await getActivities(
        page: page,
        pageSize: pageSize,
        ordering: ordering,
      );
      return response.results;
    } catch (e) {
      print('❌ Error fetching all activities: $e');
      rethrow;
    }
  }

  // Get activities with full pagination response (for pagination controls)
  static Future<ActivityListResponse> getActivitiesWithPagination({
    String? activityName,
    String? category,
    String? subcategory,
    String? society,
    String? venue,
    String? search,
    String? ordering,
    int page = 1,
    int pageSize = 10,
  }) async {
    return await getActivities(
      activityName: activityName,
      category: category,
      subcategory: subcategory,
      society: society,
      venue: venue,
      search: search,
      ordering: ordering,
      page: page,
      pageSize: pageSize,
    );
  }

  static Future<bool> validateToken() async {
    try {
      final token = await getAuthToken();
      if (token == null || token.isEmpty) {
        return false;
      }
      final response = await http.get(
        Uri.parse('$baseUrl/api/activities/?page=1&page_size=1'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      print('❌ Token validation error: $e');
      return false;
    }
  }

  static Future<void> clearAuthToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      print('🗑️ Auth token cleared');
    } catch (e) {
      print('❌ Error clearing token: $e');
    }
  }
}

// Backward compatibility - keeping old class name as alias
typedef BatchService = ActivityService;
typedef BatchWithActivity = Activity;
