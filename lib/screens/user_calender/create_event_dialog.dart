import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:klayons/screens/bottom_screens/uesr_profile/Childs/add_child.dart';
import 'package:klayons/utils/colour.dart';
import '../../services/calendar/CustomCalander/post_custome_child_calender_services.dart';
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
  int? _selectedChildId; // Changed to store child ID instead of name
  String _selectedChildName = ''; // Keep for display purposes
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

      // Set child ID from edit mode
      _selectedChildId = widget.eventToEdit!.childId;
      _selectedChildName = widget.eventToEdit!.childName ?? '';

      // Set recurrence data if exists
      if (widget.eventToEdit!.recurrence != null) {
        // Handle nullable daysOfWeek
        if (widget.eventToEdit!.recurrence!.daysOfWeek != null) {
          _selectedDays = Set<int>.from(
            widget.eventToEdit!.recurrence!.daysOfWeek!,
          );
        }
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
      _selectedChildId = widget.children.first.id;
      _selectedChildName = widget.children.first.name;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
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
                style: AppTextStyles.titleMedium(context).copyWith(
                  color: AppColors.primaryOrange,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20),

              // Activity for section
              // Activity for section - REPLACE the existing Row widget
              Row(
                children: [
                  Text(
                    'Activity for:  ',
                    style: AppTextStyles.bodyMedium(
                      context,
                    ).copyWith(fontWeight: FontWeight.w500),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          ...widget.children.map(
                            (child) => GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedChildId = child.id;
                                  _selectedChildName = child.name
                                      .split(' ')
                                      .first;
                                });
                              },
                              child: Container(
                                margin: EdgeInsets.only(right: 12),
                                padding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _selectedChildId == child.id
                                      ? AppColors.orangeHighlight
                                      : Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: _selectedChildId == child.id
                                        ? AppColors.primaryOrange
                                        : Colors.grey.shade300,
                                    width: _selectedChildId == child.id ? 2 : 1,
                                  ),
                                ),
                                child: Text(
                                  child.name.split(' ').first,
                                  style: AppTextStyles.bodyMedium(context)
                                      .copyWith(
                                        color: _selectedChildId == child.id
                                            ? AppColors.primaryOrange
                                            : Colors.grey.shade700,
                                        fontWeight: _selectedChildId == child.id
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                      ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              widget.children.isEmpty
                  ? Row(
                      children: [
                        Text(
                          'No child profile added  ',
                          style: AppTextStyles.bodyMedium(
                            context,
                          ).copyWith(color: Colors.grey.shade700),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (contex) => AddChildPage(),
                              ),
                            );
                          },
                          child: Text(
                            'Add Now?',
                            style: AppTextStyles.bodyMedium(context).copyWith(
                              color: AppColors.primaryOrange,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                              decorationColor: AppColors.primaryOrange,
                            ),
                          ),
                        ),
                      ],
                    )
                  : SizedBox.shrink(),
              // Show different UI based on children availability
              SizedBox(height: 20),

              // Activity Name
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  hintText: 'Activity Name',
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 12,
                  ),
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
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 12,
                  ),
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
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 12),
                    child: Icon(
                      Icons.arrow_forward,
                      color: Colors.grey.shade600,
                    ),
                  ),
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
                      onPressed:
                          widget.children.isEmpty || _selectedChildId == null
                          ? null
                          : _createEvent,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            widget.children.isEmpty || _selectedChildId == null
                            ? Colors.grey.shade300
                            : AppColors.primaryOrange,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        disabledBackgroundColor: Colors.grey.shade300,
                      ),
                      child: Text(
                        'Save',
                        style: AppTextStyles.bodyMedium(context).copyWith(
                          color:
                              widget.children.isEmpty ||
                                  _selectedChildId == null
                              ? Colors.grey.shade500
                              : Colors.white,
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
                backgroundColor: AppColors.primaryContainer,
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
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text(
                      'Cancel',
                      style: AppTextStyles.bodyMedium(
                        context,
                      ).copyWith(color: Colors.grey.shade600),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(tempPickedDate);
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
      final result = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) {
          DateTime tempPickedDate = _endDate;
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                backgroundColor: AppColors.primaryContainer,
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
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text(
                      'Cancel',
                      style: AppTextStyles.bodyMedium(
                        context,
                      ).copyWith(color: Colors.grey.shade600),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: Container(
                          margin: EdgeInsets.only(left: 2, right: 6),
                          child: TextButton(
                            onPressed: () {
                              Navigator.of(
                                context,
                              ).pop({'action': 'never_stop'});
                            },
                            child: Text(
                              'Never Stop',
                              style: AppTextStyles.bodyMedium(context).copyWith(
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
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
    if (_titleController.text.isEmpty || _selectedChildId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill all required fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final startTimeToUse = _startTime ?? TimeOfDay(hour: 17, minute: 0);
    final endTimeToUse = _endTime ?? TimeOfDay(hour: 18, minute: 0);

    final DateTime startDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      startTimeToUse.hour,
      startTimeToUse.minute,
    );

    final DateTime endDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      endTimeToUse.hour,
      endTimeToUse.minute,
    );

    RecurrenceRule? recurrence;
    if (_selectedDays.isNotEmpty) {
      recurrence = RecurrenceRule(
        type: RecurrenceType.weekly,
        interval: 1,
        daysOfWeek: _selectedDays.toList(), // Convert Set<int> to List<int>
        endRule: _neverStops ? RecurrenceEnd.never : RecurrenceEnd.onDate,
        endDate: _neverStops ? null : _endDate,
      );
    }

    final event = Event(
      id: widget.eventToEdit?.id,
      title: _titleController.text,
      address: _addressController.text,
      startTime: startDateTime,
      endTime: endDateTime,
      recurrence: recurrence,
      color: AppColors.primaryOrange,
      childId: _selectedChildId, // Pass childId instead of childName
      childName: _selectedChildName, // Keep for display
    );

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(child: CircularProgressIndicator()),
    );

    try {
      Event createdEvent;

      if (widget.eventToEdit != null && widget.eventToEdit!.id != null) {
        // Update existing event
        createdEvent = await CustomActivityService.updateCustomActivity(
          widget.eventToEdit!.id!,
          event,
        );
      } else {
        // Create new event
        createdEvent = await CustomActivityService.createCustomActivity(event);
      }

      Navigator.of(context).pop(); // Remove loading dialog

      widget.onEventCreated(createdEvent);
      Navigator.of(context).pop(); // Close the create dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.eventToEdit != null
                ? 'Activity updated successfully!'
                : 'Activity created successfully!',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      Navigator.of(context).pop(); // Remove loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save activity: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        ),
      );
    }
  }
}
