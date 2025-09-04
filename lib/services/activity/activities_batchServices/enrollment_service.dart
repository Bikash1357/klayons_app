import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// Enrollment Models
class EnrollmentRequest {
  final int childId;
  final int batchId;

  EnrollmentRequest({required this.childId, required this.batchId});

  Map<String, dynamic> toJson() {
    return {'child_id': childId, 'batch_id': batchId};
  }
}

class EnrollmentResponse {
  final int id;
  final String status;
  final int childId;
  final String childName;
  final int batchId;
  final String batchName;
  final int activityId;
  final String activityName;
  final double price;

  EnrollmentResponse({
    required this.id,
    required this.status,
    required this.childId,
    required this.childName,
    required this.batchId,
    required this.batchName,
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
      batchId: json['batch_id'],
      batchName: json['batch_name'],
      activityId: json['activity_id'],
      activityName: json['activity_name'],
      price: (json['price'] as num).toDouble(),
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
    return '₹${price.toStringAsFixed(0)}';
  }
}

// Enrollment Service
class EnrollmentService {
  static const String baseUrl = 'https://dev-klayonsapi.vercel.app//api';
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

  /// Enroll a child in a batch
  static Future<EnrollmentResponse> enrollChild({
    required int childId,
    required int batchId,
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
      batchId: batchId,
    );

    try {
      print('Enrolling child $childId in batch $batchId...');

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
          final errorData = json.decode(response.body);
          String errorMessage = 'Enrollment failed';

          if (errorData is Map<String, dynamic>) {
            if (errorData.containsKey('detail')) {
              errorMessage = errorData['detail'];
            } else if (errorData.containsKey('error')) {
              errorMessage = errorData['error'];
            } else if (errorData.containsKey('message')) {
              errorMessage = errorData['message'];
            }
          }

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
            'Child or batch not found. Please check and try again.',
            type: EnrollmentErrorType.notFound,
            statusCode: 404,
          );

        case 409:
          throw EnrollmentException(
            'Child is already enrolled in this batch.',
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
          throw EnrollmentException(
            'Unexpected error occurred (${response.statusCode})',
            type: EnrollmentErrorType.unknown,
            statusCode: response.statusCode,
          );
      }
    } catch (e) {
      print('Network error in enrollChild: $e');

      if (e is EnrollmentException) {
        rethrow;
      }

      throw EnrollmentException(
        'Network error. Please check your connection and try again.',
        type: EnrollmentErrorType.network,
      );
    }
  }

  /// Check if a child is already enrolled in a specific batch
  static Future<bool> isChildEnrolled({
    required int childId,
    required int batchId,
  }) async {
    // This would typically be a separate API call
    // For now, we'll handle this in the enrollment call itself
    // The API will return appropriate error if already enrolled
    return false;
  }
}

// Custom Exception for Enrollment Errors
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
        return message; // Return the specific validation message from API
      case EnrollmentErrorType.notFound:
        return 'The selected child or batch is no longer available.';
      case EnrollmentErrorType.duplicate:
        return 'This child is already enrolled in the selected batch.';
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
