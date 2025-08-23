import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'model_batchWithActivity.dart';

class BatchService {
  static const String baseUrl = 'https://klayons-backend.vercel.app';

  static Future<String?> getAuthToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      print(
        '🔑 Token retrieved: ${token != null ? "Found (${token.length} chars)" : "Not found"}',
      );
      return token;
    } catch (e) {
      print('❌ Error getting token: $e');
      return null;
    }
  }

  static Future<List<BatchWithActivity>> getBatchesWithActivity({
    String? category,
    int? page,
    int? pageSize,
  }) async {
    try {
      // Get authentication token
      final token = await getAuthToken();
      if (token == null || token.isEmpty) {
        print('❌ No authentication token found');
        throw Exception('No authentication token found. Please login again.');
      }

      // Build URL with query parameters
      String url = '$baseUrl/api/activities/batches-with-activity/';
      List<String> queryParams = [];

      if (category != null && category.isNotEmpty) {
        queryParams.add('activity__category=$category');
      }
      if (page != null) {
        queryParams.add('page=$page');
      }
      if (pageSize != null) {
        queryParams.add('page_size=$pageSize');
      }

      if (queryParams.isNotEmpty) {
        url += '?' + queryParams.join('&');
      }

      print('🌐 Fetching batches from: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('📡 Response status: ${response.statusCode}');
      print('📄 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        print('✅ Successfully fetched ${jsonData.length} batches');
        return jsonData
            .map((json) => BatchWithActivity.fromJson(json))
            .toList();
      } else if (response.statusCode == 401) {
        print('❌ Authentication failed - token may be expired');
        throw Exception('Authentication failed. Please login again.');
      } else {
        print('❌ API error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to load batches: ${response.statusCode}');
      }
    } catch (e) {
      print('💥 Error in getBatchesWithActivity: $e');
      if (e.toString().contains('No authentication token') ||
          e.toString().contains('Authentication failed')) {
        rethrow; // Re-throw auth errors as-is
      }
      throw Exception('Error fetching batches: $e');
    }
  }

  // Method to get batches by specific category
  static Future<List<BatchWithActivity>> getBatchesByCategory(
    String category,
  ) async {
    try {
      print('📂 Fetching batches for category: $category');
      return await getBatchesWithActivity(
        category: category,
        page: 1,
        pageSize: 10,
      );
    } catch (e) {
      print('❌ Error fetching batches by category: $e');
      rethrow;
    }
  }

  // Method to get all batches with pagination
  static Future<List<BatchWithActivity>> getAllBatches({
    int page = 1,
    int pageSize = 10,
  }) async {
    try {
      print('📋 Fetching all batches - Page: $page, Size: $pageSize');
      return await getBatchesWithActivity(page: page, pageSize: pageSize);
    } catch (e) {
      print('❌ Error fetching all batches: $e');
      rethrow;
    }
  }

  // Method to refresh token if needed (optional utility method)
  static Future<bool> validateToken() async {
    try {
      final token = await getAuthToken();
      if (token == null || token.isEmpty) {
        return false;
      }

      // Test the token with a simple API call
      final response = await http.get(
        Uri.parse(
          '$baseUrl/api/activities/batches-with-activity/?page=1&page_size=1',
        ),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      print('❌ Token validation error: $e');
      return false;
    }
  }

  // Method to clear token (for logout scenarios)
  static Future<void> clearAuthToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      print('🗑️ Auth token cleared');
    } catch (e) {
      print('❌ Error clearing token: $e');
    }
  }
}
