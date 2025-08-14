import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

// Data models
class Interest {
  final int id;
  final String name;
  Interest({required this.id, required this.name});
  factory Interest.fromJson(Map<String, dynamic> json) =>
      Interest(id: json['id'], name: json['name']);
}

class Child {
  final int id;
  final String name;
  final String gender;
  final String dob;
  final List<Interest> interests;

  Child({
    required this.id,
    required this.name,
    required this.gender,
    required this.dob,
    required this.interests,
  });

  factory Child.fromJson(Map<String, dynamic> json) {
    var interestsList = json['interests'] as List;
    List<Interest> interests = interestsList
        .map((interest) => Interest.fromJson(interest))
        .toList();
    return Child(
      id: json['id'],
      name: json['name'],
      gender: json['gender'],
      dob: json['dob'],
      interests: interests,
    );
  }
}

class EditChildRequest {
  final String name;
  final String gender;
  final String dob;
  final List<int> interestIds;

  EditChildRequest({
    required this.name,
    required this.gender,
    required this.dob,
    required this.interestIds,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'gender': gender,
      'dob': dob,
      'interest_ids': interestIds,
    };
  }
}

// API Service
class GetChildservices {
  static const String baseUrl = 'https://klayons-backend.vercel.app/api';
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

  // Fetch all children
  static Future<List<Child>> fetchChildren() async {
    final token = await getToken();

    if (token == null || token.isEmpty) {
      throw Exception('No authentication token found. Please login first.');
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/profiles/children/'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('API Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        List<dynamic> jsonData = json.decode(response.body);
        return jsonData.map((child) => Child.fromJson(child)).toList();
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed. Please login again.');
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('Network error: $e');
      throw Exception('Failed to load data. Check your connection.');
    }
  }

  // Edit/Update a child
  static Future<Child> editChild(int childId, EditChildRequest request) async {
    final token = await getToken();

    if (token == null || token.isEmpty) {
      throw Exception('No authentication token found. Please login first.');
    }

    try {
      final response = await http.put(
        Uri.parse('$baseUrl/profiles/children/$childId/'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(request.toJson()),
      );

      print('Edit Child API Response Status: ${response.statusCode}');
      print('Edit Child API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        Map<String, dynamic> jsonData = json.decode(response.body);
        return Child.fromJson(jsonData);
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed. Please login again.');
      } else if (response.statusCode == 404) {
        throw Exception('Child not found.');
      } else if (response.statusCode == 400) {
        throw Exception('Invalid data provided. Please check your input.');
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('Network error in editChild: $e');
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Failed to update child. Check your connection.');
    }
  }
}
