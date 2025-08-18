import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:klayons/config/api_config.dart';
import 'package:klayons/services/auth/login_auth_service.dart';

class UserProfile {
  final String name;
  final String userEmail;
  final String userPhone;
  final int societyId;
  final String flatNo;

  UserProfile({
    required this.name,
    required this.userEmail,
    required this.userPhone,
    required this.societyId,
    required this.flatNo,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      name: json['name'] ?? '',
      userEmail: json['user_email'] ?? '',
      userPhone: json['user_phone'] ?? '',
      societyId: json['society_id'] ?? 0,
      flatNo: json['flat_no'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'user_email': userEmail,
      'user_phone': userPhone,
      'society_id': societyId,
      'flat_no': flatNo,
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

  // Cache variables
  static UserProfile? _cachedProfile;
  static DateTime? _cacheTimestamp;
  static const Duration _cacheExpiration = Duration(
    minutes: 30,
  ); // Cache expires after 30 minutes
  static bool _isLoading = false;

  /// Checks if cached data is still valid
  static bool _isCacheValid() {
    if (_cachedProfile == null || _cacheTimestamp == null) {
      return false;
    }

    final now = DateTime.now();
    final cacheAge = now.difference(_cacheTimestamp!);
    return cacheAge < _cacheExpiration;
  }

  /// Clears the cache (useful for logout or when you want to force refresh)
  static void clearCache() {
    _cachedProfile = null;
    _cacheTimestamp = null;
    _isLoading = false;
    print('Profile cache cleared');
  }

  /// Fetches the authenticated user's profile (with caching)
  static Future<UserProfile?> getUserProfile({
    bool forceRefresh = false,
  }) async {
    // Return cached data if valid and not forcing refresh
    if (!forceRefresh && _isCacheValid()) {
      print('Returning cached user profile: $_cachedProfile');
      return _cachedProfile;
    }

    // If already loading, wait for the current request to complete
    if (_isLoading) {
      print('Profile loading in progress, waiting...');
      // Simple polling mechanism to wait for loading to complete
      while (_isLoading) {
        await Future.delayed(Duration(milliseconds: 100));
      }
      return _cachedProfile;
    }

    try {
      _isLoading = true;

      // Get the authentication token
      final token = await LoginAuthService.getToken();

      if (token == null) {
        print('No authentication token found');
        throw Exception('User not authenticated');
      }

      print('Fetching user profile from server...');
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

        // Parse and cache the user profile
        _cachedProfile = UserProfile.fromJson(data);
        _cacheTimestamp = DateTime.now();

        print('User profile fetched and cached successfully: $_cachedProfile');
        return _cachedProfile;
      } else if (response.statusCode == 401) {
        print('Unauthorized - token may be invalid or expired');
        // Clear cache and invalid token
        clearCache();
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
        rethrow;
      }
    } finally {
      _isLoading = false;
    }
  }

  /// Updates the user's profile and updates cache
  static Future<UserProfile?> updateUserProfile({
    String? name,
    String? userEmail,
    String? userPhone,
    int? societyId,
    String? flatNo,
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
      if (societyId != null) requestBody['society_id'] = societyId;
      if (flatNo != null) requestBody['flat_no'] = flatNo;

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

        // Parse and update cache with new profile data
        _cachedProfile = UserProfile.fromJson(data);
        _cacheTimestamp = DateTime.now();

        print('User profile updated and cached successfully: $_cachedProfile');
        return _cachedProfile;
      } else if (response.statusCode == 401) {
        print('Unauthorized - token may be invalid or expired');
        clearCache();
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

  /// Checks if user has a complete profile (uses cached data if available)
  static Future<bool> hasCompleteProfile({bool forceRefresh = false}) async {
    try {
      final profile = await getUserProfile(forceRefresh: forceRefresh);
      if (profile == null) return false;

      // Check if all required fields are filled
      return profile.name.isNotEmpty &&
          profile.userEmail.isNotEmpty &&
          profile.userPhone.isNotEmpty &&
          profile.societyId > 0;
    } catch (e) {
      print('Error checking profile completeness: $e');
      return false;
    }
  }

  /// Refreshes user profile and updates local storage (forces cache refresh)
  static Future<void> refreshAndSaveProfile() async {
    try {
      final profile = await getUserProfile(forceRefresh: true);
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

  /// Gets cached profile without making API call (returns null if no cache)
  static UserProfile? getCachedProfile() {
    if (_isCacheValid()) {
      print('Returning valid cached profile');
      return _cachedProfile;
    }
    print('No valid cached profile available');
    return null;
  }

  /// Checks if profile is currently being loaded
  static bool get isLoading => _isLoading;

  /// Gets cache age in minutes (returns -1 if no cache)
  static int getCacheAgeInMinutes() {
    if (_cacheTimestamp == null) return -1;

    final now = DateTime.now();
    final cacheAge = now.difference(_cacheTimestamp!);
    return cacheAge.inMinutes;
  }
}
