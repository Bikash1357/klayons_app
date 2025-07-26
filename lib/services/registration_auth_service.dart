import 'package:http/http.dart' as http;
import 'dart:convert';

class RegistrationAuthService {
  static const String baseUrl =
      'https://1f0f3792-ea29-4f20-8d98-5e8548cc11ac-00-1tccerdmhnsfy.pike.replit.dev';

  // Register user
  static Future<Map<String, dynamic>> registerUser({
    required String username,
    required String email,
    required String phoneNumber,
    required String societyName,
    required String flatNo,
    required String password,
    required String confirmPassword,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/register/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': username,
          'email': email,
          'phone_number': phoneNumber,
          'society_name': societyName,
          'flat_no': flatNo,
          'password': password,
          'confirm_password': confirmPassword,
        }),
      );

      final data = json.decode(response.body);

      return {
        'success': response.statusCode == 200 || response.statusCode == 201,
        'statusCode': response.statusCode,
        'data': data,
        'message': data['message'] ?? 'Registration completed',
      };
    } catch (e) {
      return {
        'success': false,
        'statusCode': 500,
        'data': null,
        'message': 'Network error. Please check your connection and try again.',
        'error': e.toString(),
      };
    }
  }

  // Verify OTP
  static Future<Map<String, dynamic>> verifyOTP({
    required String email,
    required String otpCode,
    required String purpose,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/verify-otp/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'otp_code': otpCode,
          'purpose': purpose,
        }),
      );

      final data = json.decode(response.body);

      return {
        'success': response.statusCode == 200,
        'statusCode': response.statusCode,
        'data': data,
        'message': data['message'] ?? 'OTP verification completed',
        'token': data['token'], // If token is returned
      };
    } catch (e) {
      return {
        'success': false,
        'statusCode': 500,
        'data': null,
        'message': 'Network error. Please check your connection and try again.',
        'error': e.toString(),
      };
    }
  }

  // Resend OTP
  static Future<Map<String, dynamic>> resendOTP({
    required String email,
    required String purpose,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/resend-otp/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'purpose': purpose}),
      );

      final data = json.decode(response.body);

      return {
        'success': response.statusCode == 200,
        'statusCode': response.statusCode,
        'data': data,
        'message': data['message'] ?? 'OTP resent successfully',
      };
    } catch (e) {
      return {
        'success': false,
        'statusCode': 500,
        'data': null,
        'message': 'Network error. Please try again.',
        'error': e.toString(),
      };
    }
  }

  // Helper method to parse error messages
  static String parseErrorMessage(Map<String, dynamic> errorData) {
    if (errorData.containsKey('message')) {
      return errorData['message'];
    }

    // Handle field-specific errors
    String errorMessage = 'Registration failed:\n';
    errorData.forEach((key, value) {
      if (value is List) {
        errorMessage += '• ${value.join(', ')}\n';
      } else {
        errorMessage += '• $value\n';
      }
    });

    return errorMessage.trim();
  }
}
