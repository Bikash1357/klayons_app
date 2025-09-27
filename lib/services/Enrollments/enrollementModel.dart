import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class GetEnrollment {
  final int id;
  final Child child;
  final Activity activity;
  final String status;
  final int? waitlistPosition;
  final String notes;
  final DateTime enrolledAt;
  final String history;

  GetEnrollment({
    required this.id,
    required this.child,
    required this.activity,
    required this.status,
    this.waitlistPosition,
    required this.notes,
    required this.enrolledAt,
    required this.history,
  });

  factory GetEnrollment.fromJson(Map<String, dynamic> json) {
    try {
      return GetEnrollment(
        id: _parseIntSafely(json['id']),
        child: Child.fromJson(json['child'] as Map<String, dynamic>),
        activity: Activity.fromJson(json['activity'] as Map<String, dynamic>),
        status: json['status']?.toString() ?? '',
        waitlistPosition: json['waitlist_position'],
        notes: json['notes']?.toString() ?? '',
        enrolledAt: _parseDateTimeSafely(json['timestamp']),
        history: json['history']?.toString() ?? 'No history available',
      );
    } catch (e) {
      print('Error parsing GetEnrollment from JSON: $e');
      print('JSON data: $json');
      rethrow;
    }
  }

  // Helper methods
  static int _parseIntSafely(dynamic value) {
    if (value == null) {
      print('Warning: Null value encountered for integer field');
      return 0;
    }
    if (value is int) return value;
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    if (value is double) return value.toInt();
    print('Warning: Unexpected type ${value.runtimeType} for integer field');
    return 0;
  }

  static DateTime _parseDateTimeSafely(dynamic value) {
    if (value == null) {
      print('Warning: Null value encountered for DateTime field');
      return DateTime.now();
    }
    try {
      return DateTime.parse(value.toString());
    } catch (e) {
      print('Warning: Failed to parse DateTime: $value');
      return DateTime.now();
    }
  }

  // Convert back to JSON for caching
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'child': child.toJson(),
      'activity': activity.toJson(),
      'status': status,
      'waitlist_position': waitlistPosition,
      'notes': notes,
      'timestamp': enrolledAt.toIso8601String(),
      'history': history,
    };
  }

  // EXISTING compatibility getters for UI code
  int get childId => child.id;
  String get childName => child.name;
  int get activityId => activity.id;
  String get activityName => activity.name;
  int get price => int.tryParse(activity.price) ?? 0;

  // ADD THESE MISSING GETTERS:
  String get bannerImageUrl => activity.bannerImageUrl;
  String get subcategory => activity.subcategory;
  String get society => activity.society;
  String get paymentType => activity.paymentType;
  bool get isActive => activity.isActive;
  String get category => activity.category;
  String get batchName => activity.batchName;
  String get instructor => activity.instructor;

  // Helper methods for display
  String get statusDisplay {
    switch (status.toLowerCase()) {
      case 'enrolled':
        return 'Enrolled';
      case 'waitlist':
        return 'Waitlisted';
      case 'unenrolled':
        return 'Unenrolled';
      case 'reenrolled':
        return 'Re-enrolled';
      default:
        return status;
    }
  }

  Color get statusColor {
    switch (status.toLowerCase()) {
      case 'enrolled':
        return Colors.green;
      case 'waitlist':
        return Colors.orange;
      case 'unenrolled':
        return Colors.red;
      case 'reenrolled':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String get priceDisplay => '₹${activity.price}/${activity.paymentType}';

  String get enrolledAtDisplay {
    final localDate = enrolledAt.toLocal();
    return '${localDate.day}/${localDate.month}/${localDate.year}';
  }

  // Additional display helpers
  String get societyDisplay => society.isNotEmpty ? society : 'Not specified';
  String get subcategoryDisplay =>
      subcategory.isNotEmpty ? subcategory : 'General';
  String get instructorDisplay => instructor.isNotEmpty ? instructor : 'TBD';
  String get batchDisplay => batchName.isNotEmpty ? batchName : 'Standard';
}

class Child {
  final int id;
  final String name;

  Child({required this.id, required this.name});

  factory Child.fromJson(Map<String, dynamic> json) {
    return Child(
      id: GetEnrollment._parseIntSafely(json['id']),
      name: json['name']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name};
  }
}

class Activity {
  final int id;
  final String name;
  final String category;
  final String subcategory;
  final String batchName;
  final String bannerImageUrl;
  final String instructor;
  final String society;
  final String price;
  final String paymentType;
  final bool isActive;

  Activity({
    required this.id,
    required this.name,
    required this.category,
    required this.subcategory,
    required this.batchName,
    required this.bannerImageUrl,
    required this.instructor,
    required this.society,
    required this.price,
    required this.paymentType,
    required this.isActive,
  });

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      id: GetEnrollment._parseIntSafely(json['id']),
      name: json['name']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      subcategory: json['subcategory']?.toString() ?? '',
      batchName: json['batch_name']?.toString() ?? '',
      bannerImageUrl: json['banner_image_url']?.toString() ?? '',
      instructor: json['instructor']?.toString() ?? '',
      society: json['society']?.toString() ?? '',
      price: json['price']?.toString() ?? '0',
      paymentType: json['payment_type']?.toString() ?? 'monthly',
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'subcategory': subcategory,
      'batch_name': batchName,
      'banner_image_url': bannerImageUrl,
      'instructor': instructor,
      'society': society,
      'price': price,
      'payment_type': paymentType,
      'is_active': isActive,
    };
  }
}
