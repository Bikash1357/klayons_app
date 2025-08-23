class BatchWithActivity {
  final int id;
  final String name;
  final String ageRange;
  final int capacity;
  final int price;
  final String startDate;
  final String endDate;
  final bool isActive;
  final ActivityInfo activity;

  BatchWithActivity({
    required this.id,
    required this.name,
    required this.ageRange,
    required this.capacity,
    required this.price,
    required this.startDate,
    required this.endDate,
    required this.isActive,
    required this.activity,
  });

  factory BatchWithActivity.fromJson(Map<String, dynamic> json) {
    return BatchWithActivity(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      ageRange: json['age_range'] ?? '',
      capacity: json['capacity'] ?? 0,
      price: json['price'] ?? 0,
      startDate: json['start_date'] ?? '',
      endDate: json['end_date'] ?? '',
      isActive: json['is_active'] ?? false,
      activity: ActivityInfo.fromJson(json['activity'] ?? {}),
    );
  }

  String get displayName => '$name';
  String get priceDisplay => '₹$price';
}

class ActivityInfo {
  final int id;
  final String name;
  final String category;
  final String categoryDisplay;
  final String description;
  final String bannerImageUrl;
  final String societyName;
  final String instructorName;

  ActivityInfo({
    required this.id,
    required this.name,
    required this.category,
    required this.categoryDisplay,
    required this.description,
    required this.bannerImageUrl,
    required this.societyName,
    required this.instructorName,
  });

  factory ActivityInfo.fromJson(Map<String, dynamic> json) {
    return ActivityInfo(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      category: json['category'] ?? '',
      categoryDisplay: json['category_display'] ?? '',
      description: json['description'] ?? '',
      bannerImageUrl: json['banner_image_url'] ?? '',
      societyName: json['society_name'] ?? '',
      instructorName: json['instructor_name'] ?? '',
    );
  }
}
