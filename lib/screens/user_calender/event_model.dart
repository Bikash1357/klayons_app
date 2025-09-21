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

  Event({
    required this.id,
    required this.title,
    required this.address,
    required this.startTime,
    required this.endTime,
    this.recurrence,
    this.color = Colors.orange,
    this.childName,
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
    };
  }

  static Event fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      address: json['address'] ?? '',
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
      recurrence: json['recurrence'] != null
          ? RecurrenceRule.fromJson(json['recurrence'])
          : null,
      color: json.containsKey('color') && json['color'] != null
          ? Color(json['color'])
          : Colors.orange,
      childName: json['childName'],
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
      interval: json['interval'],
      daysOfWeek: List<int>.from(json['daysOfWeek']),
      endRule: _recurrenceEndFromString(json['endRule']),
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      occurrences:
          json.containsKey('occurrences') && json['occurrences'] != null
          ? json['occurrences']
          : null,
    );
  }
}

enum RecurrenceType { daily, weekly, monthly, yearly }

enum RecurrenceEnd { never, onDate, after }
