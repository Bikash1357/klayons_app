class Batch {
  final int id;
  final String name;
  final String ageRange;
  final int capacity;
  final String startDate;
  final String endDate;
  final List<Schedule> schedules;
  final bool isActive;

  Batch({
    required this.id,
    required this.name,
    required this.ageRange,
    required this.capacity,
    required this.startDate,
    required this.endDate,
    required this.schedules,
    required this.isActive,
  });

  factory Batch.fromJson(Map<String, dynamic> json) {
    try {
      print('🔍 Parsing batch JSON: $json');

      var schedulesFromJson = json['schedules'] as List? ?? [];
      List<Schedule> scheduleList = [];

      for (var scheduleJson in schedulesFromJson) {
        try {
          scheduleList.add(
            Schedule.fromJson(scheduleJson as Map<String, dynamic>),
          );
        } catch (e) {
          print('❌ Error parsing schedule: $e');
          print('📄 Schedule data: $scheduleJson');
        }
      }

      return Batch(
        id: json['id'] ?? 0,
        name: json['name'] ?? 'Unknown Batch',
        ageRange: json['age_range'] ?? 'All Ages',
        capacity: json['capacity'] ?? 0,
        startDate: json['start_date'] ?? '',
        endDate: json['end_date'] ?? '',
        schedules: scheduleList,
        isActive: json['is_active'] ?? false,
      );
    } catch (e) {
      print('❌ Error in Batch.fromJson: $e');
      print('📄 JSON data: $json');
      rethrow;
    }
  }
}

class Schedule {
  final int id;
  final String startTimeDisplay;
  final String endTimeDisplay;
  final String nextOccurrences;
  final bool isActive;

  Schedule({
    required this.id,
    required this.startTimeDisplay,
    required this.endTimeDisplay,
    required this.nextOccurrences,
    required this.isActive,
  });

  factory Schedule.fromJson(Map<String, dynamic> json) {
    try {
      return Schedule(
        id: json['id'] ?? 0,
        startTimeDisplay: json['start_time_display'] ?? '',
        endTimeDisplay: json['end_time_display'] ?? '',
        nextOccurrences: json['next_occurrences'] ?? '',
        isActive: json['is_active'] ?? false,
      );
    } catch (e) {
      print('❌ Error in Schedule.fromJson: $e');
      print('📄 JSON data: $json');
      rethrow;
    }
  }
}
