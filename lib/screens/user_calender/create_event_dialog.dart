import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'event_calender_model.dart';

class CreateEventDialog extends StatefulWidget {
  final DateTime selectedDate;
  final Function(Event) onEventCreated;

  CreateEventDialog({required this.selectedDate, required this.onEventCreated});

  @override
  _CreateEventDialogState createState() => _CreateEventDialogState();
}

class _CreateEventDialogState extends State<CreateEventDialog> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? _startTime;
  DateTime? _endTime;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime(
      widget.selectedDate.year,
      widget.selectedDate.month,
      widget.selectedDate.day,
      DateTime.now().hour,
      DateTime.now().minute,
    );
    _endTime = _startTime!.add(Duration(hours: 1));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Text('Create Activity'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Activity Name',
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
              maxLines: 2,
            ),
            SizedBox(height: 16),
            InkWell(
              onTap: () => _selectDateTime(context),
              child: Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Icon(Icons.access_time, color: Colors.orange),
                    SizedBox(width: 8),
                    Text(
                      _startTime != null
                          ? DateFormat('MMM dd, h:mm a').format(_startTime!)
                          : 'Select time',
                    ),
                  ],
                ),
              ),
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
          onPressed: _createEvent,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
          child: Text('Create', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  void _selectDateTime(BuildContext context) async {
    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (time != null) {
      setState(() {
        _startTime = DateTime(
          widget.selectedDate.year,
          widget.selectedDate.month,
          widget.selectedDate.day,
          time.hour,
          time.minute,
        );
        _endTime = _startTime!.add(Duration(hours: 1));
      });
    }
  }

  void _createEvent() {
    if (_titleController.text.isEmpty || _startTime == null) {
      return;
    }

    final event = Event(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text,
      description: _descriptionController.text,
      startTime: _startTime!,
      endTime: _endTime!,
      color: Colors.orange,
    );

    widget.onEventCreated(event);
    Navigator.of(context).pop();
  }
}
