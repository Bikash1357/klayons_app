import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

// Data models for Children Calendar
class ChildCalendarOverride {
  final String originalDate;
  final String action;
  final String status;
  final String remarks;
  final String? newDate;
  final String? newStartTime;
  final String? newEndTime;

  ChildCalendarOverride({
    required this.originalDate,
    required this.action,
    required this.status,
    required this.remarks,
    this.newDate,
    this.newStartTime,
    this.newEndTime,
  });

  factory ChildCalendarOverride.fromJson(Map<String, dynamic> json) {
    return ChildCalendarOverride(
      originalDate: json['original_date'],
      action: json['action'],
      status: json['status'],
      remarks: json['remarks'] ?? '',
      newDate: json['new_date'],
      newStartTime: json['new_start_time'],
      newEndTime: json['new_end_time'],
    );
  }

  DateTime get originalDateTime => DateTime.parse(originalDate);

  DateTime? get newDateTime {
    if (newDate == null) return null;
    try {
      return DateTime.parse(newDate!);
    } catch (e) {
      return null;
    }
  }
}

class ChildCalendarSchedule {
  final int id;
  final String startTime;
  final String endTime;
  final List<String> rrulePatterns;
  final List<String> rdatePatterns;
  final List<String> exdatePatterns;
  final List<ChildCalendarOverride> overrides;

  ChildCalendarSchedule({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.rrulePatterns,
    required this.rdatePatterns,
    required this.exdatePatterns,
    required this.overrides,
  });

  factory ChildCalendarSchedule.fromJson(Map<String, dynamic> json) {
    return ChildCalendarSchedule(
      id: json['id'],
      startTime: json['start_time'],
      endTime: json['end_time'],
      rrulePatterns: List<String>.from(json['rrule_patterns'] ?? []),
      rdatePatterns: List<String>.from(json['rdate_patterns'] ?? []),
      exdatePatterns: List<String>.from(json['exdate_patterns'] ?? []),
      overrides:
          (json['overrides'] as List?)
              ?.map((e) => ChildCalendarOverride.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class ChildEnrolledActivity {
  final int id;
  final String name;
  final String batchName;
  final String venue;
  final List<ChildCalendarSchedule> schedules;

  ChildEnrolledActivity({
    required this.id,
    required this.name,
    required this.batchName,
    required this.venue,
    required this.schedules,
  });

  factory ChildEnrolledActivity.fromJson(Map<String, dynamic> json) {
    return ChildEnrolledActivity(
      id: json['id'],
      name: json['name'],
      batchName: json['batch_name'],
      venue: json['venue'],
      schedules: (json['schedules'] as List)
          .map((e) => ChildCalendarSchedule.fromJson(e))
          .toList(),
    );
  }
}

// Recurrence rule model for custom activities
class ChildCustomRecurrence {
  final String type;
  final int interval;
  final List<int> daysOfWeek;
  final String endRule;
  final DateTime? endDate;
  final int? occurrences;

  ChildCustomRecurrence({
    required this.type,
    required this.interval,
    required this.daysOfWeek,
    required this.endRule,
    this.endDate,
    this.occurrences,
  });

  factory ChildCustomRecurrence.fromJson(Map<String, dynamic> json) {
    return ChildCustomRecurrence(
      type: json['type'],
      interval: json['interval'],
      daysOfWeek: List<int>.from(json['daysOfWeek'] ?? []),
      endRule: json['endRule'],
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      occurrences: json['occurrences'],
    );
  }
}

class ChildCustomActivity {
  final int id;
  final String title;
  final String address;
  final DateTime startTime;
  final DateTime endTime;
  final String childName;
  final String color;
  final ChildCustomRecurrence? recurrence;
  final DateTime createdAt;
  final DateTime updatedAt;

  ChildCustomActivity({
    required this.id,
    required this.title,
    required this.address,
    required this.startTime,
    required this.endTime,
    required this.childName,
    required this.color,
    this.recurrence,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ChildCustomActivity.fromJson(Map<String, dynamic> json) {
    return ChildCustomActivity(
      id: json['id'],
      title: json['title'],
      address: json['address'],
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
      childName: json['childName'],
      color: json['color'],
      recurrence: json['recurrence'] != null
          ? ChildCustomRecurrence.fromJson(json['recurrence'])
          : null,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}

class ChildCalendarData {
  final int id;
  final String name;
  final List<ChildEnrolledActivity> enrolledActivities;
  final List<ChildCustomActivity> customActivities;

  ChildCalendarData({
    required this.id,
    required this.name,
    required this.enrolledActivities,
    required this.customActivities,
  });

  factory ChildCalendarData.fromJson(Map<String, dynamic> json) {
    return ChildCalendarData(
      id: json['id'],
      name: json['name'],
      enrolledActivities: (json['enrolledActivities'] as List)
          .map((e) => ChildEnrolledActivity.fromJson(e))
          .toList(),
      customActivities: (json['customActivities'] as List)
          .map((e) => ChildCustomActivity.fromJson(e))
          .toList(),
    );
  }
}

class ChildrenCalendarResponse {
  final List<ChildCalendarData> children;

  ChildrenCalendarResponse({required this.children});

  factory ChildrenCalendarResponse.fromJson(Map<String, dynamic> json) {
    return ChildrenCalendarResponse(
      children: (json['children'] as List)
          .map((e) => ChildCalendarData.fromJson(e))
          .toList(),
    );
  }
}

// Calendar Event for children's activities (both enrolled and custom)
class ChildCalendarEvent {
  final String id;
  final String title;
  final String venue;
  final DateTime startTime;
  final DateTime endTime;
  final Color color;
  final bool isCancelled;
  final bool isRescheduled;
  final String? cancelReason;
  final int childId;
  final String childName;
  final bool isCustomActivity;
  final bool isFromRDate;
  final dynamic
  originalActivity; // Can be ChildEnrolledActivity or ChildCustomActivity

  ChildCalendarEvent({
    required this.id,
    required this.title,
    required this.venue,
    required this.startTime,
    required this.endTime,
    required this.color,
    this.isCancelled = false,
    this.isRescheduled = false,
    this.cancelReason,
    required this.childId,
    required this.childName,
    this.isCustomActivity = false,
    this.isFromRDate = false,
    this.originalActivity,
  });
}

// API Service for Children Calendar
class ChildrenCalendarService {
  static const String baseUrl = 'https://dev-klayonsapi.vercel.app/api';
  static const String _tokenKey = 'auth_token';

  // Cache variables
  static Map<String, ChildrenCalendarResponse> _cachedChildrenCalendar = {};
  static Map<String, DateTime> _cacheTimestamps = {};
  static Set<String> _loadingChildIds = {};
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

  static bool _isCacheValid(String childIds) {
    if (!_cachedChildrenCalendar.containsKey(childIds) ||
        !_cacheTimestamps.containsKey(childIds)) {
      return false;
    }
    final now = DateTime.now();
    final cacheAge = now.difference(_cacheTimestamps[childIds]!);
    return cacheAge < _cacheExpiration;
  }

  static void clearCache() {
    _cachedChildrenCalendar.clear();
    _cacheTimestamps.clear();
    _loadingChildIds.clear();
    print('Children calendar cache cleared');
  }

  static void clearCacheForChildIds(Set<int> childIds) {
    List<int> sortedIds = childIds.toList();
    sortedIds.sort();
    String childIdsKey = sortedIds.join(',');

    _cachedChildrenCalendar.remove(childIdsKey);
    _cacheTimestamps.remove(childIdsKey);
    _loadingChildIds.remove(childIdsKey);
    print('Children calendar cache cleared for child IDs: $childIdsKey');
  }

  // Fetch children calendar from API
  static Future<ChildrenCalendarResponse> fetchChildrenCalendar(
    Set<int> childIds, {
    bool forceRefresh = false,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (childIds.isEmpty) {
      return ChildrenCalendarResponse(children: []);
    }

    List<int> sortedIds = childIds.toList();
    sortedIds.sort();
    String childIdsKey = sortedIds.join(',');

    if (!forceRefresh && _isCacheValid(childIdsKey)) {
      print('Returning cached children calendar for: $childIdsKey');
      return _cachedChildrenCalendar[childIdsKey]!;
    }

    if (_loadingChildIds.contains(childIdsKey)) {
      print(
        'Children calendar loading in progress for $childIdsKey, waiting...',
      );
      while (_loadingChildIds.contains(childIdsKey)) {
        await Future.delayed(Duration(milliseconds: 100));
      }
      return _cachedChildrenCalendar[childIdsKey] ??
          ChildrenCalendarResponse(children: []);
    }

    final token = await getToken();
    if (token == null || token.isEmpty) {
      clearCache();
      throw Exception('No authentication token found. Please login first.');
    }

    try {
      _loadingChildIds.add(childIdsKey);
      print(
        'Fetching children calendar from server for child IDs: $childIdsKey',
      );

      // Build query parameters
      Map<String, String> queryParams = {'child_ids': childIdsKey};
      if (startDate != null) {
        queryParams['startDate'] = startDate.toIso8601String();
      }
      if (endDate != null) {
        queryParams['endDate'] = endDate.toIso8601String();
      }

      Uri uri = Uri.parse(
        '$baseUrl/calendar/children/',
      ).replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Children Calendar API Response Status: ${response.statusCode}');
      print('Children Calendar API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        Map<String, dynamic> jsonData = json.decode(response.body);
        ChildrenCalendarResponse calendarResponse =
            ChildrenCalendarResponse.fromJson(jsonData);

        _cachedChildrenCalendar[childIdsKey] = calendarResponse;
        _cacheTimestamps[childIdsKey] = DateTime.now();

        print(
          'Children calendar fetched and cached successfully for ${calendarResponse.children.length} children',
        );
        return calendarResponse;
      } else if (response.statusCode == 401) {
        clearCache();
        throw Exception('Authentication failed. Please login again.');
      } else if (response.statusCode == 400) {
        throw Exception('Invalid child IDs provided.');
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('Network error in fetchChildrenCalendar: $e');
      if (e.toString().contains('Authentication failed')) {
        clearCache();
        rethrow;
      }
      throw Exception(
        'Failed to load children calendar. Check your connection.',
      );
    } finally {
      _loadingChildIds.remove(childIdsKey);
    }
  }

  static ChildrenCalendarResponse? getCachedChildrenCalendar(
    Set<int> childIds,
  ) {
    if (childIds.isEmpty) return ChildrenCalendarResponse(children: []);

    List<int> sortedIds = childIds.toList();
    sortedIds.sort();
    String childIdsKey = sortedIds.join(',');

    if (_isCacheValid(childIdsKey)) {
      return _cachedChildrenCalendar[childIdsKey];
    }
    return null;
  }

  static bool isLoading(Set<int> childIds) {
    List<int> sortedIds = childIds.toList();
    sortedIds.sort();
    String childIdsKey = sortedIds.join(',');

    return _loadingChildIds.contains(childIdsKey);
  }

  static int getCacheAgeInMinutes(Set<int> childIds) {
    List<int> sortedIds = childIds.toList();
    sortedIds.sort();
    String childIdsKey = sortedIds.join(',');

    if (!_cacheTimestamps.containsKey(childIdsKey)) return -1;
    final now = DateTime.now();
    final cacheAge = now.difference(_cacheTimestamps[childIdsKey]!);
    return cacheAge.inMinutes;
  }

  // Generate calendar events from children calendar data
  static List<ChildCalendarEvent> generateChildrenCalendarEvents(
    ChildrenCalendarResponse calendarResponse,
    DateTime startDate,
    DateTime endDate,
  ) {
    List<ChildCalendarEvent> events = [];

    for (ChildCalendarData childData in calendarResponse.children) {
      // Process enrolled activities
      for (ChildEnrolledActivity enrolledActivity
          in childData.enrolledActivities) {
        for (ChildCalendarSchedule schedule in enrolledActivity.schedules) {
          List<ChildCalendarEvent> enrolledEvents =
              _processEnrolledActivitySchedule(
                childData,
                enrolledActivity,
                schedule,
                startDate,
                endDate,
              );
          events.addAll(enrolledEvents);
        }
      }

      // Process custom activities
      for (ChildCustomActivity customActivity in childData.customActivities) {
        List<ChildCalendarEvent> customEvents = _processCustomActivity(
          childData,
          customActivity,
          startDate,
          endDate,
        );
        events.addAll(customEvents);
      }
    }

    // Sort events by start time
    events.sort((a, b) => a.startTime.compareTo(b.startTime));
    return events;
  }

  static List<ChildCalendarEvent> _processEnrolledActivitySchedule(
    ChildCalendarData childData,
    ChildEnrolledActivity enrolledActivity,
    ChildCalendarSchedule schedule,
    DateTime startDate,
    DateTime endDate,
  ) {
    List<ChildCalendarEvent> events = [];

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
    List<DateTime> rdateEvents = _parseRDatePatterns(schedule.rdatePatterns);

    // Step 3: Combine all events
    List<DateTime> allEvents = [...rruleEvents, ...rdateEvents];

    // Step 4: Remove EXDATE events
    List<DateTime> exdates = _parseExDatePatterns(schedule.exdatePatterns);
    allEvents = _filterExdates(allEvents, exdates);

    // Step 5: Apply overrides and create calendar events
    for (DateTime eventDate in allEvents) {
      if (eventDate.isAfter(startDate.subtract(Duration(days: 1))) &&
          eventDate.isBefore(endDate.add(Duration(days: 1)))) {
        ChildCalendarOverride? matchingOverride;
        for (ChildCalendarOverride override in schedule.overrides) {
          if (_isSameDay(override.originalDateTime, eventDate)) {
            matchingOverride = override;
            break;
          }
        }

        if (matchingOverride != null) {
          if (matchingOverride.action == 'cancel') {
            DateTime endTime = _parseTimeToDateTime(
              eventDate,
              schedule.endTime,
            );

            events.add(
              ChildCalendarEvent(
                id: '${childData.id}_enrolled_${enrolledActivity.id}_${schedule.id}_${eventDate.millisecondsSinceEpoch}_cancelled',
                title: '${enrolledActivity.name} (Cancelled)',
                venue: enrolledActivity.venue,
                startTime: eventDate,
                endTime: endTime,
                color: Colors.grey,
                isCancelled: true,
                cancelReason: matchingOverride.remarks,
                childId: childData.id,
                childName: childData.name,
                originalActivity: enrolledActivity,
              ),
            );
          } else if (matchingOverride.action == 'reschedule' &&
              matchingOverride.newDate != null) {
            DateTime? newDate = matchingOverride.newDateTime;
            if (newDate != null) {
              DateTime rescheduledStartTime =
                  matchingOverride.newStartTime != null
                  ? _parseTimeToDateTimeWithCustomTime(
                      newDate,
                      matchingOverride.newStartTime!,
                    )
                  : _parseTimeToDateTime(newDate, schedule.startTime);
              DateTime rescheduledEndTime = matchingOverride.newEndTime != null
                  ? _parseTimeToDateTimeWithCustomTime(
                      newDate,
                      matchingOverride.newEndTime!,
                    )
                  : _parseTimeToDateTime(newDate, schedule.endTime);

              events.add(
                ChildCalendarEvent(
                  id: '${childData.id}_enrolled_${enrolledActivity.id}_${schedule.id}_${eventDate.millisecondsSinceEpoch}_rescheduled',
                  title: '${enrolledActivity.name} (Rescheduled)',
                  venue: enrolledActivity.venue,
                  startTime: rescheduledStartTime,
                  endTime: rescheduledEndTime,
                  color: _getColorForActivity(
                    enrolledActivity.id,
                  ).withOpacity(0.7),
                  isRescheduled: true,
                  cancelReason: matchingOverride.remarks,
                  childId: childData.id,
                  childName: childData.name,
                  originalActivity: enrolledActivity,
                ),
              );
            }
          }
        } else {
          DateTime endTime = _parseTimeToDateTime(eventDate, schedule.endTime);
          bool isFromRDate = rdateEvents.any(
            (rdate) => _isSameDateTime(rdate, eventDate),
          );

          events.add(
            ChildCalendarEvent(
              id: '${childData.id}_enrolled_${enrolledActivity.id}_${schedule.id}_${eventDate.millisecondsSinceEpoch}',
              title: enrolledActivity.name,
              venue: enrolledActivity.venue,
              startTime: eventDate,
              endTime: endTime,
              color: _getColorForActivity(enrolledActivity.id),
              childId: childData.id,
              childName: childData.name,
              originalActivity: enrolledActivity,
              isFromRDate: isFromRDate,
            ),
          );
        }
      }
    }

    return events;
  }

  static List<ChildCalendarEvent> _processCustomActivity(
    ChildCalendarData childData,
    ChildCustomActivity customActivity,
    DateTime startDate,
    DateTime endDate,
  ) {
    List<ChildCalendarEvent> events = [];

    if (customActivity.recurrence != null) {
      // Process recurring custom activity
      List<DateTime> recurringDates = _generateCustomRecurringDates(
        customActivity,
        startDate,
        endDate,
      );

      for (DateTime eventDate in recurringDates) {
        if (eventDate.isAfter(startDate.subtract(Duration(days: 1))) &&
            eventDate.isBefore(endDate.add(Duration(days: 1)))) {
          // Calculate event duration
          Duration duration = customActivity.endTime.difference(
            customActivity.startTime,
          );
          DateTime eventEndTime = eventDate.add(duration);

          Color activityColor = _hexToColor(customActivity.color);

          events.add(
            ChildCalendarEvent(
              id: '${childData.id}_custom_${customActivity.id}_${eventDate.millisecondsSinceEpoch}',
              title: customActivity.title,
              venue: customActivity.address,
              startTime: eventDate,
              endTime: eventEndTime,
              color: activityColor,
              childId: childData.id,
              childName: childData.name,
              isCustomActivity: true,
              originalActivity: customActivity,
            ),
          );
        }
      }
    } else {
      // Single occurrence custom activity
      if (customActivity.startTime.isAfter(
            startDate.subtract(Duration(days: 1)),
          ) &&
          customActivity.startTime.isBefore(endDate.add(Duration(days: 1)))) {
        Color activityColor = _hexToColor(customActivity.color);

        events.add(
          ChildCalendarEvent(
            id: '${childData.id}_custom_${customActivity.id}_single',
            title: customActivity.title,
            venue: customActivity.address,
            startTime: customActivity.startTime,
            endTime: customActivity.endTime,
            color: activityColor,
            childId: childData.id,
            childName: childData.name,
            isCustomActivity: true,
            originalActivity: customActivity,
          ),
        );
      }
    }

    return events;
  }

  static List<DateTime> _generateCustomRecurringDates(
    ChildCustomActivity customActivity,
    DateTime startDate,
    DateTime endDate,
  ) {
    List<DateTime> dates = [];
    ChildCustomRecurrence recurrence = customActivity.recurrence!;

    DateTime current = customActivity.startTime;
    DateTime rangeEnd = endDate;

    if (recurrence.endRule == 'onDate' && recurrence.endDate != null) {
      rangeEnd = recurrence.endDate!.isBefore(endDate)
          ? recurrence.endDate!
          : endDate;
    }

    int count = 0;
    int maxOccurrences = recurrence.occurrences ?? 1000;

    while (current.isBefore(rangeEnd.add(Duration(days: 1))) &&
        count < maxOccurrences) {
      bool shouldInclude = false;

      switch (recurrence.type.toLowerCase()) {
        case 'daily':
          shouldInclude = true;
          break;
        case 'weekly':
          if (recurrence.daysOfWeek.contains(current.weekday)) {
            shouldInclude = true;
          }
          break;
        case 'monthly':
        case 'yearly':
          shouldInclude = true;
          break;
      }

      if (shouldInclude &&
          current.isAfter(startDate.subtract(Duration(days: 1)))) {
        dates.add(current);
        count++;
      }

      // Move to next occurrence
      switch (recurrence.type.toLowerCase()) {
        case 'daily':
          current = current.add(Duration(days: recurrence.interval));
          break;
        case 'weekly':
          current = current.add(Duration(days: 1));
          break;
        case 'monthly':
          current = DateTime(
            current.year,
            current.month + recurrence.interval,
            current.day,
            current.hour,
            current.minute,
          );
          break;
        case 'yearly':
          current = DateTime(
            current.year + recurrence.interval,
            current.month,
            current.day,
            current.hour,
            current.minute,
          );
          break;
      }
    }

    return dates;
  }

  // Helper method to convert hex string to Color
  static Color _hexToColor(String hexString) {
    String hex = hexString.replaceFirst('#', '');
    if (hex.length == 6) {
      hex = 'FF$hex'; // Add full opacity
    }
    return Color(int.parse(hex, radix: 16));
  }

  // Helper method for parsing custom time formats
  static DateTime _parseTimeToDateTimeWithCustomTime(
    DateTime date,
    String timeString,
  ) {
    try {
      List<String> timeParts = timeString.split(':');
      if (timeParts.length >= 2) {
        int hour = int.parse(timeParts[0]);
        int minute = int.parse(timeParts[1]);
        int second = timeParts.length >= 3 ? int.parse(timeParts[2]) : 0;

        return DateTime(date.year, date.month, date.day, hour, minute, second);
      } else {
        return _parseTimeToDateTime(date, timeString);
      }
    } catch (e) {
      print('Error parsing custom time "$timeString": $e');
      return _parseTimeToDateTime(date, timeString);
    }
  }

  // Keep all existing helper methods unchanged
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

      DateTime templateTime = _parseTimeToDateTime(rangeStart, startTime);
      DateTime current = DateTime(
        rangeStart.year,
        rangeStart.month,
        rangeStart.day,
        templateTime.hour,
        templateTime.minute,
      );
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

        switch (freq) {
          case 'DAILY':
            current = current.add(Duration(days: interval));
            break;
          case 'WEEKLY':
            current = current.add(Duration(days: 1));
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

  static List<DateTime> _parseRDatePatterns(List<String> rdatePatterns) {
    List<DateTime> events = [];
    for (String rdatePattern in rdatePatterns) {
      try {
        DateTime parsedDate = _parseUtcDateTime(rdatePattern);
        events.add(parsedDate);
      } catch (e) {
        print('Error parsing RDATE pattern "$rdatePattern": $e');
      }
    }
    return events;
  }

  static List<DateTime> _parseExDatePatterns(List<String> exdatePatterns) {
    List<DateTime> exdates = [];
    for (String exdatePattern in exdatePatterns) {
      try {
        DateTime parsedDate = _parseUtcDateTime(exdatePattern);
        exdates.add(parsedDate);
      } catch (e) {
        print('Error parsing EXDATE pattern "$exdatePattern": $e');
      }
    }
    return exdates;
  }

  static List<DateTime> _filterExdates(
    List<DateTime> events,
    List<DateTime> exdates,
  ) {
    return events.where((event) {
      return !exdates.any((exdate) => _isSameDateTime(event, exdate));
    }).toList();
  }

  static DateTime _parseUtcDateTime(String utcString) {
    try {
      String cleaned = utcString.replaceAll('Z', '');

      if (cleaned.contains('T')) {
        List<String> parts = cleaned.split('T');
        String datePart = parts[0];
        String timePart = parts[1];

        int year = int.parse(datePart.substring(0, 4));
        int month = int.parse(datePart.substring(4, 6));
        int day = int.parse(datePart.substring(6, 8));

        int hour = int.parse(timePart.substring(0, 2));
        int minute = int.parse(timePart.substring(2, 4));
        int second = timePart.length >= 6
            ? int.parse(timePart.substring(4, 6))
            : 0;

        DateTime utcDateTime = DateTime.utc(
          year,
          month,
          day,
          hour,
          minute,
          second,
        );
        return utcDateTime.toLocal();
      } else {
        throw FormatException('Invalid UTC datetime format: $utcString');
      }
    } catch (e) {
      print('Error parsing UTC datetime "$utcString": $e');
      return DateTime.now();
    }
  }

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
