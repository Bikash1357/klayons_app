import 'package:flutter/material.dart';
import 'package:klayons/services/activity/activities_batchServices/batchWithActivity.dart';

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
  String selectedTimeSlot = 'Morning';
  BatchWithActivity? batchData;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadBatchData();
  }

  Future<void> _loadBatchData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // Get all batches and find the one with matching ID
      final batches = await BatchService.getAllBatches(page: 1, pageSize: 100);
      final batch = batches.firstWhere(
        (b) => b.id == widget.batchId && b.activity.id == widget.activityId,
        orElse: () => throw Exception('Batch not found'),
      );

      setState(() {
        batchData = batch;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to load batch details: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          batchData?.activity.name ?? 'Activity Details',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.favorite_border, color: Colors.black),
            onPressed: () {},
          ),
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
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
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
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadBatchData,
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

                // Batch Name (if different)
                if (batch.name != batch.activity.name) ...[
                  Text(
                    batch.name,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  SizedBox(height: 8),
                ],

                // Age Range
                Text(
                  'Recommended for ${batch.ageRange.isNotEmpty ? batch.ageRange : 'All ages'}',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                SizedBox(height: 16),

                // Price
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
                      'for full course',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
                SizedBox(height: 20),

                // Course Details
                _buildDetailCard(),
                SizedBox(height: 20),

                // Book For Section
                Text(
                  'Book for',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 12),

                // Time Slot Selection
                Row(
                  children: [
                    _buildTimeSlotButton(
                      'Morning',
                      selectedTimeSlot == 'Morning',
                    ),
                    SizedBox(width: 12),
                    _buildTimeSlotButton(
                      'Evening',
                      selectedTimeSlot == 'Evening',
                    ),
                  ],
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

                // Enroll Button
                Container(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: batch.isActive
                        ? () {
                            // Handle enrollment
                            _showEnrollmentDialog();
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: batch.isActive
                          ? Colors.deepOrange
                          : Colors.grey,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      batch.isActive ? 'Enroll Now' : 'Not Available',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 30),

                // Description Section
                _buildDescriptionSection(),
                SizedBox(height: 30),

                // Instructor Section
                _buildInstructorSection(),
                SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

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

  Widget _buildDescriptionSection() {
    final batch = batchData!;

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
          batch.activity.description.isNotEmpty
              ? batch.activity.description
              : 'This ${batch.activity.categoryDisplay.toLowerCase()} activity is designed to provide students with hands-on learning experience. Join us for an engaging and educational journey that will help develop new skills and build confidence.',
          style: TextStyle(fontSize: 14, height: 1.6, color: Colors.grey[700]),
        ),
      ],
    );
  }

  Widget _buildInstructorSection() {
    final batch = batchData!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'MEET THE INSTRUCTOR',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
            letterSpacing: 1.2,
          ),
        ),
        SizedBox(height: 16),
        Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.deepOrange.withOpacity(0.1),
              child: Text(
                batch.activity.instructorName.isNotEmpty
                    ? batch.activity.instructorName
                          .substring(0, 1)
                          .toUpperCase()
                    : 'I',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepOrange,
                ),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    batch.activity.instructorName.isNotEmpty
                        ? batch.activity.instructorName
                        : 'Expert Instructor',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Experienced ${batch.activity.categoryDisplay.toLowerCase()} instructor with years of teaching experience. Passionate about helping students learn and grow in a supportive environment.',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTimeSlotButton(String text, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedTimeSlot = text;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.deepOrange : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
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

  void _showEnrollmentDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Confirm Enrollment',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Activity: ${batchData!.activity.name}'),
              Text('Batch: ${batchData!.name}'),
              Text('Price: ${batchData!.priceDisplay}'),
              Text('Time Slot: $selectedTimeSlot'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // Handle actual enrollment logic here
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Enrollment request submitted!'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text('Confirm', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}
