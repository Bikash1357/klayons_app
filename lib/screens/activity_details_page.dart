import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:klayons/screens/InstructorDetailsPage.dart';
import 'package:klayons/utils/styles/fonts.dart';
import 'package:klayons/utils/styles/errorMessage.dart';
import '../services/activity/activities_batchServices/activityDetailsService.dart';
import '../services/activity/activities_batchServices/post_enrollment_service.dart';
import '../services/activity/activities_batchServices/get_delete_enrolled_service.dart';
import '../services/user_child/get_ChildServices.dart';
import 'package:klayons/utils/colour.dart';

class ActivityBookingPage extends StatefulWidget {
  final int activityId;
  final int? batchId;

  const ActivityBookingPage({Key? key, required this.activityId, this.batchId})
    : super(key: key);

  @override
  _ActivityBookingPageState createState() => _ActivityBookingPageState();
}

class _ActivityBookingPageState extends State<ActivityBookingPage>
    with BottomMessageHandler {
  String? selectedChildId;
  Child? selectedChild;
  ActivityDetail? activityData;
  List<Child> children = [];
  List<GetEnrollment> userEnrollments = [];
  bool isLoading = true;
  bool isLoadingChildren = false;
  bool isEnrolling = false;
  bool isCheckingEnrollment = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      await Future.wait([
        _loadActivityData(),
        _loadChildren(),
        _loadEnrollments(),
      ]);
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to load data: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  Future<void> _loadActivityData() async {
    try {
      final activity = await ActivityService.getActivityDetails(
        widget.activityId,
      );
      if (activity == null) {
        throw Exception('Activity not found');
      }
      setState(() {
        activityData = activity;
      });
    } catch (e) {
      throw Exception('Failed to load activity details: ${e.toString()}');
    }
  }

  Future<void> _loadChildren() async {
    setState(() {
      isLoadingChildren = true;
    });

    try {
      final cachedChildren = GetChildservices.getCachedChildren();

      if (cachedChildren != null && cachedChildren.isNotEmpty) {
        setState(() {
          children = cachedChildren;
          if (selectedChildId == null && children.isNotEmpty) {
            selectedChildId = children.first.id.toString();
            selectedChild = children.first;
          }
        });
      } else {
        final fetchedChildren = await GetChildservices.fetchChildren();
        setState(() {
          children = fetchedChildren;
          if (selectedChildId == null && children.isNotEmpty) {
            selectedChildId = children.first.id.toString();
            selectedChild = children.first;
          }
        });
      }
    } catch (e) {
      print('Error loading children: $e');
      setState(() {
        children = [];
      });
    } finally {
      setState(() {
        isLoadingChildren = false;
      });
    }
  }

  Future<void> _loadEnrollments() async {
    try {
      final enrollments = await GetEnrollmentService.fetchMyEnrollments();
      setState(() {
        userEnrollments = enrollments;
      });
    } catch (e) {
      print('Error loading enrollments: $e');
      setState(() {
        userEnrollments = [];
      });
    }
  }

  void _selectChild(Child child) {
    setState(() {
      selectedChildId = child.id.toString();
      selectedChild = child;
    });
  }

  /// Check if selected child is already enrolled in this activity
  bool _isChildAlreadyEnrolled() {
    if (selectedChild == null) return false;

    return userEnrollments.any(
      (enrollment) =>
          enrollment.childId == selectedChild!.id &&
          enrollment.activityId == widget.activityId &&
          (enrollment.status.toLowerCase() == 'enrolled' ||
              enrollment.status.toLowerCase() == 'waitlist'),
    );
  }

  /// Get enrollment status text for the button
  String _getEnrollmentButtonText() {
    if (!activityData!.isActive) return 'Currently Inactive';
    if (_isChildAlreadyEnrolled()) return 'Already Enrolled';
    return 'Enroll Now';
  }

  /// Show success enrollment popup
  Future<void> _showSuccessDialog(EnrollmentResponse response) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Container(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Success Icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle,
                    color: Colors.green[500],
                    size: 50,
                  ),
                ),
                SizedBox(height: 24),

                // Congratulations Text
                Text(
                  'Congratulations! 🎉',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 12),

                // Success Message
                Text(
                  'You have successfully enrolled ${selectedChild!.name} in ${response.activityName}!',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),

                // Enrollment Details
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Status:',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: response.isEnrolled
                                  ? Colors.green
                                  : Colors.orange,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              response.statusDisplay,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Fee:',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          Text(
                            response.priceDisplay,
                            style: TextStyle(
                              color: Colors.green[700],
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24),

                // Done Button
                Container(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      // Optional: Navigate back to previous screen
                      // Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[500],
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Great!',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleEnrollment() async {
    if (selectedChild == null || activityData == null) {
      showBottomError('Please select a child to continue with enrollment.');
      return;
    }

    // Check if child is already enrolled
    if (_isChildAlreadyEnrolled()) {
      showBottomError('This child is already enrolled in this activity.');
      return;
    }

    final bool? shouldEnroll = await _showEnrollmentConfirmationDialog();

    if (shouldEnroll != true) {
      return;
    }

    setState(() {
      isEnrolling = true;
    });

    try {
      // Updated API call using activityId instead of batchId
      final enrollmentResponse = await EnrollmentService.enrollChild(
        childId: selectedChild!.id,
        activityId: widget.activityId,
      );

      setState(() {
        isEnrolling = false;
      });

      // Refresh enrollments to update button state
      await _loadEnrollments();

      // Show success popup
      await _showSuccessDialog(enrollmentResponse);

      // Also show bottom success message (optional)
      showBottomSuccess(
        '${selectedChild!.name} ${enrollmentResponse.statusDisplay} in ${enrollmentResponse.activityName}!',
      );
    } on EnrollmentException catch (e) {
      setState(() {
        isEnrolling = false;
      });

      // Show user-friendly error message
      showBottomError(e.userFriendlyMessage);
    } catch (e) {
      setState(() {
        isEnrolling = false;
      });

      // Show generic error message for unexpected errors
      showBottomError('An unexpected error occurred. Please try again.');
    }
  }

  String _calculateAge(String dob) {
    try {
      final birthDate = DateTime.parse(dob);
      final today = DateTime.now();
      int age = today.year - birthDate.year;

      if (today.month < birthDate.month ||
          (today.month == birthDate.month && today.day < birthDate.day)) {
        age--;
      }

      return age.toString();
    } catch (e) {
      return 'N/A';
    }
  }

  String _formatScheduleDisplay() {
    if (activityData?.schedules.isEmpty ?? true) {
      return 'Schedule not available';
    }

    final schedule = activityData!.schedules.first;
    if (schedule.nextOccurrences.isNotEmpty) {
      final days = schedule.nextOccurrences
          .map((occ) => occ.day)
          .toSet()
          .toList();
      return 'Every ${days.join(' & ')}';
    }

    return 'Schedule available';
  }

  String _getTimeSlots() {
    if (activityData?.schedule.timeSlots.isEmpty ?? true) {
      return 'Time not specified';
    }

    final timeSlot = activityData!.schedule.timeSlots.first;
    return '${timeSlot.startTime} - ${timeSlot.endTime}';
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
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.share, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: Stack(
        children: [
          isLoading
              ? _buildLoadingWidget()
              : errorMessage != null
              ? _buildErrorWidget()
              : activityData != null
              ? _buildContent()
              : _buildEmptyWidget(),

          // Add bottom messages overlay
          buildBottomMessages(),
        ],
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.deepOrange),
          SizedBox(height: 16),
          Text(
            'Loading activity details...',
            style: AppTextStyles.titleMedium(
              context,
            ).copyWith(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
            SizedBox(height: 16),
            Text(
              'Error Loading Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 8),
            Text(
              errorMessage!,
              style: AppTextStyles.titleSmall(
                context,
              ).copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
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
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text(
            'No Data Available',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final activity = activityData!;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main Image
          Container(
            width: double.infinity,
            height: 250,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              child: activity.bannerImageUrl.isNotEmpty
                  ? Image.network(
                      activity.bannerImageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[200],
                          child: Icon(
                            _getActivityIcon(activity.category),
                            size: 100,
                            color: Colors.grey[400],
                          ),
                        );
                      },
                    )
                  : Container(
                      color: Colors.grey[200],
                      child: Icon(
                        _getActivityIcon(activity.category),
                        size: 100,
                        color: Colors.grey[400],
                      ),
                    ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Activity Name
                Text(
                  activity.name,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 8),

                // Category and Subcategory
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.deepOrange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.deepOrange.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        activity.category,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.deepOrange[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (activity.subcategory.isNotEmpty) ...[
                      SizedBox(width: 8),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Text(
                          activity.subcategory,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: 8),

                Text(
                  'Recommended for ${activity.ageRange.isNotEmpty ? activity.ageRange : 'All ages'}',
                  style: AppTextStyles.titleSmall(
                    context,
                  ).copyWith(color: Colors.grey[600]),
                ),
                SizedBox(height: 16),

                // Price Section
                Row(
                  children: [
                    Text(
                      '₹${activity.price.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepOrange,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      '/${activity.paymentType}',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                  ],
                ),
                SizedBox(height: 8),

                // Sessions and timing info
                Text(
                  '${activity.sessionCount} sessions, ${activity.sessionDuration}mins each',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                SizedBox(height: 8),

                // Schedule info
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _formatScheduleDisplay(),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),

                // Time slots
                Row(
                  children: [
                    Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                    SizedBox(width: 8),
                    Text(
                      _getTimeSlots(),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),

                // Location info
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        activity.venue.isNotEmpty
                            ? activity.venue
                            : activity.society,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),

                // Batch name if available
                if (activity.batchName.isNotEmpty) ...[
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.group, size: 16, color: Colors.blue[600]),
                        SizedBox(width: 6),
                        Text(
                          'Batch: ${activity.batchName}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 12),
                ],

                // Activity status
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: activity.isActive
                        ? Colors.green[50]
                        : Colors.red[50],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: activity.isActive
                          ? Colors.green[200]!
                          : Colors.red[200]!,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        activity.isActive ? Icons.schedule : Icons.pause_circle,
                        size: 16,
                        color: activity.isActive
                            ? Colors.green[600]
                            : Colors.red[600],
                      ),
                      SizedBox(width: 6),
                      Text(
                        activity.isActive
                            ? 'Enrollment Open!'
                            : 'Currently Inactive',
                        style: TextStyle(
                          fontSize: 12,
                          color: activity.isActive
                              ? Colors.green[700]
                              : Colors.red[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 20),

                _buildDescriptionSection(),
                SizedBox(height: 20),

                // Capacity Info
                Text(
                  '${activity.capacity - (activity.capacity ~/ 3)} spots left (Total: ${activity.capacity})',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.red[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 20),

                // Duration info
                if (activity.startDate.isNotEmpty &&
                    activity.endDate.isNotEmpty) ...[
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.purple[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.purple[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.date_range, color: Colors.purple[600]),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Activity Duration',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.purple[700],
                                  fontSize: 14,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                '${activity.startDate} to ${activity.endDate}',
                                style: TextStyle(
                                  color: Colors.purple[600],
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                ],

                // Child selection for enrollment
                if (children.isNotEmpty) ...[
                  Row(
                    children: [
                      Text(
                        'Book for: ',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Expanded(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: children.map((child) {
                            final isSelected =
                                selectedChildId == child.id.toString();
                            return GestureDetector(
                              onTap: () => _selectChild(child),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Colors.deepOrange
                                      : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(
                                    color: isSelected
                                        ? Colors.deepOrange
                                        : Colors.grey[300]!,
                                  ),
                                ),
                                child: Text(
                                  child.name.split(' ').first,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.grey[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                ],

                // Enroll button with enrollment status check
                Container(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed:
                        (activity.isActive &&
                            !isEnrolling &&
                            !_isChildAlreadyEnrolled())
                        ? _handleEnrollment
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          activity.isActive && !_isChildAlreadyEnrolled()
                          ? Colors.deepOrange
                          : Colors.grey,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: isEnrolling
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Enrolling...',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          )
                        : Text(
                            _getEnrollmentButtonText(),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),

                SizedBox(height: 30),
                _buildInstructorSection(),
                SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionSection() {
    final activity = activityData!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'DESCRIPTION',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
            letterSpacing: 1.2,
          ),
        ),
        SizedBox(height: 12),
        Text(
          activity.description.isNotEmpty
              ? activity.description
              : 'This ${activity.category.toLowerCase()} activity is designed to provide students with hands-on learning experience. Join us for an engaging and educational journey that will help develop new skills and build confidence.',
          style: AppTextStyles.titleSmall(
            context,
          ).copyWith(height: 1.6, color: Colors.grey[700]),
        ),
      ],
    );
  }

  Widget _buildInstructorSection() {
    final activity = activityData!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Meet the instructor',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 16),

        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => InstructorDetailsPage()),
            );
          },
          child: Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
              children: [
                // Instructor Avatar
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.deepOrange.withOpacity(0.1),
                  backgroundImage: activity.instructor.avatarUrl != null
                      ? NetworkImage(activity.instructor.avatarUrl!)
                      : null,
                  child: activity.instructor.avatarUrl == null
                      ? Text(
                          activity.instructor.name.isNotEmpty
                              ? activity.instructor.name
                                    .substring(0, 1)
                                    .toUpperCase()
                              : 'I',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepOrange,
                          ),
                        )
                      : null,
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activity.instructor.name.isNotEmpty
                            ? activity.instructor.name
                            : 'Instructor Name',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      if (activity.instructor.profile.isNotEmpty) ...[
                        SizedBox(height: 4),
                        Text(
                          activity.instructor.profile,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (activity.instructor.phone.isNotEmpty) ...[
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.phone,
                              size: 12,
                              color: Colors.grey[500],
                            ),
                            SizedBox(width: 4),
                            Text(
                              activity.instructor.phone,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  IconData _getActivityIcon(String category) {
    switch (category.toLowerCase()) {
      case 'sports':
        return Icons.sports_soccer;
      case 'arts':
        return Icons.palette;
      case 'technology':
      case 'tech':
        return Icons.computer;
      case 'music':
        return Icons.music_note;
      case 'dance':
        return Icons.music_video;
      case 'academic':
        return Icons.school;
      default:
        return Icons.extension;
    }
  }

  Future<bool?> _showEnrollmentConfirmationDialog() async {
    if (selectedChild == null || activityData == null) return false;

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.school, color: Colors.deepOrange, size: 28),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Confirm Enrollment',
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
                'Are you sure you want to enroll ${selectedChild!.name} in ${activityData!.name}?',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.deepOrange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.currency_rupee,
                      size: 18,
                      color: Colors.deepOrange[700],
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Fee: ₹${activityData!.price.toStringAsFixed(0)} /${activityData!.paymentType}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.deepOrange[800],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Confirm',
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
}
