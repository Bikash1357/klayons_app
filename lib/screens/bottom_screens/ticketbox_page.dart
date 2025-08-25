import 'package:flutter/material.dart';

class ActivityBookingPage extends StatefulWidget {
  const ActivityBookingPage({Key? key}) : super(key: key);

  @override
  State<ActivityBookingPage> createState() => _ActivityBookingPageState();
}

class _ActivityBookingPageState extends State<ActivityBookingPage> {
  List<ActivityItem> activities = [
    ActivityItem(
      name: "ACTIVITY NAME",
      batchStartDate: "Batch Starts 1st May",
      bookedForAarav: true,
      bookedForKhushi: false,
      imageUrl: "assets/activity1.jpg", // Replace with actual image
    ),
    ActivityItem(
      name: "ACTIVITY NAME",
      batchStartDate: "Batch Starts 1st May",
      bookedForAarav: true,
      bookedForKhushi: true,
      imageUrl: "assets/activity2.jpg", // Replace with actual image
    ),
    ActivityItem(
      name: "ACTIVITY NAME",
      batchStartDate: "Batch Starts 1st May",
      bookedForAarav: true,
      bookedForKhushi: true,
      imageUrl: "assets/activity3.jpg", // Replace with actual image
    ),
    ActivityItem(
      name: "ACTIVITY NAME",
      batchStartDate: "Batch Starts 1st May",
      bookedForAarav: true,
      bookedForKhushi: true,
      imageUrl: "assets/activity4.jpg", // Replace with actual image
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.white),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: activities.length,
                itemBuilder: (context, index) {
                  return _buildActivityCard(activities[index], index);
                },
              ),
            ),
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: () {
                  // Handle proceed to book
                  print("Proceed to Book pressed");
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B35),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Proceed to Book',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityCard(ActivityItem activity, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Activity Image
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[300],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  color: _getImageColor(index),
                  child: const Icon(Icons.image, color: Colors.white, size: 30),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Activity Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          activity.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF4444),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(
                          Icons.delete_outline,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    activity.batchStartDate,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Booking Status for Aarav
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Text(
                              activity.bookedForAarav
                                  ? 'Booked for Aarav'
                                  : '+ add Aarav',
                              style: TextStyle(
                                fontSize: 14,
                                color: activity.bookedForAarav
                                    ? Colors.grey[600]
                                    : Colors.grey[600],
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (activity.bookedForAarav)
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              activity.bookedForAarav = false;
                            });
                          },
                          child: const Text(
                            'remove',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFFFF4444),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Booking Status for Khushi
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            if (!activity.bookedForKhushi) {
                              setState(() {
                                activity.bookedForKhushi = true;
                              });
                            }
                          },
                          child: Text(
                            activity.bookedForKhushi
                                ? 'Booked for Khushi'
                                : '+ add Khushi',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ),
                      if (activity.bookedForKhushi)
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              activity.bookedForKhushi = false;
                            });
                          },
                          child: const Text(
                            'remove',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFFFF4444),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getImageColor(int index) {
    List<Color> colors = [
      const Color(0xFF8B4513), // Brown
      const Color(0xFF2E8B57), // Sea Green
      const Color(0xFF4682B4), // Steel Blue
      const Color(0xFF9932CC), // Dark Orchid
    ];
    return colors[index % colors.length];
  }
}

class ActivityItem {
  String name;
  String batchStartDate;
  bool bookedForAarav;
  bool bookedForKhushi;
  String imageUrl;

  ActivityItem({
    required this.name,
    required this.batchStartDate,
    required this.bookedForAarav,
    required this.bookedForKhushi,
    required this.imageUrl,
  });
}
