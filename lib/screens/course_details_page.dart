import 'package:flutter/material.dart';

import '../services/ActivitiedsServices.dart';

class CourseDetailPage extends StatelessWidget {
  final Activity activity;

  const CourseDetailPage({Key? key, required this.activity}) : super(key: key);

  String _formatAgeGroup(int ageStart, int ageEnd) {
    if (ageStart == ageEnd) {
      return 'Recommended for ${ageStart} year olds';
    } else {
      return 'Recommended for $ageStart-$ageEnd year olds';
    }
  }

  String _getPriceInfo() {
    if (activity.pricing.isNotEmpty) {
      try {
        final price = double.parse(activity.pricing);
        return '₹${price.toStringAsFixed(0)}';
      } catch (e) {
        return '₹${activity.pricing}';
      }
    }
    return 'Price not available';
  }

  String _getSessionInfo() {
    if (activity.batchesCount.isNotEmpty) {
      return 'for ${activity.batchesCount} sessions';
    }
    return 'for multiple sessions';
  }

  bool _isActivityBookable() {
    if (!activity.isActive) return false;

    try {
      final startDate = DateTime.parse(activity.startDate);
      final now = DateTime.now();
      return now.isBefore(startDate) || now.isAtSameMomentAs(startDate);
    } catch (e) {
      return activity.isActive;
    }
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
      body: SingleChildScrollView(
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
                    image: activity.bannerImageUrl.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(activity.bannerImageUrl),
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
                    // Activity Name
                    Text(
                      activity.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Age Group
                    Text(
                      _formatAgeGroup(
                        activity.ageGroupStart,
                        activity.ageGroupEnd,
                      ),
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Price and Session Info
                    Row(
                      children: [
                        Text(
                          _getPriceInfo(),
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFF5722),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _getSessionInfo(),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Book for section
                    const Text(
                      'Book for:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Child selection buttons
                    Row(
                      children: [
                        _buildChildButton('Aarya', true),
                        const SizedBox(width: 12),
                        _buildChildButton('Khushi', false),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Spots left indicator
                    Center(
                      child: Text(
                        '7 spots left',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Enroll Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isActivityBookable()
                            ? () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Enrolling in ${activity.name}...',
                                    ),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF5722),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Enroll',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Description Section
                    const Text(
                      'DESCRIPTION',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      activity.description.isNotEmpty
                          ? activity.description
                          : 'Lorem ipsum dolor sit amet consectetur. Feugiat sollicitudin ut pellentesque in ultrices. Viverra odio id pellentesque felis sagittis arcu volutpat non vestibulum. At placerat elementum et eleifentum ut...',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () {
                        // Handle read more
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
                            image:
                                activity.instructor.profile.startsWith('http')
                                ? DecorationImage(
                                    image: NetworkImage(
                                      activity.instructor.profile,
                                    ),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: activity.instructor.profile.startsWith('http')
                              ? null
                              : Center(
                                  child: Text(
                                    activity.instructor.name.isNotEmpty
                                        ? activity.instructor.name[0]
                                              .toUpperCase()
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
                                activity.instructor.name.isNotEmpty
                                    ? activity.instructor.name
                                    : 'Name Surname',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Lorem ipsum dolor sit amet consectetur. Feugiat sollicitudin ut pellentesque in ultrices. Viverra odio id pellentesque felis sagittis arcu volutpat non vestibulum. At placerat elementum et eleifentum ut nibh lorem. Massa nisl arcu elit etiam.',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.black87,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: () {
                                  // Handle read more
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
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChildButton(String name, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFFF5722) : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFF5722), width: 1),
      ),
      child: Text(
        name,
        style: TextStyle(
          color: isSelected ? Colors.white : const Color(0xFFFF5722),
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
      ),
    );
  }
}
