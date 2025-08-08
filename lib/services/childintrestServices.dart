// services/api_service.dart
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

// models/interest_model.dart
class Interest {
  final int id;
  final String name;

  Interest({required this.id, required this.name});

  factory Interest.fromJson(Map<String, dynamic> json) {
    return Interest(id: json['id'] as int, name: json['name'] as String);
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name};
  }

  @override
  String toString() => 'Interest(id: $id, name: $name)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Interest &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name;

  @override
  int get hashCode => id.hashCode ^ name.hashCode;
}

// models/child_model.dart
class Child {
  final String name;
  final int age;
  final String gender;
  final List<int> interestIds;

  Child({
    required this.name,
    required this.age,
    required this.gender,
    required this.interestIds,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'age': age,
      'gender': gender,
      'interest_ids': interestIds,
    };
  }
}

class ApiService {
  static const String baseUrl = 'https://klayons-backend.vercel.app/api';

  // Singleton pattern
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // Get all interests
  Future<List<Interest>> getInterests() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/profiles/interests/'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((json) => Interest.fromJson(json)).toList();
      } else {
        throw ApiException(
          'Failed to load interests. Status code: ${response.statusCode}',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: $e', 0);
    }
  }

  // Add a new child (assuming there's an endpoint for this)
  Future<bool> addChild(Child child) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/profiles/children/'), // Adjust endpoint as needed
        headers: {'Content-Type': 'application/json'},
        body: json.encode(child.toJson()),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return true;
      } else {
        throw ApiException(
          'Failed to add child. Status code: ${response.statusCode}',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: $e', 0);
    }
  }
}

// exceptions/api_exception.dart
class ApiException implements Exception {
  final String message;
  final int statusCode;

  ApiException(this.message, this.statusCode);

  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';
}

// services/child_service.dart
class ChildService {
  final ApiService _apiService = ApiService();

  // Cached interests to avoid repeated API calls
  List<Interest>? _cachedInterests;

  Future<List<Interest>> getInterests({bool forceRefresh = false}) async {
    if (_cachedInterests == null || forceRefresh) {
      _cachedInterests = await _apiService.getInterests();
    }
    return _cachedInterests!;
  }

  Future<bool> addChild({
    required String name,
    required int age,
    required String gender,
    required List<int> selectedInterestIds,
  }) async {
    final child = Child(
      name: name,
      age: age,
      gender: gender,
      interestIds: selectedInterestIds,
    );

    return await _apiService.addChild(child);
  }

  // Helper method to get interest names from IDs
  List<String> getInterestNames(
    List<int> interestIds,
    List<Interest> allInterests,
  ) {
    return allInterests
        .where((interest) => interestIds.contains(interest.id))
        .map((interest) => interest.name)
        .toList();
  }

  // Clear cached interests
  void clearCache() {
    _cachedInterests = null;
  }
}

// providers/add_child_provider.dart (if using Provider state management)

class AddChildProvider extends ChangeNotifier {
  final ChildService _childService = ChildService();

  List<Interest> _interests = [];
  List<int> _selectedInterestIds = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Interest> get interests => _interests;
  List<int> get selectedInterestIds => _selectedInterestIds;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Load interests
  Future<void> loadInterests() async {
    _setLoading(true);
    _setError(null);

    try {
      _interests = await _childService.getInterests();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Toggle interest selection
  void toggleInterest(int interestId) {
    if (_selectedInterestIds.contains(interestId)) {
      _selectedInterestIds.remove(interestId);
    } else {
      _selectedInterestIds.add(interestId);
    }
    notifyListeners();
  }

  // Add child
  Future<bool> addChild({
    required String name,
    required int age,
    required String gender,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      final success = await _childService.addChild(
        name: name,
        age: age,
        gender: gender,
        selectedInterestIds: _selectedInterestIds,
      );

      if (success) {
        // Reset form
        _selectedInterestIds.clear();
      }

      return success;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  // Clear selections
  void clearSelections() {
    _selectedInterestIds.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
