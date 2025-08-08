import 'package:http/http.dart' as http;
import 'dart:convert';

class RegistrationAuthService {
  static const String baseUrl = 'https://klayons-backend.vercel.app/';

  // Register user
  static Future<Map<String, dynamic>> registerUser({
    required String username,
    required String email,
    required String phoneNumber,
    required int societyId,
    required String flatNo,
  }) async {
    try {
      print(
        'Registering user with data: {username: $username, email: $email, phone: $phoneNumber, societyId: $societyId, flatNo: $flatNo}',
      );

      final response = await http.post(
        Uri.parse('${baseUrl}api/auth/signup/'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'name': username,
          'email': email,
          'phone': phoneNumber,
          'society_id': societyId,
          'flat_no': flatNo,
        }),
      );

      print('Registration response status: ${response.statusCode}');
      print('Registration response body: ${response.body}');

      // Parse response body
      late Map<String, dynamic> data;
      try {
        data = json.decode(response.body);
      } catch (e) {
        print('JSON parsing error: $e');
        return {
          'success': false,
          'statusCode': response.statusCode,
          'data': null,
          'message': 'Invalid response from server',
          'error': 'JSON parsing failed: $e',
        };
      }

      // Check for successful registration
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'statusCode': response.statusCode,
          'data': data,
          'message':
              data['message'] ??
              'Registration successful! Please check your email for OTP.',
          'token': data['token'], // Include token if provided
          'user': data['user'], // Include user data if provided
        };
      } else {
        // Handle different error status codes
        String errorMessage;
        if (response.statusCode >= 400 && response.statusCode < 500) {
          // Client errors (400-499)
          errorMessage = parseErrorMessage(data);
        } else if (response.statusCode >= 500) {
          // Server errors (500+)
          errorMessage = 'Server error. Please try again later.';
        } else {
          errorMessage = data['message'] ?? 'Registration failed';
        }

        return {
          'success': false,
          'statusCode': response.statusCode,
          'data': data,
          'message': errorMessage,
        };
      }
    } catch (e) {
      print('Registration network error: $e');
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
      print('Verifying OTP for email: $email, purpose: $purpose');

      final response = await http.post(
        Uri.parse('${baseUrl}api/auth/verify-otp/'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'email': email,
          'otp_code': otpCode,
          'purpose': purpose,
        }),
      );

      print('OTP verification response status: ${response.statusCode}');
      print('OTP verification response body: ${response.body}');

      final data = json.decode(response.body);

      return {
        'success': response.statusCode == 200,
        'statusCode': response.statusCode,
        'data': data,
        'message': data['message'] ?? 'OTP verification completed',
        'token':
            data['token'] ??
            data['access_token'], // Handle both token field names
        'user': data['user'], // Include user data
      };
    } catch (e) {
      print('OTP verification error: $e');
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
      print('Resending OTP for email: $email, purpose: $purpose');

      final response = await http.post(
        Uri.parse('${baseUrl}api/auth/resend-otp/'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({'email': email, 'purpose': purpose}),
      );

      print('Resend OTP response status: ${response.statusCode}');
      print('Resend OTP response body: ${response.body}');

      final data = json.decode(response.body);

      return {
        'success': response.statusCode == 200,
        'statusCode': response.statusCode,
        'data': data,
        'message': data['message'] ?? 'OTP resent successfully',
      };
    } catch (e) {
      print('Resend OTP error: $e');
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
  static String parseErrorMessage(Map<String, dynamic>? errorData) {
    if (errorData == null) {
      return 'Registration failed';
    }

    // Check for direct message
    if (errorData.containsKey('message') && errorData['message'] != null) {
      return errorData['message'].toString();
    }

    // Check for error field
    if (errorData.containsKey('error') && errorData['error'] != null) {
      return errorData['error'].toString();
    }

    // Check for detail field (Django REST Framework style)
    if (errorData.containsKey('detail') && errorData['detail'] != null) {
      return errorData['detail'].toString();
    }

    // Handle field-specific validation errors
    List<String> errors = [];

    errorData.forEach((key, value) {
      if (key == 'message' || key == 'error' || key == 'detail') {
        return; // Skip already handled keys
      }

      if (value is List && value.isNotEmpty) {
        // Handle list of errors for a field
        String fieldErrors = value.map((e) => e.toString()).join(', ');
        errors.add('${_formatFieldName(key)}: $fieldErrors');
      } else if (value is String && value.isNotEmpty) {
        // Handle single error for a field
        errors.add('${_formatFieldName(key)}: $value');
      } else if (value != null) {
        // Handle other types
        errors.add('${_formatFieldName(key)}: ${value.toString()}');
      }
    });

    if (errors.isNotEmpty) {
      return errors.join('\n');
    }

    return 'Registration failed. Please check your information and try again.';
  }

  // Helper method to format field names for user display
  static String _formatFieldName(String fieldName) {
    switch (fieldName.toLowerCase()) {
      case 'username':
        return 'Name';
      case 'email':
        return 'Email';
      case 'phone_number':
        return 'Phone';
      case 'society_id':
        return 'Society';
      case 'flat_no':
        return 'Flat number';
      default:
        // Convert snake_case to Title Case
        return fieldName
            .split('_')
            .map(
              (word) => word.isEmpty
                  ? ''
                  : word[0].toUpperCase() + word.substring(1).toLowerCase(),
            )
            .join(' ');
    }
  }
}
