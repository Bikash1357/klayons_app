import 'package:flutter/material.dart';
import 'package:klayons/screens/bottom_screens/ticketbox_page.dart';
import 'package:klayons/screens/bottom_screens/uesr_profile/profile_page.dart';
import 'package:klayons/screens/course_details_page.dart';
import 'package:klayons/screens/notification.dart';

import '../services/ActivitiedsServices.dart';
import 'bottom_screens/calander.dart' hide Activity;

class KlayonsHomePage extends StatefulWidget {
  const KlayonsHomePage({Key? key}) : super(key: key);

  @override
  _KlayonsHomePageState createState() => _KlayonsHomePageState();
}

class _KlayonsHomePageState extends State<KlayonsHomePage> {
  List<Activity> activities = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchActivities();
  }

  Future<void> fetchActivities() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      // Fetch only active activities for the home page
      final fetchedActivities = await ActivitiesService.getActiveActivities();

      setState(() {
        activities = fetchedActivities;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
      print('Error fetching activities: $e');
    }
  }

  String _formatAgeGroup(int ageStart, int ageEnd) {
    if (ageStart == ageEnd) {
      return 'Recommended Age: ${ageStart} years';
    } else {
      return 'Recommended Age: $ageStart-$ageEnd years';
    }
  }

  String _formatDateRange(String startDate, String endDate) {
    try {
      final start = DateTime.parse(startDate);
      final end = DateTime.parse(endDate);
      final startFormatted = '${start.day}/${start.month}/${start.year}';
      final endFormatted = '${end.day}/${end.month}/${end.year}';

      if (startDate == endDate) {
        return 'Date: $startFormatted';
      }
      return 'Duration: $startFormatted - $endFormatted';
    } catch (e) {
      return 'Duration: $startDate - $endDate';
    }
  }

  String _getUpcomingActivityInfo() {
    if (activities.isNotEmpty) {
      final activity = activities.first;
      try {
        final startDate = DateTime.parse(activity.startDate);
        final now = DateTime.now();
        final difference = startDate.difference(now).inDays;

        if (difference > 0) {
          return difference == 1
              ? 'Starts Tomorrow'
              : 'Starts in $difference days';
        } else if (difference == 0) {
          return 'Starts Today';
        } else {
          return 'In Progress';
        }
      } catch (e) {
        return 'Starting Soon';
      }
    }
    return 'No upcoming sessions';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'klayons',
          style: TextStyle(
            color: Colors.orange,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.grey),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => NotificationsPage()),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: fetchActivities,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Blue banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 15,
                ),
                decoration: const BoxDecoration(color: Color(0xFF1E3A8A)),
                child: const Text(
                  'Introductory Offer! 2 Activities at ₹2000',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Upcoming session card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE4E1),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 30,
                            height: 30,
                            decoration: const BoxDecoration(
                              color: Colors.orange,
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Text(
                                'P',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'UPCOMING SESSION',
                            style: TextStyle(
                              color: Color(0xFF1E3A8A),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      Text(
                        activities.isNotEmpty
                            ? activities.first.name
                            : 'Activity Name',
                        style: const TextStyle(
                          color: Colors.orange,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        _getUpcomingActivityInfo(),
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 15),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'enrolled for Aarav',
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Explore activities section
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'EXPLORE ACTIVITIES',
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Activity cards - Dynamic content
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildActivitiesSection(),
              ),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        height: 80,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 10,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildBottomNavItem(context, Icons.home, true, () {
              // Already on home page, do nothing
            }),
            _buildBottomNavItem(context, Icons.calendar_today, false, () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ActivitySchedulePage(), // Replace with CalendarPage()
                ),
              );
            }),
            _buildBottomNavItem(context, Icons.shopping_bag_outlined, false, () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ActivityBookingPage(), // Replace with ActivityBookingPage()
                ),
              );
            }),
            _buildBottomNavItem(context, Icons.person_outline, false, () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => UserProfilePage()),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildActivitiesSection() {
    if (isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40.0),
          child: CircularProgressIndicator(color: Colors.orange),
        ),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              'Failed to load activities',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage!.contains('Error fetching activities:')
                  ? errorMessage!.replaceFirst(
                      'Error fetching activities: ',
                      '',
                    )
                  : errorMessage!,
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: fetchActivities,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: const Text('Retry', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    if (activities.isEmpty) {
      return Center(
        child: Column(
          children: [
            const Icon(Icons.sports, color: Colors.grey, size: 48),
            const SizedBox(height: 16),
            Text(
              'No active activities available',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Check back later for new activities',
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
          ],
        ),
      );
    }

    return Column(
      children: activities.map((activity) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 15),
          child: _buildActivityCard(context, activity),
        );
      }).toList(),
    );
  }

  Widget _buildActivityCard(BuildContext context, Activity activity) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CourseDetailPage(activity: activity),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 10,
            ),
          ],
        ),
        child: Row(
          children: [
            // Image with banner support
            Container(
              width: 100,
              height: 120,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(15),
                  bottomLeft: Radius.circular(15),
                ),
                color: Colors.grey[300],
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(15),
                  bottomLeft: Radius.circular(15),
                ),
                child: activity.bannerImageUrl.isNotEmpty
                    ? Image.network(
                        activity.bannerImageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[300],
                            child: const Icon(
                              Icons.school,
                              color: Colors.grey,
                              size: 40,
                            ),
                          );
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: Colors.grey[300],
                            child: const Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.orange,
                              ),
                            ),
                          );
                        },
                      )
                    : Container(
                        color: Colors.grey[300],
                        child: const Icon(
                          Icons.school,
                          color: Colors.grey,
                          size: 40,
                        ),
                      ),
              ),
            ),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _formatDateRange(activity.startDate, activity.endDate),
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatAgeGroup(
                        activity.ageGroupStart,
                        activity.ageGroupEnd,
                      ),
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Instructor: ${activity.instructor.name}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    if (activity.pricing.isNotEmpty)
                      Text(
                        'Price: ₹${activity.pricing}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    const SizedBox(height: 2),
                    if (activity.batchesCount.isNotEmpty)
                      Text(
                        'Batches: ${activity.batchesCount}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    const SizedBox(height: 10),
                    // Status indicator
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: activity.isActive
                            ? Colors.green[100]
                            : Colors.red[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        activity.isActive ? 'Active' : 'Inactive',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: activity.isActive
                              ? Colors.green[700]
                              : Colors.red[700],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: activity.isActive
                            ? () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        CourseDetailPage(activity: activity),
                                  ),
                                );
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: activity.isActive
                              ? Colors.orange
                              : Colors.grey,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        child: Text(
                          activity.isActive ? 'Add to Cart' : 'Not Available',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavItem(
    BuildContext context,
    IconData icon,
    bool isActive,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: isActive ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Icon(
          icon,
          color: isActive ? Colors.orange : Colors.grey,
          size: 24,
        ),
      ),
    );
  }
}
