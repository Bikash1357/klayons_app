import 'package:flutter/material.dart';
import 'event_model.dart';

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

  late TextEditingController _intervalController;

  @override
  void initState() {
    super.initState();

    if (widget.initialRule != null) {
      _interval = widget.initialRule!.interval;
      _type = widget.initialRule!.type;
      _selectedDays = List.from(widget.initialRule!.daysOfWeek);
    }

    _intervalController = TextEditingController(text: _interval.toString());
  }

  @override
  void dispose() {
    _intervalController.dispose();
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
              endRule: RecurrenceEnd.never, // Always set to never
              endDate: null, // No end date
              occurrences: null, // No occurrence limit
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
}
