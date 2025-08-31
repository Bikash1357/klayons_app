import 'package:flutter/material.dart';
import 'package:klayons/utils/colour.dart';
import 'fonts.dart';

class CustomTextButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color textColor;
  final double fontSize;

  const CustomTextButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.textColor = AppColors.primaryOrange, // Default orange
    this.fontSize = 14,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        padding: EdgeInsets.zero, // Remove default padding
        minimumSize: Size(0, 0),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        text,
        style: AppTextStyles.bodyMedium.copyWith(
          color: textColor,
          fontWeight: FontWeight.w600,
          fontSize: fontSize,
        ),
      ),
    );
  }
}
