class Announcement {
  final int id;
  final String title;
  final String content;
  final String scope;
  final List<Activity> activities;
  final List<Society> societies;
  final String? attachmentUrl;
  final DateTime expiry;
  final CreatedBy createdBy;
  final DateTime createdAt;

  Announcement({
    required this.id,
    required this.title,
    required this.content,
    required this.scope,
    required this.activities,
    required this.societies,
    this.attachmentUrl,
    required this.expiry,
    required this.createdBy,
    required this.createdAt,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      scope: json['scope'],
      activities: (json['activities'] as List)
          .map((activity) => Activity.fromJson(activity))
          .toList(),
      societies: (json['societies'] as List)
          .map((society) => Society.fromJson(society))
          .toList(),
      attachmentUrl: json['attachment_url'],
      expiry: DateTime.parse(json['expiry']),
      createdBy: CreatedBy.fromJson(json['created_by']),
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'scope': scope,
      'activities': activities.map((activity) => activity.toJson()).toList(),
      'societies': societies.map((society) => society.toJson()).toList(),
      'attachment_url': attachmentUrl,
      'expiry': expiry.toIso8601String(),
      'created_by': createdBy.toJson(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Check if announcement is expired
  bool get isExpired => DateTime.now().isAfter(expiry);

  // Check if announcement is active
  bool get isActive => !isExpired;
}

class Activity {
  final int id;
  final String name;
  final String instructor;

  Activity({required this.id, required this.name, required this.instructor});

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      id: json['id'],
      name: json['name'],
      instructor: json['instructor'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'instructor': instructor};
  }
}

class Society {
  final int id;
  final String name;

  Society({required this.id, required this.name});

  factory Society.fromJson(Map<String, dynamic> json) {
    return Society(id: json['id'], name: json['name'] ?? '');
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name};
  }
}

class CreatedBy {
  final int id;
  final String name;

  CreatedBy({required this.id, required this.name});

  factory CreatedBy.fromJson(Map<String, dynamic> json) {
    return CreatedBy(id: json['id'], name: json['name']);
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name};
  }
}
