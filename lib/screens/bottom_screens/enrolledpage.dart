import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:klayons/screens/home_screen.dart';

import '../../services/Enrollments/deleteEnrollmentService.dart';
import '../../services/Enrollments/enrollementModel.dart';
import '../../services/Enrollments/get_enrolled_service.dart';
import '../../utils/styles/fonts.dart';
import 'package:klayons/utils/colour.dart';

import '../activity_details_page.dart';

class EnrolledPage extends StatefulWidget {
  const EnrolledPage({super.key});

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
    _loadEnrollments(forceRefresh: false);
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
        final response = await EnrollmentService.unenrollFromActivity(
          enrollment.id,
        );

        if (mounted) {
          setState(() {
            _deletingEnrollments.remove(enrollment.id);
          });

          if (response.success && response.data != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '${response.data!.child.name} has been unenrolled from ${response.data!.activity.name}',
                ),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
                duration: Duration(seconds: 3),
                action: SnackBarAction(
                  label: 'OK',
                  textColor: Colors.white,
                  onPressed: () {},
                ),
              ),
            );

            EnrollmentService.clearEnrollmentCache();
            _loadEnrollments(forceRefresh: true);
          } else {
            _showErrorDialog(
              'Unenrollment Failed',
              response.error ?? 'An unknown error occurred',
            );
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _deletingEnrollments.remove(enrollment.id);
          });

          String errorMessage = 'Network error occurred';

          if (e.toString().contains('Authentication')) {
            errorMessage = 'Please log in again to continue';
          } else if (e.toString().contains('Permission')) {
            errorMessage =
                'You don\'t have permission to unenroll from this activity';
          } else if (e.toString().contains('not found')) {
            errorMessage = 'This enrollment was not found or already removed';
          }

          _showErrorDialog('Unenrollment Failed', errorMessage);
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
                    Text('Child: ${enrollment.child?.name ?? 'N/A'}'),
                    Text('Activity: ${enrollment.activity?.name ?? 'N/A'}'),
                    Text(
                      'Price: ₹${enrollment.activity?.price ?? '0'}/${enrollment.activity?.paymentType ?? 'month'}',
                    ),
                    Text('Status: ${_getStatusDisplay(enrollment.status)}'),
                    if (enrollment.activity?.batchName != null)
                      Text('Batch: ${enrollment.activity!.batchName}'),
                  ],
                ),
              ),
              SizedBox(height: 12),
              Text(
                'This action will remove the child from the activity. You can re-enroll later if needed.',
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
          content: Text(
            message,
            style: TextStyle(fontSize: 14, color: Colors.black87),
          ),
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
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
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => KlayonsHomePage()),
          ),
        ),
        title: const Text(
          "My Enrollments",
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: AppColors.darkElements),
            onPressed: _isRefreshing ? null : _refreshEnrollments,
            tooltip: 'Refresh Enrollments',
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshEnrollments,
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
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // Navigate to ActivityBookingPage with activity id
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ActivityBookingPage(
                batchId: enrollment.activity?.id ?? 0,
                activityId: enrollment.activity?.id ?? 0,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildActivityImage(enrollment),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${enrollment.activity?.name ?? 'N/A'}  ${enrollment.activity?.batchName ?? 'N/A'}',
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
                            color: _getStatusColor(
                              enrollment.status,
                            ).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _getStatusColor(enrollment.status),
                            ),
                          ),
                          child: Text(
                            _getStatusDisplay(enrollment.status),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _getStatusColor(enrollment.status),
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
                                : SvgPicture.asset(
                                    'assets/App_icons/iconDelete.svg',
                                    width: 16,
                                    height: 16,
                                    colorFilter: ColorFilter.mode(
                                      Colors.red,
                                      BlendMode.srcIn,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                    // Rest of your existing column content remains the same
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.child_care,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          enrollment.child?.name ?? 'Unknown Child',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.category, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${enrollment.activity?.category ?? 'N/A'} • ${enrollment.activity?.subcategory ?? 'N/A'}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.person, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${enrollment.activity?.instructor ?? 'N/A'} • ${enrollment.activity?.batchName ?? 'N/A'}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (enrollment.activity?.society != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              enrollment.activity!.society!,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (enrollment.waitlistPosition != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.queue,
                            size: 16,
                            color: Colors.orange[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Waitlist Position: ${enrollment.waitlistPosition}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          '₹${enrollment.activity?.price ?? '0'}/${enrollment.activity?.paymentType ?? 'month'}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.deepOrange,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'Enrolled: ${_getEnrollmentDate(enrollment)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                    if (enrollment.notes != null &&
                        enrollment.notes!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.note, size: 14, color: Colors.blue[700]),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                enrollment.notes!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue[700],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityImage(GetEnrollment enrollment) {
    final imageUrl = enrollment.activity?.bannerImageUrl ?? '';
    final activityId = enrollment.activity?.id ?? 0;
    final activityName = enrollment.activity?.name ?? '';

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: imageUrl.isNotEmpty
          ? CachedNetworkImage(
              imageUrl: imageUrl,
              width: 60,
              height: 60,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: _getImageColor(activityId),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: _getImageColor(activityId),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getFallbackActivityIcon(activityName),
                  color: Colors.white,
                  size: 24,
                ),
              ),
            )
          : Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: _getImageColor(activityId),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getFallbackActivityIcon(activityName),
                color: Colors.white,
                size: 24,
              ),
            ),
    );
  }

  Color _getImageColor(int activityId) {
    const List<Color> colors = [
      Color(0xFF8B4513),
      Color(0xFF2E8B57),
      Color(0xFF4682B4),
      Color(0xFF9932CC),
      Color(0xFFFF6347),
      Color(0xFF32CD32),
      Color(0xFFFF8C00),
      Color(0xFF20B2AA),
      Color(0xFFDC143C),
      Color(0xFF4169E1),
    ];
    return colors[activityId % colors.length];
  }

  String _getStatusDisplay(String status) {
    switch (status.toLowerCase()) {
      case 'enrolled':
        return 'Enrolled';
      case 'reenrolled':
        return 'Re-enrolled';
      case 'unenrolled':
        return 'Unenrolled';
      case 'waitlist':
        return 'Waitlisted';
      default:
        return status.toUpperCase();
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'enrolled':
        return Colors.green;
      case 'reenrolled':
        return Colors.blue;
      case 'unenrolled':
        return Colors.red;
      case 'waitlist':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getEnrollmentDate(GetEnrollment enrollment) {
    try {
      if (enrollment.toString().contains('timestamp')) {
        return _formatTimestamp(enrollment.toString());
      }
      return 'Recently';
    } catch (e) {
      return 'N/A';
    }
  }

  String _formatTimestamp(String? timestamp) {
    if (timestamp == null) return 'N/A';

    try {
      final dateTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inDays > 7) {
        return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
      } else if (difference.inDays > 0) {
        return '${difference.inDays} days ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} hours ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} minutes ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return 'N/A';
    }
  }

  IconData _getFallbackActivityIcon(String activityName) {
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
    if (name.contains('chess')) return Icons.extension;
    return Icons.school;
  }
}
