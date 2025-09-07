import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:klayons/utils/colour.dart';
import 'fonts.dart'; // Your AppTextStyles

class CustomTextField extends StatefulWidget {
  final String hintText;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final bool obscureText;
  final FocusNode? focusNode;
  final List<TextInputFormatter>? inputFormatters;
  final TextStyle? style;
  final bool showDynamicBorders;

  const CustomTextField({
    super.key,
    required this.hintText,
    required this.controller,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.focusNode,
    this.inputFormatters,
    this.style,
    this.showDynamicBorders = true,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  @override
  void initState() {
    super.initState();
    // Listen to controller changes to rebuild UI
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    if (widget.showDynamicBorders) {
      setState(() {}); // Rebuild to update border color
    }
  }

  // Get responsive text size based on screen dimensions
  double _getResponsiveTextSize(BuildContext context, double baseSize) {
    final screenWidth = MediaQuery.of(context).size.width;

    double scaleFactor;
    if (screenWidth < 350) {
      scaleFactor = 0.8; // Small phones
    } else if (screenWidth < 400) {
      scaleFactor = 0.9; // Medium phones
    } else if (screenWidth < 450) {
      scaleFactor = 1.0; // Large phones
    } else {
      scaleFactor = 1.2; // Very large phones/tablets
    }

    return (baseSize * scaleFactor).clamp(baseSize * 0.8, baseSize * 1.3);
  }

  // Get responsive padding based on screen size
  EdgeInsets _getResponsivePadding(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    double basePadding = 16.0;

    // Scale padding based on screen height
    double scaleFactor = (screenHeight / 812.0).clamp(0.8, 1.2);
    double responsivePadding = basePadding * scaleFactor;

    // Ensure minimum padding for very small screens
    responsivePadding = responsivePadding.clamp(12.0, 20.0);

    return EdgeInsets.all(responsivePadding);
  }

  @override
  Widget build(BuildContext context) {
    final responsiveTextSize = _getResponsiveTextSize(context, 18.0);
    final responsiveHintSize = _getResponsiveTextSize(context, 16.0);
    final responsivePadding = _getResponsivePadding(context);

    return TextField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      keyboardType: widget.keyboardType,
      obscureText: widget.obscureText,
      inputFormatters: widget.inputFormatters,
      style:
          widget.style ??
          TextStyle(fontSize: responsiveTextSize, fontWeight: FontWeight.w400),
      decoration: InputDecoration(
        hintText: widget.hintText,
        hintStyle: TextStyle(
          fontSize: responsiveHintSize,
          color: Colors.grey[500],
        ),
        // Default border when inactive
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey, width: 1),
        ),
        // Enabled border (when not focused)
        enabledBorder: widget.showDynamicBorders
            ? OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: widget.controller.text.isNotEmpty
                      ? AppColors.primaryOrange
                      : Colors.grey[300]!,
                  width: widget.controller.text.isNotEmpty ? 2 : 1,
                ),
              )
            : OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
              ),
        // Focused border
        focusedBorder: widget.showDynamicBorders
            ? OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: AppColors.primaryOrange,
                  width: 2,
                ),
              )
            : OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: AppColors.primaryOrange,
                  width: 2,
                ),
              ),
        contentPadding: responsivePadding,
      ),
    );
  }
}
