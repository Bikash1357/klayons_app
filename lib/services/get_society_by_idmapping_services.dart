import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

// Society model class to hold all society details
class Society {
  final int id;
  final String name;
  final String address;

  Society({required this.id, required this.name, required this.address});

  factory Society.fromJson(Map<String, dynamic> json) {
    return Society(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      address: json['address'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'address': address};
  }

  @override
  String toString() {
    return 'Society{id: $id, name: $name, address: $address}';
  }
}

class SocietyService {
  static const String _baseUrl = 'https://klayons-backend.onrender.com';
  static const String _societiesEndpoint = '/api/societies/';

  /// Fetches all societies from the backend
  static Future<List<Society>> getAllSocieties() async {
    try {
      print('Fetching all societies...');
      print('API URL: ${ApiConfig.getSocieties}');

      final response = await http
          .get(
            Uri.parse('$_baseUrl$_societiesEndpoint'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception(
                'Request timeout. Please check your internet connection.',
              );
            },
          );

      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final societies = data
            .map((societyJson) => Society.fromJson(societyJson))
            .toList();

        print('Fetched ${societies.length} societies successfully');
        return societies;
      } else if (response.statusCode >= 500) {
        print('Server error: ${response.statusCode}');
        throw Exception('Server error. Please try again later.');
      } else {
        final data = json.decode(response.body);
        final errorMessage = data['message'] ?? 'Failed to fetch societies';
        print('Error: $errorMessage');
        throw Exception(errorMessage);
      }
    } on FormatException catch (e) {
      print('JSON parsing error: $e');
      throw Exception('Invalid response from server');
    } on http.ClientException catch (e) {
      print('HTTP Client error: $e');
      throw Exception('Network error. Please check your internet connection.');
    } catch (e) {
      print('Get societies error: $e');
      if (e.toString().contains('timeout')) {
        throw Exception(
          'Request timeout. Please check your internet connection.',
        );
      } else if (e.toString().contains('SocketException')) {
        throw Exception('No internet connection. Please check your network.');
      } else {
        rethrow; // Re-throw the original exception
      }
    }
  }

  /// Fetches a specific society by ID
  static Future<Society?> getSocietyById(int societyId) async {
    try {
      print('Fetching society with ID: $societyId');
      final url = '$_baseUrl$_societiesEndpoint$societyId/';
      print('API URL: $url');

      final response = await http
          .get(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception(
                'Request timeout. Please check your internet connection.',
              );
            },
          );

      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final society = Society.fromJson(data);

        print('Fetched society successfully: $society');
        return society;
      } else if (response.statusCode == 404) {
        print('Society not found with ID: $societyId');
        return null; // Society not found
      } else if (response.statusCode >= 500) {
        print('Server error: ${response.statusCode}');
        throw Exception('Server error. Please try again later.');
      } else {
        final data = json.decode(response.body);
        final errorMessage = data['message'] ?? 'Failed to fetch society';
        print('Error: $errorMessage');
        throw Exception(errorMessage);
      }
    } on FormatException catch (e) {
      print('JSON parsing error: $e');
      throw Exception('Invalid response from server');
    } on http.ClientException catch (e) {
      print('HTTP Client error: $e');
      throw Exception('Network error. Please check your internet connection.');
    } catch (e) {
      print('Get society by ID error: $e');
      if (e.toString().contains('timeout')) {
        throw Exception(
          'Request timeout. Please check your internet connection.',
        );
      } else if (e.toString().contains('SocketException')) {
        throw Exception('No internet connection. Please check your network.');
      } else {
        rethrow; // Re-throw the original exception
      }
    }
  }

  /// Helper method to find society name by ID from a list
  static String getSocietyNameById(List<Society> societies, int societyId) {
    try {
      final society = societies.firstWhere((s) => s.id == societyId);
      return society.name;
    } catch (e) {
      return 'Unknown Society';
    }
  }

  /// Helper method to find society ID by name from a list
  static int? getSocietyIdByName(List<Society> societies, String societyName) {
    try {
      final society = societies.firstWhere((s) => s.name == societyName);
      return society.id;
    } catch (e) {
      return null;
    }
  }
}
