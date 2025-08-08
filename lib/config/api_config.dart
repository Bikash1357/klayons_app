// lib/config/api_config.dart
class ApiConfig {
  // Base URL for the API
  static const String baseUrl = 'https://klayons-backend.vercel.app';

  // API endpoints
  static const String _apiPrefix = '/api';
  static const String _authPrefix = '$_apiPrefix/auth';

  // Auth endpoints
  static const String loginEndpoint = '$_authPrefix/signin/';
  static const String registerEndpoint = '$_authPrefix/signup/';
  static const String verifyOtpEndpoint = '$_authPrefix/verify-otp/';
  static const String resendOtpEndpoint = '$_authPrefix/resend-otp/';
  static const String logoutEndpoint = '$_authPrefix/logout/';
  static const String addChildrenEndpoint = '$_apiPrefix/profiles/children/';

  // Helper method to get full URL
  static String getFullUrl(String endpoint) {
    return '$baseUrl$endpoint';
  }

  // Helper method to get auth headers
  static Map<String, String> getHeaders({String? token}) {
    Map<String, String> headers = {'Content-Type': 'application/json'};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // Connection timeout settings
  static const int connectionTimeout = 30; // seconds
  static const int receiveTimeout = 30; // seconds
}
