import 'package:flutter/material.dart';

class Event {
  final int? id;
  final String title;
  final String address;
  final DateTime startTime;
  final DateTime endTime;
  final RecurrenceRule? recurrence;
  final Color color;
  final int? childId;
  final String? childName;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Event({
    this.id,
    required this.title,
    required this.address,
    required this.startTime,
    required this.endTime,
    this.recurrence,
    this.color = Colors.orange,
    this.childId,
    this.childName,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'address': address,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      if (recurrence != null) 'recurrence': recurrence!.toJson(),
      'color': _colorToHex(color),
      if (childId != null) 'childId': childId,
      if (childName != null) 'childName': childName,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  static String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2).padLeft(6, '0').toUpperCase()}';
  }

  static Color _hexToColor(String hexString) {
    String hex = hexString.replaceFirst('#', '');
    if (hex.length == 6) {
      hex = 'FF$hex';
    }
    return Color(int.parse(hex, radix: 16));
  }

  static Event fromJson(Map<String, dynamic> json) {
    // Handle color conversion from hex string to Color
    Color eventColor = Colors.orange;
    if (json['color'] != null) {
      if (json['color'] is String) {
        eventColor = _hexToColor(json['color']);
      } else if (json['color'] is int) {
        eventColor = Color(json['color']);
      }
    }

    // Parse datetime strings - DateTime.parse() handles timezone offsets automatically
    // If the string has +05:30, it will be parsed correctly
    DateTime parsedStartTime = DateTime.parse(json['startTime']);
    DateTime parsedEndTime = DateTime.parse(json['endTime']);

    // Debug logging to verify parsing
    print('📅 Parsing Event DateTime:');
    print('   Raw startTime: ${json['startTime']}');
    print('   Parsed startTime: $parsedStartTime');
    print('   Is UTC: ${parsedStartTime.isUtc}');
    print('   TimeZone offset: ${parsedStartTime.timeZoneOffset}');
    print('   Local representation: ${parsedStartTime.toLocal()}');

    // Convert to local time if parsed as UTC
    // DateTime.parse() converts timezone-aware strings to UTC internally
    // then we convert back to local for display
    final DateTime localStartTime = parsedStartTime.toLocal();
    final DateTime localEndTime = parsedEndTime.toLocal();

    print('   Final startTime: $localStartTime');
    print('   Final endTime: $localEndTime');

    return Event(
      id: json['id'] is int
          ? json['id']
          : (json['id'] != null ? int.tryParse(json['id'].toString()) : null),
      title: json['title']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      startTime: localStartTime,
      endTime: localEndTime,
      recurrence: json['recurrence'] != null
          ? RecurrenceRule.fromJson(json['recurrence'])
          : null,
      color: eventColor,
      childId: json['childId'] is int
          ? json['childId']
          : (json['childId'] != null
                ? int.tryParse(json['childId'].toString())
                : null),
      childName: json['childName']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt']).toLocal()
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt']).toLocal()
          : null,
    );
  }

  // Helper method to create a copy with updated fields
  Event copyWith({
    int? id,
    String? title,
    String? address,
    DateTime? startTime,
    DateTime? endTime,
    RecurrenceRule? recurrence,
    Color? color,
    int? childId,
    String? childName,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Event(
      id: id ?? this.id,
      title: title ?? this.title,
      address: address ?? this.address,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      recurrence: recurrence ?? this.recurrence,
      color: color ?? this.color,
      childId: childId ?? this.childId,
      childName: childName ?? this.childName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Event(id: $id, title: $title, startTime: $startTime, endTime: $endTime, childId: $childId, childName: $childName)';
  }
}

class RecurrenceRule {
  final RecurrenceType type;
  final int interval;
  final List<int>? daysOfWeek;
  final RecurrenceEnd endRule;
  final DateTime? endDate;
  final int? occurrences;

  RecurrenceRule({
    required this.type,
    this.interval = 1,
    this.daysOfWeek,
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
      case 'date':
        return RecurrenceEnd.onDate;
      case 'after':
      case 'occurrences':
        return RecurrenceEnd.after;
      default:
        throw Exception('Unknown RecurrenceEnd: $value');
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.toString().split('.').last,
      'interval': interval,
      if (daysOfWeek != null && daysOfWeek!.isNotEmpty)
        'daysOfWeek': daysOfWeek,
      'endRule': endRule.toString().split('.').last,
      if (endDate != null) 'endDate': endDate!.toIso8601String(),
      if (occurrences != null) 'occurrences': occurrences,
    };
  }

  static RecurrenceRule fromJson(Map<String, dynamic> json) {
    return RecurrenceRule(
      type: _recurrenceTypeFromString(json['type']?.toString() ?? 'weekly'),
      interval: json['interval'] ?? 1,
      daysOfWeek: json['daysOfWeek'] != null
          ? List<int>.from(json['daysOfWeek'])
          : null,
      endRule: _recurrenceEndFromString(json['endRule']?.toString() ?? 'never'),
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate']).toLocal()
          : null,
      occurrences: json['occurrences'],
    );
  }

  @override
  String toString() {
    return 'RecurrenceRule(type: $type, interval: $interval, daysOfWeek: $daysOfWeek, endRule: $endRule, endDate: $endDate)';
  }
}

enum RecurrenceType { daily, weekly, monthly, yearly }

enum RecurrenceEnd { never, onDate, after }
