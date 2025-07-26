import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class LoginAuthService {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';
  static const String _isLoggedInKey = 'is_logged_in';

  // Save authentication data
  static Future<void> saveAuthData({
    required String token,
    required Map<String, dynamic> userData,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userKey, json.encode(userData));
    await prefs.setBool(_isLoggedInKey, true);
    print('Auth data saved successfully');
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

  // Simple token check - just verify token exists in SharedPreferences
  static Future<bool> hasValidToken() async {
    try {
      final token = await getToken();
      final isLoggedIn = await isLoggedInLocally();

      print(
        'Token check - hasToken: ${token != null}, isLoggedIn: $isLoggedIn',
      );

      return token != null && token.isNotEmpty && isLoggedIn;
    } catch (e) {
      print('Token check error: $e');
      return false;
    }
  }

  // Check authentication status using only SharedPreferences
  static Future<bool> isAuthenticated() async {
    try {
      print('Checking authentication using SharedPreferences only...');

      // Simply check if valid token exists in SharedPreferences
      final hasToken = await hasValidToken();

      print('Authentication result: $hasToken');
      return hasToken;
    } catch (e) {
      print('Authentication check error: $e');
      return false;
    }
  }

  // Clear authentication data (logout)
  static Future<void> clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
    await prefs.setBool(_isLoggedInKey, false);
    print('Auth data cleared');
  }

  // Logout from backend and clear local data
  static Future<bool> logout() async {
    try {
      final token = await getToken();
      if (token != null) {
        // Try to call logout endpoint on backend
        try {
          await http
              .post(
                Uri.parse(ApiConfig.getFullUrl('/api/auth/logout/')),
                headers: {
                  'Content-Type': 'application/json',
                  'Authorization': 'Token $token',
                },
              )
              .timeout(const Duration(seconds: 5));
        } catch (e) {
          print('Backend logout error (ignored): $e');
        }
      }
    } catch (e) {
      print('Logout error: $e');
    } finally {
      // Always clear local data
      await clearAuthData();
    }
    return true;
  }
}
