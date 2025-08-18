import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/api_config.dart';

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

  @override
  String toString() {
    return 'Child{id: $id, name: $name, gender: $gender, dob: $dob, interests: ${interests.length}}';
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

// API Service with Caching
class GetChildservices {
  static const String baseUrl = 'https://klayons-backend.vercel.app/api';
  static const String _tokenKey = 'auth_token';

  // Cache variables for children list
  static List<Child>? _cachedChildren;
  static DateTime? _childrenCacheTimestamp;
  static bool _isLoadingChildren = false;

  // Cache variables for individual children (after edit operations)
  static Map<int, Child> _cachedIndividualChildren = {};
  static Map<int, DateTime> _individualChildrenCacheTimestamps = {};
  static Set<int> _updatingChildIds = {};

  // Cache configuration
  static const Duration _cacheExpiration = Duration(
    minutes: 20,
  ); // Children cache for 20 minutes
  static const Duration _individualCacheExpiration = Duration(
    minutes: 30,
  ); // Individual child cache for 30 minutes

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

  /// Checks if children cache is still valid
  static bool _isChildrenCacheValid() {
    if (_cachedChildren == null || _childrenCacheTimestamp == null) {
      return false;
    }

    final now = DateTime.now();
    final cacheAge = now.difference(_childrenCacheTimestamp!);
    return cacheAge < _cacheExpiration;
  }

  /// Checks if individual child cache is still valid
  static bool _isIndividualChildCacheValid(int childId) {
    if (!_cachedIndividualChildren.containsKey(childId) ||
        !_individualChildrenCacheTimestamps.containsKey(childId)) {
      return false;
    }

    final now = DateTime.now();
    final cacheAge = now.difference(
      _individualChildrenCacheTimestamps[childId]!,
    );
    return cacheAge < _individualCacheExpiration;
  }

  /// Clears all caches
  static void clearAllCache() {
    _cachedChildren = null;
    _childrenCacheTimestamp = null;
    _isLoadingChildren = false;
    _cachedIndividualChildren.clear();
    _individualChildrenCacheTimestamps.clear();
    _updatingChildIds.clear();
    print('All children cache cleared');
  }

  /// Clears only children list cache
  static void clearChildrenListCache() {
    _cachedChildren = null;
    _childrenCacheTimestamp = null;
    _isLoadingChildren = false;
    print('Children list cache cleared');
  }

  /// Clears individual child cache
  static void clearIndividualChildCache(int childId) {
    _cachedIndividualChildren.remove(childId);
    _individualChildrenCacheTimestamps.remove(childId);
    _updatingChildIds.remove(childId);
    print('Individual child cache cleared for ID: $childId');
  }

  /// Updates a child in the cache after successful edit
  static void _updateChildInCache(Child updatedChild) {
    // Update in the main children list cache if it exists
    if (_cachedChildren != null) {
      final index = _cachedChildren!.indexWhere(
        (child) => child.id == updatedChild.id,
      );
      if (index != -1) {
        _cachedChildren![index] = updatedChild;
        print('Updated child ${updatedChild.id} in children list cache');
      }
    }

    // Update in individual child cache
    _cachedIndividualChildren[updatedChild.id] = updatedChild;
    _individualChildrenCacheTimestamps[updatedChild.id] = DateTime.now();
    print('Updated child ${updatedChild.id} in individual cache');
  }

  // Fetch all children with caching
  static Future<List<Child>> fetchChildren({bool forceRefresh = false}) async {
    // Return cached data if valid and not forcing refresh
    if (!forceRefresh && _isChildrenCacheValid()) {
      print(
        'Returning cached children list (${_cachedChildren!.length} items)',
      );
      return List<Child>.from(_cachedChildren!);
    }

    // If already loading, wait for the current request to complete
    if (_isLoadingChildren) {
      print('Children loading in progress, waiting...');
      while (_isLoadingChildren) {
        await Future.delayed(Duration(milliseconds: 100));
      }
      return _cachedChildren != null ? List<Child>.from(_cachedChildren!) : [];
    }

    final token = await getToken();

    if (token == null || token.isEmpty) {
      clearAllCache(); // Clear cache on auth issues
      throw Exception('No authentication token found. Please login first.');
    }

    try {
      _isLoadingChildren = true;
      print('Fetching children from server...');

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
        List<Child> children = jsonData
            .map((child) => Child.fromJson(child))
            .toList();

        // Cache the children
        _cachedChildren = children;
        _childrenCacheTimestamp = DateTime.now();

        print(
          'Children fetched and cached successfully (${children.length} items)',
        );
        return List<Child>.from(children);
      } else if (response.statusCode == 401) {
        clearAllCache(); // Clear cache on auth failure
        throw Exception('Authentication failed. Please login again.');
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('Network error: $e');
      if (e.toString().contains('Authentication failed')) {
        clearAllCache();
        rethrow;
      }
      throw Exception('Failed to load data. Check your connection.');
    } finally {
      _isLoadingChildren = false;
    }
  }

  // Edit/Update a child with cache management
  static Future<Child> editChild(int childId, EditChildRequest request) async {
    // Check if this child is currently being updated
    if (_updatingChildIds.contains(childId)) {
      print('Child $childId update in progress, waiting...');
      while (_updatingChildIds.contains(childId)) {
        await Future.delayed(Duration(milliseconds: 100));
      }
      // Return cached version if available
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
      print('Updating child $childId...');

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
        Child updatedChild = Child.fromJson(jsonData);

        // Update cache with the new child data
        _updateChildInCache(updatedChild);

        print('Child $childId updated and cached successfully');
        return updatedChild;
      } else if (response.statusCode == 401) {
        clearAllCache();
        throw Exception('Authentication failed. Please login again.');
      } else if (response.statusCode == 404) {
        // Remove from cache if child not found
        clearIndividualChildCache(childId);
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
    } finally {
      _updatingChildIds.remove(childId);
    }
  }

  /// Gets cached children without making API call (returns null if no cache)
  static List<Child>? getCachedChildren() {
    if (_isChildrenCacheValid()) {
      print('Returning valid cached children list');
      return List<Child>.from(_cachedChildren!);
    }
    print('No valid cached children available');
    return null;
  }

  /// Gets cached child by ID without making API call (returns null if no cache)
  static Child? getCachedChildById(int id) {
    // First check individual cache
    if (_isIndividualChildCacheValid(id)) {
      print('Returning valid cached child for ID: $id from individual cache');
      return _cachedIndividualChildren[id];
    }

    // Then check in the main children list cache
    if (_isChildrenCacheValid()) {
      final child = _cachedChildren!
          .where((child) => child.id == id)
          .firstOrNull;
      if (child != null) {
        print('Returning valid cached child for ID: $id from children list');
        return child;
      }
    }

    print('No valid cached child available for ID: $id');
    return null;
  }

  /// Finds a child in the current cache by name (case insensitive)
  static Child? findChildByName(String name) {
    if (_isChildrenCacheValid()) {
      try {
        return _cachedChildren!.firstWhere(
          (child) => child.name.toLowerCase() == name.toLowerCase(),
        );
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  /// Gets children filtered by gender from cache
  static List<Child>? getCachedChildrenByGender(String gender) {
    if (_isChildrenCacheValid()) {
      return _cachedChildren!
          .where((child) => child.gender.toLowerCase() == gender.toLowerCase())
          .toList();
    }
    return null;
  }

  /// Checks if children are currently being loaded
  static bool get isLoadingChildren => _isLoadingChildren;

  /// Checks if specific child is currently being updated
  static bool isUpdatingChild(int id) => _updatingChildIds.contains(id);

  /// Gets children cache age in minutes (returns -1 if no cache)
  static int getChildrenCacheAgeInMinutes() {
    if (_childrenCacheTimestamp == null) return -1;

    final now = DateTime.now();
    final cacheAge = now.difference(_childrenCacheTimestamp!);
    return cacheAge.inMinutes;
  }

  /// Gets individual child cache age in minutes (returns -1 if no cache)
  static int getIndividualChildCacheAgeInMinutes(int id) {
    if (!_individualChildrenCacheTimestamps.containsKey(id)) return -1;

    final now = DateTime.now();
    final cacheAge = now.difference(_individualChildrenCacheTimestamps[id]!);
    return cacheAge.inMinutes;
  }

  /// Gets cache statistics for debugging
  static Map<String, dynamic> getCacheStats() {
    return {
      'childrenListCached': _cachedChildren != null,
      'childrenCount': _cachedChildren?.length ?? 0,
      'childrenCacheAgeMinutes': getChildrenCacheAgeInMinutes(),
      'individualChildrenCached': _cachedIndividualChildren.length,
      'individualChildrenIds': _cachedIndividualChildren.keys.toList(),
      'currentlyLoadingChildren': _isLoadingChildren,
      'currentlyUpdatingChildIds': _updatingChildIds.toList(),
    };
  }

  /// Refreshes children cache from server
  static Future<List<Child>> refreshChildren() async {
    return await fetchChildren(forceRefresh: true);
  }
}
