import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class TokenStorage {
  static const String _tokenKey = 'auth_token';
  static const String _userEmailKey = 'user_email';
  static const String _userNameKey = 'user_name';

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<void> saveUserData({
    required String email,
    required String name,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userEmailKey, email);
    await prefs.setString(_userNameKey, name);
  }

  static Future<Map<String, String?>> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'email': prefs.getString(_userEmailKey),
      'name': prefs.getString(_userNameKey),
    };
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userEmailKey);
    await prefs.remove(_userNameKey);
  }

  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}

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

class AuthService {
  static const String baseUrl = 'https://dev-klayonsapi.vercel.app/api';

  // Send OTP (Signup) - with already registered check
  static Future<SignupResponse> sendOTP({
    required String name,
    String? email,
    String? phone,
    required String residenceType,
    String? societyName,
    required String address,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/auth/signup/');

      Map<String, dynamic> requestBody = {
        'name': name,
        'residence_type': residenceType,
        'address': address,
      };

      if (email != null && email.isNotEmpty) {
        requestBody['email'] = email;
      }

      if (phone != null && phone.isNotEmpty) {
        requestBody['phone'] = phone;
      }

      if (societyName != null && societyName.isNotEmpty) {
        requestBody['society_name'] = societyName;
      }

      print('🌐 Sending OTP with URL: $url');
      print('📝 Request body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      print('📡 Send OTP response status: ${response.statusCode}');
      print('📄 Send OTP response body: ${response.body}');

      final Map<String, dynamic> responseData = jsonDecode(response.body);
      return SignupResponse.fromJson(responseData, response.statusCode);
    } catch (e) {
      print('❌ Send OTP error: $e');
      throw Exception('Network error: ${e.toString()}');
    }
  }

  // Verify OTP - corrected to match API schema
  static Future<OTPVerificationResponse> verifyOTP({
    required String email,
    required String otpCode,
    required String purpose,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/auth/verify-otp/');

      Map<String, dynamic> requestBody = {
        'email': email.contains('@') ? email : null,
        'phone': !email.contains('@') ? email : null,
        'otp': otpCode,
      };

      requestBody.removeWhere((key, value) => value == null);

      print('🌐 Verifying OTP with URL: $url');
      print('📝 Request body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      print('📡 OTP verification response status: ${response.statusCode}');
      print('📄 OTP verification response body: ${response.body}');

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return OTPVerificationResponse(
          statusCode: 0,
          message: 'Verification successful',
          isSuccess: true,
          token: responseData['access'],
          userData: null,
        );
      } else {
        return OTPVerificationResponse(
          statusCode: responseData['status_code'] ?? 0,
          message: responseData['message'] ?? 'Verification failed',
          isSuccess: false,
          token: null,
          userData: null,
        );
      }
    } catch (e) {
      print('❌ OTP verification error: $e');
      throw Exception('Network error: ${e.toString()}');
    }
  }

  // Resend OTP - corrected to match API schema
  static Future<SignupResponse> resendOTP({
    required String email,
    required String purpose,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/auth/resend-otp/');

      Map<String, dynamic> requestBody = {
        'email': email.contains('@') ? email : null,
        'phone': !email.contains('@') ? email : null,
      };

      requestBody.removeWhere((key, value) => value == null);

      print('🌐 Resending OTP with URL: $url');
      print('📝 Request body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      print('📡 Resend OTP response status: ${response.statusCode}');
      print('📄 Resend OTP response body: ${response.body}');

      final Map<String, dynamic> responseData = jsonDecode(response.body);
      return SignupResponse.fromJson(responseData, response.statusCode);
    } catch (e) {
      print('❌ Resend OTP error: $e');
      throw Exception('Network error: ${e.toString()}');
    }
  }
}

// UPDATED: SignupResponse with already registered detection
class SignupResponse {
  final int statusCode;
  final String message;
  final bool isSuccess;
  final int httpStatusCode;
  final bool isAlreadyRegistered; // NEW: Check if user already registered

  SignupResponse({
    required this.statusCode,
    required this.message,
    required this.isSuccess,
    required this.httpStatusCode,
    required this.isAlreadyRegistered,
  });

  factory SignupResponse.fromJson(Map<String, dynamic> json, int httpCode) {
    String message = json['message'] ?? '';

    // Check if user is already registered
    bool isAlreadyRegistered = false;

    // Check for common "already registered" indicators
    String lowerMessage = message.toLowerCase();
    if (httpCode == 400 &&
        (lowerMessage.contains('already') ||
            lowerMessage.contains('exists') ||
            lowerMessage.contains('registered'))) {
      isAlreadyRegistered = true;
    }

    return SignupResponse(
      statusCode: json['status_code'] ?? 0,
      message: message,
      isSuccess: httpCode == 200,
      httpStatusCode: httpCode,
      isAlreadyRegistered: isAlreadyRegistered,
    );
  }
}

enum ResidenceType {
  society('society'),
  individual('individual');

  const ResidenceType(this.value);
  final String value;
}
