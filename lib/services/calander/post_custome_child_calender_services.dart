import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class CalendarService {
  final String baseUrl;

  CalendarService({required this.baseUrl});

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    print('Retrieved token: ${token != null ? "Found" : "Not found"}');
    return token;
  }

  Future<http.Response> createCustomActivity(
    Map<String, dynamic> activityData,
  ) async {
    final token = await getToken(); // Get token from storage
    final url = Uri.parse(
      'https://dev-klayonsapi.vercel.app/api/calendar/custom-activities/',
    );
    final headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    final body = jsonEncode(activityData);

    final response = await http.post(url, headers: headers, body: body);
    return response;
  }
}
