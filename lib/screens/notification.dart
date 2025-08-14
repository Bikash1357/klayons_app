import 'package:flutter/material.dart';
import 'package:klayons/screens/home_screen.dart';
import '../services/notification/scheduleOverideService.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({Key? key}) : super(key: key);

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  List<ScheduleOverride> scheduleOverrides = [];
  bool isLoading = true;
  String? error;
  int unreadCount = 0;

  @override
  void initState() {
    super.initState();
    NotificationCountManager.init();
    _loadScheduleOverrides();
  }

  Future<void> _loadScheduleOverrides() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      final overrides = await ScheduleOverridesService.getScheduleOverrides();

      setState(() {
        scheduleOverrides = overrides;
        unreadCount = NotificationCountManager.getUnviewedCount(overrides);
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  void _markAllNotificationsAsViewed() {
    NotificationCountManager.markAllAsViewed(scheduleOverrides);
    setState(() {
      unreadCount = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F5F5),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Colors.black87,
            size: 20,
          ),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => KlayonsHomePage()),
          ),
        ),
        title: const Text(
          'NOTIFICATIONS',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 16,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: false,
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.notifications_outlined,
                  color: Colors.black87,
                  size: 24,
                ),
                onPressed: _markAllNotificationsAsViewed,
              ),
              if (unreadCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      unreadCount > 99 ? '99+' : unreadCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black87, size: 20),
            onPressed: _loadScheduleOverrides,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Expanded(child: _buildNotificationsList()),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationsList() {
    if (isLoading) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(40.0),
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6B35)),
            ),
          ),
        ),
      );
    }

    if (error != null) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(40.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Failed to load notifications',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  error!.replaceAll('Exception: ', ''),
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadScheduleOverrides,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B35),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (scheduleOverrides.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(40.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.notifications_none,
                  color: Colors.grey[400],
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  'No notifications yet',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Schedule updates and notifications will appear here',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListView.separated(
        padding: EdgeInsets.zero,
        itemCount: scheduleOverrides.length,
        separatorBuilder: (context, index) => _buildDivider(),
        itemBuilder: (context, index) {
          final override = scheduleOverrides[index];
          return _buildScheduleNotificationItem(
            override: override,
            isLast: index == scheduleOverrides.length - 1,
          );
        },
      ),
    );
  }

  Widget _buildScheduleNotificationItem({
    required ScheduleOverride override,
    bool isLast = false,
  }) {
    // Determine if this notification is unread
    final isUnread = !override.isViewed;

    return InkWell(
      onTap: () {
        // Mark this notification as viewed when tapped
        if (isUnread) {
          NotificationCountManager.markAsViewed(override.id);
          setState(() {
            unreadCount = NotificationCountManager.getUnviewedCount(
              scheduleOverrides,
            );
          });
        }
        _showNotificationDetails(override);
      },
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(override == scheduleOverrides.first ? 12 : 0),
        bottom: Radius.circular(isLast ? 12 : 0),
      ),
      child: Container(
        color: isUnread ? Colors.orange.withOpacity(0.05) : Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              if (isUnread)
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF6B35),
                    shape: BoxShape.circle,
                  ),
                )
              else
                const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      override.getNotificationTitle(),
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                        fontWeight: isUnread
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                    if (override.getNotificationDescription().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        override.getNotificationDescription(),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w400,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (override.cancelled ||
                        override.rescheduledStartTime != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            override.cancelled
                                ? Icons.cancel_outlined
                                : Icons.schedule,
                            size: 14,
                            color: override.cancelled
                                ? Colors.red[400]
                                : Colors.blue[400],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Schedule ID: ${override.schedule}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    override.getTimeAgo(),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  if (isUnread) ...[
                    const SizedBox(height: 4),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      margin: const EdgeInsets.only(left: 20),
      height: 1,
      color: Colors.grey.withOpacity(0.1),
    );
  }

  bool _isRecentNotification(String occurrenceDate) {
    try {
      final DateTime scheduleDate = DateTime.parse(occurrenceDate);
      final DateTime now = DateTime.now();
      final Duration difference = now.difference(scheduleDate);

      // Consider notifications from the last 24 hours as recent
      return difference.inHours <= 24;
    } catch (e) {
      return false;
    }
  }

  void _showNotificationDetails(ScheduleOverride override) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(override.getNotificationTitle()),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Schedule ID: ${override.schedule}',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Text('Date: ${override.occurrenceDate}'),
              const SizedBox(height: 8),
              Text(
                'Status: ${override.cancelled ? 'Cancelled' : 'Rescheduled'}',
              ),
              if (override.rescheduledStartTime != null) ...[
                const SizedBox(height: 8),
                Text('New Start Time: ${override.rescheduledStartTime}'),
              ],
              if (override.rescheduledEndTime != null) ...[
                const SizedBox(height: 8),
                Text('New End Time: ${override.rescheduledEndTime}'),
              ],
              if (override.remarks != null && override.remarks!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('Remarks: ${override.remarks}'),
              ],
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Close'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }
}
