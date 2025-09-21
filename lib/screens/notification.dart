import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import '../utils/styles/fonts.dart';
import 'package:klayons/utils/colour.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({Key? key}) : super(key: key);

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  // List<AnnouncementModel> announcements = [];
  bool isLoading = true;
  String? errorMessage;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
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
      body: Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.all(16),
            child: TextField(
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
        ],
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
