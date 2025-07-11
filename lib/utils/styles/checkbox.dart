import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class CustomeCheckbox extends StatelessWidget {
  final bool value;
  final Function(bool?) onChanged;

  const CustomeCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Checkbox(
      value: value,
      onChanged: onChanged,
      activeColor: Color(0xFFED7733),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    );
  }
}
