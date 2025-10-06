import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:klayons/screens/home_screen.dart';
import '../../utils/styles/fonts.dart';
import '../../services/Enrollments/deleteEnrollmentService.dart';
import '../../services/Enrollments/enrollementModel.dart';
import '../../services/Enrollments/get_enrolled_service.dart';
import '../../services/calendar/children_calendar_service.dart';
import '../../services/user_child/get_ChildServices.dart' as childService;
import '../../utils/styles/fonts.dart';
import 'package:klayons/utils/colour.dart';
import '../activity_details_page.dart';
import '../user_calender/calander.dart';

class EnrolledPage extends StatefulWidget {
  const EnrolledPage({super.key});

  @override
  State<EnrolledPage> createState() => _EnrolledPageState();
}

class _EnrolledPageState extends State<EnrolledPage> {
  late Future<List<GetEnrollment>> _futureEnrollments;
  bool _isRefreshing = false;
  Set<int> _deletingEnrollments = {};
  List<ChildCustomActivity> _customActivities = [];
  bool _isLoadingCustomActivities = false;

  @override
  void initState() {
    super.initState();
    _loadEnrollments(forceRefresh: false);
    _loadCustomActivities();
  }

  // Load custom activities from ChildrenCalendarService
  // Load custom activities from ChildrenCalendarService
  Future<void> _loadCustomActivities() async {
    try {
      setState(() {
        _isLoadingCustomActivities = true;
      });

      // Get all children first - use alias
      List<childService.Child> children =
          await childService.GetChildservices.fetchChildren();
      Set<int> childIds = children.map((child) => child.id).toSet();

      if (childIds.isNotEmpty) {
        // Fetch children calendar data
        DateTime startDate = DateTime.now().subtract(Duration(days: 30));
        DateTime endDate = DateTime.now().add(Duration(days: 90));

        ChildrenCalendarResponse calendarResponse =
            await ChildrenCalendarService.fetchChildrenCalendar(
              childIds,
              startDate: startDate,
              endDate: endDate,
            );

        // Extract all custom activities from all children
        List<ChildCustomActivity> allCustomActivities = [];
        for (ChildCalendarData childData in calendarResponse.children) {
          allCustomActivities.addAll(childData.customActivities);
        }

        setState(() {
          _customActivities = allCustomActivities;
          _isLoadingCustomActivities = false;
        });
      } else {
        setState(() {
          _isLoadingCustomActivities = false;
        });
      }
    } catch (e) {
      print('Error loading custom activities: $e');
      setState(() {
        _isLoadingCustomActivities = false;
      });
    }
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
      await _loadCustomActivities(); // Also refresh custom activities
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  Future<void> _handleUnenrollment(GetEnrollment enrollment) async {
    final bool? shouldUnenroll = await showUnenrollConfirmationDialog(
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

  Future<bool?> showUnenrollConfirmationDialog(GetEnrollment enrollment) async {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          contentPadding: EdgeInsets.all(24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.primaryOrange,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: () {},
                  icon: SvgPicture.asset(
                    'assets/App_icons/Exclamation_mark.svg',
                    width: 24,
                    height: 24,
                    colorFilter: ColorFilter.mode(
                      Colors.white,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 24),
              Text(
                'Are you sure?',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  fontSize: 20,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Deleting this profile will unenroll from ${response.data!.activity.name} for the ${response.data!.child.name}!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.black87,
                  height: 1.4,
                ),
              ),
              SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        style: TextButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryOrange,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Delete',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
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
        backgroundColor: AppColors.background,
        titleSpacing: 0,
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
        title: Text(
          "Activity Tracker",
          style: AppTextStyles.titleLarge(
            context,
          ).copyWith(color: AppColors.darkElements),
        ),
        automaticallyImplyLeading: false,
        elevation: 0,
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
                  child: CircularProgressIndicator(color: Colors.deepOrange),
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
              } else if (!snapshot.hasData ||
                  (snapshot.data!.isEmpty && _customActivities.isEmpty)) {
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
                          'No Activities Found',
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
                      ],
                    ),
                  ),
                );
              }

              final enrollments = snapshot.data!;

              // Separate currently enrolled and previously enrolled
              final currentlyEnrolled = enrollments
                  .where(
                    (e) =>
                        e.status.toLowerCase() == 'enrolled' ||
                        e.status.toLowerCase() == 'reenrolled' ||
                        e.status.toLowerCase() == 'waitlist',
                  )
                  .toList();

              final previouslyEnrolled = enrollments
                  .where((e) => e.status.toLowerCase() == 'unenrolled')
                  .toList();

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Section 1: Currently Enrolled
                  if (currentlyEnrolled.isNotEmpty) ...[
                    Text(
                      'Currently Enrolled',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 12),
                    ...currentlyEnrolled.map(
                      (enrollment) => _buildEnrollmentCard(enrollment, true),
                    ),
                    SizedBox(height: 24),
                  ],

                  // Section 2: Custom Activities
                  if (_customActivities.isNotEmpty) ...[
                    Text(
                      'Custom Activities',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 12),
                    ..._customActivities.map(
                      (customActivity) =>
                          _buildCustomActivityCard(customActivity),
                    ),
                    SizedBox(height: 24),
                  ],

                  // Loading indicator for custom activities
                  if (_isLoadingCustomActivities) ...[
                    Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: CircularProgressIndicator(
                          color: Colors.deepOrange,
                        ),
                      ),
                    ),
                    SizedBox(height: 24),
                  ],

                  // Section 3: Previously Enrolled
                  if (previouslyEnrolled.isNotEmpty) ...[
                    Text(
                      'Previously Enrolled',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 12),
                    ...previouslyEnrolled.map(
                      (enrollment) => _buildEnrollmentCard(enrollment, false),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // Build card for custom activities
  Widget _buildCustomActivityCard(ChildCustomActivity customActivity) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // Navigate to CalendarScreen when custom activity card is tapped
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CalendarScreen()),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Custom activity icon/color indicator
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: _hexToColor(customActivity.color),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.event_note, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 12),

              // Activity Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customActivity.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'For ${customActivity.childName}',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),

              // Arrow indicator
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEnrollmentCard(
    GetEnrollment enrollment,
    bool isCurrentlyEnrolled,
  ) {
    final isDeleting = _deletingEnrollments.contains(enrollment.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // Null-safe navigation
          final activityId = enrollment.activity?.id;
          if (activityId != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ActivityBookingPage(
                  batchId: activityId,
                  activityId: activityId,
                ),
              ),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Activity Image
              _buildActivityImage(enrollment),
              const SizedBox(width: 12),

              // Activity Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      enrollment.batchName.isNotEmpty
                          ? '${enrollment.activityName} - ${enrollment.batchName}'
                          : enrollment.activityName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (isCurrentlyEnrolled) ...[
                      if (enrollment.child != null)
                        _buildChildInfo(enrollment.child!.name),
                    ] else ...[
                      Text(
                        'Unenrolled on ${_getUnenrollmentDate(enrollment)}',
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                    ],
                  ],
                ),
              ),

              // Delete Button (only for currently enrolled)
              if (isCurrentlyEnrolled)
                GestureDetector(
                  onTap: isDeleting
                      ? null
                      : () => _handleUnenrollment(enrollment),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: isDeleting
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.red,
                            ),
                          )
                        : SvgPicture.asset(
                            'assets/App_icons/iconDelete.svg',
                            width: 20,
                            height: 20,
                            colorFilter: ColorFilter.mode(
                              Color(0xFFE53935),
                              BlendMode.srcIn,
                            ),
                          ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChildInfo(String childName) {
    return Text(
      'Booked for $childName',
      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
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

  // Helper method to convert hex color string to Flutter Color
  Color _hexToColor(String hexString) {
    String hex = hexString.replaceFirst('#', '');
    if (hex.length == 6) {
      hex = 'FF$hex';
    }
    return Color(int.parse(hex, radix: 16));
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

  String _getUnenrollmentDate(GetEnrollment enrollment) {
    return '31/8/2025';
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
