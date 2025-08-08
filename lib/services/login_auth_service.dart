import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class LoginAuthService {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';
  static const String _isLoggedInKey = 'is_logged_in';

  // Save authentication data with optional user data
  static Future<void> saveAuthData({
    required String token,
    Map<String, dynamic>? userData,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    if (userData != null) {
      await prefs.setString(_userKey, json.encode(userData));
    }
    await prefs.setBool(_isLoggedInKey, true);
    print('Auth data saved successfully - Token: ${token.substring(0, 20)}...');
  }

  // Save just the token (for OTP verification step)
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setBool(_isLoggedInKey, true);
    print('Token saved successfully: ${token.substring(0, 20)}...');
  }

  // Get stored token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    print('Retrieved token: ${token != null ? "Found" : "Not found"}');
    return token;
  }

  // Get stored user data
  static Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString(_userKey);
    if (userData != null) {
      return json.decode(userData);
    }
    return null;
  }

  // Check if user is logged in locally
  static Future<bool> isLoggedInLocally() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool(_isLoggedInKey) ?? false;
    final hasToken = prefs.getString(_tokenKey) != null;

    print(
      'Local login check - isLoggedIn flag: $isLoggedIn, hasToken: $hasToken',
    );
    return isLoggedIn && hasToken;
  }

  // Validate token format (basic JWT structure check)
  static bool _isValidTokenFormat(String token) {
    try {
      final parts = token.split('.');
      return parts.length == 3 && token.startsWith('eyJ');
    } catch (e) {
      return false;
    }
  }

  // Simple token check - verify token exists and has valid format
  static Future<bool> hasValidToken() async {
    try {
      final token = await getToken();
      final isLoggedIn = await isLoggedInLocally();

      if (token == null || token.isEmpty || !isLoggedIn) {
        print('Token check failed - missing token or not logged in');
        return false;
      }

      if (!_isValidTokenFormat(token)) {
        print('Token check failed - invalid token format');
        return false;
      }

      print('Token check passed - valid token found');
      return true;
    } catch (e) {
      print('Token check error: $e');
      return false;
    }
  }

  // Check authentication status
  static Future<bool> isAuthenticated() async {
    try {
      print('🔍 Starting authentication check...');

      final hasToken = await hasValidToken();

      if (hasToken) {
        print('✅ Authentication successful');
      } else {
        print('❌ No token found, navigating to login');
      }

      return hasToken;
    } catch (e) {
      print('❌ Authentication check error: $e');
      return false;
    }
  }

  // Verify OTP and save token
  static Future<Map<String, dynamic>?> verifyOTP({
    required String email,
    required String otp,
  }) async {
    try {
      print('Verifying OTP for email: $email');

      final response = await http.post(
        Uri.parse(ApiConfig.getFullUrl('/api/auth/verify-otp/')),
        headers: {
          'Content-Type': 'application/json',
          'accept': 'application/json',
        },
        body: json.encode({'email': email, 'otp': otp}),
      );

      print('OTP verification response status: ${response.statusCode}');
      print('OTP verification response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        // Extract the access token
        if (responseData.containsKey('access')) {
          final accessToken = responseData['access'] as String;

          // Save the token
          await saveToken(accessToken);

          print('✅ OTP verified and token saved successfully');
          return responseData;
        } else {
          print('❌ No access token in response');
          return null;
        }
      } else {
        print('❌ OTP verification failed: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ OTP verification error: $e');
      return null;
    }
  }

  // Clear authentication data (logout)
  static Future<void> clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
    await prefs.setBool(_isLoggedInKey, false);
    print('🗑️ Auth data cleared');
  }

  // Logout from backend and clear local data
  static Future<bool> logout() async {
    try {
      final token = await getToken();
      if (token != null) {
        try {
          final response = await http
              .post(
                Uri.parse(ApiConfig.getFullUrl('/api/auth/logout/')),
                headers: {
                  'Content-Type': 'application/json',
                  'Authorization': 'Bearer $token',
                },
              )
              .timeout(const Duration(seconds: 5));

          print('Logout response: ${response.statusCode}');
        } catch (e) {
          print('Backend logout error (ignored): $e');
        }
      }
    } catch (e) {
      print('Logout error: $e');
    } finally {
      await clearAuthData();
    }
    return true;
  }

  // Get user profile (fetch user data using stored token)
  static Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final token = await getToken();
      if (token == null) {
        print('No token available for profile fetch');
        return null;
      }

      final response = await http.get(
        Uri.parse(
          ApiConfig.getFullUrl('/api/auth/user-profile/'),
        ), // Adjust endpoint as needed
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final userData = json.decode(response.body);
        await saveAuthData(token: token, userData: userData);
        return userData;
      } else {
        print('Failed to fetch user profile: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error fetching user profile: $e');
      return null;
    }
  }
}
