import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:klayons/screens/activity_details_page.dart';
import 'package:klayons/screens/home_screen.dart';
import 'package:klayons/services/activity/activityDetailsService.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../services/calendar/CustomCalander/post_custome_child_calender_services.dart';
import '../../services/calendar/children_calendar_service.dart';
import '../../services/calendar/society_activity_calander_service.dart';
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

  // Filter state
  bool _showAllActivities = true;

  // Child-related variables
  List<Child> _children = [];
  bool _isLoadingChildren = false;
  String? _childError;
  Set<int> _selectedChildIds = {};

  // Society batches variables
  List<ActivityCalendarEvent> _batchEvents = [];
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
    _loadChildren();
    _loadSocietyBatches();
  }

  @override
  void dispose() {
    _selectedEvents.dispose();
    super.dispose();
  }

  // Pull to refresh functionality
  Future<void> _onRefresh() async {
    try {
      SocietyActivitiesService.clearCache();
      ChildrenCalendarService.clearCache();

      setState(() {
        _batchEvents.clear();
        _childrenCalendarEvents.clear();
        _isLoadingBatches = true;
        _isLoadingChildren = true;
        if (_selectedChildIds.isNotEmpty) {
          _isLoadingChildrenCalendar = true;
        }
      });

      await Future.wait([_loadChildren(), _loadSocietyBatches()]);

      if (_selectedChildIds.isNotEmpty) {
        await _loadChildrenCalendar();
      }

      _selectedEvents.value = _getEventsForDay(_selectedDay!);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Calendar refreshed successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to refresh calendar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _loadSocietyBatches() async {
    try {
      setState(() {
        _isLoadingBatches = true;
        _batchError = null;
      });

      SocietyActivitiesResponse? cachedBatches =
          SocietyActivitiesService.getCachedActivities();
      if (cachedBatches != null) {
        _generateBatchEvents(cachedBatches);
      }

      SocietyActivitiesResponse batchesResponse =
          await SocietyActivitiesService.fetchSocietyActivities();
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

  void _generateBatchEvents(SocietyActivitiesResponse batchesResponse) {
    DateTime startDate = DateTime.now().subtract(Duration(days: 30));
    DateTime endDate = DateTime.now().add(Duration(days: 90));

    _batchEvents = SocietyActivitiesService.generateCalendarEvents(
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

      DateTime startDate = DateTime.now().subtract(Duration(days: 30));
      DateTime endDate = DateTime.now().add(Duration(days: 90));

      ChildrenCalendarResponse calendarResponse =
          await ChildrenCalendarService.fetchChildrenCalendar(
            _selectedChildIds,
            startDate: startDate,
            endDate: endDate,
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

  List<dynamic> _getEventsForDay(DateTime day) {
    List<dynamic> eventsForDay = [];

    if (_showAllActivities) {
      for (ActivityCalendarEvent batchEvent in _batchEvents) {
        if (isSameDay(batchEvent.startTime, day)) {
          eventsForDay.add(batchEvent);
        }
      }
    }

    if (_selectedChildIds.isNotEmpty) {
      for (ChildCalendarEvent childEvent in _childrenCalendarEvents) {
        if (isSameDay(childEvent.startTime, day)) {
          eventsForDay.add(childEvent);
        }
      }
    }

    return eventsForDay;
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

  Widget _eventMarkerBuilder(
    BuildContext context,
    DateTime day,
    List<dynamic> events,
  ) {
    if (events.isEmpty) return SizedBox.shrink();

    final int eventCount = events.length;

    if (eventCount <= 2) {
      return Positioned(
        bottom: 1,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: events.take(2).map((event) {
            Color dotColor;

            // Only 2 colors: orange for custom, primaryOrange for all others
            if (event is ChildCalendarEvent) {
              dotColor = event.isCustomActivity
                  ? Colors
                        .orange // Orange for custom activities
                  : AppColors.primaryOrange; // Primary orange for all others
            } else {
              // For ActivityCalendarEvent (society batches)
              dotColor = AppColors.primaryOrange;
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
      // When more than 2 events, show 2 dots + plus sign
      return Positioned(
        bottom: 1,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              margin: EdgeInsets.only(right: 2),
              decoration: BoxDecoration(
                color: AppColors.primaryOrange,
                shape: BoxShape.circle,
              ),
            ),
            Container(
              width: 6,
              height: 6,
              margin: EdgeInsets.only(right: 2),
              decoration: BoxDecoration(
                color: AppColors.primaryOrange,
                shape: BoxShape.circle,
              ),
            ),
            Container(
              width: 8,
              height: 8,
              child: Center(
                child: Text(
                  '+',
                  style: TextStyle(
                    color: AppColors.primaryOrange,
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
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.primaryOrange,
                ),
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
          GestureDetector(
            onTap: () {
              setState(() {
                if (!_showAllActivities) {
                  _selectedChildIds.clear();
                }
                _showAllActivities = !_showAllActivities;
                _selectedEvents.value = _getEventsForDay(_selectedDay!);
              });
            },
            child: Container(
              margin: EdgeInsets.only(right: 8),
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _showAllActivities ? AppColors.highlight2 : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _showAllActivities
                      ? AppColors.primaryOrange
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
                      ? AppColors.primaryOrange
                      : Colors.black,
                ),
              ),
            ),
          ),
          ..._children.map((child) {
            bool isSelected = _selectedChildIds.contains(child.id);
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedChildIds.remove(child.id);
                  } else {
                    _selectedChildIds.add(child.id);
                    _showAllActivities = false;
                  }
                });
                _loadChildrenCalendar();
              },
              child: Container(
                margin: EdgeInsets.only(right: 8),
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.highlight2 : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primaryOrange
                        : Colors.grey.shade300,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Text(
                  "${child.name.split(' ').first}'s Activities",
                  style: AppTextStyles.bodySmall(context).copyWith(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected ? AppColors.primaryOrange : Colors.black,
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  String _getEventStatusText(dynamic event) {
    if (event is ActivityCalendarEvent) {
      if (event.isCancelled) return 'CANCELLED';
      if (event.isRescheduled) return 'RESCHEDULED';
      if (event.isFromRDate) return 'SPECIAL';
    } else if (event is ChildCalendarEvent) {
      if (event.isCancelled) return 'CANCELLED';
      if (event.isRescheduled) return 'RESCHEDULED';
      if (event.isCustomActivity) return 'CUSTOM';
      //if (event.isFromRDate) return 'SPECIAL';
    }
    return '';
  }

  Color _getEventStatusColor(String status) {
    switch (status) {
      case 'CANCELLED':
        return Colors.red;
      case 'RESCHEDULED':
        return Colors.orange;
      case 'CUSTOM':
        return Colors.orange;
      //   case 'SPECIAL':
      // return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  // Updated conversion method to include childId
  Event _convertCustomActivityToEvent(ChildCustomActivity customActivity) {
    RecurrenceRule? recurrence;
    if (customActivity.recurrence != null) {
      var customRec = customActivity.recurrence!;

      RecurrenceType recType;
      switch (customRec.type.toLowerCase()) {
        case 'daily':
          recType = RecurrenceType.daily;
          break;
        case 'weekly':
          recType = RecurrenceType.weekly;
          break;
        case 'monthly':
          recType = RecurrenceType.monthly;
          break;
        case 'yearly':
          recType = RecurrenceType.yearly;
          break;
        default:
          recType = RecurrenceType.weekly;
      }

      RecurrenceEnd recEnd;
      switch (customRec.endRule.toLowerCase()) {
        case 'never':
          recEnd = RecurrenceEnd.never;
          break;
        case 'ondate':
        case 'date':
          recEnd = RecurrenceEnd.onDate;
          break;
        case 'after':
        case 'occurrences':
          recEnd = RecurrenceEnd.after;
          break;
        default:
          recEnd = RecurrenceEnd.never;
      }

      recurrence = RecurrenceRule(
        type: recType,
        interval: customRec.interval,
        daysOfWeek: customRec.daysOfWeek,
        endRule: recEnd,
        endDate: customRec.endDate,
        occurrences: customRec.occurrences,
      );
    }

    Color eventColor = AppColors.primaryOrange;
    try {
      String hex = customActivity.color.replaceFirst('#', '');
      if (hex.length == 6) {
        hex = 'FF$hex';
      }
      eventColor = Color(int.parse(hex, radix: 16));
    } catch (e) {
      print('Error converting color: $e');
    }

    // Find the child ID from the child name
    int? childId;
    try {
      Child? matchingChild = _children.firstWhere(
        (child) => child.name == customActivity.childName,
        orElse: () => _children.first,
      );
      childId = matchingChild.id;
    } catch (e) {
      print('Error finding child ID: $e');
      if (_children.isNotEmpty) {
        childId = _children.first.id;
      }
    }

    return Event(
      id: customActivity.id,
      title: customActivity.title,
      address: customActivity.address,
      startTime: customActivity.startTime,
      endTime: customActivity.endTime,
      recurrence: recurrence,
      color: eventColor,
      childId: childId,
      childName: customActivity.childName,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        leading: IconButton(
          icon: SvgPicture.asset(
            'assets/App_icons/iconBack.svg',
            width: 24,
            height: 24,
            colorFilter: ColorFilter.mode(
              AppColors.darkElements,
              BlendMode.srcIn,
            ),
          ),
          onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
        ),
        title: Text(
          'Activity Schedule',
          style: AppTextStyles.formLarge(context).copyWith(
            color: AppColors.darkElements,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: AppColors.primaryOrange,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        DateFormat('MMMM yyyy').format(_focusedDay),
                        style: AppTextStyles.titleLarge(context).copyWith(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryOrange,
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
                            AppColors.primaryOrange,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: _buildFilterChips(),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        offset: Offset(4, 0),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      SizedBox(height: 15),
                      TableCalendar<dynamic>(
                        firstDay: DateTime.utc(2020, 1, 1),
                        lastDay: DateTime.utc(2030, 12, 31),
                        focusedDay: _focusedDay,
                        calendarFormat: _calendarFormat,
                        eventLoader: _getEventsForDay,
                        startingDayOfWeek: StartingDayOfWeek.monday,
                        selectedDayPredicate: (day) =>
                            isSameDay(_selectedDay, day),
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
                            color: AppColors.primaryOrange,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          selectedTextStyle: AppTextStyles.bodyMedium(context)
                              .copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                          todayDecoration: BoxDecoration(
                            color: AppColors.highlight2,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          todayTextStyle: AppTextStyles.bodyMedium(context)
                              .copyWith(
                                color: AppColors.primaryOrange,
                                fontWeight: FontWeight.bold,
                              ),
                          defaultDecoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          weekendDecoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          outsideDecoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          disabledDecoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                          ),
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
              ),
              const SizedBox(height: 8.0),
              Container(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height * 0.4,
                ),
                child: ValueListenableBuilder<List<dynamic>>(
                  valueListenable: _selectedEvents,
                  builder: (context, value, _) {
                    if (value.isEmpty) {
                      String emptyMessage = _showAllActivities
                          ? 'No activities for this day'
                          : _selectedChildIds.isEmpty
                          ? 'Select a child to see their activities'
                          : 'No activities for selected children on this day';

                      String subMessage = _showAllActivities
                          ? 'Select different activity filters above to see more events'
                          : 'Try selecting different children or "All Activities"';

                      return Container(
                        padding: EdgeInsets.all(20),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                emptyMessage,
                                style: AppTextStyles.bodyLargeEmphasized(
                                  context,
                                ).copyWith(color: Colors.grey.shade600),
                              ),
                              SizedBox(height: 8),
                              Text(
                                subMessage,
                                textAlign: TextAlign.center,
                                style: AppTextStyles.bodySmall(
                                  context,
                                ).copyWith(color: Colors.grey.shade500),
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Pull down to refresh',
                                style: AppTextStyles.bodySmall(context)
                                    .copyWith(
                                      color: AppColors.primaryOrange,
                                      fontStyle: FontStyle.italic,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: EdgeInsets.all(16),
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: value.length,
                      itemBuilder: (context, index) {
                        final event = value[index];

                        String title;
                        String timeText;
                        String? venue;
                        Color iconColor;
                        String? childInfo;
                        bool isCancelled = false;
                        bool isRescheduled = false;
                        bool isCustomActivity = false;
                        String? statusText;
                        String? cancelReason;

                        if (event is ChildCalendarEvent) {
                          title = event.title;
                          timeText =
                              '${DateFormat('h:mma').format(event.startTime).toLowerCase()} - ${DateFormat('h:mma').format(event.endTime).toLowerCase()}';
                          venue = event.venue;
                          iconColor = event.color;
                          //childInfo = 'for ${event.childName.split(' ').first}';
                          isCancelled = event.isCancelled;
                          isRescheduled = event.isRescheduled;
                          isCustomActivity = event.isCustomActivity;
                          cancelReason = event.cancelReason;
                          statusText = _getEventStatusText(event);
                        } else if (event is ActivityCalendarEvent) {
                          title = event.title;
                          timeText =
                              '${DateFormat('h:mma').format(event.startTime).toLowerCase()} - ${DateFormat('h:mma').format(event.endTime).toLowerCase()}';
                          venue = event.venue;
                          iconColor = event.color;
                          isCancelled = event.isCancelled;
                          isRescheduled = event.isRescheduled;
                          cancelReason = event.cancelReason;
                          statusText = _getEventStatusText(event);
                        } else {
                          return SizedBox.shrink();
                        }

                        return GestureDetector(
                          onTap: () {
                            if (event is ActivityCalendarEvent) {
                              int activityId = event.originalActivity.id;
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ActivityBookingPage(
                                    activityId: activityId,
                                  ),
                                ),
                              );
                            } else if (event is ChildCalendarEvent) {
                              if (!event.isCustomActivity &&
                                  event.originalActivity
                                      is ChildEnrolledActivity) {
                                ChildEnrolledActivity enrolledActivity =
                                    event.originalActivity
                                        as ChildEnrolledActivity;
                                int activityId = enrolledActivity.id;

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ActivityBookingPage(
                                      activityId: activityId,
                                    ),
                                  ),
                                );
                              }
                            }
                          },
                          child: Container(
                            margin: EdgeInsets.only(bottom: 12),
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isCancelled
                                  ? Colors.grey.shade100
                                  : (isRescheduled
                                        ? Colors.orange.shade50
                                        : Colors.white),
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
                                    color: isCustomActivity
                                        ? Colors
                                              .orange // Orange for custom activities
                                        : AppColors
                                              .primaryOrange, // Primary orange for all others
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),

                                SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                                        ? TextDecoration
                                                              .lineThrough
                                                        : null,
                                                    color: isCancelled
                                                        ? Colors.grey
                                                        : Colors.black,
                                                  ),
                                            ),
                                          ),
                                          if (statusText != null &&
                                              statusText.isNotEmpty)
                                            Container(
                                              margin: EdgeInsets.only(right: 8),
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 6,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: _getEventStatusColor(
                                                  statusText,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              child: Text(
                                                statusText,
                                                style:
                                                    AppTextStyles.bodySmall(
                                                      context,
                                                    ).copyWith(
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: Colors.white,
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
                                      if (venue != null &&
                                          venue.isNotEmpty) ...[
                                        SizedBox(height: 2),
                                        Text(
                                          venue,
                                          style:
                                              AppTextStyles.bodySmall(
                                                context,
                                              ).copyWith(
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
                                          style:
                                              AppTextStyles.bodySmall(
                                                context,
                                              ).copyWith(
                                                fontWeight: FontWeight.w500,
                                                color: isCancelled
                                                    ? Colors.grey.shade400
                                                    : (isCustomActivity
                                                          ? Colors.grey.shade600
                                                          : Colors
                                                                .blue
                                                                .shade600),
                                              ),
                                        ),
                                      ],
                                      if (cancelReason != null &&
                                          cancelReason.isNotEmpty) ...[
                                        SizedBox(height: 2),
                                        Text(
                                          'Reason: $cancelReason',
                                          style:
                                              AppTextStyles.bodySmall(
                                                context,
                                              ).copyWith(
                                                fontStyle: FontStyle.italic,
                                                color: Colors.grey.shade500,
                                              ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                if (isCustomActivity &&
                                    event is ChildCalendarEvent)
                                  PopupMenuButton<String>(
                                    icon: Icon(
                                      Icons.more_vert,
                                      color: Colors.grey,
                                    ),
                                    onSelected: (value) {
                                      if (value == 'edit') {
                                        if (event.originalActivity
                                            is ChildCustomActivity) {
                                          ChildCustomActivity customActivity =
                                              event.originalActivity
                                                  as ChildCustomActivity;
                                          Event editableEvent =
                                              _convertCustomActivityToEvent(
                                                customActivity,
                                              );
                                          _showEditEventDialog(
                                            context,
                                            editableEvent,
                                          );
                                        }
                                      } else if (value == 'delete') {
                                        _showDeleteCustomActivityDialog(
                                          context,
                                          event,
                                        );
                                      }
                                    },
                                    itemBuilder: (BuildContext context) {
                                      return [
                                        PopupMenuItem<String>(
                                          value: 'edit',
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.edit,
                                                size: 18,
                                                color: Colors.grey,
                                              ),
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
                                                style: TextStyle(
                                                  color: Colors.red,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ];
                                    },
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateEventDialog(context),
        backgroundColor: AppColors.primaryOrange,
        shape: const CircleBorder(),
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showCreateEventDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => CreateEventDialog(
        selectedDate: _selectedDay ?? DateTime.now(),
        eventToEdit: null,
        children: _children,
        onEventCreated: (event) async {
          // Clear cache to force fresh data
          ChildrenCalendarService.clearCache();

          // Reload calendar data
          if (_selectedChildIds.isNotEmpty) {
            await _loadChildrenCalendar();
          }

          // Refresh the selected events for the current day
          if (mounted) {
            setState(() {
              _selectedEvents.value = _getEventsForDay(_selectedDay!);
            });
          }
        },
      ),
    );
  }

  void _showEditEventDialog(BuildContext context, Event eventToEdit) {
    showDialog(
      context: context,
      builder: (dialogContext) => CreateEventDialog(
        selectedDate: eventToEdit.startTime,
        eventToEdit: eventToEdit,
        children: _children,
        onEventCreated: (updatedEvent) async {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (loadingContext) =>
                Center(child: CircularProgressIndicator()),
          );

          try {
            await CustomActivityService.updateCustomActivity(
              eventToEdit.id!,
              updatedEvent,
            );

            if (!mounted) return;

            Navigator.of(context).pop(); // Close loading

            // Clear cache and reload
            ChildrenCalendarService.clearCache();

            if (_selectedChildIds.isNotEmpty) {
              await _loadChildrenCalendar();
            }

            // Force UI update
            if (mounted) {
              setState(() {
                _selectedEvents.value = _getEventsForDay(_selectedDay!);
              });
            }

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Custom activity updated successfully!'),
                backgroundColor: Colors.green,
              ),
            );
          } catch (e) {
            if (!mounted) return;
            Navigator.of(context).pop();

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to update activity: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
      ),
    );
  }

  void _showDeleteCustomActivityDialog(
    BuildContext context,
    ChildCalendarEvent event,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'Delete Custom Activity',
          style: AppTextStyles.titleMedium(dialogContext),
        ),
        content: Text(
          'Are you sure you want to delete "${event.title}"? This action cannot be undone.',
          style: AppTextStyles.bodyMedium(dialogContext),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'Cancel',
              style: AppTextStyles.bodyMedium(dialogContext),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop(); // Close confirmation dialog

              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (loadingContext) => AlertDialog(
                  content: Row(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(width: 16),
                      Text('Deleting activity...'),
                    ],
                  ),
                ),
              );

              try {
                int activityId = 0;
                if (event.originalActivity is ChildCustomActivity) {
                  ChildCustomActivity customActivity =
                      event.originalActivity as ChildCustomActivity;
                  activityId = customActivity.id;
                }

                if (activityId == 0) {
                  throw Exception('Activity ID not found');
                }

                bool deleted = await CustomActivityService.deleteCustomActivity(
                  activityId,
                );

                if (!mounted) return;

                Navigator.of(context).pop(); // Close loading

                if (deleted) {
                  // Clear cache and reload
                  ChildrenCalendarService.clearCache();

                  if (_selectedChildIds.isNotEmpty) {
                    await _loadChildrenCalendar();
                  }

                  // Force UI update
                  if (mounted) {
                    setState(() {
                      _selectedEvents.value = _getEventsForDay(_selectedDay!);
                    });
                  }

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Custom activity deleted successfully!'),
                      backgroundColor: Colors.deepOrange,
                    ),
                  );
                }
              } catch (e) {
                if (!mounted) return;

                Navigator.of(context).pop(); // Close loading

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to delete activity: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(
              'Delete',
              style: AppTextStyles.bodyMedium(
                dialogContext,
              ).copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
