import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'event_calender_model.dart';

class EventListWidget extends StatelessWidget {
  final ValueNotifier<List<Event>> selectedEvents;
  final Function(BuildContext, Event) onEventTap;

  const EventListWidget({
    Key? key,
    required this.selectedEvents,
    required this.onEventTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<Event>>(
      valueListenable: selectedEvents,
      builder: (context, value, _) {
        if (value.isEmpty) {
          return Container(
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                SizedBox(height: 20),
                Row(
                  children: [
                    Icon(Icons.event_note, color: Colors.orange),
                    SizedBox(width: 8),
                    Text(
                      'Activity Name',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Padding(
                  padding: EdgeInsets.only(left: 32),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '5:00pm onwards',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.calendar_today, color: Colors.orange),
                    SizedBox(width: 8),
                    Text(
                      'Activity Name',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Padding(
                  padding: EdgeInsets.only(left: 32),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '5:00pm onwards',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: value.length,
          itemBuilder: (context, index) {
            final event = value[index];
            return Container(
              margin: EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Icon(Icons.event_note, color: Colors.orange),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          '${DateFormat('h:mma').format(event.startTime).toLowerCase()} onwards',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
