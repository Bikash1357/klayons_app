// lib/config/api_config.dart
class ApiConfig {
  // Base URL for the API
  static const String baseUrl = 'https://dev-klayons.onrender.com';

  // API endpoints
  static const String _apiPrefix = '/api';
  static const String _authPrefix = '$_apiPrefix/auth';

  // Auth endpoints
  static const String loginEndpoint = '$_authPrefix/signin/';
  static const String registerEndpoint = '$_authPrefix/signup/';
  static const String verifyOtpEndpoint = '$_authPrefix/verify-otp/';
  static const String resendOtpEndpoint = '$_authPrefix/resend-otp/';
  static const String logoutEndpoint = '$_authPrefix/logout/';

  //profiles and children
  static const String addChildrenEndpoint = '$_apiPrefix/profiles/children/';
  static const String childInterestEndpoint = '$_apiPrefix/profiles/interests/';
  static const String parentProfileEndpoint = '$_apiPrefix/profiles/';

  static const String announcementEndpoint = '$_apiPrefix/announcements/';

  //calendar
  static const String getActivityChildrenCalendar =
      '$_apiPrefix/calendar/children/';
  static const String getSocietyActivityCalendar =
      '$_apiPrefix/calendar/society-activities/';

  //customCalendar
  static const String postChildrenCustomActivityCalendar =
      '$_apiPrefix/calendar/custom-activities/';

  //enrollment
  static const String getEnrollment = '$_apiPrefix/enrollment/';
  static const String postEnrollment = '$_apiPrefix/enrollment/enroll/';

  static const String activitiesEndpoint = '$_apiPrefix/activities/';
  static const String getSocieties = '$_apiPrefix/societies/';

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
