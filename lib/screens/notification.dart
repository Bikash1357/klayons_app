import 'package:flutter/material.dart';
import 'package:klayons/screens/home_screen.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({Key? key}) : super(key: key);

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
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Container(
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
              child: Column(
                children: [
                  _buildNotificationItem(
                    title: 'New Activity Available',
                    time: '5m',
                    hasOrangeDot: true,
                  ),
                  _buildDivider(),
                  _buildNotificationItem(
                    title: 'Reminder! Next session tomorrow',
                    time: '1d',
                  ),
                  _buildDivider(),
                  _buildNotificationItem(
                    title: 'New Batch Available',
                    time: '3d',
                  ),
                  _buildDivider(),
                  _buildNotificationItem(
                    title: 'New Activity Available',
                    time: '1w',
                  ),
                  _buildDivider(),
                  _buildNotificationItem(
                    title: 'Reminder! Next session tomorrow',
                    time: '3w',
                  ),
                  _buildDivider(),
                  _buildNotificationItem(
                    title: 'New Batch Available',
                    time: '1m',
                    isLast: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationItem({
    required String title,
    required String time,
    bool hasOrangeDot = false,
    bool isLast = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          if (hasOrangeDot)
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
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          Text(
            time,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
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
}
