import 'package:flutter/material.dart';

class ActivitySchedulePage extends StatefulWidget {
  @override
  _ActivitySchedulePageState createState() => _ActivitySchedulePageState();
}

class _ActivitySchedulePageState extends State<ActivitySchedulePage> {
  String selectedFilter = 'All Activities';
  List<String> filterOptions = ['All Activities', 'Booked', 'Scheduled'];

  // Sample activities data
  List<Activity> activities = [
    Activity(
      name: 'Activity Name',
      time: '5:00pm onwards',
      date: DateTime(2025, 5, 1),
    ),
    Activity(
      name: 'Activity Name',
      time: '5:00pm onwards',
      date: DateTime(2025, 5, 6),
    ),
    Activity(
      name: 'Activity Name',
      time: '5:00pm onwards',
      date: DateTime(2025, 5, 8),
    ),
    Activity(
      name: 'Activity Name',
      time: '5:00pm onwards',
      date: DateTime(2025, 5, 9),
    ),
    Activity(
      name: 'Activity Name',
      time: '5:00pm onwards',
      date: DateTime(2025, 5, 15),
    ),
    Activity(
      name: 'Activity Name',
      time: '5:00pm onwards',
      date: DateTime(2025, 5, 16),
    ),
    Activity(
      name: 'Activity Name',
      time: '5:00pm onwards',
      date: DateTime(2025, 5, 17),
    ),
    Activity(
      name: 'Activity Name',
      time: '5:00pm onwards',
      date: DateTime(2025, 5, 20),
    ),
    Activity(
      name: 'Activity Name',
      time: '5:00pm onwards',
      date: DateTime(2025, 5, 22),
    ),
    Activity(
      name: 'Activity Name',
      time: '5:00pm onwards',
      date: DateTime(2025, 5, 27),
    ),
    Activity(
      name: 'Activity Name',
      time: '5:00pm onwards',
      date: DateTime(2025, 5, 29),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.grey[600]),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'ACTIVITY SCHEDULE',
          style: TextStyle(
            color: Colors.grey[800],
            fontSize: 16,
            fontWeight: FontWeight.w500,
            letterSpacing: 1.2,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_none, color: Colors.grey[600]),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Header with month and dropdown
          Container(
            color: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'MAY 2025',
                  style: TextStyle(
                    color: Color(0xFFE67E22),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: DropdownButton<String>(
                    value: selectedFilter,
                    underline: SizedBox(),
                    icon: Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.grey[600],
                    ),
                    items: filterOptions.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(
                          value,
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 14,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedFilter = newValue!;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),

          // Calendar Grid
          Expanded(
            child: Container(
              color: Colors.white,
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  // Days of week header
                  Row(
                    children: ['M', 'T', 'W', 'T', 'F', 'S', 'S']
                        .map(
                          (day) => Expanded(
                            child: Center(
                              child: Text(
                                day,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  SizedBox(height: 16),

                  // Calendar grid
                  Expanded(
                    child: GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 7,
                        childAspectRatio: 1,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: 35, // 5 weeks
                      itemBuilder: (context, index) {
                        int day = index - 2; // Start from April 28
                        bool isCurrentMonth = day >= 1 && day <= 31;
                        bool hasActivity = hasActivityOnDay(day);
                        bool isToday = day == 1; // May 1st highlighted

                        return Container(
                          decoration: BoxDecoration(
                            color: isToday
                                ? Color(0xFFE67E22)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(4),
                            border: isToday
                                ? null
                                : (hasActivity
                                      ? Border.all(
                                          color: Color(0xFFE67E22),
                                          width: 2,
                                        )
                                      : null),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                getDayText(day, index),
                                style: TextStyle(
                                  color: isToday
                                      ? Colors.white
                                      : (isCurrentMonth
                                            ? Colors.grey[800]
                                            : Colors.grey[400]),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (hasActivity && !isToday)
                                Container(
                                  width: 20,
                                  height: 2,
                                  margin: EdgeInsets.only(top: 2),
                                  color: Color(0xFFE67E22),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  // Activity list
                  Container(
                    padding: EdgeInsets.only(top: 16),
                    child: Column(
                      children: [
                        ActivityListItem(
                          icon: Icons.directions_walk,
                          name: 'Activity Name',
                          time: '5:00pm onwards',
                        ),
                        SizedBox(height: 12),
                        ActivityListItem(
                          icon: Icons.event,
                          name: 'Activity Name',
                          time: '5:00pm onwards',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String getDayText(int day, int index) {
    if (index == 0) return '28';
    if (index == 1) return '29';
    if (index == 2) return '30';
    if (day >= 1 && day <= 31) return day.toString();
    if (day > 31) return (day - 31).toString();
    return '';
  }

  bool hasActivityOnDay(int day) {
    List<int> activityDays = [1, 6, 8, 9, 15, 16, 17, 20, 22, 27, 29];
    return activityDays.contains(day);
  }
}

class ActivityListItem extends StatelessWidget {
  final IconData icon;
  final String name;
  final String time;

  const ActivityListItem({
    Key? key,
    required this.icon,
    required this.name,
    required this.time,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 40,
          color: Color(0xFFE67E22),
          margin: EdgeInsets.only(right: 12),
        ),
        Icon(icon, color: Colors.grey[600], size: 20),
        SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: TextStyle(
                color: Colors.grey[800],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(time, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          ],
        ),
      ],
    );
  }
}

class Activity {
  final String name;
  final String time;
  final DateTime date;

  Activity({required this.name, required this.time, required this.date});
}
