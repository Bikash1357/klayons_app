// lib/config/api_config.dart
class ApiConfig {
  // Base URL for the API
  static const String baseUrl =
      'https://1f0f3792-ea29-4f20-8d98-5e8548cc11ac-00-1tccerdmhnsfy.pike.replit.dev';

  // API endpoints
  static const String _apiPrefix = '/api';
  static const String _authPrefix = '$_apiPrefix/auth';

  // Auth endpoints
  static const String loginEndpoint = '$_authPrefix/login/';
  static const String registerEndpoint = '$_authPrefix/register/';
  static const String verifyOtpEndpoint = '$_authPrefix/verify-otp/';
  static const String forgotPasswordEndpoint = '$_authPrefix/forgot-password/';
  static const String resetPasswordEndpoint = '$_authPrefix/reset-password/';
  static const String verifyTokenEndpoint = '$_authPrefix/verify-token/';
  static const String logoutEndpoint = '$_authPrefix/logout/';
  static const String addChildrenEndpoint = '$_apiPrefix/user/children/';

  // Helper method to get full URL
  static String getFullUrl(String endpoint) {
    return '$baseUrl$endpoint';
  }

  // Helper method to get auth headers
  static Map<String, String> getHeaders({String? token}) {
    Map<String, String> headers = {'Content-Type': 'application/json'};
    if (token != null) {
      headers['Authorization'] = 'Token $token';
    }
    return headers;
  }

  // Connection timeout settings
  static const int connectionTimeout = 30; // seconds
  static const int receiveTimeout = 30; // seconds
}
