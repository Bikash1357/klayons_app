import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// Token Storage Class - Use this existing one or add if missing
class TokenStorage {
  static const String _tokenKey = 'auth_token';
  static const String _userEmailKey = 'user_email';
  static const String _userNameKey = 'user_name';

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<void> saveUserData({
    required String email,
    required String name,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userEmailKey, email);
    await prefs.setString(_userNameKey, name);
  }

  static Future<Map<String, String?>> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'email': prefs.getString(_userEmailKey),
      'name': prefs.getString(_userNameKey),
    };
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userEmailKey);
    await prefs.remove(_userNameKey);
  }

  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}

class EnrollmentApiResponse {
  final bool success;
  final String? message;
  final EnrollmentData? data;
  final String? error;

  EnrollmentApiResponse({
    required this.success,
    this.message,
    this.data,
    this.error,
  });
}

class EnrollmentData {
  final int id;
  final Child child;
  final Activity activity;
  final String status;
  final int? waitlistPosition;
  final String? notes;
  final String timestamp;
  final List<EnrollmentHistory> history;

  EnrollmentData({
    required this.id,
    required this.child,
    required this.activity,
    required this.status,
    this.waitlistPosition,
    this.notes,
    required this.timestamp,
    required this.history,
  });

  factory EnrollmentData.fromJson(Map<String, dynamic> json) {
    return EnrollmentData(
      id: json['id'] ?? 0,
      child: Child.fromJson(json['child'] ?? {}),
      activity: Activity.fromJson(json['activity'] ?? {}),
      status: json['status'] ?? '',
      waitlistPosition: json['waitlist_position'],
      notes: json['notes'],
      timestamp: json['timestamp'] ?? '',
      history:
          (json['history'] as List<dynamic>?)
              ?.map((item) => EnrollmentHistory.fromJson(item))
              .toList() ??
          [],
    );
  }
}

class Child {
  final int id;
  final String name;

  Child({required this.id, required this.name});

  factory Child.fromJson(Map<String, dynamic> json) {
    return Child(id: json['id'] ?? 0, name: json['name'] ?? '');
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
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      category: json['category'] ?? '',
      subcategory: json['subcategory'] ?? '',
      batchName: json['batch_name'] ?? '',
      bannerImageUrl: json['banner_image_url'] ?? '',
      instructor: json['instructor'] ?? '',
      society: json['society'] ?? '',
      price: json['price'] ?? '0',
      paymentType: json['payment_type'] ?? 'monthly',
      isActive: json['is_active'] ?? false,
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
      id: json['id'] ?? 0,
      previousStatus: json['previous_status'],
      newStatus: json['new_status'] ?? '',
      changedAt: json['changed_at'] ?? '',
      changedByName: json['changed_by_name'] ?? '',
      reason: json['reason'] ?? '',
      timeAgo: json['time_ago'] ?? '',
    );
  }
}

class EnrollmentService {
  static const String _baseUrl = 'https://dev-klayonsapi.vercel.app/api';
  static const String _enrollEndpoint = '/enrollment/enroll/';

  /// Get authentication token using TokenStorage
  static Future<String?> _getToken() async {
    return await TokenStorage.getToken();
  }

  /// Enroll a child in an activity
  ///
  /// [childId] - ID of the child to enroll
  /// [activityId] - ID of the activity to enroll in
  /// [notes] - Optional notes for the enrollment
  ///
  /// Returns [EnrollmentApiResponse] with enrollment data or error
  static Future<EnrollmentApiResponse> enrollInActivity({
    required int childId,
    required int activityId,
    String? notes,
  }) async {
    try {
      // Get authentication token using TokenStorage
      final String? token = await _getToken();

      if (token == null || token.isEmpty) {
        print('❌ Authentication token not found');
        return EnrollmentApiResponse(
          success: false,
          error: 'Authentication token not found. Please login again.',
        );
      }

      final String url = '$_baseUrl$_enrollEndpoint';

      final Map<String, dynamic> requestBody = {
        'child': childId,
        'activity': activityId,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      };

      print('🌐 Enrollment Request URL: $url');
      print('📝 Enrollment Request Body: ${jsonEncode(requestBody)}');
      print('🔐 Using token: ${token.substring(0, 20)}...');

      final response = await http
          .post(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
            },
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 30));

      print('📡 Enrollment Response Status: ${response.statusCode}');
      print('📄 Enrollment Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        return EnrollmentApiResponse(
          success: true,
          message: _getSuccessMessage(responseData['status']),
          data: EnrollmentData.fromJson(responseData),
        );
      } else if (response.statusCode == 400) {
        final Map<String, dynamic> errorData = jsonDecode(response.body);
        return EnrollmentApiResponse(
          success: false,
          error: _parseErrorMessage(errorData),
        );
      } else if (response.statusCode == 401) {
        print('❌ Authentication failed - token may be expired');
        // Clear invalid token
        await TokenStorage.clearAll();
        return EnrollmentApiResponse(
          success: false,
          error: 'Authentication failed. Please login again.',
        );
      } else if (response.statusCode == 403) {
        return EnrollmentApiResponse(
          success: false,
          error: 'You don\'t have permission to enroll in this activity.',
        );
      } else if (response.statusCode == 404) {
        return EnrollmentApiResponse(
          success: false,
          error: 'Activity or child not found.',
        );
      } else if (response.statusCode == 409) {
        return EnrollmentApiResponse(
          success: false,
          error: 'Child is already enrolled in this activity.',
        );
      } else {
        try {
          final Map<String, dynamic> errorData = jsonDecode(response.body);
          return EnrollmentApiResponse(
            success: false,
            error: _parseErrorMessage(errorData),
          );
        } catch (e) {
          return EnrollmentApiResponse(
            success: false,
            error: 'Enrollment failed. Please try again.',
          );
        }
      }
    } on http.ClientException catch (e) {
      print('❌ Network error during enrollment: $e');
      return EnrollmentApiResponse(
        success: false,
        error: 'Network error. Please check your internet connection.',
      );
    } on FormatException catch (e) {
      print('❌ JSON parsing error during enrollment: $e');
      return EnrollmentApiResponse(
        success: false,
        error: 'Invalid server response format.',
      );
    } catch (e) {
      print('❌ Unexpected error during enrollment: $e');
      return EnrollmentApiResponse(
        success: false,
        error: 'An unexpected error occurred. Please try again.',
      );
    }
  }

  /// Check if user is authenticated
  static Future<bool> isAuthenticated() async {
    return await TokenStorage.isLoggedIn();
  }

  /// Get user data from storage
  static Future<Map<String, String?>> getUserData() async {
    return await TokenStorage.getUserData();
  }

  /// Get success message based on enrollment status
  static String _getSuccessMessage(String status) {
    switch (status.toLowerCase()) {
      case 'enrolled':
        return 'Successfully enrolled in the activity!';
      case 'reenrolled':
        return 'Successfully re-enrolled in the activity!';
      case 'waitlist':
        return 'Added to waitlist. You will be notified when a spot becomes available.';
      default:
        return 'Enrollment completed successfully!';
    }
  }

  /// Parse error message from API response
  static String _parseErrorMessage(Map<String, dynamic> errorData) {
    if (errorData.containsKey('detail')) {
      return errorData['detail'].toString();
    }

    if (errorData.containsKey('error')) {
      return errorData['error'].toString();
    }

    if (errorData.containsKey('message')) {
      return errorData['message'].toString();
    }

    // Handle field-specific errors
    if (errorData.containsKey('child')) {
      final childError = errorData['child'];
      if (childError is List && childError.isNotEmpty) {
        return 'Child selection error: ${childError.first}';
      }
      return 'Child selection error: $childError';
    }

    if (errorData.containsKey('activity')) {
      final activityError = errorData['activity'];
      if (activityError is List && activityError.isNotEmpty) {
        return 'Activity selection error: ${activityError.first}';
      }
      return 'Activity selection error: $activityError';
    }

    // Handle non_field_errors
    if (errorData.containsKey('non_field_errors')) {
      final errors = errorData['non_field_errors'];
      if (errors is List && errors.isNotEmpty) {
        return errors.first.toString();
      }
    }

    return 'Enrollment failed. Please try again.';
  }

  /// Clear enrollment cache (if you have caching implemented)
  static void clearEnrollmentCache() {
    // Clear any cached enrollment data
    // This method can be called after successful enrollment
    // to refresh the enrollment list
    print('📝 Enrollment cache cleared');
  }
}
