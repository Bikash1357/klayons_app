import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class Event {
  final String id;
  final String title;
  final String description;
  final DateTime startTime;
  final DateTime endTime;
  final RecurrenceRule? recurrence;
  final Color color;

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.startTime,
    required this.endTime,
    this.recurrence,
    this.color = Colors.orange,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'recurrence': recurrence?.toJson(),
      'color': color.value,
    };
  }

  static Event fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
      recurrence: json['recurrence'] != null
          ? RecurrenceRule.fromJson(json['recurrence'])
          : null,
      color: Color(json['color'] ?? Colors.orange.value),
    );
  }
}

class RecurrenceRule {
  final RecurrenceType type;
  final int interval;
  final List<int> daysOfWeek;
  final RecurrenceEnd endRule;
  final DateTime? endDate;
  final int? occurrences;

  RecurrenceRule({
    required this.type,
    this.interval = 1,
    this.daysOfWeek = const [],
    required this.endRule,
    this.endDate,
    this.occurrences,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type.index,
      'interval': interval,
      'daysOfWeek': daysOfWeek,
      'endRule': endRule.index,
      'endDate': endDate?.toIso8601String(),
      'occurrences': occurrences,
    };
  }

  static RecurrenceRule fromJson(Map<String, dynamic> json) {
    return RecurrenceRule(
      type: RecurrenceType.values[json['type']],
      interval: json['interval'],
      daysOfWeek: List<int>.from(json['daysOfWeek']),
      endRule: RecurrenceEnd.values[json['endRule']],
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      occurrences: json['occurrences'],
    );
  }
}

enum RecurrenceType { daily, weekly, monthly, yearly }

enum RecurrenceEnd { never, onDate, after }

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
                description: event.description,
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
                      borderRadius: BorderRadius.circular(
                        8,
                      ), // Fixed: removed shape to avoid conflict
                    ),
                    selectedTextStyle: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    todayDecoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(
                        8,
                      ), // Fixed: removed shape to avoid conflict
                    ),
                    todayTextStyle: TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                    markerDecoration: BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle, // Keep circle for markers only
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
          // Event List - Fixed: Only show user events, no default activities
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

class CreateEventDialog extends StatefulWidget {
  final DateTime selectedDate;
  final Function(Event) onEventCreated;
  final Event? eventToEdit;

  CreateEventDialog({
    required this.selectedDate,
    required this.onEventCreated,
    this.eventToEdit,
  });

  @override
  _CreateEventDialogState createState() => _CreateEventDialogState();
}

class _CreateEventDialogState extends State<CreateEventDialog> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? _startTime;
  DateTime? _endTime;
  bool _hasRecurrence = false;
  RecurrenceRule? _recurrenceRule;

  @override
  void initState() {
    super.initState();

    if (widget.eventToEdit != null) {
      _titleController.text = widget.eventToEdit!.title;
      _descriptionController.text = widget.eventToEdit!.description;
      _startTime = widget.eventToEdit!.startTime;
      _endTime = widget.eventToEdit!.endTime;
      _hasRecurrence = widget.eventToEdit!.recurrence != null;
      _recurrenceRule = widget.eventToEdit!.recurrence;
    } else {
      _startTime = DateTime(
        widget.selectedDate.year,
        widget.selectedDate.month,
        widget.selectedDate.day,
        DateTime.now().hour,
        DateTime.now().minute,
      );
      _endTime = _startTime!.add(Duration(hours: 1));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Text(
        widget.eventToEdit != null ? 'Edit Activity' : 'Create Activity',
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Activity Title',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDateTime(context, true),
                    child: Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Start Time',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            _startTime != null
                                ? DateFormat(
                                    'MMM dd, HH:mm',
                                  ).format(_startTime!)
                                : 'Select start time',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDateTime(context, false),
                    child: Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'End Time',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            _endTime != null
                                ? DateFormat('MMM dd, HH:mm').format(_endTime!)
                                : 'Select end time',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Checkbox(
                  value: _hasRecurrence,
                  onChanged: (value) {
                    setState(() {
                      _hasRecurrence = value ?? false;
                      if (!_hasRecurrence) {
                        _recurrenceRule = null;
                      }
                    });
                  },
                  activeColor: Colors.orange,
                ),
                Text('Repeat event'),
              ],
            ),
            if (_hasRecurrence) ...[
              SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _showRecurrenceDialog(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(
                    _recurrenceRule == null
                        ? 'Set Recurrence'
                        : 'Edit Recurrence',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _createEvent,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
          ),
          child: Text(widget.eventToEdit != null ? 'Update' : 'Create'),
        ),
      ],
    );
  }

  void _selectDateTime(BuildContext context, bool isStartTime) async {
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: widget.selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (date != null) {
      final TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (time != null) {
        final DateTime dateTime = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );

        setState(() {
          if (isStartTime) {
            _startTime = dateTime;
            if (_endTime != null && _endTime!.isBefore(_startTime!)) {
              _endTime = _startTime!.add(Duration(hours: 1));
            }
          } else {
            _endTime = dateTime;
          }
        });
      }
    }
  }

  void _showRecurrenceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => RecurrenceDialog(
        initialRule: _recurrenceRule,
        onRuleChanged: (rule) {
          setState(() {
            _recurrenceRule = rule;
          });
        },
      ),
    );
  }

  void _createEvent() {
    if (_titleController.text.isEmpty ||
        _startTime == null ||
        _endTime == null) {
      return;
    }

    final event = Event(
      id:
          widget.eventToEdit?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text,
      description: _descriptionController.text,
      startTime: _startTime!,
      endTime: _endTime!,
      recurrence: _hasRecurrence ? _recurrenceRule : null,
      color: Colors.orange,
    );

    widget.onEventCreated(event);
    Navigator.of(context).pop();
  }
}

class RecurrenceDialog extends StatefulWidget {
  final RecurrenceRule? initialRule;
  final Function(RecurrenceRule) onRuleChanged;

  RecurrenceDialog({this.initialRule, required this.onRuleChanged});

  @override
  _RecurrenceDialogState createState() => _RecurrenceDialogState();
}

class _RecurrenceDialogState extends State<RecurrenceDialog> {
  int _interval = 1;
  RecurrenceType _type = RecurrenceType.weekly;
  List<int> _selectedDays = [];
  RecurrenceEnd _endRule = RecurrenceEnd.never;
  DateTime? _endDate;
  int _occurrences = 1;

  // Fixed: Better text controllers for number inputs
  late TextEditingController _intervalController;
  late TextEditingController _occurrencesController;

  @override
  void initState() {
    super.initState();

    if (widget.initialRule != null) {
      _interval = widget.initialRule!.interval;
      _type = widget.initialRule!.type;
      _selectedDays = List.from(widget.initialRule!.daysOfWeek);
      _endRule = widget.initialRule!.endRule;
      _endDate = widget.initialRule!.endDate;
      _occurrences = widget.initialRule!.occurrences ?? 1;
    }

    _intervalController = TextEditingController(text: _interval.toString());
    _occurrencesController = TextEditingController(
      text: _occurrences.toString(),
    );
  }

  @override
  void dispose() {
    _intervalController.dispose();
    _occurrencesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Text('Custom recurrence'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fixed: Better layout for interval input
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Repeat every'),
                SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      width: 60,
                      child: TextField(
                        controller: _intervalController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 8,
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _interval = int.tryParse(value) ?? 1;
                            if (_interval < 1) {
                              _interval = 1;
                              _intervalController.text = '1';
                            }
                          });
                        },
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: DropdownButton<RecurrenceType>(
                        value: _type,
                        isExpanded: true,
                        onChanged: (RecurrenceType? newValue) {
                          setState(() {
                            _type = newValue!;
                            if (_type != RecurrenceType.weekly) {
                              _selectedDays.clear();
                            }
                          });
                        },
                        items: [
                          DropdownMenuItem(
                            value: RecurrenceType.daily,
                            child: Text('day(s)'),
                          ),
                          DropdownMenuItem(
                            value: RecurrenceType.weekly,
                            child: Text('week(s)'),
                          ),
                          DropdownMenuItem(
                            value: RecurrenceType.monthly,
                            child: Text('month(s)'),
                          ),
                          DropdownMenuItem(
                            value: RecurrenceType.yearly,
                            child: Text('year(s)'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (_type == RecurrenceType.weekly) ...[
              SizedBox(height: 16),
              Text('Repeat on', style: TextStyle(fontWeight: FontWeight.w500)),
              SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  _buildDayChip('S', 7),
                  _buildDayChip('M', 1),
                  _buildDayChip('T', 2),
                  _buildDayChip('W', 3),
                  _buildDayChip('T', 4),
                  _buildDayChip('F', 5),
                  _buildDayChip('S', 6),
                ],
              ),
            ],
            SizedBox(height: 16),
            Text('Ends', style: TextStyle(fontWeight: FontWeight.w500)),
            RadioListTile<RecurrenceEnd>(
              title: Text('Never'),
              value: RecurrenceEnd.never,
              groupValue: _endRule,
              activeColor: Colors.orange,
              onChanged: (RecurrenceEnd? value) {
                setState(() {
                  _endRule = value!;
                });
              },
            ),
            RadioListTile<RecurrenceEnd>(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('On'),
                  SizedBox(height: 8),
                  InkWell(
                    onTap: () => _selectEndDate(context),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _endDate != null
                            ? DateFormat('MMM dd, yyyy').format(_endDate!)
                            : 'Oct 29, 2025',
                      ),
                    ),
                  ),
                ],
              ),
              value: RecurrenceEnd.onDate,
              groupValue: _endRule,
              activeColor: Colors.orange,
              onChanged: (RecurrenceEnd? value) {
                setState(() {
                  _endRule = value!;
                  if (_endDate == null) {
                    _endDate = DateTime.now().add(Duration(days: 30));
                  }
                });
              },
            ),
            // Fixed: Better layout for occurrences to prevent overflow
            RadioListTile<RecurrenceEnd>(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('After'),
                      SizedBox(width: 8),
                      Container(
                        width: 60,
                        child: TextField(
                          controller: _occurrencesController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 8,
                            ),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _occurrences = int.tryParse(value) ?? 1;
                              if (_occurrences < 1) {
                                _occurrences = 1;
                                _occurrencesController.text = '1';
                              }
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    'occurrences',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
              value: RecurrenceEnd.after,
              groupValue: _endRule,
              activeColor: Colors.orange,
              onChanged: (RecurrenceEnd? value) {
                setState(() {
                  _endRule = value!;
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final rule = RecurrenceRule(
              type: _type,
              interval: _interval,
              daysOfWeek: _selectedDays,
              endRule: _endRule,
              endDate: _endDate,
              occurrences: _endRule == RecurrenceEnd.after
                  ? _occurrences
                  : null,
            );
            widget.onRuleChanged(rule);
            Navigator.of(context).pop();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
          ),
          child: Text('Done'),
        ),
      ],
    );
  }

  Widget _buildDayChip(String label, int dayNumber) {
    final isSelected = _selectedDays.contains(dayNumber);
    return InkWell(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedDays.remove(dayNumber);
          } else {
            _selectedDays.add(dayNumber);
          }
        });
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSelected ? Colors.orange : Colors.grey[200],
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  void _selectEndDate(BuildContext context) async {
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now().add(Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );

    if (date != null) {
      setState(() {
        _endDate = date;
      });
    }
  }
}
