import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:klayons/screens/user_calender/recurrence_dialog.dart';

import 'event_model.dart';

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
  final _addressController = TextEditingController();
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  bool _hasRecurrence = false;
  RecurrenceRule? _recurrenceRule;

  @override
  void initState() {
    super.initState();

    if (widget.eventToEdit != null) {
      _titleController.text = widget.eventToEdit!.title;
      _addressController.text = widget.eventToEdit!.address;
      _startTime = TimeOfDay.fromDateTime(widget.eventToEdit!.startTime);
      _endTime = TimeOfDay.fromDateTime(widget.eventToEdit!.endTime);
      _hasRecurrence = widget.eventToEdit!.recurrence != null;
      _recurrenceRule = widget.eventToEdit!.recurrence;
    } else {
      _startTime = TimeOfDay.now();
      _endTime = TimeOfDay(
        hour: (TimeOfDay.now().hour + 1) % 24,
        minute: TimeOfDay.now().minute,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Text(
        widget.eventToEdit != null
            ? 'Edit Add your Custom Schedule'
            : 'Add your Custom Schedule',
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
              controller: _addressController,
              decoration: InputDecoration(
                labelText: 'Address',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _selectTime(context, true),
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
                                ? _startTime!.format(context)
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
                    onTap: () => _selectTime(context, false),
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
                                ? _endTime!.format(context)
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

  void _selectTime(BuildContext context, bool isStartTime) async {
    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: isStartTime
          ? (_startTime ?? TimeOfDay.now())
          : (_endTime ?? TimeOfDay.now()),
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

    // Create DateTime objects using the selected date and times
    final DateTime startDateTime = DateTime(
      widget.selectedDate.year,
      widget.selectedDate.month,
      widget.selectedDate.day,
      _startTime!.hour,
      _startTime!.minute,
    );

    final DateTime endDateTime = DateTime(
      widget.selectedDate.year,
      widget.selectedDate.month,
      widget.selectedDate.day,
      _endTime!.hour,
      _endTime!.minute,
    );

    final event = Event(
      id:
          widget.eventToEdit?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text,
      address: _addressController.text,
      startTime: startDateTime,
      endTime: endDateTime,
      recurrence: _hasRecurrence ? _recurrenceRule : null,
      color: Colors.orange,
    );

    widget.onEventCreated(event);
    Navigator.of(context).pop();
  }
}
