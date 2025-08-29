import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'create_event_dialog.dart';
import 'event_model.dart';

class CalendarScreen extends StatefulWidget {
  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late final ValueNotifier<List<Event>> _selectedEvents;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<Event> _events = [];
  String _selectedFilter = 'All Activities';

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _selectedEvents = ValueNotifier(_getEventsForDay(_selectedDay!));
    _loadEvents();
  }

  @override
  void dispose() {
    _selectedEvents.dispose();
    super.dispose();
  }

  Future<void> _loadEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final eventsJson = prefs.getString('calendar_events');
    if (eventsJson != null) {
      final eventsList = json.decode(eventsJson) as List;
      setState(() {
        _events = eventsList.map((e) => Event.fromJson(e)).toList();
        _selectedEvents.value = _getEventsForDay(_selectedDay!);
      });
    }
  }

  Future<void> _saveEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final eventsJson = json.encode(_events.map((e) => e.toJson()).toList());
    await prefs.setString('calendar_events', eventsJson);
  }

  List<Event> _getEventsForDay(DateTime day) {
    List<Event> eventsForDay = [];

    for (Event event in _events) {
      if (isSameDay(event.startTime, day)) {
        eventsForDay.add(event);
      }

      // Check recurring events
      if (event.recurrence != null) {
        List<DateTime> occurrences = _calculateRecurrenceOccurrences(
          event,
          day,
        );
        for (DateTime occurrence in occurrences) {
          if (isSameDay(occurrence, day)) {
            eventsForDay.add(
              Event(
                id: '${event.id}_${occurrence.millisecondsSinceEpoch}',
                title: event.title,
                address: event.address,
                startTime: DateTime(
                  occurrence.year,
                  occurrence.month,
                  occurrence.day,
                  event.startTime.hour,
                  event.startTime.minute,
                ),
                endTime: DateTime(
                  occurrence.year,
                  occurrence.month,
                  occurrence.day,
                  event.endTime.hour,
                  event.endTime.minute,
                ),
                color: event.color,
              ),
            );
            break;
          }
        }
      }
    }

    return eventsForDay;
  }

  List<DateTime> _calculateRecurrenceOccurrences(
    Event event,
    DateTime targetDay,
  ) {
    List<DateTime> occurrences = [];
    if (event.recurrence == null) return occurrences;

    DateTime current = event.startTime;
    DateTime endLimit = targetDay.add(Duration(days: 365));

    if (event.recurrence!.endRule == RecurrenceEnd.onDate &&
        event.recurrence!.endDate != null) {
      endLimit = event.recurrence!.endDate!;
    }

    int count = 0;
    int maxOccurrences = event.recurrence!.occurrences ?? 1000;

    while (current.isBefore(endLimit) && count < maxOccurrences) {
      if (current.isAfter(event.startTime) ||
          isSameDay(current, event.startTime)) {
        bool shouldInclude = false;

        switch (event.recurrence!.type) {
          case RecurrenceType.weekly:
            if (event.recurrence!.daysOfWeek.contains(current.weekday)) {
              shouldInclude = true;
            }
            break;
          case RecurrenceType.daily:
          case RecurrenceType.monthly:
          case RecurrenceType.yearly:
            shouldInclude = true;
            break;
        }

        if (shouldInclude) {
          occurrences.add(current);
          count++;
        }
      }

      // Calculate next occurrence
      switch (event.recurrence!.type) {
        case RecurrenceType.daily:
          current = current.add(Duration(days: event.recurrence!.interval));
          break;
        case RecurrenceType.weekly:
          current = current.add(Duration(days: 1));
          break;
        case RecurrenceType.monthly:
          current = DateTime(
            current.year,
            current.month + event.recurrence!.interval,
            current.day,
            current.hour,
            current.minute,
          );
          break;
        case RecurrenceType.yearly:
          current = DateTime(
            current.year + event.recurrence!.interval,
            current.month,
            current.day,
            current.hour,
            current.minute,
          );
          break;
      }
    }

    return occurrences;
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
      });
      _selectedEvents.value = _getEventsForDay(selectedDay);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F9FA),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
            child: Column(
              children: [
                // Header Row
                Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Activity Schedule',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: PopupMenuButton<String>(
                          icon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _selectedFilter,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.black,
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(
                                Icons.keyboard_arrow_down,
                                size: 16,
                                color: Colors.black,
                              ),
                            ],
                          ),
                          onSelected: (value) {
                            setState(() {
                              _selectedFilter = value;
                            });
                          },
                          itemBuilder: (BuildContext context) {
                            return [
                              'All Activities',
                              'Booked',
                              'Scheduled',
                            ].map((String choice) {
                              return PopupMenuItem<String>(
                                value: choice,
                                child: Text(choice),
                              );
                            }).toList();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                // Month Row
                Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      DateFormat('MMMM yyyy').format(_focusedDay),
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ),
                ),
                // Calendar
                TableCalendar<Event>(
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _focusedDay,
                  calendarFormat: _calendarFormat,
                  eventLoader: _getEventsForDay,
                  startingDayOfWeek: StartingDayOfWeek.monday,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  onDaySelected: _onDaySelected,
                  onFormatChanged: (format) {
                    if (_calendarFormat != format) {
                      setState(() {
                        _calendarFormat = format;
                      });
                    }
                  },
                  onPageChanged: (focusedDay) {
                    setState(() {
                      _focusedDay = focusedDay;
                    });
                  },
                  calendarStyle: CalendarStyle(
                    outsideDaysVisible: false,
                    weekendTextStyle: TextStyle(color: Colors.black),
                    defaultTextStyle: TextStyle(color: Colors.black),
                    selectedDecoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    selectedTextStyle: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    todayDecoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    todayTextStyle: TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                    markerDecoration: BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                    ),
                    markersMaxCount: 3,
                    canMarkersOverflow: false,
                  ),
                  headerStyle: HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: false,
                    leftChevronVisible: false,
                    rightChevronVisible: false,
                    headerPadding: EdgeInsets.zero,
                    titleTextStyle: TextStyle(fontSize: 0),
                  ),
                  daysOfWeekStyle: DaysOfWeekStyle(
                    weekdayStyle: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                    weekendStyle: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8.0),
          // Event List
          Expanded(
            child: ValueListenableBuilder<List<Event>>(
              valueListenable: _selectedEvents,
              builder: (context, value, _) {
                if (value.isEmpty) {
                  return Container(
                    padding: EdgeInsets.all(20),
                    child: Center(
                      child: Text(
                        'No activities for this day',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
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
                          PopupMenuButton<String>(
                            icon: Icon(Icons.more_vert, color: Colors.grey),
                            onSelected: (value) {
                              if (value == 'edit') {
                                _editEvent(event);
                              } else if (value == 'delete') {
                                _deleteEvent(event);
                              }
                            },
                            itemBuilder: (BuildContext context) {
                              return [
                                PopupMenuItem<String>(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit, size: 18),
                                      SizedBox(width: 8),
                                      Text('Edit'),
                                    ],
                                  ),
                                ),
                                PopupMenuItem<String>(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.delete,
                                        size: 18,
                                        color: Colors.red,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Delete',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ],
                                  ),
                                ),
                              ];
                            },
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateEventDialog(context),
        backgroundColor: Colors.orange,
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showCreateEventDialog(BuildContext context, {Event? eventToEdit}) {
    showDialog(
      context: context,
      builder: (context) => CreateEventDialog(
        selectedDate: _selectedDay ?? DateTime.now(),
        eventToEdit: eventToEdit,
        onEventCreated: (event) {
          setState(() {
            if (eventToEdit != null) {
              // Replace existing event
              int index = _events.indexWhere((e) => e.id == eventToEdit.id);
              if (index != -1) {
                _events[index] = event;
              }
            } else {
              // Add new event
              _events.add(event);
            }
            _selectedEvents.value = _getEventsForDay(_selectedDay!);
            _saveEvents();
          });
        },
      ),
    );
  }

  void _editEvent(Event event) {
    _showCreateEventDialog(context, eventToEdit: event);
  }

  void _deleteEvent(Event event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Activity'),
        content: Text('Are you sure you want to delete "${event.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _events.removeWhere((e) => e.id == event.id);
                _selectedEvents.value = _getEventsForDay(_selectedDay!);
                _saveEvents();
              });
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
