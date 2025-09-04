import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
                style: AppTextStyles.titleLarge.copyWith(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20),

              // Activity for section
              Text(
                'Activity for',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  ...widget.children
                      .take(2)
                      .map(
                        (child) => GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedChild = child.name;
                            });
                          },
                          child: Container(
                            margin: EdgeInsets.only(right: 12),
                            padding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: _selectedChild == child.name
                                  ? Colors.orange.shade50
                                  : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _selectedChild == child.name
                                    ? Colors.orange
                                    : Colors.grey.shade300,
                                width: _selectedChild == child.name ? 2 : 1,
                              ),
                            ),
                            child: Text(
                              child.name,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: _selectedChild == child.name
                                    ? Colors.orange.shade700
                                    : Colors.grey.shade700,
                                fontWeight: _selectedChild == child.name
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
                    borderSide: BorderSide(color: Colors.orange, width: 2),
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
                    borderSide: BorderSide(color: Colors.orange, width: 2),
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
                            Text(
                              DateFormat('EEE, d MMM').format(_selectedDate),
                              style: AppTextStyles.bodyMedium,
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
                            Text(
                              _neverStops
                                  ? 'Never Stops'
                                  : DateFormat('EEE, d MMM').format(_endDate),
                              style: AppTextStyles.bodyMedium,
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
                          style: AppTextStyles.bodyMedium,
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
                          style: AppTextStyles.bodyMedium,
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
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w500,
                ),
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
                            ? Colors.orange
                            : Colors.grey.shade200,
                      ),
                      child: Center(
                        child: Text(
                          _dayLabels[index],
                          style: AppTextStyles.bodyMedium.copyWith(
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
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _createEvent,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Save',
                        style: AppTextStyles.bodyMedium.copyWith(
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
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _selectedDate : _endDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(
            context,
          ).copyWith(colorScheme: ColorScheme.light(primary: Colors.orange)),
          child: child!,
        );
      },
    );

    if (date != null) {
      setState(() {
        if (isStartDate) {
          _selectedDate = date;
        } else {
          _endDate = date;
          _neverStops = false;
        }
      });
    }
  }

  void _selectTime(BuildContext context, bool isStartTime) async {
    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: isStartTime
          ? (_startTime ?? TimeOfDay(hour: 17, minute: 0))
          : (_endTime ?? TimeOfDay(hour: 18, minute: 0)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(
            context,
          ).copyWith(colorScheme: ColorScheme.light(primary: Colors.orange)),
          child: child!,
        );
      },
    );

    if (time != null) {
      setState(() {
        if (isStartTime) {
          _startTime = time;
          // Automatically adjust end time if it's before start time
          if (_endTime != null) {
            final startMinutes = _startTime!.hour * 60 + _startTime!.minute;
            final endMinutes = _endTime!.hour * 60 + _endTime!.minute;
            if (endMinutes <= startMinutes) {
              _endTime = TimeOfDay(
                hour: (_startTime!.hour + 1) % 24,
                minute: _startTime!.minute,
              );
            }
          }
        } else {
          _endTime = time;
        }
      });
    }
  }

  void _createEvent() {
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

    // Create DateTime objects using the selected date and times
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
      color: Colors.orange,
      childName: _selectedChild, // Add this line to pass selected child name
    );

    widget.onEventCreated(event);
    Navigator.of(context).pop();
  }
}
