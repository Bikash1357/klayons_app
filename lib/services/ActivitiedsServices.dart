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

  // Cache variables for activities list
  static List<Activity>? _cachedActivities;
  static DateTime? _activitiesCacheTimestamp;
  static bool _isLoadingActivities = false;

  // Cache variables for individual activities
  static Map<int, Activity> _cachedIndividualActivities = {};
  static Map<int, DateTime> _individualActivitiesCacheTimestamps = {};
  static Set<int> _loadingActivityIds = {};

  // Cache configuration
  static const Duration _cacheExpiration = Duration(
    minutes: 15,
  ); // Activities cache for 15 minutes
  static const Duration _individualCacheExpiration = Duration(
    minutes: 30,
  ); // Individual activities cache for 30 minutes

  // Private method to get headers with token
  static Future<Map<String, String>> _getHeaders() async {
    final token = await TokenService.getToken();
    final headers = {'Content-Type': 'application/json'};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  /// Checks if activities cache is still valid
  static bool _isActivitiesCacheValid() {
    if (_cachedActivities == null || _activitiesCacheTimestamp == null) {
      return false;
    }

    final now = DateTime.now();
    final cacheAge = now.difference(_activitiesCacheTimestamp!);
    return cacheAge < _cacheExpiration;
  }

  /// Checks if individual activity cache is still valid
  static bool _isIndividualActivityCacheValid(int activityId) {
    if (!_cachedIndividualActivities.containsKey(activityId) ||
        !_individualActivitiesCacheTimestamps.containsKey(activityId)) {
      return false;
    }

    final now = DateTime.now();
    final cacheAge = now.difference(
      _individualActivitiesCacheTimestamps[activityId]!,
    );
    return cacheAge < _individualCacheExpiration;
  }

  /// Clears all caches
  static void clearAllCache() {
    _cachedActivities = null;
    _activitiesCacheTimestamp = null;
    _isLoadingActivities = false;
    _cachedIndividualActivities.clear();
    _individualActivitiesCacheTimestamps.clear();
    _loadingActivityIds.clear();
    print('All activities cache cleared');
  }

  /// Clears only activities list cache
  static void clearActivitiesListCache() {
    _cachedActivities = null;
    _activitiesCacheTimestamp = null;
    _isLoadingActivities = false;
    print('Activities list cache cleared');
  }

  /// Clears individual activity cache
  static void clearIndividualActivityCache(int activityId) {
    _cachedIndividualActivities.remove(activityId);
    _individualActivitiesCacheTimestamps.remove(activityId);
    _loadingActivityIds.remove(activityId);
    print('Individual activity cache cleared for ID: $activityId');
  }

  // Get all activities with caching
  static Future<List<Activity>> getActivities({
    bool forceRefresh = false,
  }) async {
    // Return cached data if valid and not forcing refresh
    if (!forceRefresh && _isActivitiesCacheValid()) {
      print(
        'Returning cached activities list (${_cachedActivities!.length} items)',
      );
      return List<Activity>.from(_cachedActivities!);
    }

    // If already loading, wait for the current request to complete
    if (_isLoadingActivities) {
      print('Activities loading in progress, waiting...');
      while (_isLoadingActivities) {
        await Future.delayed(Duration(milliseconds: 100));
      }
      return _cachedActivities != null
          ? List<Activity>.from(_cachedActivities!)
          : [];
    }

    try {
      _isLoadingActivities = true;
      print('Fetching activities from server...');

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

        // Cache the activities
        _cachedActivities = activities;
        _activitiesCacheTimestamp = DateTime.now();

        print(
          'Activities fetched and cached successfully (${activities.length} items)',
        );
        return List<Activity>.from(activities);
      } else if (response.statusCode == 401) {
        // Clear cache on auth error
        clearAllCache();
        throw Exception('Login first');
      } else {
        throw Exception('Error fetching activities');
      }
    } catch (e) {
      if (e.toString().contains('Login first')) {
        clearAllCache();
        throw Exception('Login first');
      }
      throw Exception('Error fetching activities');
    } finally {
      _isLoadingActivities = false;
    }
  }

  // Get activity by ID with caching
  static Future<Activity> getActivityById(
    int id, {
    bool forceRefresh = false,
  }) async {
    // Return cached data if valid and not forcing refresh
    if (!forceRefresh && _isIndividualActivityCacheValid(id)) {
      print('Returning cached activity for ID: $id');
      return _cachedIndividualActivities[id]!;
    }

    // If already loading this specific activity, wait for it
    if (_loadingActivityIds.contains(id)) {
      print('Activity $id loading in progress, waiting...');
      while (_loadingActivityIds.contains(id)) {
        await Future.delayed(Duration(milliseconds: 100));
      }
      if (_cachedIndividualActivities.containsKey(id)) {
        return _cachedIndividualActivities[id]!;
      }
    }

    try {
      _loadingActivityIds.add(id);
      print('Fetching activity $id from server...');

      final headers = await _getHeaders();
      // Use ApiConfig for URL construction
      final url = ApiConfig.getFullUrl('${ApiConfig.activitiesEndpoint}$id/');

      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        final activity = Activity.fromJson(jsonData);

        // Cache the individual activity
        _cachedIndividualActivities[id] = activity;
        _individualActivitiesCacheTimestamps[id] = DateTime.now();

        print('Activity $id fetched and cached successfully');
        return activity;
      } else if (response.statusCode == 401) {
        clearAllCache();
        throw Exception('Login first');
      } else {
        throw Exception('Error fetching activity');
      }
    } catch (e) {
      if (e.toString().contains('Login first')) {
        clearAllCache();
        throw Exception('Login first');
      }
      throw Exception('Error fetching activity');
    } finally {
      _loadingActivityIds.remove(id);
    }
  }

  // Get only active activities with caching
  static Future<List<Activity>> getActiveActivities({
    bool forceRefresh = false,
  }) async {
    try {
      final activities = await getActivities(forceRefresh: forceRefresh);
      final activeActivities = activities
          .where((activity) => activity.isActive)
          .toList();
      print(
        'Filtered ${activeActivities.length} active activities from ${activities.length} total',
      );
      return activeActivities;
    } catch (e) {
      if (e.toString().contains('Login first')) {
        throw Exception('Login first');
      }
      throw Exception('Error fetching active activities');
    }
  }

  /// Gets cached activities without making API call (returns null if no cache)
  static List<Activity>? getCachedActivities() {
    if (_isActivitiesCacheValid()) {
      print('Returning valid cached activities list');
      return List<Activity>.from(_cachedActivities!);
    }
    print('No valid cached activities available');
    return null;
  }

  /// Gets cached activity by ID without making API call (returns null if no cache)
  static Activity? getCachedActivityById(int id) {
    if (_isIndividualActivityCacheValid(id)) {
      print('Returning valid cached activity for ID: $id');
      return _cachedIndividualActivities[id];
    }
    print('No valid cached activity available for ID: $id');
    return null;
  }

  /// Checks if activities are currently being loaded
  static bool get isLoadingActivities => _isLoadingActivities;

  /// Checks if specific activity is currently being loaded
  static bool isLoadingActivity(int id) => _loadingActivityIds.contains(id);

  /// Gets activities cache age in minutes (returns -1 if no cache)
  static int getActivitiesCacheAgeInMinutes() {
    if (_activitiesCacheTimestamp == null) return -1;

    final now = DateTime.now();
    final cacheAge = now.difference(_activitiesCacheTimestamp!);
    return cacheAge.inMinutes;
  }

  /// Gets individual activity cache age in minutes (returns -1 if no cache)
  static int getIndividualActivityCacheAgeInMinutes(int id) {
    if (!_individualActivitiesCacheTimestamps.containsKey(id)) return -1;

    final now = DateTime.now();
    final cacheAge = now.difference(_individualActivitiesCacheTimestamps[id]!);
    return cacheAge.inMinutes;
  }

  /// Gets cache statistics for debugging
  static Map<String, dynamic> getCacheStats() {
    return {
      'activitiesListCached': _cachedActivities != null,
      'activitiesCount': _cachedActivities?.length ?? 0,
      'activitiesCacheAgeMinutes': getActivitiesCacheAgeInMinutes(),
      'individualActivitiesCached': _cachedIndividualActivities.length,
      'individualActivitiesIds': _cachedIndividualActivities.keys.toList(),
      'currentlyLoadingActivities': _isLoadingActivities,
      'currentlyLoadingIndividualIds': _loadingActivityIds.toList(),
    };
  }

  // Alternative: You can also use ApiConfig.getHeaders() method if you prefer
  static Future<Map<String, String>> _getHeadersUsingApiConfig() async {
    final token = await TokenService.getToken();
    return ApiConfig.getHeaders(token: token);
  }
}
