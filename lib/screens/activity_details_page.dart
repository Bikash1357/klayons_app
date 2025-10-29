import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:klayons/screens/bottom_screens/uesr_profile/Childs/add_child.dart';
import 'package:klayons/screens/user_calender/calander.dart';
import 'package:klayons/utils/styles/fonts.dart';
import 'package:klayons/screens/home_screen.dart';
import 'package:share_plus/share_plus.dart';
import '../services/activity/activityDetailsService.dart';
import '../services/Enrollments/get_enrolled_service.dart';
import '../services/Enrollments/post_enrollment_service.dart';
import '../services/user_child/get_ChildServices.dart' as ChildService;
import '../services/Enrollments/enrollementModel.dart';
import 'package:klayons/utils/colour.dart';

import '../utils/popup.dart';

/// Production-ready Activity Booking Page with comprehensive error handling,
/// caching, and performance optimizations
class ActivityBookingPage extends StatefulWidget {
  final int activityId;
  final int? batchId;

  const ActivityBookingPage({
    super.key,
    required this.activityId,
    this.batchId,
  });

  @override
  State<ActivityBookingPage> createState() => _ActivityBookingPageState();
}

class _ActivityBookingPageState extends State<ActivityBookingPage>
    with SingleTickerProviderStateMixin {
  // State management
  String? selectedChildId;
  ChildService.Child? selectedChild;
  ActivityDetail? activityData;
  List<ChildService.Child> children = [];
  List<GetEnrollment> userEnrollments = [];

  // Loading states
  bool _isLoading = true;
  bool _isLoadingChildren = false;
  bool _isEnrolling = false;

  // Error states
  String? _errorMessage;

  // Animation controller for smooth transitions
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Initialize animations for smooth UI transitions
  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  /// Load all required data concurrently for better performance
  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Load data concurrently for better performance
      await Future.wait([
        _loadActivityData(),
        _loadChildren(),
        _loadEnrollments(),
      ]);

      if (mounted) {
        setState(() => _isLoading = false);
        _animationController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = _formatErrorMessage(e);
          _isLoading = false;
        });
      }
    }
  }

  /// Format error messages for user-friendly display
  String _formatErrorMessage(dynamic error) {
    final errorString = error.toString();
    if (errorString.contains('Network') || errorString.contains('connection')) {
      return 'Please check your internet connection and try again.';
    }
    if (errorString.contains('Authentication') || errorString.contains('401')) {
      return 'Please log in again to continue.';
    }
    if (errorString.contains('404') || errorString.contains('not found')) {
      return 'The requested activity could not be found.';
    }
    return 'Something went wrong. Please try again.';
  }

  /// Load activity data with error handling
  Future<void> _loadActivityData() async {
    try {
      final activity = await ActivityService.getActivityDetails(
        widget.activityId,
      );
      if (activity == null) {
        throw Exception('Activity not found');
      }
      if (mounted) {
        setState(() => activityData = activity);
      }
    } catch (e) {
      throw Exception('Failed to load activity details: ${e.toString()}');
    }
  }

  /// Load children with caching optimization
  Future<void> _loadChildren() async {
    if (!mounted) return;

    setState(() => _isLoadingChildren = true);

    try {
      // Try cache first for better performance
      final cachedChildren = ChildService.GetChildservices.getCachedChildren();

      List<ChildService.Child> childrenList;
      if (cachedChildren != null && cachedChildren.isNotEmpty) {
        childrenList = cachedChildren;
      } else {
        childrenList = await ChildService.GetChildservices.fetchChildren();
      }

      if (mounted) {
        setState(() {
          children = childrenList;
          if (selectedChildId == null && children.isNotEmpty) {
            selectedChildId = children.first.id.toString();
            selectedChild = children.first;
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading children: $e');
      if (mounted) {
        setState(() => children = []);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingChildren = false);
      }
    }
  }

  /// Load enrollments with error handling
  Future<void> _loadEnrollments() async {
    try {
      // Use the specific activity enrollment check
      final enrollments = await GetEnrollmentService.getEnrollmentsByActivity(
        widget.activityId,
      );
      if (mounted) {
        setState(() => userEnrollments = enrollments);
      }
    } catch (e) {
      debugPrint('Error loading enrollments: $e');
      if (mounted) {
        setState(() => userEnrollments = []);
      }
    }
  }

  void _selectChild(ChildService.Child child) {
    if (mounted) {
      setState(() {
        selectedChildId = child.id.toString();
        selectedChild = child;
      });
    }
  }

  /// Check if the selected child is already enrolled
  bool get _isChildAlreadyEnrolled {
    /// Select a child for enrollment
    if (selectedChild == null) return false;

    return userEnrollments.any(
      (enrollment) =>
          enrollment.child?.id == selectedChild!.id &&
          enrollment.activity?.id == widget.activityId &&
          (enrollment.status.toLowerCase() == 'enrolled' ||
              enrollment.status.toLowerCase() == 'reenrolled' ||
              enrollment.status.toLowerCase() == 'waitlist'),
    );
  }

  /// Check if any child is enrolled in this activity
  bool get _hasAnyChildEnrolled {
    if (children.isEmpty) return false;

    for (final child in children) {
      final isEnrolled = userEnrollments.any(
        (enrollment) =>
            enrollment.child?.id == child.id &&
            enrollment.activity?.id == widget.activityId &&
            (enrollment.status.toLowerCase() == 'enrolled' ||
                enrollment.status.toLowerCase() == 'reenrolled' ||
                enrollment.status.toLowerCase() == 'waitlist'),
      );
      if (isEnrolled) return true;
    }
    return false;
  }

  /// Get appropriate button text based on current state
  String get _enrollmentButtonText {
    if (children.isEmpty) return 'Add Child to Enroll';
    if (activityData?.isActive != true) return 'Currently Inactive';
    if (_isChildAlreadyEnrolled || _hasAnyChildEnrolled)
      return 'Already Enrolled';
    return 'Enroll Now';
  }

  /// Check if enrollment button should be enabled
  bool get _isEnrollmentButtonEnabled {
    if (children.isEmpty) return true; // Allow navigation to AddChildPage
    if (activityData?.isActive != true) return false;
    if (_isChildAlreadyEnrolled || _hasAnyChildEnrolled) return false;
    return !_isEnrolling;
  }

  /// Calculate age from date of birth
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

  /// Handle enrollment process with comprehensive error handling
  Future<void> _handleEnrollment() async {
    // If no children, navigate to AddChildPage
    if (children.isEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => AddChildPage()),
      ).then((_) {
        // Refresh children list when returning from AddChildPage
        _loadChildren();
      });
      return;
    }

    if (selectedChild == null || activityData == null) {
      _showErrorMessage('Please select a child to continue.');
      return;
    }

    if (_isChildAlreadyEnrolled) {
      _showErrorMessage('This child is already enrolled in this activity.');
      return;
    }

    final shouldEnroll = await _showEnrollmentConfirmationDialog();
    if (shouldEnroll != true) return;

    if (!mounted) return;

    setState(() => _isEnrolling = true);

    try {
      // Use the new EnrollmentService
      final enrollmentResponse = await EnrollmentService.enrollInActivity(
        childId: selectedChild!.id,
        activityId: widget.activityId,
        notes: null, // Optional: You can add notes input field if needed
      );

      if (mounted) {
        setState(() => _isEnrolling = false);

        if (enrollmentResponse.success && enrollmentResponse.data != null) {
          // Clear enrollment cache and refresh data
          EnrollmentService.clearEnrollmentCache();
          GetEnrollmentService.clearCache();
          await _loadEnrollments(); // Refresh enrollments

          // Show success dialog
          await _showSuccessWithConfirmationDialog(enrollmentResponse);
        } else {
          // Show error message
          _showErrorMessage(enrollmentResponse.error ?? 'Enrollment failed');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isEnrolling = false);
        _showErrorMessage('An unexpected error occurred. Please try again.');
      }
    }
  }

  /// Show error message with auto-dismiss
  void _showErrorMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  /// Show success message using ConfirmationDialog
  /// Show success message using ConfirmationDialog
  Future<void> _showSuccessWithConfirmationDialog(
    EnrollmentApiResponse response,
  ) async {
    if (!mounted || response.data == null) return;

    final enrollment = response.data!;
    final statusIcon = _getStatusIcon(enrollment.status);
    final statusColor = _getStatusColor(enrollment.status);

    // Build detailed message
    String detailMessage =
        '${enrollment.child.name} has been ${_getStatusDisplay(enrollment.status).toLowerCase()} in ${enrollment.activity.name}!\n\n';

    if (enrollment.waitlistPosition != null) {
      detailMessage += 'Waitlist Position: #${enrollment.waitlistPosition}';
    }

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 16),
                    // Icon
                    Icon(statusIcon, color: statusColor, size: 64),
                    const SizedBox(height: 16),
                    // Title
                    Text(
                      enrollment.status.toLowerCase() == 'waitlist'
                          ? 'Added to Waitlist!'
                          : 'Congratulations!',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    // Message
                    Text(
                      detailMessage,
                      style: const TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 5),
                    // Centered View Schedule Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop(true);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: statusColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'View Schedule',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Close button in top-right corner
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        );
      },
    );

    // Replace the existing navigation in _showSuccessWithConfirmationDialog method

    if (result == true && mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);

      // Use the global key to access home page state
      homePageKey.currentState?.changeTab(1); // Index 1 is CalendarScreen
    }
  }

  /// Show enrollment confirmation dialog
  /// Show enrollment confirmation dialog using ConfirmationDialog utility
  Future<bool?> _showEnrollmentConfirmationDialog() async {
    if (selectedChild == null || activityData == null) return false;

    return ConfirmationDialog.show(
      context: context,
      title: 'Confirm Enrollment',
      message:
          'You are about to enroll ${selectedChild!.name.split(' ').first} in ${activityData!.name}',
      confirmText: 'Enroll Now',
      cancelText: 'Cancel',
      confirmColor: Colors.deepOrange,
      iconColor: Colors.deepOrange,
      icon: Icons.school,
    );
  }

  /// Handle share functionality - allows sharing activity details via WhatsApp, SMS, Email, etc.
  Future<void> _handleShare() async {
    if (activityData == null) {
      _showErrorMessage('Unable to share activity details at this time.');
      return;
    }

    try {
      final activity = activityData!;

      // Build share message
      final StringBuffer message = StringBuffer();

      // Activity name and batch
      message.writeln('🎯 ${activity.name}');
      if (activity.batchName.isNotEmpty) {
        message.writeln('Batch: ${activity.batchName}');
      }
      message.writeln();

      // Category and subcategory
      if (activity.subcategory.isNotEmpty) {
        message.writeln('📚 ${activity.category} - ${activity.subcategory}');
      } else {
        message.writeln('📚 ${activity.category}');
      }
      message.writeln();

      // Age range
      message.writeln(
        '👶 Recommended for: ${activity.ageRange.isNotEmpty ? activity.ageRange : "All ages"}',
      );
      message.writeln();

      // Price
      message.writeln(
        '💰 Fee: ₹${activity.price.toStringAsFixed(0)}${_getPaymentTypeDisplay(activity.paymentType)}',
      );
      message.writeln();

      // Schedule
      message.writeln('📅 Schedule: ${_formatScheduleWithTime()}');
      message.writeln();

      // Location
      if (activity.venue.isNotEmpty) {
        message.writeln('📍 Location: ${activity.venue}, ${activity.society}');
      } else {
        message.writeln('📍 Location: ${activity.society}');
      }
      message.writeln();

      // Batch size
      message.writeln('👥 Batch Size: ${activity.capacity} children');
      message.writeln();

      // Start date
      message.writeln('🗓️ Start Date: ${_formatDate(activity.startDate)}');
      message.writeln();

      // Instructor
      if (activity.instructor.name.isNotEmpty) {
        message.writeln('👨‍🏫 Instructor: ${activity.instructor.name}');
        message.writeln();
      }

      // Description (trimmed if too long)
      if (activity.description.isNotEmpty) {
        String desc = activity.description;
        if (desc.length > 150) {
          desc = '${desc.substring(0, 150)}...';
        }
        message.writeln('ℹ️ About:');
        message.writeln(desc);
        message.writeln();
      }

      // Activity ID for reference
      message.writeln('---');
      message.writeln('Activity ID: ${widget.activityId}');
      if (widget.batchId != null) {
        message.writeln('Batch ID: ${widget.batchId}');
      }

      // Optional: Add your app link or website
      // message.writeln();
      // message.writeln('Download Klayons App: [your app link]');

      // Share the message (simple version without result handling)
      await Share.share(
        message.toString(),
        subject: '${activity.name} - Activity Details',
      );
    } catch (e) {
      debugPrint('Error sharing activity: $e');
      if (mounted) {
        _showErrorMessage('Failed to share activity. Please try again.');
      }
    }
  }

  /// Build child selection and enrollment button in same container
  Widget _buildChildSelectionWidget() {
    if (children.isEmpty) {
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Book for section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    'Enroll:',
                    style: AppTextStyles.bodyMedium(context).copyWith(
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        Text(
                          "  No Child Profiles Added",
                          style: AppTextStyles.bodySmall(context).copyWith(
                            letterSpacing: 0.01,
                            color: Colors.grey[700],
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AddChildPage(),
                              ),
                            ).then((_) {
                              _loadChildren();
                            });
                          },
                          child: const Text(
                            'Add now?',
                            style: TextStyle(
                              color: Colors.deepOrange,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 5),

            // Enroll button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: null, // Disabled when no children
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                    disabledBackgroundColor: Colors.grey[300],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Enroll Now',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // ✅ FIX: Check enrollment status for the CURRENTLY SELECTED child
    final bool isSelectedChildEnrolled =
        selectedChild != null &&
        userEnrollments.any(
          (enrollment) =>
              enrollment.child?.id == selectedChild!.id &&
              enrollment.activity?.id == widget.activityId &&
              (enrollment.status.toLowerCase() == 'enrolled' ||
                  enrollment.status.toLowerCase() == 'reenrolled' ||
                  enrollment.status.toLowerCase() == 'waitlist'),
        );

    // ✅ FIX: Determine button state based on selected child
    final bool isButtonEnabled =
        activityData?.isActive == true &&
        !isSelectedChildEnrolled &&
        !_isEnrolling;

    final String buttonText = activityData?.isActive != true
        ? 'Currently Inactive'
        : isSelectedChildEnrolled
        ? 'Already Enrolled'
        : 'Enroll Now';

    final Color buttonColor = isButtonEnabled ? Colors.deepOrange : Colors.grey;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Book for section with Add Child option
        Row(
          children: [
            Text(
              'Enroll:',
              style: AppTextStyles.bodyMedium(
                context,
              ).copyWith(color: Colors.grey[700], fontWeight: FontWeight.w500),
            ),
            SizedBox(width: 10),
            // Children chips
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: children.map((child) {
                    final isSelected = selectedChildId == child.id.toString();
                    final childAge = _calculateAge(child.dob);
                    final ageInt = int.tryParse(childAge) ?? 0;
                    final isAgeWarning = ageInt < 4;
                    final isChildEnrolled = userEnrollments.any(
                      (enrollment) =>
                          enrollment.child?.id == child.id &&
                          enrollment.activity?.id == widget.activityId &&
                          (enrollment.status.toLowerCase() == 'enrolled' ||
                              enrollment.status.toLowerCase() == 'reenrolled' ||
                              enrollment.status.toLowerCase() == 'waitlist'),
                    );

                    return GestureDetector(
                      onTap: () => _selectChild(child),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.orangeHighlight
                              : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primaryOrange!
                                : Colors.grey[300]!,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${child.name.split(' ').first} ',
                              style: TextStyle(
                                fontSize: 12,
                                color: isSelected
                                    ? AppColors.primaryOrange
                                    : Colors.grey[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (isChildEnrolled) ...[
                              const SizedBox(width: 4),
                              Icon(
                                Icons.check_circle,
                                size: 12,
                                color: isSelected
                                    ? AppColors.primaryOrange
                                    : Colors.grey,
                              ),
                            ] else if (isAgeWarning) ...[
                              const SizedBox(width: 4),
                              Icon(
                                Icons.error_outline,
                                size: 12,
                                color: isSelected
                                    ? AppColors.primaryOrange
                                    : Colors.orange[600],
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),

        // Show enrollment status or age warning
        if (selectedChild != null) ...[
          const SizedBox(height: 12),
          Builder(
            builder: (context) {
              // ✅ Check if SELECTED child is enrolled
              if (isSelectedChildEnrolled) {
                // Optionally show enrollment info here
                return const SizedBox.shrink();
              }

              final childAge = _calculateAge(selectedChild!.dob);
              final ageInt = int.tryParse(childAge) ?? 0;
              if (ageInt < 4) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.orange[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: Colors.orange[600],
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'This child may not meet the minimum age requirement for this activity.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange[800],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],

        // Enroll button - ✅ Now uses computed values that update with selected child
        const SizedBox(height: 5),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: isButtonEnabled ? _handleEnrollment : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonColor,
                disabledBackgroundColor: Colors.grey[300],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: _isEnrolling
                  ? const Row(
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
                      buttonText,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  String _getPaymentTypeDisplay(String paymentType) {
    switch (paymentType.toLowerCase()) {
      case 'monthly':
        return '/month';
      case 'annual':
        return '/year';
      case 'quarterly':
        return '/quarter';
      case 'one-time':
        return '';
      default:
        return '';
    }
  }

  /// Get activity icon based on category
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

  String _formatScheduleWithTime() {
    if (activityData?.schedule.timeSlots.isEmpty ?? true) {
      return 'Schedule not available';
    }

    final timeSlots = activityData!.schedule.timeSlots;

    // Group time slots by their time range
    Map<String, List<String>> timeToDay = {};

    for (var timeSlot in timeSlots) {
      String timeRange = '${timeSlot.startTime} - ${timeSlot.endTime}';

      if (!timeToDay.containsKey(timeRange)) {
        timeToDay[timeRange] = [];
      }
      timeToDay[timeRange]!.addAll(timeSlot.days);
    }

    if (timeToDay.isEmpty) {
      return 'Schedule not available';
    }

    // Check if all days have the same time
    if (timeToDay.length == 1) {
      // All days have same time - Format: "Every Wed & Sat | 5pm"
      String timeRange = timeToDay.keys.first;
      List<String> days = timeToDay[timeRange]!;
      days.sort((a, b) => _getDayOrder(a).compareTo(_getDayOrder(b)));

      String timeOnly = _extractStartTime(timeRange);
      return 'Every ${days.join(' & ')} | $timeOnly';
    } else {
      // Different times - Format: "Every Sat at 10am | Sun at 12pm"
      List<String> parts = [];

      // Sort by day order
      var sortedEntries = timeToDay.entries.toList()
        ..sort((a, b) {
          int dayOrderA = a.value
              .map(_getDayOrder)
              .reduce((a, b) => a < b ? a : b);
          int dayOrderB = b.value
              .map(_getDayOrder)
              .reduce((a, b) => a < b ? a : b);
          return dayOrderA.compareTo(dayOrderB);
        });

      for (var entry in sortedEntries) {
        String timeRange = entry.key;
        List<String> days = entry.value;
        days.sort((a, b) => _getDayOrder(a).compareTo(_getDayOrder(b)));

        String timeOnly = _extractStartTime(timeRange);

        for (String day in days) {
          parts.add('$day at $timeOnly');
        }
      }

      return 'Every ${parts.join(' | ')}';
    }
  }

  /// Get day order for sorting (MON=1, TUE=2, etc.)
  int _getDayOrder(String day) {
    const dayOrder = {
      'MON': 1,
      'MONDAY': 1,
      'TUE': 2,
      'TUESDAY': 2,
      'WED': 3,
      'WEDNESDAY': 3,
      'THU': 4,
      'THURSDAY': 4,
      'FRI': 5,
      'FRIDAY': 5,
      'SAT': 6,
      'SATURDAY': 6,
      'SUN': 7,
      'SUNDAY': 7,
    };
    return dayOrder[day.toUpperCase()] ?? 8;
  }

  // Updated UI widget
  Widget _buildScheduleDisplay() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start, // ✅ Add this line
      children: [
        Padding(
          padding: const EdgeInsets.only(
            top: 2,
          ), // ✅ Add small top padding to align with text
          child: Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            _formatScheduleWithTime(),
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  /// Extract start time from time range (e.g., "05:00 PM - 07:00 PM" -> "5pm")
  String _extractStartTime(String timeRange) {
    // Split by '-' to get start time
    String startTime = timeRange.split('-')[0].trim();

    // Convert to lowercase and remove spaces
    startTime = startTime.toLowerCase().replaceAll(' ', '');

    // Remove leading zero (e.g., "05:00pm" -> "5:00pm")
    startTime = startTime.replaceFirst(RegExp(r'^0'), '');

    // Remove :00 if present (e.g., "5:00pm" -> "5pm")
    startTime = startTime.replaceAll(':00', '');

    return startTime;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isLoading
          ? _buildLoadingWidget()
          : _errorMessage != null
          ? _buildErrorWidget()
          : activityData != null
          ? _buildContent()
          : _buildEmptyWidget(),
    );
  }

  /// Build loading widget with animation
  Widget _buildLoadingWidget() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.deepOrange),
          SizedBox(height: 16),
          Text(
            'Loading activity details...',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  /// Build error widget with retry functionality
  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
            const SizedBox(height: 16),
            Text(
              'Error Loading Details',
              style: AppTextStyles.titleMedium(
                context,
              ).copyWith(fontWeight: FontWeight.w600, color: Colors.grey[700]),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: AppTextStyles.bodyMedium(
                context,
              ).copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
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
  }

  /// Build empty state widget
  Widget _buildEmptyWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No Data Available',
            style: AppTextStyles.titleMedium(
              context,
            ).copyWith(fontWeight: FontWeight.w600, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  /// Build main content with fade animation
  Widget _buildContent() {
    final activity = activityData!;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header image with overlay buttons
                  _buildHeaderImage(activity),

                  // Activity details
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildActivityHeader(activity),
                        const SizedBox(height: 16),
                        _buildPriceSection(activity),
                        const SizedBox(height: 16),
                        _buildScheduleInfo(activity),
                        const SizedBox(height: 20),
                        _buildDescriptionSection(activity),
                        const SizedBox(height: 20),
                        _buildInstructorSection(activity),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Fixed child selection widget at bottom
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Column(
                children: [
                  SizedBox(height: 8),
                  _buildChildSelectionWidget(),
                  SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build header image with navigation buttons
  Widget _buildHeaderImage(ActivityDetail activity) {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          height: 300,
          child: activity.bannerImageUrl.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: activity.bannerImageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[200],
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: Colors.deepOrange,
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[200],
                    child: Icon(
                      _getActivityIcon(activity.category),
                      size: 100,
                      color: Colors.grey[400],
                    ),
                  ),
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

        // Overlay buttons
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Back button
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
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
                ),

                // Share button
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.share,
                      color: AppColors.darkElements,
                      size: 24,
                    ),
                    onPressed: () {
                      _handleShare();
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Build activity header section
  Widget _buildActivityHeader(ActivityDetail activity) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (activity.subcategory.isNotEmpty) ...[
          const SizedBox(width: 8),
          Transform.translate(
            offset: Offset(-4, 0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primaryOrange),
                color: AppColors.orangeHighlight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                activity.subcategory,
                style: AppTextStyles.bodySmall(context).copyWith(
                  fontSize: 12,
                  color: AppColors.primaryOrange,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
        SizedBox(height: 5),
        Row(
          children: [
            Flexible(
              child: Text(
                activity.batchName.isNotEmpty
                    ? '${activity.name} - ${activity.batchName}'
                    : activity.name,
                style: AppTextStyles.titleLarge(
                  context,
                ).copyWith(letterSpacing: -0.2, fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        RichText(
          text: TextSpan(
            style: AppTextStyles.bodySmall(
              context,
            ).copyWith(color: Colors.grey[800], fontSize: 14),
            children: [
              TextSpan(text: 'Recommended for '),
              TextSpan(
                text: activity.ageRange.isNotEmpty
                    ? activity.ageRange
                    : 'All ages',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Build price section
  Widget _buildPriceSection(ActivityDetail activity) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '₹${activity.price.toStringAsFixed(0)}',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.deepOrange,
              ),
            ),
            if (_getPaymentTypeDisplay(activity.paymentType).isNotEmpty)
              Flexible(
                child: Text(
                  _getPaymentTypeDisplay(activity.paymentType),
                  style: AppTextStyles.bodyMedium(
                    context,
                  ).copyWith(color: AppColors.primaryOrange),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
          ],
        ),
        RichText(
          text: TextSpan(
            style: AppTextStyles.bodyMedium(
              context,
            ).copyWith(color: AppColors.primaryOrange),
            children: [
              TextSpan(
                text:
                    '${activity.sessionCount.toString()} sessions, ${activity.sessionDuration.toString()}mins each',
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Add this helper method to check if activity has started:
  bool _isActivityStarted(Object? dateValue) {
    if (dateValue == null) return false;

    try {
      DateTime startDate;

      if (dateValue is String) {
        startDate = DateTime.parse(dateValue);
      } else if (dateValue is int) {
        startDate = DateTime.fromMillisecondsSinceEpoch(dateValue);
      } else {
        return false;
      }

      // Compare only dates (ignore time)
      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);
      final activityDate = DateTime(
        startDate.year,
        startDate.month,
        startDate.day,
      );

      return activityDate.isBefore(todayDate);
    } catch (e) {
      return false;
    }
  }

  /// Build schedule information
  Widget _buildScheduleInfo(ActivityDetail activity) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Schedule with time (combined)
          _buildScheduleDisplay(), // ✅ NEW METHOD
          const SizedBox(height: 8),

          // Location
          Row(
            children: [
              Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  activity.venue.isNotEmpty
                      ? '${activity.venue}, ${activity.society}'
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
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.reduce_capacity_outlined,
                size: 16,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Batch Size: ${(activityData?.capacity ?? 0).toString()} children',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                _isActivityStarted(activityData?.startDate)
                    ? 'Batch Ongoing'
                    : 'Start Date: ${_formatDate(activityData?.startDate)}',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.primaryOrange,
                  fontWeight: FontWeight.w500,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(Object? dateValue) {
    if (dateValue == null) return 'N/A';

    try {
      DateTime date;

      if (dateValue is String) {
        date = DateTime.parse(dateValue);
      } else if (dateValue is int) {
        date = DateTime.fromMillisecondsSinceEpoch(dateValue);
      } else {
        return 'Invalid Date';
      }

      String getDaySuffix(int day) {
        if (day >= 11 && day <= 13) return 'th';
        switch (day % 10) {
          case 1:
            return 'st';
          case 2:
            return 'nd';
          case 3:
            return 'rd';
          default:
            return 'th';
        }
      }

      final day = date.day;
      final month = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ][date.month - 1];

      return '$day${getDaySuffix(day)} $month';
    } catch (e) {
      return 'Invalid Date';
    }
  }

  /// Build description section
  Widget _buildDescriptionSection(ActivityDetail activity) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Description',
            style: AppTextStyles.titleMedium(
              context,
            ).copyWith(fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 5),
          Text(
            activity.description.isNotEmpty
                ? activity.description
                : 'This ${activity.category.toLowerCase()} activity is designed to provide students with hands-on learning experience. Join us for an engaging and educational journey that will help develop new skills and build confidence.',
            style: AppTextStyles.bodyMedium(
              context,
            ).copyWith(height: 1.6, color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }

  /// Build instructor section
  // Add this state variable in your StatefulWidget
  bool _isInstructorExpanded = false;

  Widget _buildInstructorSection(ActivityDetail activity) {
    const int maxLines = 3;

    // Calculate if text would exceed maxLines
    final textPainter =
        TextPainter(
          text: TextSpan(
            text: activity.instructor.profile,
            style: AppTextStyles.bodySmall(
              context,
            ).copyWith(color: Colors.grey[600]),
          ),
          maxLines: maxLines,
          textDirection: TextDirection.ltr,
        )..layout(
          maxWidth: MediaQuery.of(context).size.width - 64,
        ); // Account for padding

    final bool hasLongDescription = textPainter.didExceedMaxLines;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Meet the instructor',
            style: AppTextStyles.titleMedium(
              context,
            ).copyWith(fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 16),

          // 3. Instructor Avatar - Updated to show initials for multi-word names
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: AppColors.orangeHighlight,
                backgroundImage: activity.instructor.avatarUrl != null
                    ? NetworkImage(activity.instructor.avatarUrl!)
                    : null,
                child: activity.instructor.avatarUrl == null
                    ? Text(
                        _getInstructorInitials(activity.instructor.name),
                        style: GoogleFonts.poetsenOne(
                          textStyle: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryOrange,
                          ),
                        ),
                      )
                    : null,
              ),
              SizedBox(width: 15),
              Text(
                activity.instructor.name.isNotEmpty
                    ? activity.instructor.name
                    : 'Instructor Name',
                style: AppTextStyles.titleMedium(
                  context,
                ).copyWith(fontWeight: FontWeight.w500, color: Colors.black87),
              ),
            ],
          ),

          const SizedBox(height: 6),

          // Instructor Description
          if (activity.instructor.profile.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              activity.instructor.profile,
              style: AppTextStyles.bodySmall(
                context,
              ).copyWith(color: Colors.grey[600]),
              maxLines: _isInstructorExpanded ? null : maxLines,
              overflow: _isInstructorExpanded
                  ? TextOverflow.visible
                  : TextOverflow.ellipsis,
            ),

            // Read More / Read Less Button
            if (hasLongDescription) ...[
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isInstructorExpanded = !_isInstructorExpanded;
                  });
                },
                child: Text(
                  _isInstructorExpanded ? 'Read less' : 'Read more',
                  style: TextStyle(
                    color: AppColors.primaryOrange,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  String _getInstructorInitials(String name) {
    if (name.isEmpty) return 'I';

    final words = name.trim().split(RegExp(r'\s+'));

    if (words.length == 1) {
      // Single word: return first letter
      return words[0].substring(0, 1).toUpperCase();
    } else {
      // Multiple words: return first letter of first two words
      return (words[0].substring(0, 1) + words[1].substring(0, 1))
          .toUpperCase();
    }
  }

  /// Get status color based on enrollment status
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'enrolled':
      case 'reenrolled':
        return AppColors.primaryOrange;
      case 'waitlist':
        return AppColors.primaryOrange;
      case 'unenrolled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  /// Get status icon based on enrollment status
  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'enrolled':
      case 'reenrolled':
        return Icons.check_circle;
      case 'waitlist':
        return Icons.schedule;
      case 'unenrolled':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  /// Get status display text
  String _getStatusDisplay(String status) {
    switch (status.toLowerCase()) {
      case 'enrolled':
        return 'Enrolled';
      case 'reenrolled':
        return 'Re-enrolled';
      case 'waitlist':
        return 'Waitlisted';
      case 'unenrolled':
        return 'Unenrolled';
      default:
        return status.toUpperCase();
    }
  }
}
