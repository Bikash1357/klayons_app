import 'package:flutter/material.dart';

class Event {
  final String id;
  final String title;
  final String address;
  final DateTime startTime;
  final DateTime endTime;
  final RecurrenceRule? recurrence;
  final Color color;

  Event({
    required this.id,
    required this.title,
    required this.address,
    required this.startTime,
    required this.endTime,
    this.recurrence,
    this.color = Colors.orange,
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
    };
  }

  static Event fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'],
      title: json['title'],
      address: json['address'],
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
      recurrence: json['recurrence'] != null
          ? RecurrenceRule.fromJson(json['recurrence'])
          : null,
      color: Color(json['color'] ?? Colors.orange.value),
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

  Map<String, dynamic> toJson() {
    return {
      'type': type.index,
      'interval': interval,
      'daysOfWeek': daysOfWeek,
      'endRule': endRule.index,
      'endDate': endDate?.toIso8601String(),
      'occurrences': occurrences,
    };
  }

  static RecurrenceRule fromJson(Map<String, dynamic> json) {
    return RecurrenceRule(
      type: RecurrenceType.values[json['type']],
      interval: json['interval'],
      daysOfWeek: List<int>.from(json['daysOfWeek']),
      endRule: RecurrenceEnd.values[json['endRule']],
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      occurrences: json['occurrences'],
    );
  }
}

enum RecurrenceType { daily, weekly, monthly, yearly }

enum RecurrenceEnd { never, onDate, after }
