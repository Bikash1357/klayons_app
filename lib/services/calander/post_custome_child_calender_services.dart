import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../screens/user_calender/event_model.dart';

class CustomActivityException implements Exception {
  final String message;
  final int? statusCode;

  CustomActivityException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class CustomActivityService {
  static const String _baseUrl =
      'https://dev-klayonsapi.vercel.app/api/calendar/custom-activities/';
  static const String _tokenKey = 'auth_token';

  static Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);
      print(
        'Retrieved token: ${token != null ? "Found (${token.length} chars)" : "Not found"}',
      );
      return token;
    } catch (e) {
      print('Error getting token: $e');
      return null;
    }
  }

  static String recurrenceTypeToString(RecurrenceType type) =>
      type.toString().split('.').last;

  static String recurrenceEndToString(RecurrenceEnd end) =>
      end.toString().split('.').last;

  static Future<Event> createCustomActivity(
    Event event, {
    required String accessToken,
  }) async {
    final token = await getToken();

    if (token == null || token.isEmpty) {
      throw CustomActivityException(
        'Authentication token missing. Please login.',
      );
    }

    Map<String, dynamic> requestBody = {
      "title": event.title,
      "address": event.address,
      "startTime": event.startTime.toIso8601String(),
      "endTime": event.endTime.toIso8601String(),
      "childName": event.childName ?? '',
      "color": event.color.value,
    };

    if (event.recurrence != null) {
      final recurrence = {
        "type": recurrenceTypeToString(event.recurrence!.type),
        "interval": event.recurrence!.interval,
        "daysOfWeek": event.recurrence!.daysOfWeek,
        "endRule": recurrenceEndToString(event.recurrence!.endRule),
        if (event.recurrence!.endDate != null)
          "endDate": event.recurrence!.endDate!.toIso8601String(),
        if (event.recurrence!.occurrences != null)
          "occurrences": event.recurrence!.occurrences,
      };
      requestBody['recurrence'] = recurrence;
    }

    print('Creating custom activity...');
    print('Endpoint: $_baseUrl');
    print('Token length: ${token.length}');
    print('Request body: ${jsonEncode(requestBody)}');

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      switch (response.statusCode) {
        case 201:
          try {
            final Map<String, dynamic> jsonResponse = json.decode(
              response.body,
            );
            final eventData = jsonResponse['data'];

            if (eventData == null || eventData is! Map<String, dynamic>) {
              throw CustomActivityException('Invalid event data in response.');
            }

            return Event.fromJson(eventData);
          } catch (e) {
            print('JSON decode error: $e');
            print('Raw response: ${response.body}');
            throw CustomActivityException('Invalid response from server');
          }

        case 400:
          final Map<String, dynamic> errorData = json.decode(response.body);
          final errorMessage = _extractErrorMessage(errorData);
          throw CustomActivityException(errorMessage, statusCode: 400);

        case 401:
          throw CustomActivityException(
            'Authentication failed. Please login again.',
            statusCode: 401,
          );

        case 500:
          throw CustomActivityException(
            'Server error occurred. Please try again later.',
            statusCode: 500,
          );

        default:
          String unknownError =
              'Unexpected error occurred (${response.statusCode})';
          try {
            final Map<String, dynamic> errorData = json.decode(response.body);
            unknownError = _extractErrorMessage(errorData);
          } catch (_) {}
          throw CustomActivityException(
            unknownError,
            statusCode: response.statusCode,
          );
      }
    } catch (e) {
      print('Exception in createCustomActivity: $e');
      rethrow;
    }
  }

  static String _extractErrorMessage(Map<String, dynamic> errorData) {
    try {
      if (errorData.containsKey('error')) {
        final error = errorData['error'];
        if (error is Map<String, dynamic>) {
          List<String> messages = [];
          error.forEach((field, value) {
            if (value is List) {
              messages.addAll(value.map((m) => '$field: $m'));
            } else {
              messages.add('$field: $value');
            }
          });
          return messages.join(', ');
        } else if (error is String) {
          return error;
        }
      }
      if (errorData.containsKey('detail')) {
        final detail = errorData['detail'];
        return detail != null ? detail.toString() : 'Unknown error occurred';
      }
      if (errorData.containsKey('message')) {
        final message = errorData['message'];
        return message != null ? message.toString() : 'Unknown error occurred';
      }
      return errorData.toString();
    } catch (e) {
      print('Error parsing error message: $e');
      return 'Unknown error occurred';
    }
  }
}
