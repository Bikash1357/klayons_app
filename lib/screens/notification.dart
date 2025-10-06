import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import '../services/notification/announcementService.dart';
import '../services/notification/modelAnnouncement.dart';
import '../utils/styles/fonts.dart';
import 'package:klayons/utils/colour.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({Key? key}) : super(key: key);

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final NotificationService _notificationService = NotificationService();
  List<NotificationItem> notifications = [];
  bool isLoading = true;
  String? errorMessage;
  int currentPage = 1;
  bool hasMorePages = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      if (!isLoading && hasMorePages) {
        _loadMoreNotifications();
      }
    }
  }

  Future<void> _loadNotifications() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
      currentPage = 1;
      notifications.clear();
    });

    try {
      final response = await _notificationService.getNotificationFeed(
        page: currentPage,
        pageSize: 20,
      );

      setState(() {
        notifications = response.results;
        hasMorePages = response.next != null;
        isLoading = false;
      });

      print('NotificationsPage: Loaded ${notifications.length} notifications');
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to load notifications';
        isLoading = false;
      });
      print('Error loading notifications: $e');
    }
  }

  Future<void> _loadMoreNotifications() async {
    if (isLoading || !hasMorePages) return;

    setState(() {
      isLoading = true;
    });

    try {
      currentPage++;
      final response = await _notificationService.getNotificationFeed(
        page: currentPage,
        pageSize: 20,
      );

      setState(() {
        notifications.addAll(response.results);
        hasMorePages = response.next != null;
        isLoading = false;
      });

      print(
        'NotificationsPage: Loaded page $currentPage, total: ${notifications.length}',
      );
    } catch (e) {
      setState(() {
        isLoading = false;
        currentPage--; // Revert page number on error
      });
      print('Error loading more notifications: $e');
    }
  }

  Future<void> _handleNotificationTap(NotificationItem notification) async {
    if (!notification.isRead) {
      // Mark as read
      await _notificationService.markAsRead(notification.id);

      // Update local state
      setState(() {
        int index = notifications.indexWhere((n) => n.id == notification.id);
        if (index != -1) {
          notifications[index] = notification.copyWith(isRead: true);
        }
      });
    }

    // Show notification details
    _showNotificationDetails(notification);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: SvgPicture.asset(
            'assets/App_icons/iconBack.svg',
            width: 24,
            height: 24,
            colorFilter: ColorFilter.mode(
              AppColors.darkElements,
              BlendMode.srcIn,
            ),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Notifications',
          style: AppTextStyles.titleMedium(context).copyWith(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
      ),
      body: RefreshIndicator(
        onRefresh: _loadNotifications,
        color: AppColors.primaryOrange,
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    if (isLoading && notifications.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFFF6B35)),
      );
    }

    if (errorMessage != null && notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              errorMessage!,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium(
                context,
              ).copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadNotifications,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B35),
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_none, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No notifications available',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium(
                context,
              ).copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: notifications.length + (hasMorePages ? 1 : 0),
      separatorBuilder: (context, index) => const SizedBox(height: 0),
      itemBuilder: (context, index) {
        if (index == notifications.length) {
          // Loading indicator at bottom
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: isLoading
                  ? const CircularProgressIndicator(color: Color(0xFFFF6B35))
                  : const SizedBox.shrink(),
            ),
          );
        }

        final notification = notifications[index];
        return _buildNotificationCard(notification);
      },
    );
  }

  Widget _buildNotificationCard(NotificationItem notification) {
    return InkWell(
      onTap: () => _handleNotificationTap(notification),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: notification.isRead ? Colors.white : Colors.orange.shade50,
          border: Border(
            bottom: BorderSide(color: Colors.grey.shade200, width: 1),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Red/Orange dot indicator for unread
            Container(
              margin: const EdgeInsets.only(right: 12, top: 4),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: notification.isRead
                    ? Colors.transparent
                    : _getTypeColor(notification.type),
                shape: BoxShape.circle,
              ),
            ),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title row with time
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: AppTextStyles.bodyMedium(context).copyWith(
                            fontWeight: notification.isRead
                                ? FontWeight.w500
                                : FontWeight.w600,
                            color: Colors.black87,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatTimeAgo(notification.createdAt),
                        style: AppTextStyles.bodySmall(
                          context,
                        ).copyWith(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Body text
                  Text(
                    _stripHtmlTags(notification.body),
                    style: AppTextStyles.bodySmall(context).copyWith(
                      color: Colors.grey[700],
                      fontSize: 13,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showNotificationDetails(NotificationItem notification) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getTypeColor(notification.type).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      notification.type.toUpperCase(),
                      style: AppTextStyles.bodySmall(context).copyWith(
                        color: _getTypeColor(notification.type),
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _formatFullDate(notification.createdAt),
                    style: AppTextStyles.bodySmall(
                      context,
                    ).copyWith(color: Colors.grey[600], fontSize: 12),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      notification.title,
                      style: AppTextStyles.titleLarge(context).copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Body (strip HTML tags for display)
                    Text(
                      _stripHtmlTags(notification.body),
                      style: AppTextStyles.bodyMedium(context).copyWith(
                        color: Colors.grey[800],
                        height: 1.6,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Image if available
                    if (notification.imageUrl != null) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          notification.imageUrl!,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 200,
                              color: Colors.grey[200],
                              child: Center(
                                child: Icon(
                                  Icons.broken_image,
                                  size: 48,
                                  color: Colors.grey[400],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Attachment button if available
                    if (notification.attachmentUrl != null) ...[
                      ElevatedButton.icon(
                        onPressed: () =>
                            _openAttachment(notification.attachmentUrl!),
                        icon: const Icon(Icons.attachment, size: 18),
                        label: const Text('View Attachment'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF6B35),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Expiry info if available
                    if (notification.expiresAt != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.schedule,
                              size: 16,
                              color: Colors.orange[700],
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Expires on ${_formatFullDate(notification.expiresAt!)}',
                              style: AppTextStyles.bodySmall(context).copyWith(
                                color: Colors.orange[700],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'payment':
        return Colors.red;
      case 'promotion':
        return Colors.green;
      case 'alert':
        return Colors.red.shade700;
      case 'announcement':
        return Colors.blue;
      case 'general':
      default:
        return const Color(0xFFFF6B35);
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()}w';
    } else if (difference.inDays < 365) {
      return '${(difference.inDays / 30).floor()}mo';
    } else {
      return '${(difference.inDays / 365).floor()}y';
    }
  }

  String _formatFullDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _stripHtmlTags(String htmlText) {
    // Remove HTML tags for plain text display
    final RegExp exp = RegExp(r'<[^>]*>', multiLine: true, caseSensitive: true);
    return htmlText.replaceAll(exp, '').trim();
  }

  void _openAttachment(String attachmentUrl) {
    // Implement attachment opening logic
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening attachment: $attachmentUrl'),
        backgroundColor: const Color(0xFFFF6B35),
      ),
    );
  }
}
