import 'package:flutter/material.dart';

import '../services/ActivitiedsServices.dart';

class CourseDetailPage extends StatelessWidget {
  final Activity activity;

  const CourseDetailPage({Key? key, required this.activity}) : super(key: key);

  String _formatAgeGroup(int ageStart, int ageEnd) {
    if (ageStart == ageEnd) {
      return 'Recommended for ${ageStart} year olds';
    } else {
      return 'Recommended for $ageStart-$ageEnd year olds';
    }
  }

  String _formatDateRange() {
    try {
      final startDate = DateTime.parse(activity.startDate);
      final endDate = DateTime.parse(activity.endDate);

      final startFormatted =
          '${startDate.day}/${startDate.month}/${startDate.year}';
      final endFormatted = '${endDate.day}/${endDate.month}/${endDate.year}';

      if (activity.startDate == activity.endDate) {
        return 'Date: $startFormatted';
      }
      return 'Duration: $startFormatted - $endFormatted';
    } catch (e) {
      return 'Duration: ${activity.startDate} - ${activity.endDate}';
    }
  }

  String _getActivityStatus() {
    try {
      final startDate = DateTime.parse(activity.startDate);
      final endDate = DateTime.parse(activity.endDate);
      final now = DateTime.now();

      if (now.isBefore(startDate)) {
        final daysUntilStart = startDate.difference(now).inDays;
        if (daysUntilStart == 0) return 'Starts Today';
        if (daysUntilStart == 1) return 'Starts Tomorrow';
        return 'Starts in $daysUntilStart days';
      } else if (now.isAfter(endDate)) {
        return 'Activity Completed';
      } else {
        return 'Activity in Progress';
      }
    } catch (e) {
      return activity.isActive ? 'Available' : 'Not Available';
    }
  }

  Color _getStatusColor() {
    try {
      final startDate = DateTime.parse(activity.startDate);
      final endDate = DateTime.parse(activity.endDate);
      final now = DateTime.now();

      if (now.isBefore(startDate)) {
        return Colors.blue; // Upcoming
      } else if (now.isAfter(endDate)) {
        return Colors.grey; // Completed
      } else {
        return Colors.green; // In progress
      }
    } catch (e) {
      return activity.isActive ? Colors.green : Colors.red;
    }
  }

  String _getPriceInfo() {
    if (activity.pricing.isNotEmpty) {
      // Try to parse as number for better formatting
      try {
        final price = double.parse(activity.pricing);
        return '₹${price.toStringAsFixed(0)}';
      } catch (e) {
        return '₹${activity.pricing}';
      }
    }
    return 'Price not available';
  }

  bool _isActivityBookable() {
    if (!activity.isActive) return false;

    try {
      final startDate = DateTime.parse(activity.startDate);
      final now = DateTime.now();
      // Allow booking if activity hasn't started yet
      return now.isBefore(startDate) || now.isAtSameMomentAs(startDate);
    } catch (e) {
      return activity.isActive;
    }
  }

  Widget _buildStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getStatusColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _getStatusColor(), width: 1),
      ),
      child: Text(
        _getActivityStatus(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: _getStatusColor(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Image with Banner Support and Blending
            Stack(
              children: [
                Container(
                  width: double.infinity,
                  height: 250,
                  decoration: BoxDecoration(
                    image: activity.bannerImageUrl.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(activity.bannerImageUrl),
                            fit: BoxFit.cover,
                            onError: (error, stackTrace) {
                              // Fallback handled by container below
                            },
                          )
                        : const DecorationImage(
                            image: AssetImage(
                              'assets/images/klayons_auth_cover.png',
                            ),
                            fit: BoxFit.cover,
                          ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.3),
                          Colors.transparent,
                          Colors.black.withOpacity(0.1),
                        ],
                      ),
                    ),
                  ),
                ),
                // Rounded overlay to blend with content section
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 30,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Content Section
            Container(
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Activity Name and Status
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                activity.name.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatAgeGroup(
                                  activity.ageGroupStart,
                                  activity.ageGroupEnd,
                                ),
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        _buildStatusBadge(),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Price
                    Row(
                      children: [
                        Text(
                          _getPriceInfo(),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFE65100),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'per activity',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Schedule Info
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _formatDateRange(),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (activity.batchesCount.isNotEmpty)
                            Text(
                              'Total Batches: ${activity.batchesCount}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Activity Status Info
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _getStatusColor(),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _getActivityStatus(),
                          style: TextStyle(
                            fontSize: 14,
                            color: _getStatusColor(),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: activity.isActive
                                ? () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          '${activity.name} added to TicketBox',
                                        ),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  }
                                : null,
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: activity.isActive
                                    ? const Color(0xFFE65100)
                                    : Colors.grey,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            child: Text(
                              'Add to TicketBox',
                              style: TextStyle(
                                color: activity.isActive
                                    ? const Color(0xFFE65100)
                                    : Colors.grey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isActivityBookable()
                                ? () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Booking ${activity.name}...',
                                        ),
                                        backgroundColor: Colors.orange,
                                      ),
                                    );
                                  }
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isActivityBookable()
                                  ? const Color(0xFFE65100)
                                  : Colors.grey,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            child: Text(
                              _isActivityBookable()
                                  ? 'Book Now'
                                  : 'Not Available',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Description
                    const Text(
                      'DESCRIPTION',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      activity.description.isNotEmpty
                          ? activity.description
                          : 'This activity offers a comprehensive learning experience designed to engage participants and help them develop new skills. Join us for an exciting journey of discovery and growth.',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Meet the Instructor
                    const Text(
                      'MEET THE INSTRUCTOR',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Instructor Profile
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            color: Colors.orange.withOpacity(0.2),
                            image:
                                activity.instructor.profile.startsWith('http')
                                ? DecorationImage(
                                    image: NetworkImage(
                                      activity.instructor.profile,
                                    ),
                                    fit: BoxFit.cover,
                                    onError: (error, stackTrace) {
                                      // Fallback to initial letter
                                    },
                                  )
                                : null,
                          ),
                          child: activity.instructor.profile.startsWith('http')
                              ? null
                              : Center(
                                  child: Text(
                                    activity.instructor.name.isNotEmpty
                                        ? activity.instructor.name[0]
                                              .toUpperCase()
                                        : 'I',
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange,
                                    ),
                                  ),
                                ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                activity.instructor.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                activity.instructor.profile.startsWith('http')
                                    ? 'Experienced instructor with expertise in ${activity.name}. Passionate about teaching and helping students achieve their goals.'
                                    : (activity.instructor.profile.isNotEmpty
                                          ? activity.instructor.profile
                                          : 'Experienced instructor with expertise in ${activity.name}. Passionate about teaching and helping students achieve their goals.'),
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black87,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Additional Activity Info
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ACTIVITY INFORMATION',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildInfoRow(
                            'Age Group',
                            _formatAgeGroup(
                              activity.ageGroupStart,
                              activity.ageGroupEnd,
                            ),
                          ),
                          _buildInfoRow('Pricing', _getPriceInfo()),
                          if (activity.batchesCount.isNotEmpty)
                            _buildInfoRow(
                              'Available Batches',
                              activity.batchesCount,
                            ),
                          _buildInfoRow(
                            'Status',
                            activity.isActive ? 'Active' : 'Inactive',
                          ),
                          _buildInfoRow(
                            'Activity Duration',
                            _formatDateRange(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Booking Notice
                    if (!activity.isActive || !_isActivityBookable())
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.orange.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.orange[700],
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                !activity.isActive
                                    ? 'This activity is currently inactive and not available for booking.'
                                    : 'This activity has already started or completed. Booking is not available.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
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

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}
