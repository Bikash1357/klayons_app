import 'package:flutter/material.dart';

class Event {
  final String id;
  final String title;
  final String address;
  final DateTime startTime;
  final DateTime endTime;
  final RecurrenceRule? recurrence;
  final Color color;
  final String? childName;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Event({
    required this.id,
    required this.title,
    required this.address,
    required this.startTime,
    required this.endTime,
    this.recurrence,
    this.color = Colors.orange,
    this.childName,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'address': address,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'recurrence': recurrence?.toJson(),
      'color': color.value,
      'childName': childName,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  static Event fromJson(Map<String, dynamic> json) {
    // Handle color conversion from hex string to Color
    Color eventColor = Colors.orange;
    if (json['color'] != null) {
      if (json['color'] is String) {
        // Convert hex string to Color
        String hex = json['color'].toString().replaceFirst('#', '');
        if (hex.length == 6) {
          hex = 'FF$hex'; // Add full opacity
        }
        eventColor = Color(int.parse(hex, radix: 16));
      } else if (json['color'] is int) {
        eventColor = Color(json['color']);
      }
    }

    return Event(
      id: json['id']?.toString() ?? '', // Convert int to string
      title: json['title'] ?? '',
      address: json['address'] ?? '',
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
      recurrence: json['recurrence'] != null
          ? RecurrenceRule.fromJson(json['recurrence'])
          : null,
      color: eventColor,
      childName: json['childName'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }
}

class RecurrenceRule {
  final RecurrenceType type;
  final int interval;
  final List<int> daysOfWeek;
  final RecurrenceEnd endRule;
  final DateTime? endDate;
  final int? occurrences;

  RecurrenceRule({
    required this.type,
    this.interval = 1,
    this.daysOfWeek = const [],
    required this.endRule,
    this.endDate,
    this.occurrences,
  });

  static RecurrenceType _recurrenceTypeFromString(String value) {
    switch (value.toLowerCase()) {
      case 'daily':
        return RecurrenceType.daily;
      case 'weekly':
        return RecurrenceType.weekly;
      case 'monthly':
        return RecurrenceType.monthly;
      case 'yearly':
        return RecurrenceType.yearly;
      default:
        throw Exception('Unknown RecurrenceType: $value');
    }
  }

  static RecurrenceEnd _recurrenceEndFromString(String value) {
    switch (value.toLowerCase()) {
      case 'never':
        return RecurrenceEnd.never;
      case 'ondate':
        return RecurrenceEnd.onDate;
      case 'after':
        return RecurrenceEnd.after;
      default:
        throw Exception('Unknown RecurrenceEnd: $value');
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.toString().split('.').last, // 'weekly' etc.
      'interval': interval,
      'daysOfWeek': daysOfWeek,
      'endRule': endRule.toString().split('.').last, // 'onDate' etc.
      'endDate': endDate?.toIso8601String(),
      'occurrences': occurrences,
    };
  }

  static RecurrenceRule fromJson(Map<String, dynamic> json) {
    return RecurrenceRule(
      type: _recurrenceTypeFromString(json['type']),
      interval: json['interval'] ?? 1,
      daysOfWeek: List<int>.from(json['daysOfWeek'] ?? []),
      endRule: _recurrenceEndFromString(json['endRule']),
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      occurrences: json['occurrences'],
    );
  }
}

enum RecurrenceType { daily, weekly, monthly, yearly }

enum RecurrenceEnd { never, onDate, after }
