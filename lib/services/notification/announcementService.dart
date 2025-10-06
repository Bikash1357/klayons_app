import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:klayons/services/auth/login_service.dart';
import 'modelAnnouncement.dart';

class NotificationService {
  static const String baseUrl = 'https://dev-klayons.onrender.com';
  static const String notificationFeedEndpoint = '/api/notifications/feed/';
  static const String markAsReadEndpoint = '/api/notifications/';

  // Get notification feed with pagination
  Future<NotificationFeedResponse> getNotificationFeed({
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      // Build query parameters
      Map<String, String> queryParams = {
        'page': page.toString(),
        'page_size': pageSize.toString(),
      };

      // Build URL with query parameters
      Uri url = Uri.parse(
        '$baseUrl$notificationFeedEndpoint',
      ).replace(queryParameters: queryParams);

      // Get auth token
      String? token = await LoginAuthService.getToken();

      if (token == null) {
        print('NotificationService: No authentication token found');
        throw Exception('Authentication token not found. Please login again.');
      }

      // Prepare headers
      Map<String, String> headers = {
        'Content-Type': 'application/json',
        'accept': 'application/json',
        'Authorization': 'Bearer $token',
      };

      print('NotificationService: GET $url');
      print('NotificationService: Using token: ${token.substring(0, 20)}...');

      // Make HTTP request
      final response = await http.get(url, headers: headers);

      print('NotificationService: Response status: ${response.statusCode}');
      print('NotificationService: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        // Handle both array and paginated response
        NotificationFeedResponse feedResponse;
        if (jsonData is List) {
          feedResponse = NotificationFeedResponse(
            count: jsonData.length,
            next: null,
            previous: null,
            results: jsonData
                .map((item) => NotificationItem.fromJson(item))
                .toList(),
          );
        } else {
          feedResponse = NotificationFeedResponse.fromJson(jsonData);
        }

        print(
          'NotificationService: Parsed ${feedResponse.results.length} notifications',
        );
        return feedResponse;
      } else if (response.statusCode == 401) {
        print('NotificationService: Unauthorized - token may be expired');
        throw Exception('Authentication failed. Please login again.');
      } else {
        print(
          'NotificationService: HTTP Error ${response.statusCode}: ${response.body}',
        );
        throw Exception(
          'Failed to fetch notifications: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('NotificationService Error: $e');
      rethrow;
    }
  }

  // Get all notifications (load all pages)
  Future<List<NotificationItem>> getAllNotifications() async {
    List<NotificationItem> allNotifications = [];
    int currentPage = 1;
    bool hasMorePages = true;

    while (hasMorePages) {
      try {
        final response = await getNotificationFeed(page: currentPage);
        allNotifications.addAll(response.results);

        // Check if there are more pages
        hasMorePages = response.next != null;
        currentPage++;

        print(
          'NotificationService: Loaded page $currentPage, total: ${allNotifications.length}',
        );
      } catch (e) {
        print('NotificationService: Error loading page $currentPage: $e');
        break;
      }
    }

    return allNotifications;
  }

  // Get unread notifications only
  Future<List<NotificationItem>> getUnreadNotifications({
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await getNotificationFeed(page: page, pageSize: pageSize);
    return response.results
        .where((notification) => !notification.isRead)
        .toList();
  }

  // Get notifications by type
  Future<List<NotificationItem>> getNotificationsByType(
    String type, {
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await getNotificationFeed(page: page, pageSize: pageSize);
    return response.results
        .where((notification) => notification.type == type)
        .toList();
  }

  // Mark notification as read
  Future<bool> markAsRead(int notificationId) async {
    try {
      Uri url = Uri.parse('$baseUrl$markAsReadEndpoint$notificationId/read/');

      String? token = await LoginAuthService.getToken();

      if (token == null) {
        print('NotificationService: No authentication token found');
        throw Exception('Authentication token not found. Please login again.');
      }

      Map<String, String> headers = {
        'Content-Type': 'application/json',
        'accept': 'application/json',
        'Authorization': 'Bearer $token',
      };

      print('NotificationService: POST $url (mark as read)');

      final response = await http.post(url, headers: headers);

      print('NotificationService: Mark as read status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        print(
          'NotificationService: Notification $notificationId marked as read',
        );
        return true;
      } else {
        print(
          'NotificationService: Failed to mark as read: ${response.statusCode}',
        );
        return false;
      }
    } catch (e) {
      print('NotificationService: Error marking as read: $e');
      return false;
    }
  }

  // Get unread count
  Future<int> getUnreadCount() async {
    try {
      final response = await getNotificationFeed(page: 1, pageSize: 100);
      return response.results.where((n) => !n.isRead).length;
    } catch (e) {
      print('NotificationService: Error getting unread count: $e');
      return 0;
    }
  }
}
