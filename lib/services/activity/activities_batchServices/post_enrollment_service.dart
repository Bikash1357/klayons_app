import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// Enrollment Models
enum EnrollmentErrorType {
  authentication,
  validation,
  notFound,
  duplicate,
  server,
  network,
  unknown,
}

class EnrollmentException implements Exception {
  final String message;
  final EnrollmentErrorType type;
  final int? statusCode;

  EnrollmentException(this.message, {required this.type, this.statusCode});

  @override
  String toString() => message;

  String get userFriendlyMessage {
    switch (type) {
      case EnrollmentErrorType.authentication:
        return 'Please login to continue with enrollment.';
      case EnrollmentErrorType.validation:
        return message; // Return API validation message
      case EnrollmentErrorType.notFound:
        return 'The selected child or activity is no longer available.';
      case EnrollmentErrorType.duplicate:
        return 'This child is already enrolled in the selected activity.';
      case EnrollmentErrorType.server:
        return 'Server temporarily unavailable. Please try again later.';
      case EnrollmentErrorType.network:
        return 'Please check your internet connection and try again.';
      case EnrollmentErrorType.unknown:
        return 'An unexpected error occurred. Please try again.';
    }
  }

  Color get errorColor {
    switch (type) {
      case EnrollmentErrorType.authentication:
        return Colors.orange;
      case EnrollmentErrorType.validation:
      case EnrollmentErrorType.duplicate:
        return Colors.amber;
      case EnrollmentErrorType.notFound:
      case EnrollmentErrorType.server:
      case EnrollmentErrorType.network:
      case EnrollmentErrorType.unknown:
        return Colors.red;
    }
  }

  IconData get errorIcon {
    switch (type) {
      case EnrollmentErrorType.authentication:
        return Icons.login;
      case EnrollmentErrorType.validation:
        return Icons.warning;
      case EnrollmentErrorType.duplicate:
        return Icons.person_add_disabled;
      case EnrollmentErrorType.notFound:
        return Icons.search_off;
      case EnrollmentErrorType.server:
        return Icons.error;
      case EnrollmentErrorType.network:
        return Icons.wifi_off;
      case EnrollmentErrorType.unknown:
        return Icons.error;
    }
  }
}

class EnrollmentRequest {
  final int childId;
  final int activityId;

  EnrollmentRequest({required this.childId, required this.activityId});

  Map<String, dynamic> toJson() {
    return {'child_id': childId, 'activity_id': activityId};
  }
}

class EnrollmentResponse {
  final int id;
  final String status;
  final int childId;
  final String childName;
  final int activityId;
  final String activityName;
  final int price;

  EnrollmentResponse({
    required this.id,
    required this.status,
    required this.childId,
    required this.childName,
    required this.activityId,
    required this.activityName,
    required this.price,
  });

  factory EnrollmentResponse.fromJson(Map<String, dynamic> json) {
    return EnrollmentResponse(
      id: json['id'],
      status: json['status'],
      childId: json['child_id'],
      childName: json['child_name'],
      activityId: json['activity_id'],
      activityName: json['activity_name'],
      price: json['price'],
    );
  }

  bool get isEnrolled => status.toLowerCase() == 'enrolled';
  bool get isWaitlisted => status.toLowerCase() == 'waitlisted';

  String get statusDisplay {
    switch (status.toLowerCase()) {
      case 'enrolled':
        return 'Enrolled Successfully';
      case 'waitlisted':
        return 'Added to Waitlist';
      default:
        return status;
    }
  }

  String get priceDisplay {
    return '₹$price';
  }
}

class EnrollmentService {
  static const String baseUrl = 'https://dev-klayonsapi.vercel.app/api';
  static const String _tokenKey = 'auth_token';

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

  /// Helper method to extract error message from API response
  static String _extractErrorMessage(Map<String, dynamic> errorData) {
    try {
      // Handle different error response formats
      if (errorData.containsKey('error')) {
        final error = errorData['error'];

        if (error is Map<String, dynamic>) {
          // Format: {"error":{"activity_id":["This field is required."]}}
          List<String> errorMessages = [];

          error.forEach((field, messages) {
            if (messages is List) {
              for (var message in messages) {
                errorMessages.add('$field: ${message.toString()}');
              }
            } else {
              errorMessages.add('$field: ${messages.toString()}');
            }
          });

          return errorMessages.join(', ');
        } else if (error is String) {
          return error;
        }
      }

      // Handle direct error messages
      if (errorData.containsKey('detail')) {
        return errorData['detail'].toString();
      }

      if (errorData.containsKey('message')) {
        return errorData['message'].toString();
      }

      // Fallback - return the entire error object as string
      return errorData.toString();
    } catch (e) {
      print('Error parsing error message: $e');
      return 'Unknown error occurred';
    }
  }

  /// Enroll a child in an activity
  static Future<EnrollmentResponse> enrollChild({
    required int childId,
    required int activityId,
  }) async {
    final token = await _getToken();

    if (token == null || token.isEmpty) {
      throw EnrollmentException(
        'Authentication required. Please login first.',
        type: EnrollmentErrorType.authentication,
      );
    }

    final enrollmentRequest = EnrollmentRequest(
      childId: childId,
      activityId: activityId,
    );

    try {
      print('Enrolling child $childId in activity $activityId...');
      print('Request body: ${json.encode(enrollmentRequest.toJson())}');

      final response = await http.post(
        Uri.parse('$baseUrl/enrollment/enroll/'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(enrollmentRequest.toJson()),
      );

      print('Enrollment API Response Status: ${response.statusCode}');
      print('Enrollment API Response Body: ${response.body}');

      switch (response.statusCode) {
        case 201:
          final Map<String, dynamic> jsonData = json.decode(response.body);
          final enrollmentResponse = EnrollmentResponse.fromJson(jsonData);

          print('Enrollment successful: ${enrollmentResponse.status}');
          return enrollmentResponse;

        case 400:
          final Map<String, dynamic> errorData = json.decode(response.body);
          final String errorMessage = _extractErrorMessage(errorData);

          throw EnrollmentException(
            errorMessage,
            type: EnrollmentErrorType.validation,
            statusCode: 400,
          );

        case 401:
          throw EnrollmentException(
            'Authentication failed. Please login again.',
            type: EnrollmentErrorType.authentication,
            statusCode: 401,
          );

        case 404:
          throw EnrollmentException(
            'Child or activity not found. Please check and try again.',
            type: EnrollmentErrorType.notFound,
            statusCode: 404,
          );

        case 409:
          throw EnrollmentException(
            'Child is already enrolled in this activity.',
            type: EnrollmentErrorType.duplicate,
            statusCode: 409,
          );

        case 500:
          throw EnrollmentException(
            'Server error occurred. Please try again later.',
            type: EnrollmentErrorType.server,
            statusCode: 500,
          );

        default:
          // Try to parse error response for other status codes
          String errorMessage =
              'Unexpected error occurred (${response.statusCode})';
          try {
            final Map<String, dynamic> errorData = json.decode(response.body);
            errorMessage = _extractErrorMessage(errorData);
          } catch (e) {
            // If parsing fails, use default message
            print('Failed to parse error response: $e');
          }

          throw EnrollmentException(
            errorMessage,
            type: EnrollmentErrorType.unknown,
            statusCode: response.statusCode,
          );
      }
    } catch (e) {
      print('Network error in enrollChild: $e');

      if (e is EnrollmentException) {
        rethrow;
      }

      // Handle JSON parsing errors
      if (e.toString().contains('FormatException')) {
        throw EnrollmentException(
          'Invalid response from server. Please try again.',
          type: EnrollmentErrorType.server,
        );
      }

      throw EnrollmentException(
        'Network error. Please check your connection and try again.',
        type: EnrollmentErrorType.network,
      );
    }
  }
}
