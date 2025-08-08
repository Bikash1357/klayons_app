import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

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
}

// Main Widget
class ChildrenListScreen extends StatefulWidget {
  @override
  _ChildrenListScreenState createState() => _ChildrenListScreenState();
}

class _ChildrenListScreenState extends State<ChildrenListScreen> {
  late Future<List<Child>> futureChildren;

  @override
  void initState() {
    super.initState();
    futureChildren = GetChildservices.fetchChildren();
  }

  void _refresh() =>
      setState(() => futureChildren = GetChildservices.fetchChildren());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Children Profiles'),
        backgroundColor: Colors.blue,
        actions: [IconButton(icon: Icon(Icons.refresh), onPressed: _refresh)],
      ),
      body: FutureBuilder<List<Child>>(
        future: futureChildren,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.red),
                    SizedBox(height: 16),
                    Text('${snapshot.error}', textAlign: TextAlign.center),
                    SizedBox(height: 20),
                    ElevatedButton(onPressed: _refresh, child: Text('Retry')),
                  ],
                ),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.child_care, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No children found'),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              Child child = snapshot.data![index];
              return Card(
                margin: EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: child.gender == 'male'
                        ? Colors.blue.shade100
                        : Colors.pink.shade100,
                    child: Icon(
                      child.gender == 'male' ? Icons.boy : Icons.girl,
                      color: child.gender == 'male' ? Colors.blue : Colors.pink,
                    ),
                  ),
                  title: Text(
                    child.name,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('DOB: ${child.dob} • ${child.gender}'),
                      if (child.interests.isNotEmpty) ...[
                        SizedBox(height: 4),
                        Wrap(
                          spacing: 4,
                          children: child.interests
                              .take(3)
                              .map(
                                (interest) => Chip(
                                  label: Text(
                                    interest.name,
                                    style: TextStyle(fontSize: 10),
                                  ),
                                  visualDensity: VisualDensity.compact,
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
