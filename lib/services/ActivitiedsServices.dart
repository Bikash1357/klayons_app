import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// Data Models
class Instructor {
  final int id;
  final String name;
  final String profile;

  Instructor({required this.id, required this.name, required this.profile});

  factory Instructor.fromJson(Map<String, dynamic> json) {
    return Instructor(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      profile: json['profile'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'profile': profile};
  }
}

class Activity {
  final int id;
  final String name;
  final String description;
  final String bannerImageUrl;
  final String pricing;
  final int ageGroupStart;
  final int ageGroupEnd;
  final String startDate;
  final String endDate;
  final Instructor instructor;
  final bool isActive;
  final String batchesCount;

  Activity({
    required this.id,
    required this.name,
    required this.description,
    required this.bannerImageUrl,
    required this.pricing,
    required this.ageGroupStart,
    required this.ageGroupEnd,
    required this.startDate,
    required this.endDate,
    required this.instructor,
    required this.isActive,
    required this.batchesCount,
  });

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      bannerImageUrl: json['banner_image_url'] ?? '',
      pricing: json['pricing']?.toString() ?? '0.00',
      ageGroupStart: json['age_group_start'] ?? 0,
      ageGroupEnd: json['age_group_end'] ?? 0,
      startDate: json['start_date'] ?? '',
      endDate: json['end_date'] ?? '',
      instructor: json['instructor'] != null
          ? Instructor.fromJson(json['instructor'])
          : Instructor(id: 0, name: 'Unknown', profile: ''),
      isActive: json['is_active'] ?? false,
      batchesCount: json['batches_count']?.toString() ?? '0',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'banner_image_url': bannerImageUrl,
      'pricing': pricing,
      'age_group_start': ageGroupStart,
      'age_group_end': ageGroupEnd,
      'start_date': startDate,
      'end_date': endDate,
      'instructor': instructor.toJson(),
      'is_active': isActive,
      'batches_count': batchesCount,
    };
  }
}

// Token Storage Service
class TokenService {
  static const String _tokenKey = 'auth_token';

  // Get stored token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    print('Retrieved token: ${token != null ? "Found" : "Not found"}');
    return token;
  }

  // Save token
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    print('Token saved successfully');
  }

  // Remove token
  static Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    print('Token removed');
  }
}

// Service Class with Authentication
class ActivitiesService {
  static const String baseUrl = 'https://klayons-backend.vercel.app/api';
  static const String activitiesEndpoint = '/activities/';

  // Helper method to get headers with authentication
  static Future<Map<String, String>> _getHeaders() async {
    final token = await TokenService.getToken();
    final headers = {'Content-Type': 'application/json'};

    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  // Get all activities
  static Future<List<Activity>> getActivities() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl$activitiesEndpoint'),
        headers: headers,
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        List<Activity> activities = [];

        for (var json in jsonData) {
          try {
            activities.add(Activity.fromJson(json));
          } catch (e) {
            print('Error parsing activity: $e');
            print('Problematic JSON: $json');
            // Skip this activity and continue with others
          }
        }

        return activities;
      } else if (response.statusCode == 401) {
        throw AuthenticationException(
          'Authentication failed. Please login again.',
        );
      } else {
        throw Exception(
          'Failed to load activities: ${response.statusCode}\nResponse: ${response.body}',
        );
      }
    } catch (e) {
      if (e is AuthenticationException) {
        rethrow;
      }
      throw Exception('Error fetching activities: $e');
    }
  }

  // Get activity by ID
  static Future<Activity> getActivityById(int id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl$activitiesEndpoint$id/'),
        headers: headers,
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        return Activity.fromJson(jsonData);
      } else if (response.statusCode == 401) {
        throw AuthenticationException(
          'Authentication failed. Please login again.',
        );
      } else {
        throw Exception(
          'Failed to load activity: ${response.statusCode}\nResponse: ${response.body}',
        );
      }
    } catch (e) {
      if (e is AuthenticationException) {
        rethrow;
      }
      throw Exception('Error fetching activity: $e');
    }
  }

  // Get only active activities
  static Future<List<Activity>> getActiveActivities() async {
    try {
      final activities = await getActivities();
      return activities.where((activity) => activity.isActive).toList();
    } catch (e) {
      throw Exception('Error fetching active activities: $e');
    }
  }
}

// Custom Exception for Authentication Errors
class AuthenticationException implements Exception {
  final String message;

  AuthenticationException(this.message);

  @override
  String toString() => 'AuthenticationException: $message';
}

// Updated Usage Example in a StatefulWidget
class ActivitiesPage extends StatefulWidget {
  @override
  _ActivitiesPageState createState() => _ActivitiesPageState();
}

class _ActivitiesPageState extends State<ActivitiesPage> {
  List<Activity> activities = [];
  bool isLoading = true;
  String? errorMessage;
  bool showOnlyActive = false;

  @override
  void initState() {
    super.initState();
    fetchActivities();
  }

  Future<void> fetchActivities() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final fetchedActivities = showOnlyActive
          ? await ActivitiesService.getActiveActivities()
          : await ActivitiesService.getActivities();

      setState(() {
        activities = fetchedActivities;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        if (e is AuthenticationException) {
          errorMessage = 'Authentication error: Please login again';
          // You might want to navigate to login page here
          _handleAuthenticationError();
        } else {
          errorMessage = e.toString();
        }
        isLoading = false;
      });
    }
  }

  void _handleAuthenticationError() {
    // Handle authentication error
    // For example, navigate to login page
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Authentication Required'),
        content: Text('Your session has expired. Please login again.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Navigate to login page
              // Navigator.pushReplacementNamed(context, '/login');
            },
            child: Text('Login'),
          ),
        ],
      ),
    );
  }

  String formatDateRange(String startDate, String endDate) {
    return '$startDate to $endDate';
  }

  String formatAgeGroup(int startAge, int endAge) {
    if (startAge == endAge) {
      return '${startAge} years';
    }
    return '${startAge}-${endAge} years';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Activities'),
        actions: [
          IconButton(
            icon: Icon(
              showOnlyActive ? Icons.visibility : Icons.visibility_off,
            ),
            onPressed: () {
              setState(() {
                showOnlyActive = !showOnlyActive;
              });
              fetchActivities();
            },
            tooltip: showOnlyActive ? 'Show All' : 'Show Active Only',
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : errorMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red),
                  SizedBox(height: 16),
                  Text(
                    'Error: $errorMessage',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: fetchActivities,
                    child: Text('Retry'),
                  ),
                ],
              ),
            )
          : activities.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No activities found',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: fetchActivities,
              child: ListView.builder(
                itemCount: activities.length,
                itemBuilder: (context, index) {
                  final activity = activities[index];
                  return Card(
                    margin: EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        // Banner Image (if available)
                        if (activity.bannerImageUrl.isNotEmpty)
                          Container(
                            height: 150,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(4.0),
                              ),
                              image: DecorationImage(
                                image: NetworkImage(activity.bannerImageUrl),
                                fit: BoxFit.cover,
                                onError: (exception, stackTrace) {
                                  // Handle image loading error
                                  print('Failed to load image: $exception');
                                },
                              ),
                            ),
                          ),
                        ListTile(
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  activity.name,
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              if (!activity.isActive)
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'Inactive',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 4),
                              Text(activity.description),
                              SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.person, size: 16),
                                  SizedBox(width: 4),
                                  Text(
                                    'Instructor: ${activity.instructor.name}',
                                  ),
                                ],
                              ),
                              SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(Icons.group, size: 16),
                                  SizedBox(width: 4),
                                  Text(
                                    'Age: ${formatAgeGroup(activity.ageGroupStart, activity.ageGroupEnd)}',
                                  ),
                                ],
                              ),
                              SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(Icons.currency_rupee, size: 16),
                                  SizedBox(width: 4),
                                  Text('Pricing: ${activity.pricing}'),
                                ],
                              ),
                              SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(Icons.batch_prediction, size: 16),
                                  SizedBox(width: 4),
                                  Text('Batches: ${activity.batchesCount}'),
                                ],
                              ),
                              SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(Icons.date_range, size: 16),
                                  SizedBox(width: 4),
                                  Text(
                                    formatDateRange(
                                      activity.startDate,
                                      activity.endDate,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: Icon(Icons.arrow_forward_ios),
                          onTap: () {
                            // Navigate to activity details or perform action
                            print('Tapped on ${activity.name}');
                            // You can navigate to a detailed page here
                            // Navigator.push(context, MaterialPageRoute(
                            //   builder: (context) => ActivityDetailPage(activity: activity)
                            // ));
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }
}
