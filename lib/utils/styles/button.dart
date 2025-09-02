import 'package:flutter/material.dart';
import 'package:klayons/utils/colour.dart';
import 'package:klayons/utils/styles/fonts.dart';

class OrangeButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final bool isDisabled;

  const OrangeButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: isDisabled ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryOrange,
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: child,
      ),
    );
  }
}
