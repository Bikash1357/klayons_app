import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class CalendarService {
  final String baseUrl;
  static const String _tokenKey = 'auth_token'; // Replace with your actual key

  CalendarService({required this.baseUrl});

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    print('Retrieved token: ${token != null ? "Found" : "Not found"}');
    return token;
  }

  Future<http.Response> editCustomActivity(
    String activityId,
    Map<String, dynamic> activityData,
  ) async {
    final token = await getToken();
    final url = Uri.parse(
      'https://dev-klayonsapi.vercel.app/api/calendar/custom-activities/$activityId/',
    );
    final headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
    final body = jsonEncode(activityData);

    final response = await http.put(url, headers: headers, body: body);
    return response; // Status 200: updated, 400/404 are handled by caller
  }
}
