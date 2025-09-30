import 'dart:convert';
import 'dart:ui';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../screens/user_calender/event_model.dart';

class CustomActivityException implements Exception {
  final String message;
  final int? statusCode;

  CustomActivityException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class CustomActivityService {
  static const String _baseUrl =
      'https://klayons-backend.onrender.com/api/calendar/custom-activities';
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

  // Helper method to convert Flutter Color to hex string
  static String colorToHex(Color color) {
    // Convert color to hex format without alpha channel (#RRGGBB)
    return '#${color.value.toRadixString(16).substring(2).padLeft(6, '0')}';
  }

  // Helper method to convert hex string back to Flutter Color
  static Color hexToColor(String hexString) {
    // Remove # if present and convert to Color
    String hex = hexString.replaceFirst('#', '');
    if (hex.length == 6) {
      hex = 'FF$hex'; // Add full opacity
    }
    return Color(int.parse(hex, radix: 16));
  }

  static Future<Event> createCustomActivity(Event event) async {
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
      "color": colorToHex(event.color),
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
    print('Endpoint: $_baseUrl/');
    print('Token length: ${token.length}');
    print('Request body: ${jsonEncode(requestBody)}');

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      return _handleResponse(response, event);
    } catch (e) {
      print('Exception in createCustomActivity: $e');
      rethrow;
    }
  }

  // New method: Update Custom Activity
  static Future<Event> updateCustomActivity(String id, Event event) async {
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
      "color": colorToHex(event.color),
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

    print('Updating custom activity...');
    print('Endpoint: $_baseUrl/$id/');
    print('Token length: ${token.length}');
    print('Request body: ${jsonEncode(requestBody)}');

    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/$id/'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      print('Update response status: ${response.statusCode}');
      print('Update response body: ${response.body}');

      return _handleResponse(response, event);
    } catch (e) {
      print('Exception in updateCustomActivity: $e');
      rethrow;
    }
  }

  // New method: Delete Custom Activity
  static Future<bool> deleteCustomActivity(String id) async {
    final token = await getToken();

    if (token == null || token.isEmpty) {
      throw CustomActivityException(
        'Authentication token missing. Please login.',
      );
    }

    print('Deleting custom activity...');
    print('Endpoint: $_baseUrl/$id/');
    print('Token length: ${token.length}');

    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/$id/'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Delete response status: ${response.statusCode}');
      print('Delete response body: ${response.body}');

      switch (response.statusCode) {
        case 200:
          print('Custom activity deleted successfully');
          return true;

        case 404:
          throw CustomActivityException(
            'Custom activity not found.',
            statusCode: 404,
          );

        case 401:
          throw CustomActivityException(
            'Authentication failed. Please login again.',
            statusCode: 401,
          );

        default:
          String unknownError =
              'Failed to delete activity (${response.statusCode})';
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
      print('Exception in deleteCustomActivity: $e');
      rethrow;
    }
  }

  // Helper method to handle API responses
  static Event _handleResponse(http.Response response, Event originalEvent) {
    switch (response.statusCode) {
      case 200:
      case 201:
        try {
          final Map<String, dynamic> jsonResponse = json.decode(response.body);

          // Handle different response structures
          Map<String, dynamic> eventData;
          if (jsonResponse.containsKey('data')) {
            eventData = jsonResponse['data'];
          } else {
            eventData = jsonResponse;
          }

          if (eventData.isEmpty) {
            throw CustomActivityException('Invalid event data in response.');
          }

          return Event.fromJson(eventData);
        } catch (e) {
          print('JSON decode error: $e');
          print('Raw response: ${response.body}');
          throw CustomActivityException(
            'Failed to parse server response: ${e.toString()}',
          );
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

      case 404:
        throw CustomActivityException(
          'Custom activity not found.',
          statusCode: 404,
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
      if (errorData.containsKey('details') && errorData['details'] is Map) {
        final details = errorData['details'] as Map<String, dynamic>;
        List<String> messages = [];
        details.forEach((field, value) {
          if (value is List) {
            messages.addAll(value.map((m) => '$field: $m'));
          } else {
            messages.add('$field: $value');
          }
        });
        return messages.join(', ');
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
