import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class GetEnrollment {
  final int id;
  final int childId;
  final String childName;
  final int batchId;
  final String batchName;
  final int activityId;
  final String activityName;
  final double price;
  final String status;
  final DateTime enrolledAt;

  GetEnrollment({
    required this.id,
    required this.childId,
    required this.childName,
    required this.batchId,
    required this.batchName,
    required this.activityId,
    required this.activityName,
    required this.price,
    required this.status,
    required this.enrolledAt,
  });

  factory GetEnrollment.fromJson(Map<String, dynamic> json) {
    return GetEnrollment(
      id: json['id'],
      childId: json['child_id'],
      childName: json['child_name'],
      batchId: json['batch_id'],
      batchName: json['batch_name'],
      activityId: json['activity_id'],
      activityName: json['activity_name'],
      price: (json['price'] as num).toDouble(),
      status: json['status'],
      enrolledAt: DateTime.parse(json['enrolled_at']),
    );
  }

  // Convert back to JSON for caching
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'child_id': childId,
      'child_name': childName,
      'batch_id': batchId,
      'batch_name': batchName,
      'activity_id': activityId,
      'activity_name': activityName,
      'price': price,
      'status': status,
      'enrolled_at': enrolledAt.toIso8601String(),
    };
  }

  // Helper methods (keep existing)
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

  String get priceDisplay => '₹${price.toStringAsFixed(0)}';

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

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData =
            json.decode(response.body) as Map<String, dynamic>;
        final List<dynamic> enrollmentsList =
            responseData['enrollments'] as List<dynamic>;

        final List<GetEnrollment> enrollments = enrollmentsList
            .map(
              (enrollmentJson) => GetEnrollment.fromJson(
                enrollmentJson as Map<String, dynamic>,
              ),
            )
            .toList();

        // Update cache with new data
        _updateCache(enrollments);

        print(
          'Enrollments fetched and cached successfully (${enrollments.length} items)',
        );
        return List<GetEnrollment>.from(enrollments);
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
      if (e.toString().contains('FormatException') ||
          e.toString().contains('type')) {
        throw Exception(
          'Invalid response format from server. Please try again.',
        );
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
