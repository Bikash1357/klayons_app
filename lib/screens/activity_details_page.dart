import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:klayons/screens/bottom_screens/uesr_profile/Childs/add_child.dart';
import 'package:klayons/utils/styles/fonts.dart';
import 'package:klayons/utils/styles/errorMessage.dart';
import '../services/activity/activityDetailsService.dart';
import '../services/Enrollments/get_enrolled_service.dart';
import '../services/Enrollments/post_enrollment_service.dart';
import '../services/user_child/get_ChildServices.dart' as ChildService;
import '../services/Enrollments/enrollementModel.dart';
import 'package:klayons/utils/colour.dart';

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
  String? _successMessage;

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

  /// Select a child for enrollment
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
          await _showSuccessDialog(enrollmentResponse);
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

  /// Show success dialog with new API response structure
  Future<void> _showSuccessDialog(EnrollmentApiResponse response) async {
    if (!mounted || response.data == null) return;

    final enrollment = response.data!;

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        final statusColor = _getStatusColor(enrollment.status);
        final statusIcon = _getStatusIcon(enrollment.status);

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Success Icon with status-based color
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(statusIcon, color: Colors.white, size: 50),
                ),
                const SizedBox(height: 24),

                // Title
                Text(
                  enrollment.status.toLowerCase() == 'waitlist'
                      ? 'Added to Waitlist!'
                      : 'Congratulations!',
                  style: AppTextStyles.titleLarge(context).copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                // Success Message
                Text(
                  '${enrollment.child.name} has been ${_getStatusDisplay(enrollment.status).toLowerCase()} in ${enrollment.activity.name}!',
                  style: AppTextStyles.bodyMedium(
                    context,
                  ).copyWith(color: Colors.grey[700], height: 1.4),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // Enrollment Details
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Status:',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _getStatusDisplay(enrollment.status),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Date:',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          Text(
                            _formatEnrollmentDate(enrollment.timestamp),
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),

                      // Show waitlist position if applicable
                      if (enrollment.waitlistPosition != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Waitlist Position:',
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                            Text(
                              '#${enrollment.waitlistPosition}',
                              style: TextStyle(
                                color: Colors.orange[700],
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ],

                      // Show price information
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Fee:',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          Text(
                            '₹${enrollment.activity.price}/${enrollment.activity.paymentType}',
                            style: const TextStyle(
                              color: Colors.deepOrange,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Show notes if available
                if (enrollment.notes != null &&
                    enrollment.notes!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Notes:',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.blue[800],
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          enrollment.notes!,
                          style: TextStyle(
                            color: Colors.blue[700],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Done Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pop(); // Go back to previous screen
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: statusColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
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

  /// Show enrollment confirmation dialog
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
              const Icon(Icons.school, color: Colors.deepOrange, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Confirm Enrollment',
                  style: AppTextStyles.titleMedium(context).copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
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
                style: AppTextStyles.bodyMedium(
                  context,
                ).copyWith(color: Colors.black87, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.deepOrange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.currency_rupee,
                      size: 18,
                      color: Color(0xFFFF6D00),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Fee: ₹${activityData!.price.toStringAsFixed(0)}/${activityData!.paymentType}',
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
              child: const Text(
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

  /// Build child selection widget with age validation
  /// Build child selection and enrollment button in same container
  /// Build child selection and enrollment button in same container
  Widget _buildChildSelectionWidget() {
    // Get total capacity directly from backend
    final totalCapacity = activityData?.capacity ?? 0;

    if (children.isEmpty) {
      return Container(
        width: double.infinity,

        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Book for section
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  'Book for:',
                  style: AppTextStyles.bodyMedium(context).copyWith(
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  "  No Child Profiles Added",
                  style: AppTextStyles.bodySmall(
                    context,
                  ).copyWith(letterSpacing: 0.01, color: Colors.grey[700]),
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
            const SizedBox(height: 4),

            // Total spots text
            Center(
              child: Text(
                '$totalCapacity ${totalCapacity == 1 ? 'spot' : 'spots'} remaining',
                style: TextStyle(
                  fontSize: 14,
                  color: totalCapacity <= 5
                      ? Colors.red[600]
                      : AppColors.primaryOrange,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Enroll button
            SizedBox(
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
          ],
        ),
      );
    }

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
          // Book for section with Add Child option
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Book for: ',
                style: AppTextStyles.bodyMedium(context).copyWith(
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
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
                  'Add Child',
                  style: TextStyle(
                    color: Colors.deepOrange,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),

          // Children chips
          Wrap(
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
                        ? (isChildEnrolled
                              ? Colors.green
                              : (isAgeWarning
                                    ? Colors.orange
                                    : Colors.deepOrange))
                        : (isChildEnrolled
                              ? Colors.green[50]
                              : (isAgeWarning
                                    ? Colors.orange[50]
                                    : Colors.grey[100])),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? (isChildEnrolled
                                ? Colors.green[300]!
                                : (isAgeWarning
                                      ? Colors.orange[300]!
                                      : AppColors.highlight2))
                          : (isChildEnrolled
                                ? Colors.green[200]!
                                : (isAgeWarning
                                      ? Colors.orange[200]!
                                      : Colors.grey[300]!)),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${child.name.split(' ').first} ($childAge)',
                        style: TextStyle(
                          fontSize: 12,
                          color: isSelected
                              ? Colors.white
                              : (isChildEnrolled
                                    ? Colors.green[800]
                                    : (isAgeWarning
                                          ? Colors.orange[800]
                                          : Colors.grey[700])),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (isChildEnrolled) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.check_circle,
                          size: 12,
                          color: isSelected ? Colors.white : Colors.green[600],
                        ),
                      ] else if (isAgeWarning) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.warning,
                          size: 12,
                          color: isSelected ? Colors.white : Colors.orange[600],
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          // Show enrollment status or age warning
          if (selectedChild != null) ...[
            const SizedBox(height: 12),
            Builder(
              builder: (context) {
                final isChildEnrolled = userEnrollments.any(
                  (enrollment) =>
                      enrollment.child?.id == selectedChild!.id &&
                      enrollment.activity?.id == widget.activityId &&
                      (enrollment.status.toLowerCase() == 'enrolled' ||
                          enrollment.status.toLowerCase() == 'reenrolled' ||
                          enrollment.status.toLowerCase() == 'waitlist'),
                );

                if (isChildEnrolled) {
                  final enrollment = userEnrollments.firstWhere(
                    (enrollment) =>
                        enrollment.child?.id == selectedChild!.id &&
                        enrollment.activity?.id == widget.activityId,
                  );

                  return Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.green[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 16,
                          color: Colors.green[600],
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'This child is already ${enrollment.status.toLowerCase()} in this activity.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green[800],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final childAge = _calculateAge(selectedChild!.dob);
                final ageInt = int.tryParse(childAge) ?? 0;
                if (ageInt < 4) {
                  return Container(
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
                        const SizedBox(width: 8),
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
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],

          // Total spots text (from backend capacity field)
          const SizedBox(height: 12),
          Text(
            '$totalCapacity ${totalCapacity == 1 ? 'spot' : 'spots'} remaining',
            style: TextStyle(
              fontSize: 14,
              color: totalCapacity <= 5
                  ? Colors.red[600]
                  : AppColors.primaryOrange,
              fontWeight: FontWeight.w500,
            ),
          ),

          // Enroll button
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isEnrollmentButtonEnabled ? _handleEnrollment : null,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    activityData?.isActive == true &&
                        !(_isChildAlreadyEnrolled || _hasAnyChildEnrolled)
                    ? Colors.deepOrange
                    : Colors.grey,
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
                      _enrollmentButtonText,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
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

  /// Format schedule display
  String _formatScheduleDisplay() {
    if (activityData?.schedules.isEmpty ?? true)
      return 'Schedule not available';

    final schedule = activityData!.schedules.first;
    if (schedule.nextOccurrences.isNotEmpty) {
      final days = schedule.nextOccurrences
          .map((occ) => occ.day)
          .toSet()
          .toList();
      return 'Every ${days.join(', ')}';
    }
    return 'Schedule available';
  }

  /// Get time slots display
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
              padding: const EdgeInsets.all(16),
              child: _buildChildSelectionWidget(),
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
                      // Implement share functionality
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
        Row(
          children: [
            Flexible(
              child: Text(
                activity.batchName.isNotEmpty
                    ? '${activity.name} - ${activity.batchName}'
                    : activity.name,
                style: AppTextStyles.titleMedium(context),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            if (activity.subcategory.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.primaryOrange),
                  color: AppColors.primaryOrange.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  activity.subcategory,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Recommended for ${activity.ageRange.isNotEmpty ? activity.ageRange : 'All ages'}',
          style: AppTextStyles.bodySmall(
            context,
          ).copyWith(color: Colors.grey[600]),
        ),
      ],
    );
  }

  /// Build price section
  Widget _buildPriceSection(ActivityDetail activity) {
    return Row(
      children: [
        Text(
          '₹${activity.price.toStringAsFixed(0)}',
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.deepOrange,
          ),
        ),
        const SizedBox(width: 8),
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
    );
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
          // Schedule
          Row(
            children: [
              Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
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
          const SizedBox(height: 8),

          // Time slots
          Row(
            children: [
              Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
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

          // Status
          Row(
            children: [
              Icon(
                activity.isActive ? Icons.schedule : Icons.pause_circle,
                size: 16,
                color: activity.isActive ? Colors.green[600] : Colors.red[600],
              ),
              const SizedBox(width: 6),
              Text(
                activity.isActive ? 'Enrollment Open!' : 'Currently Inactive',
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
        ],
      ),
    );
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
            'DESCRIPTION',
            style: AppTextStyles.titleMedium(context).copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
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

  /// Build enrollment button
  Widget _buildEnrollmentButton(ActivityDetail activity) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isEnrollmentButtonEnabled ? _handleEnrollment : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: children.isEmpty
              ? Colors.blue[600] // Different color for "Add Child" action
              : (activity.isActive &&
                        !(_isChildAlreadyEnrolled || _hasAnyChildEnrolled)
                    ? Colors.deepOrange
                    : Colors.grey),
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
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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
                _enrollmentButtonText,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  /// Build instructor section
  Widget _buildInstructorSection(ActivityDetail activity) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Meet the instructor',
          style: AppTextStyles.titleMedium(
            context,
          ).copyWith(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[100]!),
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
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepOrange,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity.instructor.name.isNotEmpty
                          ? activity.instructor.name
                          : 'Instructor Name',
                      style: AppTextStyles.titleMedium(context).copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    if (activity.instructor.profile.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        activity.instructor.profile,
                        style: AppTextStyles.bodySmall(
                          context,
                        ).copyWith(color: Colors.grey[600]),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (activity.instructor.phone.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.phone, size: 12, color: Colors.grey[500]),
                          const SizedBox(width: 4),
                          Text(
                            activity.instructor.phone,
                            style: AppTextStyles.bodySmall(
                              context,
                            ).copyWith(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Get status color based on enrollment status
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'enrolled':
      case 'reenrolled':
        return Colors.green;
      case 'waitlist':
        return Colors.orange;
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

  /// Format enrollment date for display
  String _formatEnrollmentDate(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inDays == 0) {
        return 'Today';
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else {
        return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
      }
    } catch (e) {
      return 'Recently';
    }
  }
}
