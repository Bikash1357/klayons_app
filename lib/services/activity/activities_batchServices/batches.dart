import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'batch_model.dart';

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

  static Future<List<Batch>> getBatchesByActivityId(int activityId) async {
    try {
      print('🚀 Starting getBatchesByActivityId for activity: $activityId');

      // Check token
      final token = await getAuthToken();
      if (token == null || token.isEmpty) {
        print('❌ No authentication token found');
        throw Exception('No authentication token found. Please login again.');
      }

      // Build URL
      final url = Uri.parse('$baseUrl/api/activities/$activityId/batches/');
      print('🌐 Making request to: $url');

      // Make request
      final response = await http
          .get(
            url,
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 10)); // Add timeout

      print('📡 Response status: ${response.statusCode}');
      print('📄 Response body: ${response.body}');
      print('📋 Response headers: ${response.headers}');

      if (response.statusCode == 200) {
        try {
          final List<dynamic> data = json.decode(response.body);
          print('✅ Successfully parsed ${data.length} batches');

          List<Batch> batches = [];
          for (int i = 0; i < data.length; i++) {
            try {
              final batch = Batch.fromJson(data[i]);
              batches.add(batch);
              print('✅ Parsed batch ${i + 1}: ${batch.name} (ID: ${batch.id})');
            } catch (e) {
              print('❌ Error parsing batch ${i + 1}: $e');
              print('📄 Batch data: ${data[i]}');
            }
          }

          return batches;
        } catch (e) {
          print('❌ JSON parsing error: $e');
          print('📄 Raw response: ${response.body}');
          throw Exception('Failed to parse response data');
        }
      } else if (response.statusCode == 401) {
        print('❌ Unauthorized access - token may be expired');
        throw Exception('Session expired. Please login again.');
      } else if (response.statusCode == 404) {
        print('❌ Activity not found or no batches available');
        throw Exception('No batches found for this activity');
      } else if (response.statusCode == 403) {
        print('❌ Forbidden access');
        throw Exception(
          'Access denied. You may not have permission to view batches.',
        );
      } else {
        print('❌ HTTP Error: ${response.statusCode}');
        print('📄 Error body: ${response.body}');
        throw Exception(
          'Server error (${response.statusCode}): ${response.body}',
        );
      }
    } catch (e) {
      print('❌ Exception in getBatchesByActivityId: $e');
      if (e.toString().contains('TimeoutException')) {
        throw Exception(
          'Request timeout. Please check your internet connection.',
        );
      } else if (e.toString().contains('SocketException')) {
        throw Exception(
          'Network error. Please check your internet connection.',
        );
      } else {
        rethrow; // Re-throw the original exception
      }
    }
  }
}
