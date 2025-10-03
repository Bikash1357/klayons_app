import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../notification/fcmService.dart'; // Import FCM service

class LoginAuthService {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';
  static const String _isLoggedInKey = 'is_logged_in';
  static const String baseUrl = 'https://dev-klayons.onrender.com/api';

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
      print('Starting authentication check...');

      final token = await getToken();

      if (token == null || token.isEmpty) {
        print('No token found, navigating to login');
        return false;
      }

      if (!_isValidTokenFormat(token)) {
        print('Invalid token format');
        return false;
      }

      // If token exists and is valid, sync the logged-in flag
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_isLoggedInKey, true);

      print('Authentication successful');
      return true;
    } catch (e) {
      print('Authentication check error: $e');
      return false;
    }
  }

  // NEW: Send OTP for Login (Signin) - Updated to match new API schema
  static Future<SigninResponse> sendLoginOTP({
    required String emailOrPhone,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/auth/signin/');

      // Match API schema: {"email": "...", "phone": "..."}
      Map<String, dynamic> requestBody = {
        'email': emailOrPhone.contains('@') ? emailOrPhone : null,
        'phone': !emailOrPhone.contains('@') ? emailOrPhone : null,
      };

      // Remove null values
      requestBody.removeWhere((key, value) => value == null);

      print('Sending login OTP with URL: $url');
      print('Request body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      print('Send login OTP response status: ${response.statusCode}');
      print('Send login OTP response body: ${response.body}');

      final Map<String, dynamic> responseData = jsonDecode(response.body);
      return SigninResponse.fromJson(responseData, response.statusCode);
    } catch (e) {
      print('Send login OTP error: $e');
      throw Exception('Network error: ${e.toString()}');
    }
  }

  // UPDATED: Verify OTP for Login - With automatic FCM token registration
  static Future<OTPVerificationResponse> verifyLoginOTP({
    required String emailOrPhone,
    required String otp,
  }) async {
    try {
      print('Verifying login OTP for: $emailOrPhone');

      final url = Uri.parse('$baseUrl/auth/verify-otp/');

      // Match API schema: {"email": "...", "phone": "...", "otp": "..."}
      Map<String, dynamic> requestBody = {
        'email': emailOrPhone.contains('@') ? emailOrPhone : null,
        'phone': !emailOrPhone.contains('@') ? emailOrPhone : null,
        'otp': otp,
      };

      // Remove null values
      requestBody.removeWhere((key, value) => value == null);

      print('Verifying login OTP with URL: $url');
      print('Request body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      print('Login OTP verification response status: ${response.statusCode}');
      print('Login OTP verification response body: ${response.body}');

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Success response: {"access": "token"}
        final accessToken = responseData['access'];
        if (accessToken != null) {
          await saveToken(accessToken);
          print('Login OTP verified and token saved successfully');

          // NEW: Register FCM token after successful login
          print('🚀 Attempting to register FCM token after login...');
          try {
            bool fcmSuccess = await FCMService.getFCMTokenAndSendToBackend();
            if (fcmSuccess) {
              print('✅ FCM token registered successfully after login');
            } else {
              print('⚠️ FCM token registration failed (non-blocking)');
            }
          } catch (fcmError) {
            print('⚠️ FCM registration error (non-blocking): $fcmError');
          }
        }

        return OTPVerificationResponse(
          statusCode: 0,
          message: 'Login successful',
          isSuccess: true,
          token: accessToken,
          userData: null,
        );
      } else {
        // Error response: {"status_code": 0, "message": "error"}
        return OTPVerificationResponse(
          statusCode: responseData['status_code'] ?? 0,
          message: responseData['message'] ?? 'Login failed',
          isSuccess: false,
          token: null,
          userData: null,
        );
      }
    } catch (e) {
      print('Login OTP verification error: $e');
      throw Exception('Network error: ${e.toString()}');
    }
  }

  // DEPRECATED: Old verifyOTP method - use verifyLoginOTP instead
  @deprecated
  static Future<Map<String, dynamic>?> verifyOTP({
    required String email,
    required String otp,
  }) async {
    try {
      print('Using deprecated verifyOTP method. Use verifyLoginOTP instead.');

      final result = await verifyLoginOTP(emailOrPhone: email, otp: otp);

      if (result.isSuccess) {
        return {
          'access': result.token,
          'success': true,
          'message': result.message,
        };
      } else {
        return {'success': false, 'message': result.message};
      }
    } catch (e) {
      print('Deprecated verifyOTP error: $e');
      return null;
    }
  }

  // Clear authentication data (logout)
  static Future<void> clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
    await prefs.setBool(_isLoggedInKey, false);

    // Also clear FCM token from local storage
    await prefs.remove('fcm_token');

    print('Auth data cleared');
  }

  // UPDATED: Logout from backend with FCM token cleanup
  static Future<bool> logout() async {
    try {
      final token = await getToken();

      if (token != null) {
        // Step 1: Delete FCM token from backend
        try {
          final fcmToken = await FCMService.getLocalFCMToken();

          if (fcmToken != null && fcmToken.isNotEmpty) {
            print('Deleting FCM token from backend...');

            final fcmResponse = await http
                .post(
                  Uri.parse('$baseUrl/notifications/devices/unregister/'),
                  headers: {
                    'Content-Type': 'application/json',
                    'Authorization': 'Bearer $token',
                  },
                  body: jsonEncode({'fcm_token': fcmToken}),
                )
                .timeout(const Duration(seconds: 5));

            print('FCM token deletion response: ${fcmResponse.statusCode}');

            if (fcmResponse.statusCode == 200) {
              print('FCM token deleted from backend successfully');
            }
          }
        } catch (e) {
          print('FCM token deletion error (ignored): $e');
        }

        // Step 2: Call backend logout endpoint
        try {
          final response = await http
              .post(
                Uri.parse('$baseUrl/auth/logout/'),
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

      // Step 3: Delete FCM token from Firebase
      try {
        await FCMService.deleteFCMToken();
        print('FCM token deleted from Firebase');
      } catch (e) {
        print('Firebase FCM token deletion error (ignored): $e');
      }
    } catch (e) {
      print('Logout error: $e');
    } finally {
      // Step 4: Always clear local auth data
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
        Uri.parse('$baseUrl/auth/user-profile/'),
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

// Response model for signin API
class SigninResponse {
  final int statusCode;
  final String message;
  final bool isSuccess;
  final int httpStatusCode;

  SigninResponse({
    required this.statusCode,
    required this.message,
    required this.isSuccess,
    required this.httpStatusCode,
  });

  factory SigninResponse.fromJson(Map<String, dynamic> json, int httpCode) {
    return SigninResponse(
      statusCode: json['status_code'] ?? 0,
      message: json['message'] ?? '',
      isSuccess: httpCode == 200,
      httpStatusCode: httpCode,
    );
  }
}

// Response model for OTP verification
class OTPVerificationResponse {
  final int statusCode;
  final String message;
  final bool isSuccess;
  final String? token;
  final Map<String, dynamic>? userData;

  OTPVerificationResponse({
    required this.statusCode,
    required this.message,
    required this.isSuccess,
    this.token,
    this.userData,
  });

  factory OTPVerificationResponse.fromJson(
    Map<String, dynamic> json,
    int httpCode,
  ) {
    return OTPVerificationResponse(
      statusCode: json['status_code'] ?? 0,
      message: json['message'] ?? '',
      isSuccess: httpCode == 200,
      token: json['access'],
      userData: json['user_data'],
    );
  }
}
