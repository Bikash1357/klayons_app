import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:klayons/utils/colour.dart';

import '../../services/calander/post_custome_child_calender_services.dart';
import '../../services/user_child/get_ChildServices.dart';
import '../../utils/styles/fonts.dart';
import 'event_model.dart';

class CreateEventDialog extends StatefulWidget {
  final DateTime selectedDate;
  final Function(Event) onEventCreated;
  final Event? eventToEdit;
  final List<Child> children;

  CreateEventDialog({
    required this.selectedDate,
    required this.onEventCreated,
    required this.children,
    this.eventToEdit,
  });

  @override
  _CreateEventDialogState createState() => _CreateEventDialogState();
}

class _CreateEventDialogState extends State<CreateEventDialog> {
  final _titleController = TextEditingController();
  final _addressController = TextEditingController();
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  DateTime _selectedDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  String _selectedChild = 'Aarav';
  bool _neverStops = true;
  Set<int> _selectedDays = <int>{};

  final List<String> _dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  final List<int> _dayValues = [1, 2, 3, 4, 5, 6, 7];

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.selectedDate;
    _endDate = widget.selectedDate.add(Duration(days: 30));

    if (widget.eventToEdit != null) {
      _titleController.text = widget.eventToEdit!.title;
      _addressController.text = widget.eventToEdit!.address;
      _startTime = TimeOfDay.fromDateTime(widget.eventToEdit!.startTime);
      _endTime = TimeOfDay.fromDateTime(widget.eventToEdit!.endTime);
      _selectedDate = widget.eventToEdit!.startTime;

      // Set recurrence data if exists
      if (widget.eventToEdit!.recurrence != null) {
        _selectedDays = Set<int>.from(
          widget.eventToEdit!.recurrence!.daysOfWeek,
        );
        _neverStops =
            widget.eventToEdit!.recurrence!.endRule == RecurrenceEnd.never;
        if (!_neverStops && widget.eventToEdit!.recurrence!.endDate != null) {
          _endDate = widget.eventToEdit!.recurrence!.endDate!;
        }
      }
    } else {
      _startTime = TimeOfDay(hour: 17, minute: 0); // 5:00 PM
      _endTime = TimeOfDay(hour: 18, minute: 0); // 6:00 PM
    }

    // Set default child if available
    if (widget.children.isNotEmpty) {
      _selectedChild = widget.children.first.name;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        padding: EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add Custom Activity',
                style: AppTextStyles.titleLarge(context).copyWith(          
                  color: AppColors.primaryOrange,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20),

              // Activity for section
              Text(
                'Activity for',
                style: AppTextStyles.bodyMedium(
                  context,
                ).copyWith(fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ...widget.children
                        .take(2)
                        .map(
                          (child) => GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedChild = child.name.split(' ').first;
                              });
                            },
                            child: Container(
                              margin: EdgeInsets.only(right: 12),
                              padding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    _selectedChild ==
                                        child.name.split(' ').first
                                    ? AppColors.primaryOrange
                                    : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color:
                                      _selectedChild ==
                                          child.name.split(' ').first
                                      ? AppColors.primaryOrange
                                      : Colors.grey.shade300,
                                  width:
                                      _selectedChild ==
                                          child.name.split(' ').first
                                      ? 2
                                      : 1,
                                ),
                              ),
                              child: Text(
                                child.name.split(' ').first,
                                style: AppTextStyles.bodyMedium(context)
                                    .copyWith(
                                      color:
                                          _selectedChild ==
                                              child.name.split(' ').first
                                          ? Colors.white
                                          : Colors.grey.shade700,
                                      fontWeight:
                                          _selectedChild ==
                                              child.name.split(' ').first
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ],
                ),
              ),
              SizedBox(height: 20),

              // Activity Name
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  hintText: 'Activity Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: AppColors.primaryOrange,
                      width: 2,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16),

              // Instructor and Location
              TextField(
                controller: _addressController,
                decoration: InputDecoration(
                  hintText: 'Instructor and Location',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: AppColors.primaryOrange,
                      width: 2,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16),

              // Date and time selection
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _selectDate(context, true),
                      child: Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 20,
                              color: Colors.grey.shade600,
                            ),
                            SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                DateFormat('EEE, d MMM').format(_selectedDate),
                                style: AppTextStyles.bodyMedium(context),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _selectDate(context, false),
                      child: Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 20,
                              color: Colors.grey.shade600,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _neverStops
                                    ? 'Never Stops'
                                    : DateFormat('EEE, d MMM').format(_endDate),
                                style: AppTextStyles.bodyMedium(context),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),

              // Time selection
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _selectTime(context, true),
                      child: Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _startTime != null
                              ? _startTime!.format(context)
                              : '5:00 PM',
                          style: AppTextStyles.bodyMedium(context),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 12),
                    child: Icon(
                      Icons.arrow_forward,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _selectTime(context, false),
                      child: Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _endTime != null
                              ? _endTime!.format(context)
                              : '6:00 PM',
                          style: AppTextStyles.bodyMedium(context),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),

              // Repeat every section
              Text(
                'Repeat every',
                style: AppTextStyles.bodyMedium(
                  context,
                ).copyWith(fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 12),

              // Day selection
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(7, (index) {
                  final dayValue = _dayValues[index];
                  final isSelected = _selectedDays.contains(dayValue);

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedDays.remove(dayValue);
                        } else {
                          _selectedDays.add(dayValue);
                        }
                      });
                    },
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected
                            ? AppColors.primaryOrange
                            : Colors.grey.shade200,
                      ),
                      child: Center(
                        child: Text(
                          _dayLabels[index],
                          style: AppTextStyles.bodyMedium(context).copyWith(
                            color: isSelected
                                ? Colors.white
                                : Colors.grey.shade600,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
              SizedBox(height: 24),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        'Cancel',
                        style: AppTextStyles.bodyMedium(
                          context,
                        ).copyWith(color: Colors.grey.shade600),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _createEvent,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryOrange,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Save',
                        style: AppTextStyles.bodyMedium(context).copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _selectDate(BuildContext context, bool isStartDate) async {
    if (isStartDate) {
      // Custom dialog for start date with CalendarDatePicker and Save button
      final DateTime? pickedDate = await showDialog<DateTime>(
        context: context,
        builder: (context) {
          DateTime tempPickedDate = _selectedDate;
          return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: Text(
                  'Select Start Date',
                  style: AppTextStyles.titleMedium(
                    context,
                  ).copyWith(fontWeight: FontWeight.w600),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 300,
                      height: 300,
                      child: Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: ColorScheme.light(
                            primary: AppColors.primaryOrange,
                          ),
                        ),
                        child: CalendarDatePicker(
                          initialDate: _selectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(Duration(days: 365)),
                          onDateChanged: (date) {
                            tempPickedDate = date;
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                actions: [
                  // Cancel button
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Returns null
                    },
                    child: Text(
                      'Cancel',
                      style: AppTextStyles.bodyMedium(
                        context,
                      ).copyWith(color: Colors.grey.shade600),
                    ),
                  ),
                  // Save button - returns the selected date
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(
                        context,
                      ).pop(tempPickedDate); // Returns DateTime
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryOrange,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    child: Text(
                      'Save',
                      style: AppTextStyles.bodyMedium(context).copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      );

      if (pickedDate != null) {
        setState(() {
          _selectedDate = pickedDate;
        });
      }
    } else {
      // Custom dialog for end date with CalendarDatePicker, Save and "Set as Never Stop" buttons
      final result = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) {
          DateTime tempPickedDate = _endDate;
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: Text(
                  'Select End Date',
                  style: AppTextStyles.titleMedium(
                    context,
                  ).copyWith(fontWeight: FontWeight.w600),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 300,
                      height: 300,
                      child: Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: ColorScheme.light(
                            primary: AppColors.primaryOrange,
                          ),
                        ),
                        child: CalendarDatePicker(
                          initialDate: _neverStops ? DateTime.now() : _endDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(Duration(days: 365)),
                          onDateChanged: (date) {
                            tempPickedDate = date;
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                actions: [
                  // Cancel button
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Cancel
                    },
                    child: Text(
                      'Cancel',
                      style: AppTextStyles.bodyMedium(
                        context,
                      ).copyWith(color: Colors.grey.shade600),
                    ),
                  ),
                  // Row with Never Stop and Save buttons with proper spacing
                  Row(
                    children: [
                      // Never Stop button - aligned to left with margin
                      Expanded(
                        flex: 1,
                        child: Container(
                          margin: EdgeInsets.only(left: 2, right: 6),
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(
                                context,
                              ).pop({'action': 'never_stop'});
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryOrange,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: Text(
                              'Never Stop',
                              style: AppTextStyles.bodyMedium(context).copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Save button - aligned to right with margin
                      Expanded(
                        flex: 1,
                        child: Container(
                          margin: EdgeInsets.only(left: 6, right: 2),
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(
                                context,
                              ).pop({'action': 'save', 'date': tempPickedDate});
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryOrange,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: Text(
                              'Save',
                              style: AppTextStyles.bodyMedium(context).copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          );
        },
      );

      // Handle the result
      if (result != null) {
        if (result['action'] == 'save') {
          setState(() {
            _endDate = result['date'];
            _neverStops = false;
          });
        } else if (result['action'] == 'never_stop') {
          setState(() {
            _neverStops = true;
          });
        }
      }
    }
  }

  void _selectTime(BuildContext context, bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStartTime
          ? (_startTime ?? TimeOfDay(hour: 17, minute: 0))
          : (_endTime ?? TimeOfDay(hour: 18, minute: 0)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: AppColors.primaryOrange),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      int roundedMinute = (picked.minute / 5).round() * 5;
      if (roundedMinute == 60) roundedMinute = 0;
      final roundedTime = TimeOfDay(hour: picked.hour, minute: roundedMinute);
      setState(() {
        if (isStartTime) {
          _startTime = roundedTime;
        } else {
          _endTime = roundedTime;
        }
      });
    }
  }

  void _createEvent() async {
    if (_titleController.text.isEmpty ||
        _startTime == null ||
        _endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill all required fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final DateTime startDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _startTime!.hour,
      _startTime!.minute,
    );

    final DateTime endDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _endTime!.hour,
      _endTime!.minute,
    );

    RecurrenceRule? recurrence;
    if (_selectedDays.isNotEmpty) {
      recurrence = RecurrenceRule(
        type: RecurrenceType.weekly,
        interval: 1,
        daysOfWeek: _selectedDays.toList(),
        endRule: _neverStops ? RecurrenceEnd.never : RecurrenceEnd.onDate,
        endDate: _neverStops ? null : _endDate,
      );
    }

    final event = Event(
      id:
          widget.eventToEdit?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text,
      address: _addressController.text,
      startTime: startDateTime,
      endTime: endDateTime,
      recurrence: recurrence,
      color: AppColors.primaryOrange,
      childName: _selectedChild,
    );

    // Show loading indicator while API is called
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(child: CircularProgressIndicator()),
    );

    try {
      // You need to get the current access token for the API.
      // Replace this with your actual token retrieval logic.
      String accessToken = await getAccessToken();

      final createdEvent = await CustomActivityService.createCustomActivity(
        event,
        accessToken: accessToken,
      );

      Navigator.of(context).pop(); // Remove loading dialog

      // Pass the created event back
      widget.onEventCreated(createdEvent);
      Navigator.of(context).pop(); // Close the create dialog
    } catch (e) {
      Navigator.of(context).pop(); // Remove loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create activity: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Dummy function for access token
  Future<String> getAccessToken() async {
    // Replace with your actual SharedPreferences/JWT fetch logic.
    return 'auth_token';
  }
}
