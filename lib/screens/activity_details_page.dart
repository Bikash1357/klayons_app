import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:klayons/screens/InstructorDetailsPage.dart';
import 'package:klayons/utils/styles/fonts.dart';
import 'package:klayons/utils/styles/errorMessage.dart';
import 'package:klayons/utils/colour.dart';

import '../services/activity/activities_batchServices/activityDetailsService.dart';
import '../services/activity/activities_batchServices/post_enrollment_service.dart';
import '../services/activity/activities_batchServices/get_delete_enrolled_service.dart';
import '../services/user_child/get_ChildServices.dart';

class ActivityBookingPage extends StatefulWidget {
  final int activityId;
  final int? batchId; // kept for route compatibility if used elsewhere

  const ActivityBookingPage({Key? key, required this.activityId, this.batchId})
    : super(key: key);

  @override
  State<ActivityBookingPage> createState() => _ActivityBookingPageState();
}

class _ActivityBookingPageState extends State<ActivityBookingPage>
    with BottomMessageHandler {
  Child? selectedChild;
  ActivityDetail? activityData;
  List<Child> children = [];
  List<GetEnrollment> userEnrollments = [];

  bool isLoading = true;
  bool isEnrolling = false;
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
      final results = await Future.wait([
        ActivityService.getActivityDetails(widget.activityId),
        _loadChildrenInternal(),
        GetEnrollmentService.fetchMyEnrollments(),
      ]);

      final activity = results as ActivityDetail?;
      final childrenList = results[1] as List<Child>;
      final enrollments = results as List<GetEnrollment>;

      if (activity == null) {
        throw Exception('Activity not found');
      }

      setState(() {
        activityData = activity;
        children = childrenList;
        userEnrollments = enrollments;
        if (selectedChild == null && children.isNotEmpty) {
          selectedChild = children.first;
        }
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to load data: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  Future<List<Child>> _loadChildrenInternal() async {
    final cached = GetChildservices.getCachedChildren();
    if (cached != null && cached.isNotEmpty) return cached;
    return await GetChildservices.fetchChildren();
  }

  bool _isChildAlreadyEnrolled() {
    if (selectedChild == null) return false;
    return userEnrollments.any((enr) {
      final status = enr.status.toLowerCase();
      return enr.childId == selectedChild!.id &&
          enr.activityId == widget.activityId &&
          (status == 'enrolled' || status == 'waitlist');
    });
  }

  String _getEnrollCta() {
    if (activityData == null) return 'Enroll';
    if (!activityData!.isActive) return 'Currently Inactive';
    if (_isChildAlreadyEnrolled()) return 'Already Enrolled';
    return 'Enroll Now';
  }

  Future<void> _handleEnrollment() async {
    if (selectedChild == null || activityData == null) {
      showBottomError('Please select a child to continue with enrollment.');
      return;
    }
    if (_isChildAlreadyEnrolled()) {
      showBottomError('This child is already enrolled in this activity.');
      return;
    }

    final confirm = await _showEnrollmentConfirmationDialog();
    if (confirm != true) return;

    setState(() => isEnrolling = true);

    try {
      final resp = await EnrollmentService.enrollChild(
        childId: selectedChild!.id,
        activityId: widget.activityId,
      );

      setState(() => isEnrolling = false);

      // refresh enrollments after successful call
      final refresh = await GetEnrollmentService.fetchMyEnrollments();
      setState(() => userEnrollments = refresh);

      await _showSuccessDialog(resp);
      showBottomSuccess(
        '${selectedChild!.name} ${resp.statusDisplay} in ${resp.activityName}!',
      );
    } on EnrollmentException catch (e) {
      setState(() => isEnrolling = false);
      showBottomError(e.userFriendlyMessage);
      if (e.type == EnrollmentErrorType.validation) {
        await _showValidationErrorDialog(e.message);
      }
    } catch (_) {
      setState(() => isEnrolling = false);
      showBottomError('An unexpected error occurred. Please try again.');
    }
  }

  String _ageYears(String dob) {
    try {
      final birth = DateTime.parse(dob);
      final now = DateTime.now();
      int age = now.year - birth.year;
      if (now.month < birth.month ||
          (now.month == birth.month && now.day < birth.day)) {
        age--;
      }
      return age.toString();
    } catch (_) {
      return 'N/A';
    }
  }

  String _formatScheduleDisplay() {
    final schedules = activityData?.schedules;
    if (schedules == null || schedules.isEmpty) return 'Schedule not available';
    final sched = schedules.first;
    if ((sched.nextOccurrences).isNotEmpty) {
      final days = sched.nextOccurrences.map((o) => o.day).toSet().toList();
      return 'Every ${days.join(' & ')}';
    }
    return 'Schedule available';
  }

  String _formatTimeSlots() {
    final schedule = activityData?.schedule;
    if (schedule == null || schedule.timeSlots.isEmpty) {
      return 'Time not specified';
    }
    final ts = schedule.timeSlots.first;
    final start = ts.startTime?.trim().isNotEmpty == true ? ts.startTime : null;
    final end = ts.endTime?.trim().isNotEmpty == true ? ts.endTime : null;
    if (start != null && end != null) return '$start - $end';
    if (start != null) return start!;
    if (end != null) return end!;
    return 'Time not specified';
  }

  IconData _activityIcon(String category) {
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
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.school, color: Colors.deepOrange, size: 28),
            const SizedBox(width: 12),
            const Expanded(
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
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
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
                  Icon(
                    Icons.currency_rupee,
                    size: 18,
                    color: Colors.deepOrange,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Fee: ₹${activityData!.price.toStringAsFixed(0)} /${activityData!.paymentType}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.deepOrange,
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
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600),
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
      ),
    );
  }

  Future<void> _showSuccessDialog(EnrollmentResponse response) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check_circle, color: Colors.green, size: 50),
              ),
              const SizedBox(height: 24),
              const Text(
                'Congratulations! 🎉',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'You have successfully enrolled ${selectedChild?.name ?? 'your child'} in ${response.activityName}!',
                style: TextStyle(fontSize: 16, color: Colors.grey, height: 1.4),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green!),
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
                            color: response.isEnrolled
                                ? Colors.green
                                : Colors.orange,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            response.statusDisplay,
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
                          'Fee:',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Text(
                          response.priceDisplay,
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
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
      ),
    );
  }

  Future<void> _showValidationErrorDialog(String message) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.error_outline, color: Colors.red, size: 30),
              ),
              const SizedBox(height: 16),
              Text(
                'Enrollment Not Possible',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red!),
                ),
                child: Text(
                  message,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.red,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'I Understand',
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
      ),
    );
  }

  void _selectChild(Child child) {
    setState(() => selectedChild = child);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          if (isLoading)
            _buildLoading()
          else if (errorMessage != null)
            _buildError()
          else if (activityData != null)
            _buildContent()
          else
            _buildEmpty(),
          buildBottomMessages(),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Colors.deepOrange),
          const SizedBox(height: 16),
          Text(
            'Loading activity details...',
            style: AppTextStyles.titleMedium(
              context,
            ).copyWith(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Error Loading Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage ?? 'Unknown error',
              style: AppTextStyles.titleSmall(
                context,
              ).copyWith(color: Colors.grey),
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

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.inbox, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No Data Available',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChildSelector() {
    if (children.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Book for:',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: children.map((child) {
                  final selected = selectedChild?.id == child.id;
                  final age = _ageYears(child.dob);
                  final ageInt = int.tryParse(age) ?? 0;
                  final isAgeWarning = ageInt < 4; // business rule placeholder

                  final Color bg = selected
                      ? (isAgeWarning ? Colors.orange : Colors.deepOrange)
                      : (isAgeWarning ? Colors.orange! : Colors.grey!);

                  final Color border = selected
                      ? (isAgeWarning ? Colors.orange! : AppColors.highlight2)
                      : (isAgeWarning ? Colors.orange! : Colors.grey!);

                  final Color fg = selected
                      ? Colors.white
                      : (isAgeWarning ? Colors.orange! : Colors.grey!);

                  return GestureDetector(
                    onTap: () => _selectChild(child),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${child.name.split(' ').first} ($age)',
                            style: TextStyle(
                              fontSize: 12,
                              color: fg,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (isAgeWarning) ...[
                            const SizedBox(width: 4),
                            Icon(
                              Icons.warning,
                              size: 12,
                              color: selected ? Colors.white : Colors.orange,
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (selectedChild != null)
          Builder(
            builder: (_) {
              final age = _ageYears(selectedChild!.dob);
              final ageInt = int.tryParse(age) ?? 0;
              if (ageInt < 4) {
                return Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.orange!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: Colors.orange),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'This child may not meet the minimum age requirement for this activity.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange,
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
    );
  }

  Widget _buildHeaderImage(ActivityDetail activity) {
    final hasImage = activity.bannerImageUrl.trim().isNotEmpty;
    return Stack(
      children: [
        SizedBox(
          width: double.infinity,
          height: 300,
          child: hasImage
              ? Image.network(
                  activity.bannerImageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.grey,
                    child: Icon(
                      _activityIcon(activity.category),
                      size: 100,
                      color: Colors.grey,
                    ),
                  ),
                )
              : Container(
                  color: Colors.grey,
                  child: Icon(
                    _activityIcon(activity.category),
                    size: 100,
                    color: Colors.grey,
                  ),
                ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                DecoratedBox(
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
                DecoratedBox(
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
                      // TODO: integrate share
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

  Widget _buildContent() {
    final activity = activityData!;
    final venueDisplay = activity.venue.isNotEmpty
        ? activity.venue
        : activity.society;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderImage(activity),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title, batch and subcategory
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        activity.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (activity.subcategory.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryOrange,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey!),
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
                if (activity.batchName.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      activity.batchName,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                Text(
                  'Recommended for ${activity.ageRange.isNotEmpty ? activity.ageRange : 'All ages'}',
                  style: AppTextStyles.titleSmall(
                    context,
                  ).copyWith(color: Colors.grey),
                ),
                const SizedBox(height: 16),

                // Price
                Row(
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
                    Text(
                      '/${activity.paymentType}',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.primaryOrange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Sessions
                Text(
                  '${activity.sessionCount} sessions, ${activity.sessionDuration}mins each',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.primaryOrange,
                  ),
                ),
                const SizedBox(height: 8),

                // Schedule card
                Container(
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
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _formatScheduleDisplay(),
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 16, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text(
                            _formatTimeSlots(),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 16, color: Colors.grey),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              venueDisplay,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
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
                            activity.isActive
                                ? Icons.schedule
                                : Icons.pause_circle,
                            size: 16,
                            color: activity.isActive
                                ? Colors.green
                                : Colors.red,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            activity.isActive
                                ? 'Enrollment Open!'
                                : 'Currently Inactive',
                            style: TextStyle(
                              fontSize: 12,
                              color: activity.isActive
                                  ? Colors.green
                                  : Colors.red,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Description
                Container(
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
                      const Text(
                        'DESCRIPTION',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        activity.description.isNotEmpty
                            ? activity.description
                            : 'This ${activity.category.toLowerCase()} activity is designed to provide students with hands-on learning experience.',
                        style: AppTextStyles.titleSmall(
                          context,
                        ).copyWith(height: 1.6, color: Colors.grey),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Duration and child selection + capacity + CTA
                Container(
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
                      if (activity.startDate.isNotEmpty &&
                          activity.endDate.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.purple,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.purple!),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.date_range, color: Colors.purple),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Activity Duration',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.purple,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${activity.startDate} to ${activity.endDate}',
                                      style: TextStyle(
                                        color: Colors.purple,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                      _buildChildSelector(),
                      const SizedBox(height: 12),
                      if (activity.capacity > 0)
                        Text(
                          // Placeholder for real seats left; replace with backend actual if available
                          '${activity.capacity - (activity.capacity ~/ 3)} spots left (Total: ${activity.capacity})',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.primaryOrange,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed:
                              activity.isActive &&
                                  !isEnrolling &&
                                  !_isChildAlreadyEnrolled()
                              ? _handleEnrollment
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                activity.isActive && !_isChildAlreadyEnrolled()
                                ? Colors.deepOrange
                                : Colors.grey,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: isEnrolling
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
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
                                  _getEnrollCta(),
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
                ),

                const SizedBox(height: 30),

                // Instructor
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Meet the instructor',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => InstructorDetailsPage(),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
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
                          // border: Border.all(color: Colors.grey!),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: Colors.deepOrange.withOpacity(
                                0.1,
                              ),
                              backgroundImage:
                                  activity.instructor.avatarUrl != null
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
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  if (activity
                                      .instructor
                                      .profile
                                      .isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      activity.instructor.profile,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                  if (activity.instructor.phone.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.phone,
                                          size: 12,
                                          color: Colors.grey,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          activity.instructor.phone,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
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
                              color: Colors.grey,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
