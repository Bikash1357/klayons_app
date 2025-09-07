import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../../services/calander/children_calendar_service.dart';
import '../../services/calander/society_batch_calander.dart';
import '../../services/user_child/get_ChildServices.dart';
import '../../utils/styles/fonts.dart';
import 'create_event_dialog.dart';
import 'event_model.dart';
import 'package:klayons/utils/colour.dart';

class CalendarScreen extends StatefulWidget {
  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late final ValueNotifier<List<dynamic>> _selectedEvents;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<Event> _events = [];

  // Filter state
  bool _showAllActivities = true; // "All Activities" selected by default

  // Child-related variables
  List<Child> _children = [];
  bool _isLoadingChildren = false;
  String? _childError;
  Set<int> _selectedChildIds = {};

  // Society batches variables
  List<BatchCalendarEvent> _batchEvents = [];
  bool _isLoadingBatches = false;
  String? _batchError;

  // Children calendar variables
  List<ChildCalendarEvent> _childrenCalendarEvents = [];
  bool _isLoadingChildrenCalendar = false;
  String? _childrenCalendarError;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _selectedEvents = ValueNotifier(_getEventsForDay(_selectedDay!));
    _loadEvents();
    _loadChildren();
    _loadSocietyBatches();
  }

  @override
  void dispose() {
    _selectedEvents.dispose();
    super.dispose();
  }

  // Load society batches
  Future<void> _loadSocietyBatches() async {
    try {
      setState(() {
        _isLoadingBatches = true;
        _batchError = null;
      });

      SocietyBatchesResponse? cachedBatches =
          SocietyBatchesService.getCachedBatches();
      if (cachedBatches != null) {
        _generateBatchEvents(cachedBatches);
      }

      SocietyBatchesResponse batchesResponse =
          await SocietyBatchesService.fetchSocietyBatches();
      _generateBatchEvents(batchesResponse);

      setState(() {
        _isLoadingBatches = false;
        _selectedEvents.value = _getEventsForDay(_selectedDay!);
      });
    } catch (e) {
      setState(() {
        _batchError = e.toString();
        _isLoadingBatches = false;
      });
      print('Error loading society batches: $e');
    }
  }

  void _generateBatchEvents(SocietyBatchesResponse batchesResponse) {
    DateTime startDate = DateTime.now().subtract(Duration(days: 30));
    DateTime endDate = DateTime.now().add(Duration(days: 90));

    _batchEvents = SocietyBatchesService.generateCalendarEvents(
      batchesResponse,
      startDate,
      endDate,
    );
  }

  Future<void> _loadChildren() async {
    try {
      setState(() {
        _isLoadingChildren = true;
        _childError = null;
      });

      List<Child>? cachedChildren = GetChildservices.getCachedChildren();
      if (cachedChildren != null) {
        setState(() {
          _children = cachedChildren;
        });
      }

      List<Child> children = await GetChildservices.fetchChildren();
      setState(() {
        _children = children;
        _isLoadingChildren = false;
      });
    } catch (e) {
      setState(() {
        _childError = e.toString();
        _isLoadingChildren = false;
      });
      print('Error loading children: $e');
    }
  }

  Future<void> _loadChildrenCalendar() async {
    if (_selectedChildIds.isEmpty) {
      setState(() {
        _childrenCalendarEvents = [];
        _selectedEvents.value = _getEventsForDay(_selectedDay!);
      });
      return;
    }

    try {
      setState(() {
        _isLoadingChildrenCalendar = true;
        _childrenCalendarError = null;
      });

      ChildrenCalendarResponse? cachedCalendar =
          ChildrenCalendarService.getCachedChildrenCalendar(_selectedChildIds);
      if (cachedCalendar != null) {
        _generateChildrenCalendarEvents(cachedCalendar);
      }

      ChildrenCalendarResponse calendarResponse =
          await ChildrenCalendarService.fetchChildrenCalendar(
            _selectedChildIds,
          );
      _generateChildrenCalendarEvents(calendarResponse);

      setState(() {
        _isLoadingChildrenCalendar = false;
        _selectedEvents.value = _getEventsForDay(_selectedDay!);
      });
    } catch (e) {
      setState(() {
        _childrenCalendarError = e.toString();
        _isLoadingChildrenCalendar = false;
      });
      print('Error loading children calendar: $e');
    }
  }

  void _generateChildrenCalendarEvents(
    ChildrenCalendarResponse calendarResponse,
  ) {
    DateTime startDate = DateTime.now().subtract(Duration(days: 30));
    DateTime endDate = DateTime.now().add(Duration(days: 90));

    _childrenCalendarEvents =
        ChildrenCalendarService.generateChildrenCalendarEvents(
          calendarResponse,
          startDate,
          endDate,
        );
  }

  Future<void> _refreshData() async {
    await Future.wait([
      _loadSocietyBatches(),
      if (_selectedChildIds.isNotEmpty) _loadChildrenCalendar(),
    ]);
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

  List<dynamic> _getEventsForDay(DateTime day) {
    List<dynamic> eventsForDay = [];

    // Always add custom events
    for (Event event in _events) {
      if (isSameDay(event.startTime, day)) {
        eventsForDay.add(event);
      }

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
                childName: event.childName,
              ),
            );
            break;
          }
        }
      }
    }

    // Add society batch events if "All Activities" is selected
    if (_showAllActivities) {
      for (BatchCalendarEvent batchEvent in _batchEvents) {
        if (isSameDay(batchEvent.startTime, day)) {
          eventsForDay.add(batchEvent);
        }
      }
    }

    // Add children calendar events if specific children are selected
    if (_selectedChildIds.isNotEmpty) {
      for (ChildCalendarEvent childEvent in _childrenCalendarEvents) {
        if (isSameDay(childEvent.startTime, day)) {
          eventsForDay.add(childEvent);
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

  // Custom event marker builder for dots + plus
  Widget _eventMarkerBuilder(
    BuildContext context,
    DateTime day,
    List<dynamic> events,
  ) {
    if (events.isEmpty) return SizedBox.shrink();

    final int eventCount = events.length;

    if (eventCount <= 2) {
      // Show individual dots for 1-2 events
      return Positioned(
        bottom: 1,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: events.take(2).map((event) {
            Color dotColor = Colors.orange;
            if (event is BatchCalendarEvent) {
              dotColor = event.color;
            } else if (event is ChildCalendarEvent) {
              dotColor = event.color;
            }

            return Container(
              margin: EdgeInsets.only(right: eventCount > 1 ? 2 : 0),
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            );
          }).toList(),
        ),
      );
    } else {
      // Show 2 dots + plus for 3+ events
      return Positioned(
        bottom: 1,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // First dot
            Container(
              width: 6,
              height: 6,
              margin: EdgeInsets.only(right: 2),
              decoration: BoxDecoration(
                color: Colors.orange,
                shape: BoxShape.circle,
              ),
            ),
            // Second dot
            Container(
              width: 6,
              height: 6,
              margin: EdgeInsets.only(right: 2),
              decoration: BoxDecoration(
                color: Colors.orange,
                shape: BoxShape.circle,
              ),
            ),
            // Plus sign
            Container(
              width: 8,
              height: 8,
              child: Center(
                child: Text(
                  '+',
                  style: TextStyle(
                    color: Colors.orange,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildFilterChips() {
    if (_isLoadingChildren) {
      return Container(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
              ),
            ),
            SizedBox(width: 8),
            Text(
              'Loading children...',
              style: AppTextStyles.bodySmall(
                context,
              ).copyWith(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return Container(
      height: 35,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          // "All Activities" chip (always first)
          GestureDetector(
            onTap: () {
              setState(() {
                _showAllActivities = !_showAllActivities;
                _selectedEvents.value = _getEventsForDay(_selectedDay!);
              });
            },
            child: Container(
              margin: EdgeInsets.only(right: 8),
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _showAllActivities
                    ? Colors.orange.shade50
                    : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: _showAllActivities
                      ? Colors.orange
                      : Colors.grey.shade300,
                  width: _showAllActivities ? 2 : 1,
                ),
              ),
              child: Text(
                'All Activities',
                style: AppTextStyles.bodySmall(context).copyWith(
                  fontWeight: _showAllActivities
                      ? FontWeight.w600
                      : FontWeight.w400,
                  color: _showAllActivities
                      ? Colors.orange.shade700
                      : Colors.black,
                ),
              ),
            ),
          ),

          // Children chips
          ..._children.map((child) {
            bool isSelected = _selectedChildIds.contains(child.id);
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedChildIds.remove(child.id);
                  } else {
                    _selectedChildIds.add(child.id);
                  }
                });
                _loadChildrenCalendar();
              },
              child: Container(
                margin: EdgeInsets.only(right: 8),
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.orange.shade50 : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isSelected ? Colors.orange : Colors.grey.shade300,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Text(
                  "${child.name}'s Activities",
                  style: AppTextStyles.bodySmall(context).copyWith(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected ? Colors.orange.shade700 : Colors.black,
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Activity Schedule',
          style: AppTextStyles.headlineSmall(
            context,
          ).copyWith(color: Colors.black, fontSize: 20),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            onPressed: _refreshData,
            icon: Icon(
              (_isLoadingBatches || _isLoadingChildrenCalendar)
                  ? Icons.hourglass_empty
                  : Icons.refresh,
              color: Colors.orange,
            ),
            tooltip: 'Refresh activities',
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            child: Column(
              children: [
                // Filter chips section
                Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: _buildFilterChips(),
                ),

                // Month Row
                Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          DateFormat('MMMM yyyy').format(_focusedDay),
                          style: AppTextStyles.titleLarge(context).copyWith(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ),
                      if (_isLoadingBatches || _isLoadingChildrenCalendar)
                        Container(
                          margin: EdgeInsets.only(left: 8),
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.orange,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Calendar with custom markers
                TableCalendar<dynamic>(
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
                  calendarBuilders: CalendarBuilders(
                    // Custom marker builder
                    markerBuilder: _eventMarkerBuilder,
                  ),
                  calendarStyle: CalendarStyle(
                    outsideDaysVisible: false,
                    weekendTextStyle: AppTextStyles.bodyMedium(
                      context,
                    ).copyWith(color: Colors.black),
                    defaultTextStyle: AppTextStyles.bodyMedium(
                      context,
                    ).copyWith(color: Colors.black),
                    selectedDecoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    selectedTextStyle: AppTextStyles.bodyMedium(context)
                        .copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                    todayDecoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    todayTextStyle: AppTextStyles.bodyMedium(context).copyWith(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                    // Disable default markers since we're using custom ones
                    markersMaxCount: 0,
                    canMarkersOverflow: false,
                  ),
                  headerStyle: HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: false,
                    leftChevronVisible: false,
                    rightChevronVisible: false,
                    headerPadding: EdgeInsets.zero,
                    titleTextStyle: AppTextStyles.bodySmall(
                      context,
                    ).copyWith(fontSize: 0),
                  ),
                  daysOfWeekStyle: DaysOfWeekStyle(
                    weekdayStyle: AppTextStyles.bodySmall(
                      context,
                    ).copyWith(color: Colors.grey.shade600),
                    weekendStyle: AppTextStyles.bodySmall(
                      context,
                    ).copyWith(color: Colors.grey.shade600),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8.0),

          // Event List
          Expanded(
            child: ValueListenableBuilder<List<dynamic>>(
              valueListenable: _selectedEvents,
              builder: (context, value, _) {
                if (value.isEmpty) {
                  return Container(
                    padding: EdgeInsets.all(20),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'No activities for this day',
                            style: AppTextStyles.bodyLargeEmphasized(
                              context,
                            ).copyWith(color: Colors.grey.shade600),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Select different activity filters above to see more events',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.bodySmall(
                              context,
                            ).copyWith(color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: value.length,
                  itemBuilder: (context, index) {
                    final event = value[index];

                    String title;
                    String timeText;
                    String? venue;
                    Color iconColor;
                    String? childInfo;
                    bool isCancelled = false;

                    if (event is ChildCalendarEvent) {
                      title = event.title;
                      timeText =
                          '${DateFormat('h:mma').format(event.startTime).toLowerCase()} - ${DateFormat('h:mma').format(event.endTime).toLowerCase()}';
                      venue = event.venue;
                      iconColor = event.color;
                      childInfo = 'for ${event.childName}';
                      isCancelled = event.isCancelled;
                    } else if (event is BatchCalendarEvent) {
                      title = event.title;
                      timeText =
                          '${DateFormat('h:mma').format(event.startTime).toLowerCase()} - ${DateFormat('h:mma').format(event.endTime).toLowerCase()}';
                      venue = event.venue;
                      iconColor = event.color;
                      isCancelled = event.isCancelled;
                    } else if (event is Event) {
                      title = event.title;
                      timeText =
                          '${DateFormat('h:mma').format(event.startTime).toLowerCase()} - ${DateFormat('h:mma').format(event.endTime).toLowerCase()}';
                      venue = event.address;
                      iconColor = Colors.orange;
                      if (event.childName != null &&
                          event.childName!.isNotEmpty) {
                        childInfo = 'for ${event.childName}';
                      }
                    } else {
                      return SizedBox.shrink();
                    }

                    return Container(
                      margin: EdgeInsets.only(bottom: 12),
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isCancelled
                            ? Colors.grey.shade100
                            : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 3,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 4,
                            height: 50,
                            decoration: BoxDecoration(
                              color: isCancelled ? Colors.grey : iconColor,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        title,
                                        style:
                                            AppTextStyles.bodyLargeEmphasized(
                                              context,
                                            ).copyWith(
                                              fontWeight: FontWeight.w600,
                                              decoration: isCancelled
                                                  ? TextDecoration.lineThrough
                                                  : null,
                                              color: isCancelled
                                                  ? Colors.grey
                                                  : Colors.black,
                                            ),
                                      ),
                                    ),
                                    if (isCancelled)
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.red.shade100,
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: Text(
                                          'CANCELLED',
                                          style:
                                              AppTextStyles.bodySmall(
                                                context,
                                              ).copyWith(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.red.shade700,
                                              ),
                                        ),
                                      ),
                                  ],
                                ),
                                SizedBox(height: 4),
                                Text(
                                  timeText,
                                  style: AppTextStyles.bodyMedium(context)
                                      .copyWith(
                                        color: isCancelled
                                            ? Colors.grey.shade500
                                            : Colors.grey.shade600,
                                      ),
                                ),
                                if (venue != null && venue.isNotEmpty) ...[
                                  SizedBox(height: 2),
                                  Text(
                                    venue,
                                    style: AppTextStyles.bodySmall(context)
                                        .copyWith(
                                          color: isCancelled
                                              ? Colors.grey.shade400
                                              : Colors.grey.shade500,
                                        ),
                                  ),
                                ],
                                if (childInfo != null) ...[
                                  SizedBox(height: 2),
                                  Text(
                                    childInfo,
                                    style: AppTextStyles.bodySmall(context)
                                        .copyWith(
                                          fontWeight: FontWeight.w500,
                                          color: isCancelled
                                              ? Colors.grey.shade400
                                              : Colors.blue.shade600,
                                        ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (event is Event)
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
        children: _children,
        onEventCreated: (event) {
          setState(() {
            if (eventToEdit != null) {
              int index = _events.indexWhere((e) => e.id == eventToEdit.id);
              if (index != -1) {
                _events[index] = event;
              }
            } else {
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
        title: Text(
          'Delete Activity',
          style: AppTextStyles.titleMedium(context),
        ),
        content: Text(
          'Are you sure you want to delete "${event.title}"?',
          style: AppTextStyles.bodyMedium(context),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel', style: AppTextStyles.bodyMedium(context)),
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
            child: Text(
              'Delete',
              style: AppTextStyles.bodyMedium(
                context,
              ).copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
