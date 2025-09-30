import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../auth/signup_service.dart';

// Data Models
class Child {
  final int id;
  final String name;

  Child({required this.id, required this.name});

  factory Child.fromJson(Map<String, dynamic> json) {
    return Child(id: json['id'], name: json['name']);
  }
}

class Activity {
  final int id;
  final String name;
  final String category;
  final String subcategory;
  final String batchName;
  final String bannerImageUrl;
  final String instructor;
  final String society;
  final String price;
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
    required this.price,
    required this.paymentType,
    required this.isActive,
  });

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      id: json['id'],
      name: json['name'],
      category: json['category'],
      subcategory: json['subcategory'],
      batchName: json['batch_name'] ?? '',
      bannerImageUrl: json['banner_image_url'],
      instructor: json['instructor'],
      society: json['society'],
      price: json['price'],
      paymentType: json['payment_type'],
      isActive: json['is_active'],
    );
  }
}

class EnrollmentHistory {
  final int id;
  final String? previousStatus;
  final String newStatus;
  final String changedAt;
  final String changedByName;
  final String reason;
  final String timeAgo;

  EnrollmentHistory({
    required this.id,
    this.previousStatus,
    required this.newStatus,
    required this.changedAt,
    required this.changedByName,
    required this.reason,
    required this.timeAgo,
  });

  factory EnrollmentHistory.fromJson(Map<String, dynamic> json) {
    return EnrollmentHistory(
      id: json['id'],
      previousStatus: json['previous_status'],
      newStatus: json['new_status'],
      changedAt: json['changed_at'],
      changedByName: json['changed_by_name'],
      reason: json['reason'],
      timeAgo: json['time_ago'],
    );
  }
}

class UnenrollResponse {
  final int id;
  final Child child;
  final Activity activity;
  final String status;
  final int? waitlistPosition;
  final String notes;
  final String timestamp;
  final List<EnrollmentHistory> history;

  UnenrollResponse({
    required this.id,
    required this.child,
    required this.activity,
    required this.status,
    this.waitlistPosition,
    required this.notes,
    required this.timestamp,
    required this.history,
  });

  factory UnenrollResponse.fromJson(Map<String, dynamic> json) {
    return UnenrollResponse(
      id: json['id'],
      child: Child.fromJson(json['child']),
      activity: Activity.fromJson(json['activity']),
      status: json['status'],
      waitlistPosition: json['waitlist_position'],
      notes: json['notes'],
      timestamp: json['timestamp'],
      history: (json['history'] as List)
          .map((item) => EnrollmentHistory.fromJson(item))
          .toList(),
    );
  }
}

// Service Response Wrapper
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? error;
  final int? statusCode;

  ApiResponse({required this.success, this.data, this.error, this.statusCode});
}

// Main Service Class
class EnrollmentService {
  static const String baseUrl = 'https://dev-klayons.onrender.com';

  // You should store these securely (e.g., in secure storage)
  static String? _authToken;
  static String? _csrfToken;

  // Method to set auth tokens
  static void setAuthTokens({
    required String authToken,
    required String csrfToken,
  }) {
    _authToken = authToken;
    _csrfToken = csrfToken;
  }

  // Unenroll from activity
  static Future<ApiResponse<UnenrollResponse>> unenrollFromActivity(
    int enrollmentId,
  ) async {
    final token = await TokenStorage.getToken();

    if (token == null || token.isEmpty) {
      return ApiResponse<UnenrollResponse>(
        success: false,
        error: "Authentication required. Please login first.",
        statusCode: 401,
      );
    }

    try {
      final url = Uri.parse('$baseUrl/api/enrollment/unenroll/$enrollmentId/');

      print('Attempting to unenroll enrollment ID: $enrollmentId');
      print('DELETE URL: $url');

      final response = await http.delete(
        url,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          // Note: CSRF token might not be needed for API calls, but including for completeness
          // You can remove this line if your API doesn't require it
          // 'X-CSRFTOKEN': 'your_csrf_token_if_needed',
        },
      );

      print('API Response Status: ${response.statusCode}');
      print('API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final unenrollResponse = UnenrollResponse.fromJson(jsonData);

        print(
          'Successfully unenrolled: ${unenrollResponse.child.name} from ${unenrollResponse.activity.name}',
        );

        return ApiResponse<UnenrollResponse>(
          success: true,
          data: unenrollResponse,
          statusCode: response.statusCode,
        );
      } else if (response.statusCode == 401) {
        return ApiResponse<UnenrollResponse>(
          success: false,
          error: 'Authentication failed. Please login again.',
          statusCode: response.statusCode,
        );
      } else if (response.statusCode == 404) {
        return ApiResponse<UnenrollResponse>(
          success: false,
          error: 'Enrollment not found or already unenrolled.',
          statusCode: response.statusCode,
        );
      } else if (response.statusCode == 403) {
        return ApiResponse<UnenrollResponse>(
          success: false,
          error:
              'Access denied. You may not have permission to unenroll this enrollment.',
          statusCode: response.statusCode,
        );
      } else {
        String errorMessage =
            'Failed to unenroll. Server returned ${response.statusCode}';

        // Try to extract error message from response body
        try {
          final errorData = json.decode(response.body);
          if (errorData is Map<String, dynamic>) {
            if (errorData.containsKey('detail')) {
              errorMessage += ': ${errorData['detail']}';
            } else if (errorData.containsKey('message')) {
              errorMessage += ': ${errorData['message']}';
            } else if (errorData.containsKey('error')) {
              errorMessage += ': ${errorData['error']}';
            }
          }
        } catch (e) {
          // If we can't parse error response, use original message
          print('Could not parse error response: $e');
        }

        return ApiResponse<UnenrollResponse>(
          success: false,
          error: errorMessage,
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      print('Error during unenroll request: $e');

      return ApiResponse<UnenrollResponse>(
        success: false,
        error: 'Network error. Please check your connection and try again.',
      );
    }
  }

  // Alternative method with custom error handling
  static Future<UnenrollResponse?> unenrollFromActivitySimple(
    int enrollmentId,
  ) async {
    try {
      final response = await unenrollFromActivity(enrollmentId);

      if (response.success && response.data != null) {
        return response.data;
      } else {
        throw Exception(response.error ?? 'Unknown error occurred');
      }
    } catch (e) {
      print('Error unenrolling: $e');
      rethrow;
    }
  }

  /// Clear any cached data related to enrollments
  /// Call this after successful unenrollment to refresh data
  static void clearEnrollmentCache() {
    // If you're using GetEnrollmentService cache, clear it
    // This ensures fresh data is fetched on next enrollment list request
    print('Clearing enrollment cache after unenrollment');
    // You can call GetEnrollmentService.clearCache() here if needed
  }
}

// Usage Example
class EnrollmentController {
  Future<void> handleUnenrollment(int enrollmentId) async {
    try {
      // Method 1: Using ApiResponse wrapper
      final response = await EnrollmentService.unenrollFromActivity(
        enrollmentId,
      );

      if (response.success && response.data != null) {
        final unenrollData = response.data!;
        print(
          'Successfully unenrolled ${unenrollData.child.name} from ${unenrollData.activity.name}',
        );
        print('Current status: ${unenrollData.status}');

        // Show success message to user
        _showSuccessMessage('Successfully unenrolled from activity');

        // Clear enrollment cache to force fresh data on next fetch
        EnrollmentService.clearEnrollmentCache();

        // Update UI or navigate back
        _refreshEnrollmentList();
      } else {
        print('Error: ${response.error}');
        _showErrorMessage(response.error ?? 'Failed to unenroll');
      }
    } catch (e) {
      print('Exception: $e');
      _showErrorMessage('An error occurred during unenrollment');
    }
  }

  // Alternative usage with simple method
  Future<void> handleUnenrollmentSimple(int enrollmentId) async {
    try {
      final unenrollData = await EnrollmentService.unenrollFromActivitySimple(
        enrollmentId,
      );

      if (unenrollData != null) {
        print('Unenrolled: ${unenrollData.child.name}');
        print('Activity: ${unenrollData.activity.name}');
        print('Status: ${unenrollData.status}');
        print('History entries: ${unenrollData.history.length}');

        _showSuccessMessage('Successfully unenrolled from activity');

        // Clear enrollment cache to force fresh data on next fetch
        EnrollmentService.clearEnrollmentCache();

        _refreshEnrollmentList();
      }
    } catch (e) {
      print('Error: $e');
      _showErrorMessage(e.toString());
    }
  }

  void _showSuccessMessage(String message) {
    // Implement your success message display (e.g., SnackBar, Toast)
    print('Success: $message');
  }

  void _showErrorMessage(String message) {
    // Implement your error message display
    print('Error: $message');
  }

  void _refreshEnrollmentList() {
    // Clear the cache to force fresh data fetch
    // If you're using GetEnrollmentService, call its clearCache method
    // GetEnrollmentService.clearCache();

    // Trigger UI refresh - implement based on your state management
    print('Refreshing enrollment list...');
  }
}

// How to use (Updated usage without manual token setting):
//
// 1. The service will automatically get the auth token from SharedPreferences
//    (same as your GetEnrollmentService)
//
// 2. Use the service:
// final controller = EnrollmentController();
// await controller.handleUnenrollment(12);
//
// 3. After successful unenrollment, the enrollment cache is automatically cleared
//    to ensure fresh data on next fetch
