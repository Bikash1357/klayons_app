import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

// Data models for Society Batches
class BatchOverride {
  final String originalDate;
  final String action;
  final String status;
  final String remarks;

  BatchOverride({
    required this.originalDate,
    required this.action,
    required this.status,
    required this.remarks,
  });

  factory BatchOverride.fromJson(Map<String, dynamic> json) {
    return BatchOverride(
      originalDate: json['original_date'],
      action: json['action'],
      status: json['status'],
      remarks: json['remarks'] ?? '',
    );
  }

  DateTime get originalDateTime => DateTime.parse(originalDate);
}

class BatchSchedule {
  final int id;
  final String startTime;
  final String endTime;
  final List<String> rrulePatterns;
  final List<String> rdatePatterns;
  final List<String> exdatePatterns;
  final List<BatchOverride> overrides;

  BatchSchedule({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.rrulePatterns,
    required this.rdatePatterns,
    required this.exdatePatterns,
    required this.overrides,
  });

  factory BatchSchedule.fromJson(Map<String, dynamic> json) {
    return BatchSchedule(
      id: json['id'],
      startTime: json['start_time'],
      endTime: json['end_time'],
      rrulePatterns: List<String>.from(json['rrule_patterns']),
      rdatePatterns: List<String>.from(json['rdate_patterns'] ?? []),
      exdatePatterns: List<String>.from(json['exdate_patterns'] ?? []),
      overrides:
          (json['overrides'] as List?)
              ?.map((e) => BatchOverride.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class SocietyBatch {
  final int id;
  final String name;
  final int activityId;
  final String activityName;
  final String venue;
  final List<BatchSchedule> schedules;

  SocietyBatch({
    required this.id,
    required this.name,
    required this.activityId,
    required this.activityName,
    required this.venue,
    required this.schedules,
  });

  factory SocietyBatch.fromJson(Map<String, dynamic> json) {
    return SocietyBatch(
      id: json['id'],
      name: json['name'],
      activityId: json['activity_id'],
      activityName: json['activity_name'],
      venue: json['venue'],
      schedules: (json['schedules'] as List)
          .map((e) => BatchSchedule.fromJson(e))
          .toList(),
    );
  }
}

class SocietyBatchesResponse {
  final List<SocietyBatch> batches;

  SocietyBatchesResponse({required this.batches});

  factory SocietyBatchesResponse.fromJson(Map<String, dynamic> json) {
    return SocietyBatchesResponse(
      batches: (json['batches'] as List)
          .map((e) => SocietyBatch.fromJson(e))
          .toList(),
    );
  }
}

// Calendar Event for batches
class BatchCalendarEvent {
  final String id;
  final String title;
  final String venue;
  final DateTime startTime;
  final DateTime endTime;
  final Color color;
  final bool isCancelled;
  final String? cancelReason;
  final SocietyBatch originalBatch;
  final bool isFromRDate;

  BatchCalendarEvent({
    required this.id,
    required this.title,
    required this.venue,
    required this.startTime,
    required this.endTime,
    required this.color,
    this.isCancelled = false,
    this.cancelReason,
    required this.originalBatch,
    this.isFromRDate = false,
  });
}

// API Service for Society Batches
class SocietyBatchesService {
  static const String baseUrl = 'https://klayons-backend.vercel.app/api';
  static const String _tokenKey = 'auth_token';

  // Cache variables
  static SocietyBatchesResponse? _cachedBatches;
  static DateTime? _cacheTimestamp;
  static bool _isLoading = false;
  static const Duration _cacheExpiration = Duration(minutes: 15);

  static Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);
      return token;
    } catch (e) {
      print('Error getting token: $e');
      return null;
    }
  }

  static bool _isCacheValid() {
    if (_cachedBatches == null || _cacheTimestamp == null) {
      return false;
    }
    final now = DateTime.now();
    final cacheAge = now.difference(_cacheTimestamp!);
    return cacheAge < _cacheExpiration;
  }

  static void clearCache() {
    _cachedBatches = null;
    _cacheTimestamp = null;
    _isLoading = false;
    print('Society batches cache cleared');
  }

  // Fetch society batches from API
  static Future<SocietyBatchesResponse> fetchSocietyBatches({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _isCacheValid()) {
      print('Returning cached society batches');
      return _cachedBatches!;
    }

    if (_isLoading) {
      print('Society batches loading in progress, waiting...');
      while (_isLoading) {
        await Future.delayed(Duration(milliseconds: 100));
      }
      return _cachedBatches ?? SocietyBatchesResponse(batches: []);
    }

    final token = await getToken();
    if (token == null || token.isEmpty) {
      clearCache();
      throw Exception('No authentication token found. Please login first.');
    }

    try {
      _isLoading = true;
      print('Fetching society batches from server...');

      final response = await http.get(
        Uri.parse('$baseUrl/calendar/society-batches/'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Society Batches API Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        Map<String, dynamic> jsonData = json.decode(response.body);
        SocietyBatchesResponse batchesResponse =
            SocietyBatchesResponse.fromJson(jsonData);

        _cachedBatches = batchesResponse;
        _cacheTimestamp = DateTime.now();

        print(
          'Society batches fetched and cached successfully (${batchesResponse.batches.length} batches)',
        );
        return batchesResponse;
      } else if (response.statusCode == 401) {
        clearCache();
        throw Exception('Authentication failed. Please login again.');
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('Network error in fetchSocietyBatches: $e');
      if (e.toString().contains('Authentication failed')) {
        clearCache();
        rethrow;
      }
      throw Exception('Failed to load society batches. Check your connection.');
    } finally {
      _isLoading = false;
    }
  }

  static SocietyBatchesResponse? getCachedBatches() {
    if (_isCacheValid()) {
      return _cachedBatches;
    }
    return null;
  }

  static bool get isLoading => _isLoading;

  static int getCacheAgeInMinutes() {
    if (_cacheTimestamp == null) return -1;
    final now = DateTime.now();
    final cacheAge = now.difference(_cacheTimestamp!);
    return cacheAge.inMinutes;
  }

  // Generate calendar events with proper RDATE and EXDATE handling
  static List<BatchCalendarEvent> generateCalendarEvents(
    SocietyBatchesResponse batchesResponse,
    DateTime startDate,
    DateTime endDate,
  ) {
    List<BatchCalendarEvent> events = [];

    for (SocietyBatch batch in batchesResponse.batches) {
      for (BatchSchedule schedule in batch.schedules) {
        // Step 1: Generate RRULE events
        List<DateTime> rruleEvents = [];
        for (String rrulePattern in schedule.rrulePatterns) {
          rruleEvents.addAll(
            _parseRRulePattern(
              rrulePattern,
              schedule.startTime,
              startDate,
              endDate,
            ),
          );
        }

        // Step 2: Add RDATE events
        List<DateTime> rdateEvents = _parseRDatePatterns(
          schedule.rdatePatterns,
          schedule.startTime,
        );

        // Step 3: Combine all events
        List<DateTime> allEvents = [...rruleEvents, ...rdateEvents];

        // Step 4: Remove EXDATE events
        List<DateTime> exdates = _parseExDatePatterns(schedule.exdatePatterns);
        allEvents = _filterExdates(allEvents, exdates);

        // Step 5: Apply overrides (cancellations)
        for (DateTime eventDate in allEvents) {
          if (eventDate.isAfter(startDate.subtract(Duration(days: 1))) &&
              eventDate.isBefore(endDate.add(Duration(days: 1)))) {
            // Check if this date is cancelled in overrides
            bool isCancelled = false;
            String? cancelReason;

            for (BatchOverride override in schedule.overrides) {
              if (_isSameDay(override.originalDateTime, eventDate) &&
                  override.action == 'cancel') {
                isCancelled = true;
                cancelReason = override.remarks;
                break;
              }
            }

            // Create end time
            DateTime endTime = _parseTimeToDateTime(
              eventDate,
              schedule.endTime,
            );

            // Check if it's from RDATE
            bool isFromRDate = rdateEvents.any(
              (rdate) => _isSameDateTime(rdate, eventDate),
            );

            events.add(
              BatchCalendarEvent(
                id: '${batch.id}_${schedule.id}_${eventDate.millisecondsSinceEpoch}',
                title: batch.name,
                venue: batch.venue,
                startTime: eventDate,
                endTime: endTime,
                color: _getColorForActivity(batch.activityId),
                isCancelled: isCancelled,
                cancelReason: cancelReason,
                originalBatch: batch,
                isFromRDate: isFromRDate,
              ),
            );
          }
        }
      }
    }

    // Sort events by start time
    events.sort((a, b) => a.startTime.compareTo(b.startTime));
    return events;
  }

  // Parse RRULE pattern (improved version)
  static List<DateTime> _parseRRulePattern(
    String rrulePattern,
    String startTime,
    DateTime rangeStart,
    DateTime rangeEnd,
  ) {
    List<DateTime> events = [];

    try {
      Map<String, String> rruleParams = {};
      List<String> parts = rrulePattern.split(';');

      for (String part in parts) {
        List<String> keyValue = part.split('=');
        if (keyValue.length == 2) {
          rruleParams[keyValue[0]] = keyValue[1];
        }
      }

      String? freq = rruleParams['FREQ'];
      String? until = rruleParams['UNTIL'];
      String? byDay = rruleParams['BYDAY'];
      int interval = int.tryParse(rruleParams['INTERVAL'] ?? '1') ?? 1;

      if (freq == null) return events;

      DateTime? untilDate;
      if (until != null) {
        try {
          untilDate = _parseUtcDateTime(until);
        } catch (e) {
          print('Error parsing UNTIL date: $e');
        }
      }

      // Parse start time for events
      DateTime templateTime = _parseTimeToDateTime(rangeStart, startTime);

      // Start from range start, find first occurrence
      DateTime current = DateTime(
        rangeStart.year,
        rangeStart.month,
        rangeStart.day,
        templateTime.hour,
        templateTime.minute,
      );

      // Go back a bit to ensure we catch events that start before range
      current = current.subtract(Duration(days: 30));

      while (current.isBefore(rangeEnd.add(Duration(days: 1)))) {
        if (untilDate != null && current.isAfter(untilDate)) {
          break;
        }

        bool shouldInclude = false;

        switch (freq) {
          case 'WEEKLY':
            if (byDay != null) {
              List<String> days = byDay.split(',');
              for (String day in days) {
                if (_matchesWeekDay(current, day)) {
                  shouldInclude = true;
                  break;
                }
              }
            } else {
              shouldInclude = true;
            }
            break;
          case 'DAILY':
            shouldInclude = true;
            break;
          case 'MONTHLY':
            shouldInclude = true;
            break;
          case 'YEARLY':
            shouldInclude = true;
            break;
        }

        if (shouldInclude &&
            current.isAfter(rangeStart.subtract(Duration(days: 1)))) {
          events.add(current);
        }

        // Move to next occurrence
        switch (freq) {
          case 'DAILY':
            current = current.add(Duration(days: interval));
            break;
          case 'WEEKLY':
            current = current.add(
              Duration(days: 1),
            ); // Check each day for BYDAY matching
            break;
          case 'MONTHLY':
            current = DateTime(
              current.year,
              current.month + interval,
              current.day,
              current.hour,
              current.minute,
            );
            break;
          case 'YEARLY':
            current = DateTime(
              current.year + interval,
              current.month,
              current.day,
              current.hour,
              current.minute,
            );
            break;
        }
      }
    } catch (e) {
      print('Error parsing RRULE: $e');
    }

    return events;
  }

  // Parse RDATE patterns - Updated to handle individual UTC datetime strings
  static List<DateTime> _parseRDatePatterns(
    List<String> rdatePatterns,
    String defaultStartTime,
  ) {
    List<DateTime> events = [];

    for (String rdatePattern in rdatePatterns) {
      try {
        // Each pattern is a single UTC datetime like "20250830T183000Z"
        DateTime parsedDate = _parseUtcDateTime(rdatePattern);
        events.add(parsedDate);
        print('Parsed RDATE: $parsedDate from $rdatePattern');
      } catch (e) {
        print('Error parsing RDATE pattern "$rdatePattern": $e');
      }
    }

    return events;
  }

  // Parse EXDATE patterns - Updated to handle individual UTC datetime strings
  static List<DateTime> _parseExDatePatterns(List<String> exdatePatterns) {
    List<DateTime> exdates = [];

    for (String exdatePattern in exdatePatterns) {
      try {
        // Each pattern is a single UTC datetime like "20250831T183000Z"
        DateTime parsedDate = _parseUtcDateTime(exdatePattern);
        exdates.add(parsedDate);
        print('Parsed EXDATE: $parsedDate from $exdatePattern');
      } catch (e) {
        print('Error parsing EXDATE pattern "$exdatePattern": $e');
      }
    }

    return exdates;
  }

  // Filter out EXDATE events
  static List<DateTime> _filterExdates(
    List<DateTime> events,
    List<DateTime> exdates,
  ) {
    return events.where((event) {
      return !exdates.any((exdate) => _isSameDateTime(event, exdate));
    }).toList();
  }

  // Parse UTC datetime format like "20250831T183000Z"
  static DateTime _parseUtcDateTime(String utcString) {
    // Remove 'Z' and insert separators
    String cleaned = utcString.replaceAll('Z', '');

    if (cleaned.contains('T')) {
      List<String> parts = cleaned.split('T');
      String datePart = parts[0];
      String timePart = parts[1];

      // Parse date part: YYYYMMDD
      int year = int.parse(datePart.substring(0, 4));
      int month = int.parse(datePart.substring(4, 6));
      int day = int.parse(datePart.substring(6, 8));

      // Parse time part: HHMMSS
      int hour = int.parse(timePart.substring(0, 2));
      int minute = int.parse(timePart.substring(2, 4));
      int second = int.parse(timePart.substring(4, 6));

      return DateTime.utc(year, month, day, hour, minute, second);
    } else {
      throw FormatException('Invalid UTC datetime format: $utcString');
    }
  }

  // Helper methods
  static bool _matchesWeekDay(DateTime date, String rruleDay) {
    Map<String, int> dayMap = {
      'MO': 1,
      'TU': 2,
      'WE': 3,
      'TH': 4,
      'FR': 5,
      'SA': 6,
      'SU': 7,
    };

    int? rruleDayNum = dayMap[rruleDay];
    return rruleDayNum != null && date.weekday == rruleDayNum;
  }

  static DateTime _parseTimeToDateTime(DateTime date, String timeString) {
    try {
      DateFormat timeFormat = DateFormat('hh:mm a');
      DateTime parsedTime = timeFormat.parse(timeString);

      return DateTime(
        date.year,
        date.month,
        date.day,
        parsedTime.hour,
        parsedTime.minute,
      );
    } catch (e) {
      print('Error parsing time: $e');
      return date;
    }
  }

  static bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  static bool _isSameDateTime(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day &&
        date1.hour == date2.hour &&
        date1.minute == date2.minute;
  }

  static Color _getColorForActivity(int activityId) {
    List<Color> colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.amber,
      Colors.indigo,
    ];
    return colors[activityId % colors.length];
  }
}
