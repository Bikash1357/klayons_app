import 'package:flutter/material.dart';

import '../../services/activity/activities_batchServices/get_delete_enrolled_service.dart';

class EnrolledPage extends StatefulWidget {
  const EnrolledPage({Key? key}) : super(key: key);

  @override
  State<EnrolledPage> createState() => _EnrolledPageState();
}

class _EnrolledPageState extends State<EnrolledPage> {
  late Future<List<GetEnrollment>> _futureEnrollments;
  bool _isRefreshing = false;
  Set<int> _deletingEnrollments = {};

  @override
  void initState() {
    super.initState();
    _loadEnrollments(forceRefresh: false); // Use cache on initial load
  }

  void _loadEnrollments({bool forceRefresh = false}) {
    setState(() {
      _futureEnrollments = GetEnrollmentService.fetchMyEnrollments(
        forceRefresh: forceRefresh,
      );
    });
  }

  Future<void> _refreshEnrollments() async {
    setState(() {
      _isRefreshing = true;
      _deletingEnrollments.clear();
    });

    try {
      // Force refresh ignores cache and calls API
      _loadEnrollments(forceRefresh: true);
      await _futureEnrollments;
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  Future<void> _handleUnenrollment(GetEnrollment enrollment) async {
    final bool? shouldUnenroll = await _showUnenrollConfirmationDialog(
      enrollment,
    );

    if (shouldUnenroll == true) {
      setState(() {
        _deletingEnrollments.add(enrollment.id);
      });

      try {
        await GetEnrollmentService.unenrollChild(enrollment.id);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${enrollment.childName} has been unenrolled from ${enrollment.activityName}',
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );

          // Reload data after successful unenrollment
          // Don't force refresh since cache was already updated
          _loadEnrollments(forceRefresh: false);
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _deletingEnrollments.remove(enrollment.id);
          });

          _showErrorDialog('Unenrollment Failed', e.toString());
        }
      }
    }
  }

  Future<bool?> _showUnenrollConfirmationDialog(
    GetEnrollment enrollment,
  ) async {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.warning_amber, color: Colors.orange, size: 28),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Confirm Unenrollment',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to unenroll from this activity?',
                style: TextStyle(fontSize: 16, color: Colors.black87),
              ),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Enrollment Details:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Colors.red[800],
                      ),
                    ),
                    SizedBox(height: 8),
                    Text('Child: ${enrollment.childName}'),
                    Text('Activity: ${enrollment.activityName}'),
                    Text('Batch: ${enrollment.batchName}'),
                    Text('Status: ${enrollment.statusDisplay}'),
                  ],
                ),
              ),
              SizedBox(height: 12),
              Text(
                'This action will remove the child from the batch. You can re-enroll later if needed.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Yes, Unenroll',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.error, color: Colors.red, size: 28),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          content: Text(message),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text('OK', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Enrolled Batches",
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Debug button to show cache stats (remove in production)
          if (true) // Set to false in production
            IconButton(
              icon: Icon(Icons.info_outline, color: Colors.grey[600]),
              onPressed: () {
                final stats = GetEnrollmentService.getCacheStats();
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Cache Stats'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Has Cache: ${stats['hasCachedData']}'),
                        Text('Count: ${stats['enrollmentCount']}'),
                        Text('Age: ${stats['cacheAgeMinutes']} min'),
                        Text('Valid: ${stats['isCacheValid']}'),
                        Text('Loading: ${stats['isCurrentlyLoading']}'),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          GetEnrollmentService.clearCache();
                          Navigator.pop(context);
                        },
                        child: Text('Clear Cache'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Close'),
                      ),
                    ],
                  ),
                );
              },
            ),
          IconButton(
            icon: _isRefreshing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.deepOrange,
                    ),
                  )
                : const Icon(Icons.refresh, color: Colors.black87),
            onPressed: _isRefreshing ? null : _refreshEnrollments,
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshEnrollments, // This will force refresh
          color: Colors.deepOrange,
          child: FutureBuilder<List<GetEnrollment>>(
            future: _futureEnrollments,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Colors.deepOrange),
                      SizedBox(height: 16),
                      Text(
                        'Loading enrollments...',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                );
              } else if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red[400],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Error Loading Enrollments',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          snapshot.error.toString(),
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.red,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _refreshEnrollments,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepOrange,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Try Again',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.school_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No Enrollments Found',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'You haven\'t enrolled in any activities yet.',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        TextButton.icon(
                          onPressed: _refreshEnrollments,
                          icon: const Icon(
                            Icons.refresh,
                            color: Colors.deepOrange,
                          ),
                          label: const Text(
                            'Refresh',
                            style: TextStyle(color: Colors.deepOrange),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final enrollments = snapshot.data!;
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: enrollments.length,
                itemBuilder: (context, index) {
                  return _buildEnrollmentCard(enrollments[index], index);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildEnrollmentCard(GetEnrollment enrollment, int index) {
    final isDeleting = _deletingEnrollments.contains(enrollment.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: _getImageColor(index),
              ),
              child: Icon(
                _getActivityIcon(enrollment.activityName),
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          enrollment.activityName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: enrollment.statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: enrollment.statusColor),
                        ),
                        child: Text(
                          enrollment.statusDisplay,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: enrollment.statusColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: isDeleting
                            ? null
                            : () => _handleUnenrollment(enrollment),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red[200]!),
                          ),
                          child: isDeleting
                              ? SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.red,
                                  ),
                                )
                              : Icon(
                                  Icons.delete_outline,
                                  color: Colors.red,
                                  size: 16,
                                ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  Text(
                    enrollment.batchName,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Icon(Icons.child_care, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        enrollment.childName,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Text(
                        enrollment.priceDisplay,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.deepOrange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Enrolled: ${enrollment.enrolledAtDisplay}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getImageColor(int index) {
    const List<Color> colors = [
      Color(0xFF8B4513),
      Color(0xFF2E8B57),
      Color(0xFF4682B4),
      Color(0xFF9932CC),
      Color(0xFFFF6347),
      Color(0xFF32CD32),
    ];
    return colors[index % colors.length];
  }

  IconData _getActivityIcon(String activityName) {
    final name = activityName.toLowerCase();
    if (name.contains('swim')) return Icons.pool;
    if (name.contains('dance')) return Icons.music_video;
    if (name.contains('music') ||
        name.contains('piano') ||
        name.contains('guitar'))
      return Icons.music_note;
    if (name.contains('art') || name.contains('paint') || name.contains('draw'))
      return Icons.palette;
    if (name.contains('sport') ||
        name.contains('football') ||
        name.contains('cricket'))
      return Icons.sports;
    if (name.contains('cook')) return Icons.restaurant;
    if (name.contains('tech') ||
        name.contains('code') ||
        name.contains('robot'))
      return Icons.computer;
    if (name.contains('yoga') || name.contains('fitness'))
      return Icons.self_improvement;
    if (name.contains('drama')) return Icons.theater_comedy;
    return Icons.school;
  }
}
