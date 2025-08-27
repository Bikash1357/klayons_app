import 'package:flutter/material.dart';

class Event {
  final String id;
  final String title;
  final String description;
  final DateTime startTime;
  final DateTime endTime;
  final RecurrenceRule? recurrence;
  final Color color;

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.startTime,
    required this.endTime,
    this.recurrence,
    this.color = Colors.orange,
  });
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
}

enum RecurrenceType { daily, weekly, monthly, yearly }

enum RecurrenceEnd { never, onDate, after }
