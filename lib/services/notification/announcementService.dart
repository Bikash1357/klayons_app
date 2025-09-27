import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:klayons/services/auth/login_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'modelAnnouncement.dart';

class AnnouncementService {
  static const String baseUrl =
      'https://dce6c40c-1aee-4939-b9fa-cf0144c03e80-00-awz9qsmkv8d2.pike.replit.dev';
  static const String announcementsEndpoint = '/api/announcements/';

  // Get stored auth token
  Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  // Get announcements with optional filters
  Future<List<Announcement>> getAnnouncements({
    int? activityId,
    String? scope,
    String? search,
    int? societyId,
  }) async {
    try {
      // Build query parameters
      Map<String, String> queryParams = {};

      if (activityId != null) {
        queryParams['activity'] = activityId.toString();
      }
      if (scope != null) {
        queryParams['scope'] = scope.toUpperCase();
      }
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (societyId != null) {
        queryParams['society'] = societyId.toString();
      }

      // Build URL with query parameters
      Uri url = Uri.parse('$baseUrl$announcementsEndpoint');
      if (queryParams.isNotEmpty) {
        url = url.replace(queryParameters: queryParams);
      }

      // Use your existing auth service method
      String? token =
          await LoginAuthService.getToken(); // Replace YourAuthService with actual class name

      if (token == null) {
        print('AnnouncementService: No authentication token found');
        throw Exception('Authentication token not found. Please login again.');
      }

      // Prepare headers
      Map<String, String> headers = {
        'Content-Type': 'application/json',
        'accept': 'application/json',
        'Authorization': 'Bearer $token',
      };

      print('AnnouncementService: GET $url');
      print('AnnouncementService: Using token: ${token.substring(0, 20)}...');

      // Make HTTP request
      final response = await http.get(url, headers: headers);

      print('AnnouncementService: Response status: ${response.statusCode}');
      print('AnnouncementService: Response body: ${response.body}');

      if (response.statusCode == 200) {
        List<dynamic> jsonData = json.decode(response.body);
        print('AnnouncementService: Parsed ${jsonData.length} announcements');
        return jsonData.map((json) => Announcement.fromJson(json)).toList();
      } else if (response.statusCode == 401) {
        print('AnnouncementService: Unauthorized - token may be expired');
        throw Exception('Authentication failed. Please login again.');
      } else {
        print(
          'AnnouncementService: HTTP Error ${response.statusCode}: ${response.body}',
        );
        throw Exception(
          'Failed to fetch announcements: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('AnnouncementService Error: $e');
      rethrow;
    }
  }

  // Get announcements by scope
  Future<List<Announcement>> getAnnouncementsByScope(String scope) async {
    return await getAnnouncements(scope: scope);
  }

  // Get announcements for specific activity
  Future<List<Announcement>> getActivityAnnouncements(int activityId) async {
    return await getAnnouncements(activityId: activityId, scope: 'ACTIVITY');
  }

  // Get society announcements
  Future<List<Announcement>> getSocietyAnnouncements(int societyId) async {
    return await getAnnouncements(societyId: societyId, scope: 'SOCIETY');
  }

  // Get general announcements
  Future<List<Announcement>> getGeneralAnnouncements() async {
    return await getAnnouncements(scope: 'GENERAL');
  }

  // Search announcements
  Future<List<Announcement>> searchAnnouncements(String searchTerm) async {
    return await getAnnouncements(search: searchTerm);
  }
}
