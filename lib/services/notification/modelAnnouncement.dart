// Type alias for notification detail - reuses NotificationItem structure
typedef NotificationDetail = NotificationItem;

class NotificationFeedResponse {
  final int? count;
  final String? next;
  final String? previous;
  final List<NotificationItem> results;

  NotificationFeedResponse({
    this.count,
    this.next,
    this.previous,
    required this.results,
  });

  factory NotificationFeedResponse.fromJson(Map<String, dynamic> json) {
    // Handle both paginated and non-paginated responses
    if (json.containsKey('results')) {
      // Paginated response
      return NotificationFeedResponse(
        count: json['count'],
        next: json['next'],
        previous: json['previous'],
        results: (json['results'] as List)
            .map((item) => NotificationItem.fromJson(item))
            .toList(),
      );
    } else {
      // Non-paginated response (direct array)
      return NotificationFeedResponse(
        count: null,
        next: null,
        previous: null,
        results: (json as List)
            .map((item) => NotificationItem.fromJson(item))
            .toList(),
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'count': count,
      'next': next,
      'previous': previous,
      'results': results.map((item) => item.toJson()).toList(),
    };
  }
}

class NotificationItem {
  final int id;
  final String title;
  final String body;
  final String? attachmentUrl;
  final String? imageUrl;
  final String
  type; // 'general', 'announcement', 'payment', 'promotion', 'alert'
  final DateTime createdAt;
  final DateTime? expiresAt;
  final bool isRead;

  NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    this.attachmentUrl,
    this.imageUrl,
    required this.type,
    required this.createdAt,
    this.expiresAt,
    required this.isRead,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'],
      title: json['title'],
      body: json['body'],
      attachmentUrl: json['attachment_url'],
      imageUrl: json['image_url'],
      type: json['type'],
      createdAt: DateTime.parse(json['created_at']),
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'])
          : null,
      isRead: json['is_read'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'attachment_url': attachmentUrl,
      'image_url': imageUrl,
      'type': type,
      'created_at': createdAt.toIso8601String(),
      'expires_at': expiresAt?.toIso8601String(),
      'is_read': isRead,
    };
  }

  // Check if notification is expired
  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);

  // Check if notification is active
  bool get isActive => !isExpired;

  // Copy with method for updating isRead status
  NotificationItem copyWith({
    int? id,
    String? title,
    String? body,
    String? attachmentUrl,
    String? imageUrl,
    String? type,
    DateTime? createdAt,
    DateTime? expiresAt,
    bool? isRead,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
      imageUrl: imageUrl ?? this.imageUrl,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      isRead: isRead ?? this.isRead,
    );
  }
}
