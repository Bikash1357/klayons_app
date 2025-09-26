import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'enrollementModel.dart';

class GetEnrollmentService {
  static const String baseUrl = "https://dev-klayonsapi.vercel.app/api";
  static const String _tokenKey = "auth_token";

  // Cache variables
  static List<GetEnrollment>? _cachedEnrollments;
  static DateTime? _cacheTimestamp;
  static bool _isLoading = false;

  // Cache configuration - 5 minutes
  static const Duration _cacheExpiration = Duration(minutes: 5);

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

  /// Fetch enrollments with caching support and query parameters
  static Future<List<GetEnrollment>> fetchMyEnrollments({
    bool forceRefresh = false,
    int? activityId,
    int? childId,
    String? status,
  }) async {
    // Return cached data if valid and not forcing refresh
    if (!forceRefresh &&
        _isCacheValid() &&
        activityId == null &&
        childId == null &&
        status == null) {
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
      clearCache();
      throw Exception("Authentication required. Please login first.");
    }

    try {
      _isLoading = true;
      print(
        forceRefresh
            ? 'Force refreshing enrollments from API...'
            : 'Fetching enrollments from API...',
      );

      // Build query parameters
      Map<String, String> queryParams = {};
      if (activityId != null)
        queryParams['activity_id'] = activityId.toString();
      if (childId != null) queryParams['child_id'] = childId.toString();
      if (status != null) queryParams['status'] = status;

      // Construct URL with query parameters
      String url = "$baseUrl/enrollment/";
      if (queryParams.isNotEmpty) {
        url +=
            '?' +
            queryParams.entries.map((e) => '${e.key}=${e.value}').join('&');
      }

      final response = await http.get(
        Uri.parse(url),
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
        List<GetEnrollment> allEnrollments = [];

        // Handle the API response structure - direct array of enrollment objects
        if (responseData is List) {
          for (var enrollmentJson in responseData) {
            try {
              // Validate required fields exist
              if (enrollmentJson is Map<String, dynamic>) {
                // Check for required nested objects
                if (enrollmentJson['child'] == null ||
                    enrollmentJson['activity'] == null) {
                  print(
                    'Skipping enrollment with missing child or activity data',
                  );
                  continue;
                }

                final enrollment = GetEnrollment.fromJson(enrollmentJson);
                allEnrollments.add(enrollment);
                print('Successfully parsed enrollment ID: ${enrollment.id}');
              } else {
                print(
                  'Invalid enrollment data type: ${enrollmentJson.runtimeType}',
                );
              }
            } catch (e) {
              print('Error parsing individual enrollment: $e');
              print('Problematic enrollment JSON: $enrollmentJson');
              // Continue with other enrollments instead of failing completely
            }
          }
        } else if (responseData is Map<String, dynamic>) {
          // Handle case where API might return a single enrollment object
          try {
            if (responseData['child'] != null &&
                responseData['activity'] != null) {
              final enrollment = GetEnrollment.fromJson(responseData);
              allEnrollments.add(enrollment);
            }
          } catch (e) {
            print('Error parsing single enrollment object: $e');
          }
        } else {
          print('Unexpected response structure: ${responseData.runtimeType}');
          print('Response content: $responseData');
          throw Exception('Invalid API response format');
        }

        // Update cache with new data only if no filtering was applied
        if (activityId == null && childId == null && status == null) {
          _updateCache(allEnrollments);
        }

        print(
          'Enrollments fetched successfully (${allEnrollments.length} items)',
        );

        // Log enrollment details for debugging
        for (var enrollment in allEnrollments) {
          print(
            'Enrollment ${enrollment.id}: ${enrollment.child?.name} - ${enrollment.activity?.name} (${enrollment.status})',
          );
        }

        return List<GetEnrollment>.from(allEnrollments);
      } else if (response.statusCode == 401) {
        clearCache();
        throw Exception('Authentication failed. Please login again.');
      } else if (response.statusCode == 404) {
        throw Exception('Enrollment endpoint not found.');
      } else if (response.statusCode == 403) {
        throw Exception(
          'Access denied. You may not have permission to view these enrollments.',
        );
      } else {
        String errorMessage =
            'Failed to fetch enrollments. Server returned ${response.statusCode}';

        // Try to extract error message from response body
        try {
          final errorData = json.decode(response.body);
          if (errorData is Map<String, dynamic> &&
              errorData.containsKey('detail')) {
            errorMessage += ': ${errorData['detail']}';
          } else if (errorData is Map<String, dynamic> &&
              errorData.containsKey('message')) {
            errorMessage += ': ${errorData['message']}';
          }
        } catch (e) {
          // If we can't parse error response, use original message
        }

        throw Exception(errorMessage);
      }
    } catch (e) {
      print('Error fetching enrollments: $e');

      // Re-throw specific exceptions
      if (e.toString().contains('Authentication')) {
        clearCache();
        rethrow;
      }

      if (e.toString().contains('Access denied') ||
          e.toString().contains('Enrollment endpoint not found')) {
        rethrow;
      }

      // Don't throw FormatException for individual parsing errors
      if (e.toString().contains('FormatException') &&
          _cachedEnrollments != null) {
        print('Using cached data due to parsing errors');
        return List<GetEnrollment>.from(_cachedEnrollments!);
      }

      // For network errors, try to return cached data if available
      if (_cachedEnrollments != null && _cachedEnrollments!.isNotEmpty) {
        print('Using cached data due to network error');
        return List<GetEnrollment>.from(_cachedEnrollments!);
      }

      throw Exception(
        'Network error. Please check your connection and try again.',
      );
    } finally {
      _isLoading = false;
    }
  }

  /// Get enrollments by status
  static Future<List<GetEnrollment>> getEnrollmentsByStatus(
    String status,
  ) async {
    return await fetchMyEnrollments(status: status);
  }

  /// Get enrollments for a specific child
  static Future<List<GetEnrollment>> getEnrollmentsByChild(int childId) async {
    return await fetchMyEnrollments(childId: childId);
  }

  /// Get enrollments for a specific activity
  static Future<List<GetEnrollment>> getEnrollmentsByActivity(
    int activityId,
  ) async {
    return await fetchMyEnrollments(activityId: activityId);
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
      'cacheExpirationMinutes': _cacheExpiration.inMinutes,
    };
  }
}
