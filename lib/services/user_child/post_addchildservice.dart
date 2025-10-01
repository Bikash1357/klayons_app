import 'package:http/http.dart' as http;
import 'package:klayons/config/api_config.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AddChildService {
  // API endpoint
  static String apiUrl = ApiConfig.getFullUrl(ApiConfig.addChildrenEndpoint);

  // Get token from SharedPreferences with debugging
  static Future<String?> _getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Debug: Check all keys in SharedPreferences
      Set<String> keys = prefs.getKeys();
      print('All SharedPreferences keys: $keys');

      // Try multiple possible token keys
      String? token =
          prefs.getString('auth_token') ??
          prefs.getString('token') ??
          prefs.getString('access_token') ??
          prefs.getString('user_token');

      print(
        'Retrieved token: ${token != null ? "Token found (${token.length} chars)" : "No token found"}',
      );

      return token;
    } catch (e) {
      print('Error getting token: $e');
      return null;
    }
  }

  // Format date for API (YYYY-MM-DD format)
  static String _formatDateForAPI(DateTime date) {
    return "${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  // Convert gender to API format
  static String _formatGenderForAPI(String gender) {
    return gender.toLowerCase() == 'boy' ? 'male' : 'female';
  }

  // Submit child data to API
  static Future<Map<String, dynamic>> createChild({
    required String firstName,
    required DateTime dateOfBirth,
    required String gender,
    required List<int> interestIds,
  }) async {
    try {
      // Get authentication token
      final token = await _getToken();

      if (token == null || token.isEmpty) {
        return {
          'success': false,
          'error': 'Authentication required. Please login again.',
        };
      }

      // Prepare data for API with correct field names and formats
      final Map<String, dynamic> childData = {
        'name': '$firstName'.trim(),
        'gender': _formatGenderForAPI(gender),
        'dob': _formatDateForAPI(dateOfBirth),
        'interest_ids': interestIds,
      };

      print('Sending child data: $childData');
      print('API URL: $apiUrl');

      // Try Django Token format first
      Map<String, String> headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Token $token',
      };

      print('Using headers: $headers');

      // Make API call with Django Token authentication
      http.Response response = await http.post(
        Uri.parse(apiUrl),
        headers: headers,
        body: json.encode(childData),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      // If Token format fails with 401, try Bearer format
      if (response.statusCode == 401) {
        print('Trying Bearer token format...');
        headers['Authorization'] = 'Bearer $token';

        response = await http.post(
          Uri.parse(apiUrl),
          headers: headers,
          body: json.encode(childData),
        );

        print('Bearer response status: ${response.statusCode}');
        print('Bearer response body: ${response.body}');
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Success
        final responseData = json.decode(response.body);
        return {'success': true, 'data': responseData};
      } else {
        // Handle API error
        String errorMessage = 'Failed to create child profile';

        try {
          final errorData = json.decode(response.body);

          // Handle detailed field errors from Django
          if (errorData['errors'] != null) {
            List<String> fieldErrors = [];
            errorData['errors'].forEach((field, messages) {
              if (messages is List) {
                fieldErrors.add('$field: ${messages.join(', ')}');
              } else {
                fieldErrors.add('$field: $messages');
              }
            });
            errorMessage = fieldErrors.join('\n');
          } else if (errorData['detail'] != null) {
            errorMessage = errorData['detail'];
          } else if (errorData['message'] != null) {
            errorMessage = errorData['message'];
          } else if (errorData['error'] != null) {
            errorMessage = errorData['error'];
          }
        } catch (e) {
          // If response is not JSON, use status code
          if (response.statusCode == 401) {
            errorMessage = 'Authentication failed. Please login again.';
          } else if (response.statusCode == 400) {
            errorMessage = 'Invalid data provided. Please check your inputs.';
          } else {
            errorMessage =
                'Server error (${response.statusCode}). Please try again later.';
          }
        }

        return {'success': false, 'error': errorMessage};
      }
    } catch (error) {
      // Handle network or other errors
      print('Error submitting child data: $error');
      return {
        'success': false,
        'error': 'Network error: Please check your internet connection',
      };
    }
  }
}
