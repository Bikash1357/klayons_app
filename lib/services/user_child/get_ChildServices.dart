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
      Interest(id: json['id'] ?? 0, name: json['name'] ?? '');

  Map<String, dynamic> toJson() => {'id': id, 'name': name};
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
    required this.interests,
    required this.dob,
  });

  factory Child.fromJson(Map<String, dynamic> json) {
    final interestsList = (json['interests'] as List? ?? []);
    final interests = interestsList
        .map((interest) => Interest.fromJson(interest as Map<String, dynamic>))
        .toList();

    return Child(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      gender: json['gender'] ?? '',
      dob: json['dob'] ?? '',
      interests: interests,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'gender': gender,
    'dob': dob,
    'interests': interests.map((i) => i.toJson()).toList(),
  };

  @override
  String toString() =>
      'Child{id: $id, name: $name, gender: $gender, dob: $dob, interests: ${interests.length}}';
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

  Map<String, dynamic> toJson() => {
    'name': name,
    'gender': gender,
    'dob': dob,
    'interest_ids': interestIds,
  };
}

// API Service with Caching
class GetChildservices {
  static const String _baseUrl = 'https://klayons-backend.onrender.com/api/';
  static const String _tokenKey = 'auth_token';
  static const Duration _cacheExpiration = Duration(minutes: 20);
  static const Duration _individualCacheExpiration = Duration(minutes: 30);

  // Cache variables
  static List<Child>? _cachedChildren;
  static DateTime? _childrenCacheTimestamp;
  static bool _isLoadingChildren = false;
  static Map<int, Child> _cachedIndividualChildren = {};
  static Map<int, DateTime> _individualChildrenCacheTimestamps = {};
  static Set<int> _updatingChildIds = {};

  /// Get authentication token
  static Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_tokenKey);
    } catch (e) {
      debugPrint('Error getting token: $e');
      return null;
    }
  }

  /// Check if children cache is valid
  static bool _isChildrenCacheValid() {
    if (_cachedChildren == null || _childrenCacheTimestamp == null)
      return false;
    return DateTime.now().difference(_childrenCacheTimestamp!) <
        _cacheExpiration;
  }

  /// Check if individual child cache is valid
  static bool _isIndividualChildCacheValid(int childId) {
    if (!_cachedIndividualChildren.containsKey(childId) ||
        !_individualChildrenCacheTimestamps.containsKey(childId))
      return false;
    return DateTime.now().difference(
          _individualChildrenCacheTimestamps[childId]!,
        ) <
        _individualCacheExpiration;
  }

  /// Clear all caches
  static void clearAllCache() {
    _cachedChildren = null;
    _childrenCacheTimestamp = null;
    _isLoadingChildren = false;
    _cachedIndividualChildren.clear();
    _individualChildrenCacheTimestamps.clear();
    _updatingChildIds.clear();
  }

  /// Update child in cache after successful edit
  static void _updateChildInCache(Child updatedChild) {
    // Update main children list cache
    if (_cachedChildren != null) {
      final index = _cachedChildren!.indexWhere(
        (child) => child.id == updatedChild.id,
      );
      if (index != -1) {
        _cachedChildren![index] = updatedChild;
      }
    }

    // Update individual child cache
    _cachedIndividualChildren[updatedChild.id] = updatedChild;
    _individualChildrenCacheTimestamps[updatedChild.id] = DateTime.now();
  }

  /// Fetch all children with caching
  static Future<List<Child>> fetchChildren({bool forceRefresh = false}) async {
    // Return cached data if valid and not forcing refresh
    if (!forceRefresh && _isChildrenCacheValid()) {
      return List<Child>.from(_cachedChildren!);
    }

    // Wait if already loading
    if (_isLoadingChildren) {
      while (_isLoadingChildren) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      return _cachedChildren != null ? List<Child>.from(_cachedChildren!) : [];
    }

    final token = await getToken();
    if (token == null || token.isEmpty) {
      clearAllCache();
      throw Exception('No authentication token found. Please login first.');
    }

    try {
      _isLoadingChildren = true;

      final response = await http.get(
        Uri.parse('$_baseUrl/profiles/children/'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        final List<Child> children = jsonData
            .map((child) => Child.fromJson(child as Map<String, dynamic>))
            .toList();

        // Cache the children
        _cachedChildren = children;
        _childrenCacheTimestamp = DateTime.now();

        return List<Child>.from(children);
      } else if (response.statusCode == 401) {
        clearAllCache();
        throw Exception('Authentication failed. Please login again.');
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      if (e.toString().contains('Authentication failed')) {
        clearAllCache();
        rethrow;
      }
      throw Exception('Failed to load data. Check your connection.');
    } finally {
      _isLoadingChildren = false;
    }
  }

  /// Edit/Update a child with cache management
  static Future<Child> editChild(int childId, EditChildRequest request) async {
    // Wait if already updating
    if (_updatingChildIds.contains(childId)) {
      while (_updatingChildIds.contains(childId)) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      if (_cachedIndividualChildren.containsKey(childId)) {
        return _cachedIndividualChildren[childId]!;
      }
    }

    final token = await getToken();
    if (token == null || token.isEmpty) {
      throw Exception('No authentication token found. Please login first.');
    }

    try {
      _updatingChildIds.add(childId);

      final response = await http.put(
        Uri.parse('$_baseUrl/profiles/children/$childId/'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(request.toJson()),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        final Child updatedChild = Child.fromJson(jsonData);

        // Update cache with the new child data
        _updateChildInCache(updatedChild);

        return updatedChild;
      } else if (response.statusCode == 401) {
        clearAllCache();
        throw Exception('Authentication failed. Please login again.');
      } else if (response.statusCode == 404) {
        throw Exception('Child not found.');
      } else if (response.statusCode == 400) {
        throw Exception('Invalid data provided. Please check your input.');
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Failed to update child. Check your connection.');
    } finally {
      _updatingChildIds.remove(childId);
    }
  }

  /// Get cached children without API call
  static List<Child>? getCachedChildren() {
    return _isChildrenCacheValid() ? List<Child>.from(_cachedChildren!) : null;
  }

  /// Get cached child by ID
  static Child? getCachedChildById(int id) {
    if (_isIndividualChildCacheValid(id)) {
      return _cachedIndividualChildren[id];
    }

    if (_isChildrenCacheValid()) {
      try {
        return _cachedChildren!.firstWhere((child) => child.id == id);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  /// Check if children are currently being loaded
  static bool get isLoadingChildren => _isLoadingChildren;

  /// Check if specific child is currently being updated
  static bool isUpdatingChild(int id) => _updatingChildIds.contains(id);

  /// Refresh children cache from server
  static Future<List<Child>> refreshChildren() =>
      fetchChildren(forceRefresh: true);
}
