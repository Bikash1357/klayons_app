import 'package:flutter/material.dart';
import '../services/activity/ActivitiedsServices.dart';
import '../services/activity/activities_batchServices/batch_model.dart';
import '../services/activity/activities_batchServices/batches.dart';

class CourseDetailPage extends StatelessWidget {
  final Activity? activity;
  final int? activityId;

  const CourseDetailPage({Key? key, this.activity, this.activityId})
    : assert(
        activity != null || activityId != null,
        'Either activity or activityId must be provided',
      ),
      super(key: key);

  // Helper method to get activity data
  Future<Activity> _getActivity() async {
    if (activity != null) {
      return activity!;
    }
    return await ActivitiesService.getActivityById(activityId!);
  }

  String _formatRecommendedAge(String recommendedAge) {
    if (recommendedAge.isEmpty) {
      return 'Suitable for all ages';
    }
    return 'Recommended for $recommendedAge year olds';
  }

  String _getBatchInfo(String batchCount) {
    if (batchCount.isEmpty || batchCount == '0') {
      return 'Batches available soon';
    }
    final count = int.tryParse(batchCount) ?? 1;
    return count == 1 ? '1 batch available' : '$count batches available';
  }

  String _getCategoryInfo(Activity activity) {
    if (activity.categoryDisplay.isNotEmpty) {
      return activity.categoryDisplay;
    } else if (activity.category.isNotEmpty) {
      return activity.category.toUpperCase();
    }
    return 'General Activity';
  }

  // Method to show batches popup
  // Method to show batches popup with better error handling
  void _showBatchesPopup(BuildContext context, int activityId) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            constraints: const BoxConstraints(maxHeight: 600, maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Available Batches',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Batches List
                Flexible(
                  child: FutureBuilder<List<Batch>>(
                    future: BatchService.getBatchesByActivityId(activityId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(color: Colors.orange),
                              SizedBox(height: 16),
                              Text(
                                'Loading batches...',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        );
                      }

                      if (snapshot.hasError) {
                        String errorMessage = 'Failed to load batches';

                        if (snapshot.error.toString().contains(
                          'Network error',
                        )) {
                          errorMessage =
                              'Network connection error.\nPlease check your internet connection.';
                        } else if (snapshot.error.toString().contains('404')) {
                          errorMessage = 'No batches found for this activity.';
                        } else if (snapshot.error.toString().contains('401')) {
                          errorMessage =
                              'Authentication required.\nPlease log in again.';
                        } else if (snapshot.error.toString().contains('500')) {
                          errorMessage =
                              'Server error.\nPlease try again later.';
                        }

                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: Colors.red,
                                size: 48,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                errorMessage,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  // Retry by showing the popup again
                                  _showBatchesPopup(context, activityId);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 8,
                                  ),
                                ),
                                child: const Text(
                                  'Retry',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      final batches = snapshot.data ?? [];

                      if (batches.isEmpty) {
                        return const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.inbox_outlined,
                                color: Colors.grey,
                                size: 48,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'No batches available\nfor this activity',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 16,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.separated(
                        shrinkWrap: true,
                        itemCount: batches.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final batch = batches[index];
                          return _buildBatchCard(batch);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBatchCard(Batch batch) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Batch header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    batch.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
                // Batch ID
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'ID: ${batch.id}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Batch details
            _buildBatchDetailRow('Age Range', batch.ageRange),
            _buildBatchDetailRow('Capacity', '${batch.capacity} students'),
            _buildBatchDetailRow('Start Date', batch.startDate),
            _buildBatchDetailRow('End Date', batch.endDate),

            // Status
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: batch.isActive ? Colors.green : Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  batch.isActive ? 'Active' : 'Inactive',
                  style: TextStyle(
                    fontSize: 14,
                    color: batch.isActive ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),

            // Schedules if available
            if (batch.schedules.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'Schedules:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 6),
              ...batch.schedules
                  .take(2)
                  .map(
                    (schedule) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '${schedule.startTimeDisplay} - ${schedule.endTimeDisplay}',
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                    ),
                  ),
              if (batch.schedules.length > 2)
                Text(
                  '... and ${batch.schedules.length - 2} more',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBatchDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
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
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
          ),
        ],
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
      body: FutureBuilder<Activity>(
        future: _getActivity(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.orange),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load activity details',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                    ),
                    child: const Text(
                      'Go Back',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            );
          }

          final activityData = snapshot.data!;
          return _buildContent(context, activityData);
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, Activity activityData) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Image
          Stack(
            children: [
              Container(
                width: double.infinity,
                height: 250,
                decoration: BoxDecoration(
                  image: activityData.bannerImageUrl.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(activityData.bannerImageUrl),
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
              // Rounded overlay
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
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Activity ID and Category Row
                  Row(
                    children: [
                      // Activity ID Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: Colors.orange.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          'ID: ${activityData.id}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.orange,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Category badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: Colors.blue.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          _getCategoryInfo(activityData),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                      const Spacer(),
                      // Active status indicator
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: activityData.isActive
                                  ? Colors.green
                                  : Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            activityData.isActive ? 'Active' : 'Inactive',
                            style: TextStyle(
                              fontSize: 12,
                              color: activityData.isActive
                                  ? Colors.green
                                  : Colors.red,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Activity Name
                  Text(
                    activityData.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Recommended Age
                  Text(
                    _formatRecommendedAge(activityData.recommendedAge),
                    style: const TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                  const SizedBox(height: 16),

                  // Society and Instructor Info
                  if (activityData.societyName.isNotEmpty) ...[
                    _buildInfoRow(
                      Icons.business,
                      'Society',
                      activityData.societyName,
                    ),
                    const SizedBox(height: 12),
                  ],

                  if (activityData.instructorName.isNotEmpty) ...[
                    _buildInfoRow(
                      Icons.person,
                      'Instructor',
                      activityData.instructorName,
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Batch Information - Made clickable
                  GestureDetector(
                    onTap: () => _showBatchesPopup(context, activityData.id),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 4,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.transparent),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.group, size: 18, color: Colors.grey[600]),
                          const SizedBox(width: 8),
                          Text(
                            'Batches: ',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              _getBatchInfo(activityData.batchCount),
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.blue[700],
                                decoration: TextDecoration.underline,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
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
                  const SizedBox(height: 32),

                  // Activity Details Section
                  const Text(
                    'ACTIVITY DETAILS',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Details Grid
                  _buildDetailItem('Activity ID', activityData.id.toString()),
                  _buildDetailItem('Category', _getCategoryInfo(activityData)),
                  if (activityData.societyName.isNotEmpty)
                    _buildDetailItem('Society', activityData.societyName),
                  if (activityData.instructorName.isNotEmpty)
                    _buildDetailItem('Instructor', activityData.instructorName),
                  _buildDetailItem(
                    'Recommended Age',
                    activityData.recommendedAge.isEmpty
                        ? 'All Ages'
                        : activityData.recommendedAge,
                  ),
                  _buildDetailItem(
                    'Available Batches',
                    activityData.batchCount.isEmpty
                        ? 'TBD'
                        : activityData.batchCount,
                  ),
                  _buildDetailItem(
                    'Status',
                    activityData.isActive ? 'Active' : 'Inactive',
                  ),

                  const SizedBox(height: 32),

                  // Description Section
                  const Text(
                    'ABOUT THIS ACTIVITY',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'This ${activityData.name.toLowerCase()} activity is organized by ${activityData.societyName.isNotEmpty ? activityData.societyName : 'our team'}'
                    '${activityData.instructorName.isNotEmpty ? ' and will be conducted by ${activityData.instructorName}' : ''}. '
                    '${activityData.recommendedAge.isNotEmpty ? 'This activity is recommended for ${activityData.recommendedAge} year olds. ' : ''}'
                    'Join us for an engaging and fun-filled experience!',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () {
                      // Handle read more - could expand to show more details
                    },
                    child: const Text(
                      'read more',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFFFF5722),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Meet the Instructor Section
                  if (activityData.instructorName.isNotEmpty) ...[
                    const Text(
                      'MEET THE INSTRUCTOR',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Instructor Profile
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(25),
                            color: Colors.orange.withOpacity(0.2),
                          ),
                          child: Center(
                            child: Text(
                              activityData.instructorName.isNotEmpty
                                  ? activityData.instructorName[0].toUpperCase()
                                  : 'I',
                              style: const TextStyle(
                                fontSize: 20,
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
                                activityData.instructorName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Experienced instructor specializing in ${_getCategoryInfo(activityData).toLowerCase()} activities. '
                                'Passionate about creating engaging learning experiences for children and helping them develop new skills.',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.black87,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: () {
                                  // Handle read more about instructor
                                },
                                child: const Text(
                                  'read more',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFFFF5722),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
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
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }
}
