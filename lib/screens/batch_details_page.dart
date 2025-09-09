import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:klayons/screens/InstructorDetailsPage.dart';
import 'package:klayons/services/activity/activities_batchServices/batchWithActivity.dart';
import 'package:klayons/utils/styles/fonts.dart';
import '../services/activity/activities_batchServices/enrollment_service.dart';
import '../services/user_child/get_ChildServices.dart';
import 'package:klayons/utils/colour.dart';

class ActivityBookingPage extends StatefulWidget {
  final int batchId;
  final int activityId;

  const ActivityBookingPage({
    Key? key,
    required this.batchId,
    required this.activityId,
  }) : super(key: key);

  @override
  _ActivityBookingPageState createState() => _ActivityBookingPageState();
}

class _ActivityBookingPageState extends State<ActivityBookingPage> {
  String? selectedChildId;
  Child? selectedChild;
  BatchWithActivity? batchData;
  List<Child> children = [];
  bool isLoading = true;
  bool isLoadingChildren = false;
  bool isEnrolling = false; // Add enrollment loading state
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
      await Future.wait([_loadBatchData(), _loadChildren()]);

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

  Future<void> _loadBatchData() async {
    try {
      final batches = await BatchService.getAllBatches(page: 1, pageSize: 100);
      final batch = batches.firstWhere(
        (b) => b.id == widget.batchId && b.activity.id == widget.activityId,
        orElse: () => throw Exception('Batch not found'),
      );

      setState(() {
        batchData = batch;
      });
    } catch (e) {
      throw Exception('Failed to load batch details: ${e.toString()}');
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

  void _selectChild(Child child) {
    setState(() {
      selectedChildId = child.id.toString();
      selectedChild = child;
    });
  }

  // UPDATED: Handle enrollment process with confirmation
  Future<void> _handleEnrollment() async {
    if (selectedChild == null || batchData == null) {
      _showErrorDialog('Please select a child to continue with enrollment.');
      return;
    }

    // Show confirmation dialog first
    final bool? shouldEnroll = await _showEnrollmentConfirmationDialog();

    if (shouldEnroll != true) {
      // User cancelled or closed dialog
      return;
    }

    setState(() {
      isEnrolling = true;
    });

    try {
      final enrollmentResponse = await EnrollmentService.enrollChild(
        childId: selectedChild!.id,
        batchId: batchData!.id,
      );

      setState(() {
        isEnrolling = false;
      });

      _showEnrollmentSuccessDialog(enrollmentResponse);
    } catch (e) {
      setState(() {
        isEnrolling = false;
      });

      if (e is EnrollmentException) {
        _showEnrollmentErrorDialog(e);
      } else {
        _showErrorDialog('An unexpected error occurred. Please try again.');
      }
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

      body: isLoading
          ? _buildLoadingWidget()
          : errorMessage != null
          ? _buildErrorWidget()
          : batchData != null
          ? _buildContent()
          : _buildEmptyWidget(),
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
    final batch = batchData!;

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
              child: batch.activity.bannerImageUrl.isNotEmpty
                  ? Image.network(
                      batch.activity.bannerImageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[200],
                          child: Icon(
                            _getActivityIcon(batch.activity.category),
                            size: 100,
                            color: Colors.grey[400],
                          ),
                        );
                      },
                    )
                  : Container(
                      color: Colors.grey[200],
                      child: Icon(
                        _getActivityIcon(batch.activity.category),
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
                  batch.activity.name,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 8),

                Text(
                  'Recommended for ${batch.ageRange.isNotEmpty ? batch.ageRange : 'All ages'}',
                  style: AppTextStyles.titleSmall(
                    context,
                  ).copyWith(color: Colors.grey[600]),
                ),
                SizedBox(height: 16),

                Row(
                  children: [
                    Text(
                      batch.priceDisplay,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepOrange,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      '/month',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                  ],
                ),
                SizedBox(height: 8),

                // Sessions and timing info
                Text(
                  '8 sessions, 60mins each',
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
                    Text(
                      'Every Wednesday & Saturday',
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
                    Text(
                      batch.activity.societyName.isNotEmpty
                          ? batch.activity.societyName
                          : 'Society Clubhouse',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),

                // Batch starting soon (instead of capacity)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.schedule, size: 16, color: Colors.green[600]),
                      SizedBox(width: 6),
                      Text(
                        'Batch starts soon!',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 20),

                // Capacity Info
                Text(
                  '${batch.capacity - (batch.capacity ~/ 3)} spots left (Total: ${batch.capacity})',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.red[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 20),

                // UPDATED: Enroll Button with enrollment functionality
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
                ],

                SizedBox(height: 16),

                // Spots remaining
                Text(
                  '7 spots remaining',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.orange[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 20),

                // Enroll button (keep existing button code)
                Container(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: batch.isActive ? _handleEnrollment : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: batch.isActive
                          ? Colors.deepOrange
                          : Colors.grey,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25), // More rounded
                      ),
                    ),
                    child: Text(
                      'Enroll Now',
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

  Widget _buildChildSelectionButton(Child child, bool isSelected) {
    return GestureDetector(
      onTap: () => _selectChild(child),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.deepOrange : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.deepOrange : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              child.gender.toLowerCase() == 'male' ? Icons.boy : Icons.girl,
              color: isSelected ? Colors.white : Colors.grey[600],
              size: 18,
            ),
            SizedBox(width: 6),
            Text(
              child.name,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[700],
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Keep existing methods for detail card, description, instructor sections...
  Widget _buildDetailCard() {
    final batch = batchData!;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          if (batch.activity.societyName.isNotEmpty)
            _buildDetailRow(
              Icons.location_on,
              'Location',
              batch.activity.societyName,
            ),
          if (batch.activity.categoryDisplay.isNotEmpty)
            _buildDetailRow(
              Icons.category,
              'Category',
              batch.activity.categoryDisplay,
            ),
          _buildDetailRow(
            Icons.date_range,
            'Duration',
            '${batch.startDate} to ${batch.endDate}',
          ),
          _buildDetailRow(
            Icons.people,
            'Capacity',
            '${batch.capacity} students',
          ),
          _buildDetailRow(
            Icons.circle,
            'Status',
            batch.isActive ? 'Active' : 'Inactive',
            statusColor: batch.isActive ? Colors.green : Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value, {
    Color? statusColor,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600], size: 20),
          SizedBox(width: 12),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: statusColor ?? Colors.black87,
                fontWeight: statusColor != null
                    ? FontWeight.w600
                    : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructorSection() {
    final batch = batchData!;

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
                CircleAvatar(
                  radius: 25,
                  backgroundColor: Colors.deepOrange.withOpacity(0.1),
                  child: Text(
                    batch.activity.instructorName.isNotEmpty
                        ? batch.activity.instructorName
                              .substring(0, 1)
                              .toUpperCase()
                        : 'I',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepOrange,
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Text(
                    batch.activity.instructorName.isNotEmpty
                        ? batch.activity.instructorName
                        : 'Name Surname',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
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

  // NEW: Show enrollment confirmation dialog
  Future<bool?> _showEnrollmentConfirmationDialog() async {
    if (selectedChild == null || batchData == null) return false;

    return showDialog<bool>(
      context: context,
      barrierDismissible: false, // Prevents closing by tapping outside
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
                'Are you sure you want to enroll your child in this activity?',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 16),

              // Enrollment Summary Card
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.deepOrange.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.deepOrange.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Enrollment Summary:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Colors.deepOrange[800],
                      ),
                    ),
                    SizedBox(height: 12),

                    // Child info
                    Row(
                      children: [
                        Icon(
                          Icons.child_care,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Child: ',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[700],
                          ),
                        ),
                        Expanded(
                          child: Text(
                            selectedChild!.name,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),

                    // Age info
                    Row(
                      children: [
                        Icon(Icons.cake, size: 16, color: Colors.grey[600]),
                        SizedBox(width: 8),
                        Text(
                          'Age: ',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[700],
                          ),
                        ),
                        Text(
                          '${_calculateAge(selectedChild!.dob)} years old',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),

                    // Activity info
                    Row(
                      children: [
                        Icon(Icons.sports, size: 16, color: Colors.grey[600]),
                        SizedBox(width: 8),
                        Text(
                          'Activity: ',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[700],
                          ),
                        ),
                        Expanded(
                          child: Text(
                            batchData!.activity.name,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),

                    // Batch info
                    Row(
                      children: [
                        Icon(Icons.group, size: 16, color: Colors.grey[600]),
                        SizedBox(width: 8),
                        Text(
                          'Batch: ',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[700],
                          ),
                        ),
                        Expanded(
                          child: Text(
                            batchData!.name,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),

                    // Duration info
                    Row(
                      children: [
                        Icon(
                          Icons.date_range,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Duration: ',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[700],
                          ),
                        ),
                        Expanded(
                          child: Text(
                            '${batchData!.startDate} to ${batchData!.endDate}',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),

                    // Price info (highlighted)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.deepOrange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.deepOrange.withOpacity(0.3),
                        ),
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
                            'Total Fee: ',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: Colors.deepOrange[700],
                            ),
                          ),
                          Text(
                            batchData!.priceDisplay,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.deepOrange[800],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),

              // Important note
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.withOpacity(0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info, color: Colors.amber[700], size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Important:',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.amber[800],
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '• Payment will be processed after enrollment confirmation\n• You can cancel enrollment within 24 hours\n• Refund policy applies as per terms & conditions',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.amber[700],
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            // Cancel Button
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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

            // Confirm Button
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 2,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check, color: Colors.white, size: 18),
                  SizedBox(width: 6),
                  Text(
                    'Yes, Enroll Now',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // NEW: Success Dialog for Enrollment
  void _showEnrollmentSuccessDialog(EnrollmentResponse response) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                response.isEnrolled ? Icons.check_circle : Icons.schedule,
                color: response.isEnrolled ? Colors.green : Colors.orange,
                size: 28,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  response.statusDisplay,
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
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: response.isEnrolled
                      ? Colors.green[50]
                      : Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Enrollment Details:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text('Child: ${response.childName}'),
                    Text('Activity: ${response.activityName}'),
                    Text('Batch: ${response.batchName}'),
                    Text('Price: ${response.priceDisplay}'),
                    Text('Status: ${response.status.toUpperCase()}'),
                  ],
                ),
              ),
              SizedBox(height: 12),
              Text(
                response.isEnrolled
                    ? 'Great! ${response.childName} has been successfully enrolled in ${response.activityName}. You will receive a confirmation email shortly.'
                    : 'The batch is currently full, but ${response.childName} has been added to the waitlist. We will notify you if a spot becomes available.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.4,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Go back to previous screen
              },
              child: Text('Back to Activities'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: response.isEnrolled
                    ? Colors.green
                    : Colors.orange,
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

  // NEW: Error Dialog for Enrollment
  void _showEnrollmentErrorDialog(EnrollmentException error) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(error.errorIcon, color: error.errorColor, size: 28),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Enrollment Failed',
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
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: error.errorColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  error.userFriendlyMessage,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    height: 1.4,
                  ),
                ),
              ),
              if (error.type == EnrollmentErrorType.authentication) ...[
                SizedBox(height: 16),
                Text(
                  'Would you like to go to login?',
                  style: AppTextStyles.titleSmall(
                    context,
                  ).copyWith(color: Colors.grey[600]),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Close'),
            ),
            if (error.type == EnrollmentErrorType.authentication) ...[
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // Navigate to login screen
                  // Navigator.pushNamed(context, '/login');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text('Login', style: TextStyle(color: Colors.white)),
              ),
            ] else ...[
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _handleEnrollment(); // Retry enrollment
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text('Try Again', style: TextStyle(color: Colors.white)),
              ),
            ],
          ],
        );
      },
    );
  }

  // NEW: Simple Error Dialog
  void _showErrorDialog(String message) {
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
              Text(
                'Error',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
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
}
