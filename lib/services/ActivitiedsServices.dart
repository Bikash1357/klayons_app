import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

// Data Models
class Instructor {
  final int id;
  final String name;
  final String profile;

  Instructor({required this.id, required this.name, required this.profile});

  factory Instructor.fromJson(Map<String, dynamic> json) {
    return Instructor(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      profile: json['profile'] ?? '',
    );
  }
}

class Activity {
  final int id;
  final String name;
  final String description;
  final String bannerImageUrl;
  final String pricing;
  final int ageGroupStart;
  final int ageGroupEnd;
  final String startDate;
  final String endDate;
  final Instructor instructor;
  final bool isActive;
  final String batchesCount;

  Activity({
    required this.id,
    required this.name,
    required this.description,
    required this.bannerImageUrl,
    required this.pricing,
    required this.ageGroupStart,
    required this.ageGroupEnd,
    required this.startDate,
    required this.endDate,
    required this.instructor,
    required this.isActive,
    required this.batchesCount,
  });

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      bannerImageUrl: json['banner_image_url'] ?? '',
      pricing: json['pricing']?.toString() ?? '0.00',
      ageGroupStart: json['age_group_start'] ?? 0,
      ageGroupEnd: json['age_group_end'] ?? 0,
      startDate: json['start_date'] ?? '',
      endDate: json['end_date'] ?? '',
      instructor: json['instructor'] != null
          ? Instructor.fromJson(json['instructor'])
          : Instructor(id: 0, name: 'Unknown', profile: ''),
      isActive: json['is_active'] ?? false,
      batchesCount: json['batches_count']?.toString() ?? '0',
    );
  }
}

// Token Storage Service
class TokenService {
  static const String _tokenKey = 'auth_token';

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }
}

class ActivitiesService {
  // Get the full activities URL from ApiConfig
  static String get _activitiesUrl =>
      ApiConfig.getFullUrl(ApiConfig.activitiesEndpoint);

  // Private method to get headers with token
  static Future<Map<String, String>> _getHeaders() async {
    final token = await TokenService.getToken();
    final headers = {'Content-Type': 'application/json'};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // Get all activities
  static Future<List<Activity>> getActivities() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse(_activitiesUrl),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        List<Activity> activities = [];

        for (var json in jsonData) {
          try {
            activities.add(Activity.fromJson(json));
          } catch (e) {
            // Skip problematic data
            print('Error parsing activity: $e');
          }
        }
        return activities;
      } else if (response.statusCode == 401) {
        throw Exception('Login first');
      } else {
        throw Exception('Error fetching activities');
      }
    } catch (e) {
      if (e.toString().contains('Login first')) {
        throw Exception('Login first');
      }
      throw Exception('Error fetching activities');
    }
  }

  // Get activity by ID
  static Future<Activity> getActivityById(int id) async {
    try {
      final headers = await _getHeaders();
      // Use ApiConfig for URL construction
      final url = ApiConfig.getFullUrl('${ApiConfig.activitiesEndpoint}$id/');

      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        return Activity.fromJson(jsonData);
      } else if (response.statusCode == 401) {
        throw Exception('Login first');
      } else {
        throw Exception('Error fetching activity');
      }
    } catch (e) {
      if (e.toString().contains('Login first')) {
        throw Exception('Login first');
      }
      throw Exception('Error fetching activity');
    }
  }

  // Get only active activities
  static Future<List<Activity>> getActiveActivities() async {
    try {
      final activities = await getActivities();
      return activities.where((activity) => activity.isActive).toList();
    } catch (e) {
      if (e.toString().contains('Login first')) {
        throw Exception('Login first');
      }
      throw Exception('Error fetching active activities');
    }
  }

  // Alternative: You can also use ApiConfig.getHeaders() method if you prefer
  static Future<Map<String, String>> _getHeadersUsingApiConfig() async {
    final token = await TokenService.getToken();
    return ApiConfig.getHeaders(token: token);
  }
}
