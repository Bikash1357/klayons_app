import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class CalendarService {
  final String baseUrl;
  static const String _tokenKey = 'auth_token'; // Replace with actual token key

  CalendarService({required this.baseUrl});

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    print('Retrieved token: ${token != null ? "Found" : "Not found"}');
    return token;
  }

  Future<http.Response> deleteCustomActivity(String activityId) async {
    final token = await getToken();
    final url = Uri.parse(
      'https://dce6c40c-1aee-4939-b9fa-cf0144c03e80-00-awz9qsmkv8d2.pike.replit.dev/api/calendar/custom-activities/$activityId/',
    );
    final headers = {if (token != null) 'Authorization': 'Bearer $token'};

    final response = await http.delete(url, headers: headers);

    return response; // 200 on success, 404 if not found
  }
}
