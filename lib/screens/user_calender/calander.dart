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
  String _selectedFilter = 'All Activities';

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

  Future<void> _refreshSocietyBatches() async {
    try {
      setState(() {
        _isLoadingBatches = true;
        _batchError = null;
      });

      SocietyBatchesResponse batchesResponse =
          await SocietyBatchesService.fetchSocietyBatches(forceRefresh: true);
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
    }
  }

  // Load children calendar when child IDs are selected
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

      // Try to get cached children calendar first
      ChildrenCalendarResponse? cachedCalendar =
          ChildrenCalendarService.getCachedChildrenCalendar(_selectedChildIds);
      if (cachedCalendar != null) {
        _generateChildrenCalendarEvents(cachedCalendar);
      }

      // Fetch fresh data from server
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

    print(
      'Generated ${_childrenCalendarEvents.length} children calendar events',
    );
  }

  Future<void> _refreshChildrenCalendar() async {
    if (_selectedChildIds.isEmpty) return;

    try {
      setState(() {
        _isLoadingChildrenCalendar = true;
        _childrenCalendarError = null;
      });

      ChildrenCalendarResponse calendarResponse =
          await ChildrenCalendarService.fetchChildrenCalendar(
            _selectedChildIds,
            forceRefresh: true,
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
    }
  }

  Future<void> _loadChildren() async {
    if (_children.isNotEmpty) return;

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

  Future<void> _refreshChildren() async {
    try {
      setState(() {
        _isLoadingChildren = true;
        _childError = null;
      });

      List<Child> children = await GetChildservices.refreshChildren();
      setState(() {
        _children = children;
        _isLoadingChildren = false;
      });
    } catch (e) {
      setState(() {
        _childError = e.toString();
        _isLoadingChildren = false;
      });
    }
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

  // Updated to handle Event, BatchCalendarEvent, and ChildCalendarEvent types
  List<dynamic> _getEventsForDay(DateTime day) {
    List<dynamic> eventsForDay = [];

    // Add regular events based on filter
    if (_selectedFilter == 'All Activities' || _selectedFilter == 'Scheduled') {
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
                ),
              );
              break;
            }
          }
        }
      }
    }

    // Add society batch events when "All Activities" is selected
    if (_selectedFilter == 'All Activities') {
      for (BatchCalendarEvent batchEvent in _batchEvents) {
        if (isSameDay(batchEvent.startTime, day)) {
          eventsForDay.add(batchEvent);
        }
      }
    }

    // Add children calendar events when "Booked" is selected and children are selected
    if (_selectedFilter == 'Booked' && _selectedChildIds.isNotEmpty) {
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

  Widget _buildChildSelectionSection() {
    if (_selectedFilter != 'Booked') {
      return SizedBox.shrink();
    }

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
              'Loading...',
              style: AppTextStyles.bodySmall.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    if (_childError != null) {
      return Container(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 16),
            SizedBox(width: 4),
            Text(
              'Error',
              style: AppTextStyles.bodySmall.copyWith(color: Colors.red),
            ),
            TextButton(
              onPressed: _refreshChildren,
              child: Text(
                'Retry',
                style: AppTextStyles.bodySmall.copyWith(fontSize: 10),
              ),
            ),
          ],
        ),
      );
    }

    if (_children.isEmpty) {
      return Container(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'No children found',
          style: AppTextStyles.bodySmall.copyWith(color: Colors.grey.shade600),
        ),
      );
    }

    return Container(
      height: 35,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _children.length,
        itemBuilder: (context, index) {
          final child = _children[index];
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
              // Load children calendar when selection changes
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
                child.name,
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? Colors.orange.shade700 : Colors.black,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _onFilterChanged(String value) async {
    setState(() {
      _selectedFilter = value;
      if (value != 'Booked') {
        _selectedChildIds.clear();
        _childrenCalendarEvents = [];
      }
      _selectedEvents.value = _getEventsForDay(_selectedDay!);
    });

    if (value == 'Booked' && _children.isEmpty) {
      await _loadChildren();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          'Activity Schedule',
          style: AppTextStyles.headlineSmall.copyWith(
            color: Colors.black,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
        actions: [
          if (_selectedFilter == 'All Activities')
            IconButton(
              onPressed: _refreshSocietyBatches,
              icon: Icon(
                _isLoadingBatches ? Icons.hourglass_empty : Icons.refresh,
                color: Colors.orange,
              ),
              tooltip: 'Refresh activities',
            ),
          if (_selectedFilter == 'Booked' && _selectedChildIds.isNotEmpty)
            IconButton(
              onPressed: _refreshChildrenCalendar,
              icon: Icon(
                _isLoadingChildrenCalendar
                    ? Icons.hourglass_empty
                    : Icons.refresh,
                color: Colors.orange,
              ),
              tooltip: 'Refresh booked activities',
            ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            child: Column(
              children: [
                // Header Row with Child Selection and Filter
                Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    children: [
                      Expanded(child: _buildChildSelectionSection()),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: PopupMenuButton<String>(
                          icon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Padding(
                                padding: EdgeInsets.only(left: 12),
                                child: Text(
                                  _selectedFilter,
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(
                                Icons.keyboard_arrow_down,
                                size: 16,
                                color: Colors.black,
                              ),
                              SizedBox(width: 8),
                            ],
                          ),
                          onSelected: _onFilterChanged,
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

                // Month Row with loading indicators
                Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          DateFormat('MMMM yyyy').format(_focusedDay),
                          style: AppTextStyles.titleLarge.copyWith(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ),
                      if (_selectedFilter == 'Booked' &&
                          _selectedChildIds.isNotEmpty)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${_selectedChildIds.length} selected',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: Colors.orange.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      if (_selectedFilter == 'All Activities' &&
                          _isLoadingBatches)
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
                      if (_selectedFilter == 'Booked' &&
                          _isLoadingChildrenCalendar)
                        Container(
                          margin: EdgeInsets.only(left: 8),
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.blue,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Calendar
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
                  calendarStyle: CalendarStyle(
                    outsideDaysVisible: false,
                    weekendTextStyle: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.black,
                    ),
                    defaultTextStyle: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.black,
                    ),
                    selectedDecoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    selectedTextStyle: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    todayDecoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    todayTextStyle: AppTextStyles.bodyMedium.copyWith(
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
                    titleTextStyle: AppTextStyles.bodySmall.copyWith(
                      fontSize: 0,
                    ),
                  ),
                  daysOfWeekStyle: DaysOfWeekStyle(
                    weekdayStyle: AppTextStyles.bodySmall.copyWith(
                      color: Colors.grey.shade600,
                    ),
                    weekendStyle: AppTextStyles.bodySmall.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8.0),

          // Event List - Updated to handle all event types
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
                            style: AppTextStyles.bodyLargeEmphasized.copyWith(
                              color: Colors.grey.shade600,
                            ),
                          ),
                          if (_selectedChildIds.isNotEmpty &&
                              _selectedFilter == 'Booked') ...[
                            SizedBox(height: 8),
                            Text(
                              'Showing schedule for ${_selectedChildIds.length} selected children',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                          if (_batchError != null &&
                              _selectedFilter == 'All Activities') ...[
                            SizedBox(height: 16),
                            Text(
                              'Error loading activities',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: Colors.red,
                              ),
                            ),
                            TextButton(
                              onPressed: _refreshSocietyBatches,
                              child: Text('Retry'),
                            ),
                          ],
                          if (_childrenCalendarError != null &&
                              _selectedFilter == 'Booked') ...[
                            SizedBox(height: 16),
                            Text(
                              'Error loading booked activities',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: Colors.red,
                              ),
                            ),
                            TextButton(
                              onPressed: _refreshChildrenCalendar,
                              child: Text('Retry'),
                            ),
                          ],
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
                          '${DateFormat('h:mma').format(event.startTime).toLowerCase()} onwards';
                      venue = event.address;
                      iconColor = Colors.orange;
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
                                        style: AppTextStyles.bodyLargeEmphasized
                                            .copyWith(
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
                                          style: AppTextStyles.bodySmall
                                              .copyWith(
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
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: isCancelled
                                        ? Colors.grey.shade500
                                        : Colors.grey.shade600,
                                  ),
                                ),
                                if (venue != null && venue.isNotEmpty) ...[
                                  SizedBox(height: 2),
                                  Text(
                                    venue,
                                    style: AppTextStyles.bodySmall.copyWith(
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
                                    style: AppTextStyles.bodySmall.copyWith(
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
        title: Text('Delete Activity', style: AppTextStyles.titleMedium),
        content: Text(
          'Are you sure you want to delete "${event.title}"?',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel', style: AppTextStyles.bodyMedium),
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
              style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
