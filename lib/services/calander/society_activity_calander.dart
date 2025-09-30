import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:klayons/utils/colour.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

// Data models for Society Activities (updated structure)
class ActivityOverride {
  final String originalDate;
  final String action;
  final String status;
  final String remarks;
  final String? newDate;
  final String? newStartTime;
  final String? newEndTime;

  ActivityOverride({
    required this.originalDate,
    required this.action,
    required this.status,
    required this.remarks,
    this.newDate,
    this.newStartTime,
    this.newEndTime,
  });

  factory ActivityOverride.fromJson(Map<String, dynamic> json) {
    return ActivityOverride(
      originalDate: json['original_date'] ?? '',
      action: json['action'] ?? '',
      status: json['status'] ?? '',
      remarks: json['remarks'] ?? '',
      newDate: json['new_date'],
      newStartTime: json['new_start_time'],
      newEndTime: json['new_end_time'],
    );
  }

  DateTime get originalDateTime {
    try {
      return DateTime.parse(originalDate);
    } catch (e) {
      return DateTime.now();
    }
  }

  DateTime? get newDateTime {
    if (newDate == null) return null;
    try {
      return DateTime.parse(newDate!);
    } catch (e) {
      return null;
    }
  }
}

class ActivitySchedule {
  final int id;
  final String startTime;
  final String endTime;
  final List<String> rrulePatterns;
  final List<String> rdatePatterns;
  final List<String> exdatePatterns;
  final List<ActivityOverride> overrides;

  ActivitySchedule({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.rrulePatterns,
    required this.rdatePatterns,
    required this.exdatePatterns,
    required this.overrides,
  });

  factory ActivitySchedule.fromJson(Map<String, dynamic> json) {
    return ActivitySchedule(
      id: json['id'] ?? 0,
      startTime: json['start_time'] ?? '',
      endTime: json['end_time'] ?? '',
      rrulePatterns: List<String>.from(json['rrule_patterns'] ?? []),
      rdatePatterns: List<String>.from(json['rdate_patterns'] ?? []),
      exdatePatterns: List<String>.from(json['exdate_patterns'] ?? []),
      overrides:
          (json['overrides'] as List?)
              ?.map((e) => ActivityOverride.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class SocietyActivity {
  final int id;
  final String name;
  final int activityId;
  final String activityName;
  final String venue;
  final List<ActivitySchedule> schedules;

  SocietyActivity({
    required this.id,
    required this.name,
    required this.activityId,
    required this.activityName,
    required this.venue,
    required this.schedules,
  });

  factory SocietyActivity.fromJson(Map<String, dynamic> json) {
    return SocietyActivity(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      activityId: json['activity_id'] ?? 0,
      activityName: json['activity_name'] ?? '',
      venue: json['venue'] ?? '',
      schedules:
          (json['schedules'] as List?)
              ?.map((e) => ActivitySchedule.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class SocietyActivitiesResponse {
  final List<SocietyActivity> activities;

  SocietyActivitiesResponse({required this.activities});

  factory SocietyActivitiesResponse.fromJson(Map<String, dynamic> json) {
    return SocietyActivitiesResponse(
      activities:
          (json['activities'] as List?)
              ?.map((e) => SocietyActivity.fromJson(e))
              .toList() ??
          [],
    );
  }
}

// Calendar Event for activities
class ActivityCalendarEvent {
  final String id;
  final String title;
  final String venue;
  final DateTime startTime;
  final DateTime endTime;
  final Color color;
  final bool isCancelled;
  final bool isRescheduled;
  final String? cancelReason;
  final SocietyActivity originalActivity;
  final bool isFromRDate;

  ActivityCalendarEvent({
    required this.id,
    required this.title,
    required this.venue,
    required this.startTime,
    required this.endTime,
    required this.color,
    this.isCancelled = false,
    this.isRescheduled = false,
    this.cancelReason,
    required this.originalActivity,
    this.isFromRDate = false,
  });
}

// API Service for Society Activities
class SocietyActivitiesService {
  static const String baseUrl = 'https://dev-klayons.onrender.com/api';
  static const String _tokenKey = 'auth_token';

  // Cache variables
  static SocietyActivitiesResponse? _cachedActivities;
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
    if (_cachedActivities == null || _cacheTimestamp == null) {
      return false;
    }
    final now = DateTime.now();
    final cacheAge = now.difference(_cacheTimestamp!);
    return cacheAge < _cacheExpiration;
  }

  static void clearCache() {
    _cachedActivities = null;
    _cacheTimestamp = null;
    _isLoading = false;
    print('Society activities cache cleared');
  }

  // Fetch society activities from API
  static Future<SocietyActivitiesResponse> fetchSocietyActivities({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _isCacheValid()) {
      print('Returning cached society activities');
      return _cachedActivities!;
    }

    if (_isLoading) {
      print('Society activities loading in progress, waiting...');
      while (_isLoading) {
        await Future.delayed(Duration(milliseconds: 100));
      }
      return _cachedActivities ?? SocietyActivitiesResponse(activities: []);
    }

    final token = await getToken();
    if (token == null || token.isEmpty) {
      clearCache();
      throw Exception('No authentication token found. Please login first.');
    }

    try {
      _isLoading = true;
      print('Fetching society activities from server...');

      final response = await http.get(
        Uri.parse('$baseUrl/calendar/society-activities/'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Society Activities API Response Status: ${response.statusCode}');
      print('Society Activities API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          Map<String, dynamic> jsonData = json.decode(response.body);
          SocietyActivitiesResponse activitiesResponse =
              SocietyActivitiesResponse.fromJson(jsonData);

          _cachedActivities = activitiesResponse;
          _cacheTimestamp = DateTime.now();

          print(
            'Society activities fetched and cached successfully (${activitiesResponse.activities.length} activities)',
          );
          return activitiesResponse;
        } catch (parseError) {
          print('JSON parsing error: $parseError');
          print('Raw response: ${response.body}');
          throw Exception('Failed to parse server response: $parseError');
        }
      } else if (response.statusCode == 401) {
        clearCache();
        throw Exception('Authentication failed. Please login again.');
      } else {
        print('Server error response: ${response.body}');
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('Network error in fetchSocietyActivities: $e');
      if (e.toString().contains('Authentication failed') ||
          e.toString().contains('Failed to parse server response')) {
        clearCache();
        rethrow;
      }
      throw Exception(
        'Failed to load society activities. Check your connection.',
      );
    } finally {
      _isLoading = false;
    }
  }

  static SocietyActivitiesResponse? getCachedActivities() {
    if (_isCacheValid()) {
      return _cachedActivities;
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
  static List<ActivityCalendarEvent> generateCalendarEvents(
    SocietyActivitiesResponse activitiesResponse,
    DateTime startDate,
    DateTime endDate,
  ) {
    List<ActivityCalendarEvent> events = [];

    for (SocietyActivity activity in activitiesResponse.activities) {
      for (ActivitySchedule schedule in activity.schedules) {
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

        // Step 5: Process overrides and create events
        for (DateTime eventDate in allEvents) {
          if (eventDate.isAfter(startDate.subtract(Duration(days: 1))) &&
              eventDate.isBefore(endDate.add(Duration(days: 1)))) {
            // Check for overrides
            ActivityOverride? matchingOverride;
            for (ActivityOverride override in schedule.overrides) {
              if (_isSameDay(override.originalDateTime, eventDate)) {
                matchingOverride = override;
                break;
              }
            }

            if (matchingOverride != null) {
              if (matchingOverride.action == 'cancel') {
                // Create cancelled event
                DateTime endTime = _parseTimeToDateTime(
                  eventDate,
                  schedule.endTime,
                );

                events.add(
                  ActivityCalendarEvent(
                    id: '${activity.id}_${schedule.id}_${eventDate.millisecondsSinceEpoch}_cancelled',
                    title: '${activity.name} (Cancelled)',
                    venue: activity.venue,
                    startTime: eventDate,
                    endTime: endTime,
                    color: Colors.grey,
                    isCancelled: true,
                    cancelReason: matchingOverride.remarks,
                    originalActivity: activity,
                  ),
                );
              } else if (matchingOverride.action == 'reschedule' &&
                  matchingOverride.newDate != null &&
                  matchingOverride.newStartTime != null &&
                  matchingOverride.newEndTime != null) {
                // Create rescheduled event at new date/time
                DateTime? newDate = matchingOverride.newDateTime;
                if (newDate != null) {
                  DateTime rescheduledStartTime =
                      _parseTimeToDateTimeWithCustomTime(
                        newDate,
                        matchingOverride.newStartTime!,
                      );
                  DateTime rescheduledEndTime =
                      _parseTimeToDateTimeWithCustomTime(
                        newDate,
                        matchingOverride.newEndTime!,
                      );

                  events.add(
                    ActivityCalendarEvent(
                      id: '${activity.id}_${schedule.id}_${eventDate.millisecondsSinceEpoch}_rescheduled',
                      title: '${activity.name} (Rescheduled)',
                      venue: activity.venue,
                      startTime: rescheduledStartTime,
                      endTime: rescheduledEndTime,
                      color: _getColorForActivity(
                        activity.activityId,
                      ).withOpacity(0.7),
                      isRescheduled: true,
                      cancelReason: matchingOverride.remarks,
                      originalActivity: activity,
                    ),
                  );
                }
              }
            } else {
              // Normal event (no overrides)
              DateTime endTime = _parseTimeToDateTime(
                eventDate,
                schedule.endTime,
              );

              bool isFromRDate = rdateEvents.any(
                (rdate) => _isSameDateTime(rdate, eventDate),
              );

              events.add(
                ActivityCalendarEvent(
                  id: '${activity.id}_${schedule.id}_${eventDate.millisecondsSinceEpoch}',
                  title: activity.name,
                  venue: activity.venue,
                  startTime: eventDate,
                  endTime: endTime,
                  color: _getColorForActivity(activity.activityId),
                  originalActivity: activity,
                  isFromRDate: isFromRDate,
                ),
              );
            }
          }
        }
      }
    }

    // Sort events by start time
    events.sort((a, b) => a.startTime.compareTo(b.startTime));
    return events;
  }

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

  // Updated RDATE parsing to handle UTC format properly
  static List<DateTime> _parseRDatePatterns(
    List<String> rdatePatterns,
    String defaultStartTime,
  ) {
    List<DateTime> events = [];

    for (String rdatePattern in rdatePatterns) {
      try {
        DateTime parsedDate = _parseUtcDateTime(rdatePattern);
        events.add(parsedDate);
        print('Parsed RDATE: $parsedDate from $rdatePattern');
      } catch (e) {
        print('Error parsing RDATE pattern "$rdatePattern": $e');
      }
    }

    return events;
  }

  // Updated EXDATE parsing to handle UTC format properly
  static List<DateTime> _parseExDatePatterns(List<String> exdatePatterns) {
    List<DateTime> exdates = [];

    for (String exdatePattern in exdatePatterns) {
      try {
        DateTime parsedDate = _parseUtcDateTime(exdatePattern);
        exdates.add(parsedDate);
        print('Parsed EXDATE: $parsedDate from $exdatePattern');
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

  // Improved UTC datetime parsing for RFC 5545 format (YYYYMMDDTHHMMSSZ)
  static DateTime _parseUtcDateTime(String utcString) {
    try {
      // Remove Z suffix if present
      String cleaned = utcString.replaceAll('Z', '');

      if (cleaned.contains('T')) {
        List<String> parts = cleaned.split('T');
        String datePart = parts[0];
        String timePart = parts[1];

        // Parse date part (YYYYMMDD)
        int year = int.parse(datePart.substring(0, 4));
        int month = int.parse(datePart.substring(4, 6));
        int day = int.parse(datePart.substring(6, 8));

        // Parse time part (HHMMSS)
        int hour = int.parse(timePart.substring(0, 2));
        int minute = int.parse(timePart.substring(2, 4));
        int second = timePart.length >= 6
            ? int.parse(timePart.substring(4, 6))
            : 0;

        // Create UTC datetime
        DateTime utcDateTime = DateTime.utc(
          year,
          month,
          day,
          hour,
          minute,
          second,
        );

        // Convert to local time
        DateTime localDateTime = utcDateTime.toLocal();

        print('Converted UTC $utcString to local time: $localDateTime');
        return localDateTime;
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
      print('Error parsing time "$timeString": $e');
      return date;
    }
  }

  // Helper method for parsing custom time formats like "00:00:00" or "13:00:00"
  static DateTime _parseTimeToDateTimeWithCustomTime(
    DateTime date,
    String timeString,
  ) {
    try {
      // Handle HH:MM:SS format
      List<String> timeParts = timeString.split(':');
      if (timeParts.length >= 2) {
        int hour = int.parse(timeParts[0]);
        int minute = int.parse(timeParts[1]);
        int second = timeParts.length >= 3 ? int.parse(timeParts[2]) : 0;

        return DateTime(date.year, date.month, date.day, hour, minute, second);
      } else {
        // Fallback to regular time parsing
        return _parseTimeToDateTime(date, timeString);
      }
    } catch (e) {
      print('Error parsing custom time "$timeString": $e');
      return _parseTimeToDateTime(date, timeString);
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
    List<Color> colors = [AppColors.primaryOrange];
    return colors[activityId % colors.length];
  }
}
