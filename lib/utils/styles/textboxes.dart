import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:klayons/utils/colour.dart';
import 'fonts.dart';
import 'package:klayons/utils/colour.dart';

class CustomTextField extends StatelessWidget {
  final String hintText;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final bool obscureText;
  final FocusNode? focusNode;
  final List<TextInputFormatter>? inputFormatters;
  final TextStyle? style;

  const CustomTextField({
    super.key,
    required this.hintText,
    required this.controller,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.focusNode,
    this.inputFormatters,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return StatefulBuilder(
      builder: (context, setState) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: keyboardType,
          obscureText: obscureText,
          inputFormatters: inputFormatters,
          style:
              style ??
              AppTextStyles.titleLarge.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w400,
              ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: AppTextStyles.bodyLarge.copyWith(
              color: Colors.grey[500],
            ),
            // Removed filled and fillColor for transparent background
            // Grey border when inactive
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey!, width: 1),
            ),
            // Dynamic border when enabled but not focused
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: controller.text.isNotEmpty
                    ? AppColors.primaryOrange
                    : Colors.grey[300]!,
                width: controller.text.isNotEmpty ? 2 : 1,
              ),
            ),
            // Orange border when focused
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.primaryOrange, width: 2),
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
          onChanged: (value) {
            setState(() {}); // Rebuild to update border color
          },
        );
      },
    );
  }
}
