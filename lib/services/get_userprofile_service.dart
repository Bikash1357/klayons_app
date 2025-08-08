import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:klayons/config/api_config.dart';
import 'package:klayons/services/login_auth_service.dart';

class UserProfile {
  final String name; // Added name field
  final String userEmail;
  final String userPhone;
  final int societyId;
  final String flatNo; // Added flat_no field

  UserProfile({
    required this.name, // Added name as required
    required this.userEmail,
    required this.userPhone,
    required this.societyId,
    required this.flatNo, // Added flatNo as required
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      name: json['name'] ?? '', // Parse name from backend
      userEmail: json['user_email'] ?? '',
      userPhone: json['user_phone'] ?? '',
      societyId: json['society_id'] ?? 0,
      flatNo: json['flat_no'] ?? '', // Parse flat_no from backend
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name, // Include name in JSON
      'user_email': userEmail,
      'user_phone': userPhone,
      'society_id': societyId,
      'flat_no': flatNo, // Include flat_no in JSON
    };
  }

  @override
  String toString() {
    return 'UserProfile{name: $name, userEmail: $userEmail, userPhone: $userPhone, societyId: $societyId, flatNo: $flatNo}';
  }
}

class GetUserProfileService {
  static const String _baseUrl = 'https://klayons-backend.vercel.app';
  static const String _profileEndpoint = '/api/profiles/parent/';

  /// Fetches the authenticated user's profile
  static Future<UserProfile?> getUserProfile() async {
    try {
      // Get the authentication token
      final token = await LoginAuthService.getToken();

      if (token == null) {
        print('No authentication token found');
        throw Exception('User not authenticated');
      }

      print('Fetching user profile...');
      print('API URL: $_baseUrl$_profileEndpoint');
      print('Token available: ${token.isNotEmpty}');

      final response = await http
          .get(
            Uri.parse('$_baseUrl$_profileEndpoint'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
              ...ApiConfig.getHeaders(),
            },
          )
          .timeout(
            Duration(seconds: 30),
            onTimeout: () {
              throw Exception(
                'Request timeout. Please check your internet connection.',
              );
            },
          );

      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Parse the user profile from response
        final userProfile = UserProfile.fromJson(data);

        print('User profile fetched successfully: $userProfile');
        return userProfile;
      } else if (response.statusCode == 401) {
        print('Unauthorized - token may be invalid or expired');
        // Clear invalid token
        await LoginAuthService.clearAuthData();
        throw Exception('Session expired. Please login again.');
      } else if (response.statusCode == 404) {
        print('Profile not found');
        throw Exception(
          'Profile not found. Please complete your profile setup.',
        );
      } else if (response.statusCode >= 500) {
        print('Server error: ${response.statusCode}');
        throw Exception('Server error. Please try again later.');
      } else {
        final data = json.decode(response.body);
        final errorMessage = data['message'] ?? 'Failed to fetch profile';
        print('Error: $errorMessage');
        throw Exception(errorMessage);
      }
    } on FormatException catch (e) {
      print('JSON parsing error: $e');
      throw Exception('Invalid response from server');
    } on http.ClientException catch (e) {
      print('HTTP Client error: $e');
      throw Exception('Network error. Please check your internet connection.');
    } catch (e) {
      print('Get user profile error: $e');
      if (e.toString().contains('timeout')) {
        throw Exception(
          'Request timeout. Please check your internet connection.',
        );
      } else if (e.toString().contains('SocketException')) {
        throw Exception('No internet connection. Please check your network.');
      } else {
        rethrow; // Re-throw the original exception
      }
    }
  }

  /// Updates the user's profile
  static Future<UserProfile?> updateUserProfile({
    String? name, // Added name parameter
    String? userEmail,
    String? userPhone,
    int? societyId,
    String? flatNo, // Added flatNo parameter
  }) async {
    try {
      // Get the authentication token
      final token = await LoginAuthService.getToken();

      if (token == null) {
        print('No authentication token found');
        throw Exception('User not authenticated');
      }

      // Prepare request body with only non-null values
      Map<String, dynamic> requestBody = {};
      if (name != null) requestBody['name'] = name; // Include name
      if (userEmail != null) requestBody['user_email'] = userEmail;
      if (userPhone != null) requestBody['user_phone'] = userPhone;
      if (societyId != null) requestBody['society_id'] = societyId;
      if (flatNo != null) requestBody['flat_no'] = flatNo; // Include flat_no

      if (requestBody.isEmpty) {
        throw Exception('No data provided to update');
      }

      print('Updating user profile...');
      print('API URL: $_baseUrl$_profileEndpoint');
      print('Update data: $requestBody');

      final response = await http
          .put(
            Uri.parse('$_baseUrl$_profileEndpoint'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
              ...ApiConfig.getHeaders(),
            },
            body: json.encode(requestBody),
          )
          .timeout(
            Duration(seconds: 30),
            onTimeout: () {
              throw Exception(
                'Request timeout. Please check your internet connection.',
              );
            },
          );

      print('Update response status code: ${response.statusCode}');
      print('Update response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Parse the updated user profile from response
        final userProfile = UserProfile.fromJson(data);

        print('User profile updated successfully: $userProfile');
        return userProfile;
      } else if (response.statusCode == 401) {
        print('Unauthorized - token may be invalid or expired');
        await LoginAuthService.clearAuthData();
        throw Exception('Session expired. Please login again.');
      } else if (response.statusCode == 422) {
        final data = json.decode(response.body);
        String errorMessage = 'Validation error. ';
        if (data.containsKey('errors')) {
          errorMessage += data['errors'].toString();
        } else {
          errorMessage += data['message'] ?? 'Please check your input.';
        }
        throw Exception(errorMessage);
      } else {
        final data = json.decode(response.body);
        final errorMessage = data['message'] ?? 'Failed to update profile';
        print('Error: $errorMessage');
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('Update user profile error: $e');
      rethrow;
    }
  }

  /// Checks if user has a complete profile
  static Future<bool> hasCompleteProfile() async {
    try {
      final profile = await getUserProfile();
      if (profile == null) return false;

      // Check if all required fields are filled
      return profile.name.isNotEmpty && // Include name check
          profile.userEmail.isNotEmpty &&
          profile.userPhone.isNotEmpty &&
          profile.societyId > 0;
    } catch (e) {
      print('Error checking profile completeness: $e');
      return false;
    }
  }

  /// Refreshes user profile and updates local storage
  static Future<void> refreshAndSaveProfile() async {
    try {
      final profile = await getUserProfile();
      if (profile != null) {
        // Save updated profile data to local storage
        final existingToken = await LoginAuthService.getToken();
        if (existingToken != null) {
          await LoginAuthService.saveAuthData(
            token: existingToken,
            userData: profile.toJson(),
          );
          print('Profile refreshed and saved to local storage');
        }
      }
    } catch (e) {
      print('Error refreshing profile: $e');
      rethrow;
    }
  }
}
