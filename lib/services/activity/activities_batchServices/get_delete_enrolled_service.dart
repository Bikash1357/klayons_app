import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class GetEnrollment {
  final int id;
  final int childId;
  final String childName;
  final int activityId;
  final String activityName;
  final int price;
  final String status;
  final DateTime enrolledAt;

  GetEnrollment({
    required this.id,
    required this.childId,
    required this.childName,
    required this.activityId,
    required this.activityName,
    required this.price,
    required this.status,
    required this.enrolledAt,
  });

  factory GetEnrollment.fromJson(Map<String, dynamic> json) {
    try {
      return GetEnrollment(
        id: _parseIntSafely(json['id']),
        childId: _parseIntSafely(json['child_id']),
        childName: json['child_name']?.toString() ?? '',
        activityId: _parseIntSafely(json['activity_id']),
        activityName: json['activity_name']?.toString() ?? '',
        price: _parseIntSafely(json['price']),
        status: json['status']?.toString() ?? '',
        enrolledAt: _parseDateTimeSafely(json['enrolled_at']),
      );
    } catch (e) {
      print('Error parsing GetEnrollment from JSON: $e');
      print('JSON data: $json');
      rethrow;
    }
  }

  // Helper method to safely parse integers from JSON
  static int _parseIntSafely(dynamic value) {
    if (value == null) {
      print('Warning: Null value encountered for integer field');
      return 0; // Default value for null integers
    }
    if (value is int) return value;
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    if (value is double) return value.toInt();
    print('Warning: Unexpected type ${value.runtimeType} for integer field');
    return 0;
  }

  // Helper method to safely parse DateTime from JSON
  static DateTime _parseDateTimeSafely(dynamic value) {
    if (value == null) {
      print('Warning: Null value encountered for DateTime field');
      return DateTime.now(); // Default to current time
    }
    try {
      return DateTime.parse(value.toString());
    } catch (e) {
      print('Warning: Failed to parse DateTime: $value');
      return DateTime.now(); // Default to current time
    }
  }

  // Convert back to JSON for caching
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'child_id': childId,
      'child_name': childName,
      'activity_id': activityId,
      'activity_name': activityName,
      'price': price,
      'status': status,
      'enrolled_at': enrolledAt.toIso8601String(),
    };
  }

  // Helper methods
  String get statusDisplay {
    switch (status.toLowerCase()) {
      case 'enrolled':
        return 'Enrolled';
      case 'waitlist':
        return 'Waitlisted';
      default:
        return status;
    }
  }

  Color get statusColor {
    switch (status.toLowerCase()) {
      case 'enrolled':
        return Colors.green;
      case 'waitlist':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String get priceDisplay => '₹$price';

  String get enrolledAtDisplay {
    final localDate = enrolledAt.toLocal();
    return '${localDate.day}/${localDate.month}/${localDate.year}';
  }
}

class GetEnrollmentService {
  static const String baseUrl = "https://dev-klayonsapi.vercel.app/api";
  static const String _tokenKey = "auth_token";

  // Cache variables
  static List<GetEnrollment>? _cachedEnrollments;
  static DateTime? _cacheTimestamp;
  static bool _isLoading = false;

  // Cache configuration - 10 minutes
  static const Duration _cacheExpiration = Duration(minutes: 10);

  static Future<String?> _getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);
      print(
        'Retrieved token: ${token != null ? "Found (${token.length} chars)" : "Not found"}',
      );
      return token;
    } catch (e) {
      print('Error getting token: $e');
      return null;
    }
  }

  /// Check if cache is still valid
  static bool _isCacheValid() {
    if (_cachedEnrollments == null || _cacheTimestamp == null) {
      return false;
    }

    final now = DateTime.now();
    final cacheAge = now.difference(_cacheTimestamp!);
    final isValid = cacheAge < _cacheExpiration;

    print('Cache age: ${cacheAge.inMinutes} minutes, Valid: $isValid');
    return isValid;
  }

  /// Clear cache manually
  static void clearCache() {
    _cachedEnrollments = null;
    _cacheTimestamp = null;
    _isLoading = false;
    print('Enrollment cache cleared');
  }

  /// Get cached enrollments without API call
  static List<GetEnrollment>? getCachedEnrollments() {
    if (_isCacheValid()) {
      print(
        'Returning cached enrollments (${_cachedEnrollments!.length} items)',
      );
      return List<GetEnrollment>.from(_cachedEnrollments!);
    }
    print('No valid cached enrollments available');
    return null;
  }

  /// Update cache with new data
  static void _updateCache(List<GetEnrollment> enrollments) {
    _cachedEnrollments = List<GetEnrollment>.from(enrollments);
    _cacheTimestamp = DateTime.now();
    print(
      'Cache updated with ${enrollments.length} enrollments at ${_cacheTimestamp}',
    );
  }

  /// Fetch enrollments with caching support
  static Future<List<GetEnrollment>> fetchMyEnrollments({
    bool forceRefresh = false,
  }) async {
    // Return cached data if valid and not forcing refresh
    if (!forceRefresh && _isCacheValid()) {
      print('Using cached enrollment data');
      return List<GetEnrollment>.from(_cachedEnrollments!);
    }

    // If already loading, wait for current request
    if (_isLoading) {
      print('Enrollment loading in progress, waiting...');
      while (_isLoading) {
        await Future.delayed(Duration(milliseconds: 100));
      }
      // Return cached data after loading completes
      return _cachedEnrollments != null
          ? List<GetEnrollment>.from(_cachedEnrollments!)
          : [];
    }

    final token = await _getToken();

    if (token == null || token.isEmpty) {
      clearCache(); // Clear cache on auth issues
      throw Exception("Authentication required. Please login first.");
    }

    try {
      _isLoading = true;
      print(
        forceRefresh
            ? 'Force refreshing enrollments from API...'
            : 'Fetching enrollments from API...',
      );

      final response = await http.get(
        Uri.parse("$baseUrl/enrollment/my-enrollments/"),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('API Response Status: ${response.statusCode}');
      print('API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final dynamic responseData = json.decode(response.body);

        // Handle different response structures
        List<GetEnrollment> allEnrollments = [];

        // Check if response is a list directly
        if (responseData is List) {
          for (var item in responseData) {
            if (item is Map<String, dynamic> &&
                item.containsKey('enrollments')) {
              final List<dynamic> enrollmentsList =
                  item['enrollments'] as List<dynamic>;

              for (var enrollmentJson in enrollmentsList) {
                try {
                  final enrollment = GetEnrollment.fromJson(
                    enrollmentJson as Map<String, dynamic>,
                  );
                  allEnrollments.add(enrollment);
                } catch (e) {
                  print('Error parsing individual enrollment: $e');
                  print('Problematic enrollment JSON: $enrollmentJson');
                  // Continue with other enrollments instead of failing completely
                }
              }
            }
          }
        }
        // Check if response is a single object with enrollments array
        else if (responseData is Map<String, dynamic> &&
            responseData.containsKey('enrollments')) {
          final List<dynamic> enrollmentsList =
              responseData['enrollments'] as List<dynamic>;

          for (var enrollmentJson in enrollmentsList) {
            try {
              final enrollment = GetEnrollment.fromJson(
                enrollmentJson as Map<String, dynamic>,
              );
              allEnrollments.add(enrollment);
            } catch (e) {
              print('Error parsing individual enrollment: $e');
              print('Problematic enrollment JSON: $enrollmentJson');
              // Continue with other enrollments instead of failing completely
            }
          }
        }
        // If response structure is unexpected, log it for debugging
        else {
          print('Unexpected response structure: ${responseData.runtimeType}');
          print('Response content: $responseData');
        }

        // Update cache with new data
        _updateCache(allEnrollments);

        print(
          'Enrollments fetched and cached successfully (${allEnrollments.length} items)',
        );
        return List<GetEnrollment>.from(allEnrollments);
      } else if (response.statusCode == 401) {
        clearCache(); // Clear cache on auth failure
        throw Exception('Authentication failed. Please login again.');
      } else if (response.statusCode == 404) {
        throw Exception('Enrollment endpoint not found.');
      } else {
        throw Exception(
          'Failed to fetch enrollments. Server returned ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error fetching enrollments: $e');

      // Re-throw specific exceptions
      if (e.toString().contains('Authentication')) {
        clearCache();
        rethrow;
      }

      // Don't throw FormatException for individual parsing errors
      if (e.toString().contains('FormatException') &&
          _cachedEnrollments != null) {
        print('Using cached data due to parsing errors');
        return List<GetEnrollment>.from(_cachedEnrollments!);
      }

      throw Exception(
        'Network error. Please check your connection and try again.',
      );
    } finally {
      _isLoading = false;
    }
  }

  /// Unenroll child and update cache
  static Future<bool> unenrollChild(int enrollmentId) async {
    final token = await _getToken();

    if (token == null || token.isEmpty) {
      throw Exception("Authentication required. Please login first.");
    }

    try {
      print('Unenrolling enrollment ID: $enrollmentId...');

      final response = await http.delete(
        Uri.parse("$baseUrl/enrollment/unenroll/$enrollmentId/"),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Unenroll API Response Status: ${response.statusCode}');
      print('Unenroll API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        print('Child successfully unenrolled from enrollment $enrollmentId');

        // Update cache by removing the unenrolled item
        if (_cachedEnrollments != null) {
          _cachedEnrollments!.removeWhere(
            (enrollment) => enrollment.id == enrollmentId,
          );
          _cacheTimestamp = DateTime.now(); // Update cache timestamp
          print('Removed enrollment $enrollmentId from cache');
        }

        return true;
      } else if (response.statusCode == 401) {
        clearCache(); // Clear cache on auth failure
        throw Exception('Authentication failed. Please login again.');
      } else if (response.statusCode == 404) {
        // Remove from cache even if API says not found
        if (_cachedEnrollments != null) {
          _cachedEnrollments!.removeWhere(
            (enrollment) => enrollment.id == enrollmentId,
          );
        }
        throw Exception(
          'Enrollment not found. It may have been already removed.',
        );
      } else {
        throw Exception(
          'Failed to unenroll. Server returned ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error unenrolling child: $e');

      if (e.toString().contains('Authentication')) {
        rethrow;
      }
      if (e.toString().contains('Enrollment not found')) {
        rethrow;
      }

      throw Exception(
        'Network error. Please check your connection and try again.',
      );
    }
  }

  /// Get cache statistics for debugging
  static Map<String, dynamic> getCacheStats() {
    return {
      'hasCachedData': _cachedEnrollments != null,
      'enrollmentCount': _cachedEnrollments?.length ?? 0,
      'cacheTimestamp': _cacheTimestamp?.toIso8601String(),
      'cacheAgeMinutes': _cacheTimestamp != null
          ? DateTime.now().difference(_cacheTimestamp!).inMinutes
          : -1,
      'isCacheValid': _isCacheValid(),
      'isCurrentlyLoading': _isLoading,
    };
  }
}
