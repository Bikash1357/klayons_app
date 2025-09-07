import 'package:flutter/material.dart';
import '../utils/styles/fonts.dart';
import 'package:klayons/utils/colour.dart';

import '../services/notification/notification_service.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({Key? key}) : super(key: key);

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  List<AnnouncementModel> announcements = [];
  bool isLoading = true;
  String? errorMessage;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadAnnouncements();
  }

  Future<void> _loadAnnouncements() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final data = await NotificationService.getAnnouncements(
        search: searchQuery.isNotEmpty ? searchQuery : null,
      );

      setState(() {
        announcements = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  Future<void> _searchAnnouncements(String query) async {
    setState(() {
      searchQuery = query;
    });
    await _loadAnnouncements();
  }

  Future<void> _refreshAnnouncements() async {
    await _loadAnnouncements();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Colors.black87,
            size: 20,
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
      body: Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (value) {
                // Debounce search to avoid too many API calls
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (value == searchQuery) return;
                  _searchAnnouncements(value);
                });
              },
              decoration: InputDecoration(
                hintText: 'Search notifications...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),

          // Content
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6B35)),
        ),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Failed to load notifications',
              style: AppTextStyles.titleMedium(context).copyWith(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage!,
              textAlign: TextAlign.center,
              style: AppTextStyles.titleSmall(
                context,
              ).copyWith(color: Colors.grey[500]),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _refreshAnnouncements,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B35),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (announcements.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_none, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No notifications found',
              style: AppTextStyles.titleMedium(context).copyWith(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Check back later for new announcements',
              style: AppTextStyles.titleSmall(
                context,
              ).copyWith(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshAnnouncements,
      color: const Color(0xFFFF6B35),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: announcements.length,
        itemBuilder: (context, index) {
          final announcement = announcements[index];
          return _buildNotificationItem(announcement);
        },
      ),
    );
  }

  Widget _buildNotificationItem(AnnouncementModel announcement) {
    return Container(
      margin: const EdgeInsets.only(bottom: 1),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE5E5E5), width: 0.5),
        ),
      ),
      child: InkWell(
        onTap: () {
          _handleNotificationTap(announcement);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Unread indicator dot
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: announcement.isUnread
                          ? const Color(0xFFFF6B35)
                          : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                  ),

                  // Notification title
                  Expanded(
                    child: Text(
                      announcement.title,
                      style: AppTextStyles.titleMedium(context).copyWith(
                        color: Colors.black87,
                        fontWeight: announcement.isUnread
                            ? FontWeight.w500
                            : FontWeight.w400,
                      ),
                    ),
                  ),

                  // Scope badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getScopeColor(
                        announcement.scope,
                      ).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      announcement.scope,
                      style: AppTextStyles.bodySmall(context).copyWith(
                        fontSize: 10,
                        color: _getScopeColor(announcement.scope),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Time ago
                  Text(
                    announcement.getTimeAgo(),
                    style: AppTextStyles.titleSmall(context).copyWith(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),

              // Content preview (if available)
              if (announcement.content.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  announcement.content,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.titleSmall(
                    context,
                  ).copyWith(color: Colors.grey[600], height: 1.3),
                ),
              ],

              // Activity/Society name (if available)
              if (announcement.activityName != null ||
                  announcement.societyName != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      announcement.activityName != null
                          ? Icons.event
                          : Icons.group,
                      size: 14,
                      color: Colors.grey[500],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      announcement.activityName ??
                          announcement.societyName ??
                          '',
                      style: AppTextStyles.bodySmall(context).copyWith(
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getScopeColor(String scope) {
    switch (scope) {
      case 'ACTIVITY':
        return const Color(0xFF4CAF50);
      case 'BATCH':
        return const Color(0xFF2196F3);
      case 'SOCIETY':
        return const Color(0xFF9C27B0);
      case 'GENERAL':
      default:
        return const Color(0xFFFF6B35);
    }
  }

  void _handleNotificationTap(AnnouncementModel announcement) {
    _showAnnouncementDialog(announcement);
  }

  void _showAnnouncementDialog(AnnouncementModel announcement) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Row(
            children: [
              Icon(
                _getScopeIcon(announcement.scope),
                color: _getScopeColor(announcement.scope),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  announcement.title,
                  style: AppTextStyles.titleMedium(context),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Content
                Text(announcement.content),

                const SizedBox(height: 16),

                // Additional info
                if (announcement.activityName != null) ...[
                  _buildInfoRow('Activity', announcement.activityName!),
                  const SizedBox(height: 8),
                ],
                if (announcement.societyName != null) ...[
                  _buildInfoRow('Society', announcement.societyName!),
                  const SizedBox(height: 8),
                ],
                if (announcement.batchNames != null &&
                    announcement.batchNames!.isNotEmpty) ...[
                  _buildInfoRow('Batches', announcement.batchNames!.join(', ')),
                  const SizedBox(height: 8),
                ],
                if (announcement.expiry != null) ...[
                  _buildInfoRow('Expires', _formatDate(announcement.expiry!)),
                  const SizedBox(height: 8),
                ],
                _buildInfoRow('Posted', _formatDate(announcement.createdAt)),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            if (announcement.attachment != null)
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // Handle attachment opening
                  _openAttachment(announcement.attachment!);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _getScopeColor(announcement.scope),
                ),
                child: const Text('View Attachment'),
              ),
          ],
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            '$label:',
            style: AppTextStyles.bodySmall(
              context,
            ).copyWith(color: Colors.grey[600], fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.bodySmall(
              context,
            ).copyWith(color: Colors.black87),
          ),
        ),
      ],
    );
  }

  IconData _getScopeIcon(String scope) {
    switch (scope) {
      case 'ACTIVITY':
        return Icons.event;
      case 'BATCH':
        return Icons.group;
      case 'SOCIETY':
        return Icons.groups;
      case 'GENERAL':
      default:
        return Icons.notifications;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _openAttachment(String attachmentUrl) {
    // Implement attachment opening logic
    // This could launch a URL, open a file viewer, etc.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening attachment: $attachmentUrl'),
        backgroundColor: const Color(0xFFFF6B35),
      ),
    );
  }
}
