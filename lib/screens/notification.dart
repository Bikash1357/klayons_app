import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  final AnnouncementService _announcementService = AnnouncementService();
  List<Announcement> announcements = [];
  List<Announcement> filteredAnnouncements = [];
  bool isLoading = true;
  String? errorMessage;
  String searchQuery = '';
  String selectedScope = 'ALL';

  @override
  void initState() {
    super.initState();
    _loadAnnouncements();
  }

  Future<void> _loadAnnouncements() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      List<Announcement> loadedAnnouncements;

      if (selectedScope == 'ALL') {
        loadedAnnouncements = await _announcementService.getAnnouncements();
      } else {
        loadedAnnouncements = await _announcementService
            .getAnnouncementsByScope(selectedScope);
      }

      setState(() {
        announcements = loadedAnnouncements.where((a) => a.isActive).toList();
        _filterAnnouncements();
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to load notifications: ${e.toString()}';
        isLoading = false;
      });
      print('Error loading announcements: $e');
    }
  }

  void _filterAnnouncements() {
    if (searchQuery.isEmpty) {
      filteredAnnouncements = announcements;
    } else {
      filteredAnnouncements = announcements.where((announcement) {
        return announcement.title.toLowerCase().contains(
              searchQuery.toLowerCase(),
            ) ||
            announcement.content.toLowerCase().contains(
              searchQuery.toLowerCase(),
            );
      }).toList();
    }
  }

  Future<void> _markAnnouncementAsRead(int announcementId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final readNotifications = prefs.getStringList('read_notifications') ?? [];

      if (!readNotifications.contains(announcementId.toString())) {
        readNotifications.add(announcementId.toString());
        await prefs.setStringList('read_notifications', readNotifications);
      }
    } catch (e) {
      print('Error marking announcement as read: $e');
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      searchQuery = query;
      _filterAnnouncements();
    });
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
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.filter_list, color: AppColors.darkElements),
            onSelected: (value) {
              setState(() {
                selectedScope = value;
              });
              _loadAnnouncements();
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'ALL',
                child: Row(
                  children: [
                    Icon(Icons.all_inclusive, size: 18),
                    SizedBox(width: 8),
                    Text('All'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'GENERAL',
                child: Row(
                  children: [
                    Icon(Icons.notifications, size: 18),
                    SizedBox(width: 8),
                    Text('General'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'SOCIETY',
                child: Row(
                  children: [
                    Icon(Icons.groups, size: 18),
                    SizedBox(width: 8),
                    Text('Society'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'ACTIVITY',
                child: Row(
                  children: [
                    Icon(Icons.event, size: 18),
                    SizedBox(width: 8),
                    Text('Activity'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search notifications...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            searchQuery = '';
                            _filterAnnouncements();
                          });
                        },
                      )
                    : null,
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

          // Filter chip
          if (selectedScope != 'ALL')
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Chip(
                    label: Text(selectedScope),
                    backgroundColor: _getScopeColor(
                      selectedScope,
                    ).withOpacity(0.1),
                    labelStyle: TextStyle(
                      color: _getScopeColor(selectedScope),
                      fontWeight: FontWeight.w500,
                    ),
                    deleteIcon: Icon(
                      Icons.close,
                      size: 18,
                      color: _getScopeColor(selectedScope),
                    ),
                    onDeleted: () {
                      setState(() {
                        selectedScope = 'ALL';
                      });
                      _loadAnnouncements();
                    },
                  ),
                ],
              ),
            ),

          // Content area
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadAnnouncements,
              child: _buildContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFFF6B35)),
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
              errorMessage!,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium(
                context,
              ).copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadAnnouncements,
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

    if (filteredAnnouncements.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              searchQuery.isNotEmpty
                  ? Icons.search_off
                  : Icons.notifications_none,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              searchQuery.isNotEmpty
                  ? 'No notifications found for "$searchQuery"'
                  : 'No notifications available',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium(
                context,
              ).copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: filteredAnnouncements.length,
      itemBuilder: (context, index) {
        final announcement = filteredAnnouncements[index];
        return _buildAnnouncementCard(announcement);
      },
    );
  }

  Widget _buildAnnouncementCard(Announcement announcement) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showAnnouncementDetails(announcement),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with scope and date
              Row(
                children: [
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
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getScopeIcon(announcement.scope),
                          size: 14,
                          color: _getScopeColor(announcement.scope),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          announcement.scope,
                          style: AppTextStyles.bodySmall(context).copyWith(
                            color: _getScopeColor(announcement.scope),
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _formatDate(announcement.createdAt),
                    style: AppTextStyles.bodySmall(
                      context,
                    ).copyWith(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Title
              Text(
                announcement.title,
                style: AppTextStyles.titleSmall(
                  context,
                ).copyWith(fontWeight: FontWeight.w600, color: Colors.black87),
              ),
              const SizedBox(height: 8),

              // Content preview
              Text(
                announcement.content,
                style: AppTextStyles.bodyMedium(
                  context,
                ).copyWith(color: Colors.grey[700]),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),

              // Activities (if any)
              if (announcement.activities.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: announcement.activities.take(2).map((activity) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        activity.name,
                        style: AppTextStyles.bodySmall(
                          context,
                        ).copyWith(color: Colors.orange[700], fontSize: 11),
                      ),
                    );
                  }).toList(),
                ),
              ],

              // Attachment indicator
              if (announcement.attachmentUrl != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.attachment, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      'Attachment available',
                      style: AppTextStyles.bodySmall(
                        context,
                      ).copyWith(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ],

              // Footer with creator and expiry
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'By ${announcement.createdBy.name}',
                      style: AppTextStyles.bodySmall(
                        context,
                      ).copyWith(color: Colors.grey[600], fontSize: 12),
                    ),
                  ),
                  Text(
                    'Expires: ${_formatDate(announcement.expiry)}',
                    style: AppTextStyles.bodySmall(
                      context,
                    ).copyWith(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAnnouncementDetails(Announcement announcement) {
    _markAnnouncementAsRead(announcement.id);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
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
                      color: _getScopeColor(
                        announcement.scope,
                      ).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getScopeIcon(announcement.scope),
                          size: 16,
                          color: _getScopeColor(announcement.scope),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          announcement.scope,
                          style: AppTextStyles.bodySmall(context).copyWith(
                            color: _getScopeColor(announcement.scope),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
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
                    Text(
                      announcement.title,
                      style: AppTextStyles.titleLarge(context).copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),

                    Text(
                      announcement.content,
                      style: AppTextStyles.bodyMedium(
                        context,
                      ).copyWith(color: Colors.grey[700], height: 1.5),
                    ),
                    const SizedBox(height: 20),

                    if (announcement.activities.isNotEmpty) ...[
                      Text(
                        'Activities',
                        style: AppTextStyles.titleMedium(context).copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...announcement.activities.map(
                        (activity) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: _buildInfoRow(
                            '${activity.name}',
                            activity.instructor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    if (announcement.attachmentUrl != null) ...[
                      ElevatedButton.icon(
                        onPressed: () =>
                            _openAttachment(announcement.attachmentUrl!),
                        icon: const Icon(Icons.attachment),
                        label: const Text('View Attachment'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF6B35),
                          foregroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    _buildInfoRow('Created by', announcement.createdBy.name),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      'Created on',
                      _formatDate(announcement.createdAt),
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      'Expires on',
                      _formatDate(announcement.expiry),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
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
