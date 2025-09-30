import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:klayons/config/api_config.dart';
import 'package:klayons/services/UserProfileServices/userProfileModels.dart';
import 'package:klayons/services/auth/login_service.dart';

import 'get_userprofile_service.dart';

class UpdateUserProfileService {
  static const String _baseUrl = 'https://klayons-backend.onrender.com/';
  static const String _profileEndpoint = 'api/profiles/';

  /// Updates the user's profile based on residence type
  static Future<UserProfile?> updateUserProfile({
    String? name,
    String? userEmail,
    String? userPhone,
    String? residenceType,
    int? societyId,
    String? societyName,
    String? tower,
    String? flatNo,
    String? address,
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

      if (name != null) requestBody['name'] = name;
      if (userEmail != null) requestBody['user_email'] = userEmail;
      if (userPhone != null) requestBody['user_phone'] = userPhone;
      if (residenceType != null) requestBody['residence_type'] = residenceType;

      // Handle residence type specific fields
      if (residenceType != null) {
        switch (residenceType) {
          case 'society':
            // For active society, include society_id, tower, flat_no
            if (societyId != null) requestBody['society_id'] = societyId;
            if (tower != null) requestBody['tower'] = tower;
            if (flatNo != null) requestBody['flat_no'] = flatNo;
            // Clear other residence fields when switching to society
            break;

          case 'society_other':
            // For other society, include society_name and address
            if (societyName != null) requestBody['society_name'] = societyName;
            if (address != null) requestBody['address'] = address;
            // Previous society_id, tower, flat_no will be cleared by API
            break;

          case 'individual':
            // For individual housing, only include address
            if (address != null) requestBody['address'] = address;
            // Other society fields will be cleared by API
            break;
        }
      } else {
        // If not changing residence type, include all provided fields
        if (societyId != null) requestBody['society_id'] = societyId;
        if (societyName != null) requestBody['society_name'] = societyName;
        if (tower != null) requestBody['tower'] = tower;
        if (flatNo != null) requestBody['flat_no'] = flatNo;
        if (address != null) requestBody['address'] = address;
      }

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

        // Parse the updated profile data
        final updatedProfile = UserProfile.fromJson(data);

        // Update the cache in GetUserProfileService
        GetUserProfileService.updateCache(updatedProfile);

        print('User profile updated successfully: $updatedProfile');
        return updatedProfile;
      } else if (response.statusCode == 401) {
        print('Unauthorized - token may be invalid or expired');
        GetUserProfileService.clearCache();
        await LoginAuthService.clearAuthData();
        throw Exception('Session expired. Please login again.');
      } else if (response.statusCode == 422) {
        final data = json.decode(response.body);
        String errorMessage = 'Validation error. ';
        if (data.containsKey('errors')) {
          if (data['errors'] is Map) {
            // Handle field-specific validation errors
            Map<String, dynamic> errors = data['errors'];
            List<String> errorList = [];
            errors.forEach((field, messages) {
              if (messages is List) {
                errorList.addAll(messages.map((msg) => '$field: $msg'));
              } else {
                errorList.add('$field: $messages');
              }
            });
            errorMessage += errorList.join(', ');
          } else {
            errorMessage += data['errors'].toString();
          }
        } else {
          errorMessage += data['message'] ?? 'Please check your input.';
        }
        throw Exception(errorMessage);
      } else if (response.statusCode >= 500) {
        print('Server error: ${response.statusCode}');
        throw Exception('Server error. Please try again later.');
      } else {
        final data = json.decode(response.body);
        final errorMessage = data['message'] ?? 'Failed to update profile';
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
      print('Update user profile error: $e');
      if (e.toString().contains('timeout')) {
        throw Exception(
          'Request timeout. Please check your internet connection.',
        );
      } else if (e.toString().contains('SocketException')) {
        throw Exception('No internet connection. Please check your network.');
      } else {
        rethrow;
      }
    }
  }

  /// Switches residence type from Active Society to Other Society
  static Future<UserProfile?> switchToOtherSociety({
    required String societyName,
    required String address,
    String? name,
  }) async {
    return await updateUserProfile(
      name: name,
      residenceType: 'society_other',
      societyName: societyName,
      address: address,
    );
  }

  /// Switches residence type to Individual Housing
  static Future<UserProfile?> switchToIndividualHousing({
    required String address,
    String? name,
  }) async {
    return await updateUserProfile(
      name: name,
      residenceType: 'individual',
      address: address,
    );
  }

  /// Switches residence type to Active Society
  static Future<UserProfile?> switchToActiveSociety({
    required int societyId,
    required String tower,
    required String flatNo,
    String? name,
  }) async {
    return await updateUserProfile(
      name: name,
      residenceType: 'society',
      societyId: societyId,
      tower: tower,
      flatNo: flatNo,
    );
  }

  /// Updates only the parent name
  static Future<UserProfile?> updateName({required String name}) async {
    return await updateUserProfile(name: name);
  }

  /// Updates society name and address for Other Society residence
  static Future<UserProfile?> updateOtherSocietyDetails({
    String? societyName,
    String? address,
  }) async {
    return await updateUserProfile(societyName: societyName, address: address);
  }

  /// Updates address for Individual Housing
  static Future<UserProfile?> updateIndividualAddress({
    required String address,
  }) async {
    return await updateUserProfile(address: address);
  }

  /// Updates Active Society details (tower, flat number)
  static Future<UserProfile?> updateActiveSocietyDetails({
    int? societyId,
    String? tower,
    String? flatNo,
  }) async {
    return await updateUserProfile(
      societyId: societyId,
      tower: tower,
      flatNo: flatNo,
    );
  }

  /// Updates contact information (email, phone)
  static Future<UserProfile?> updateContactInfo({
    String? userEmail,
    String? userPhone,
  }) async {
    return await updateUserProfile(userEmail: userEmail, userPhone: userPhone);
  }
}
