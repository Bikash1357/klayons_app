import 'package:flutter/material.dart';

/// A reusable error message widget that can be used across different pages
class ErrorMessageWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onClose;
  final bool showCloseButton;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final Color? borderColor;
  final Color? textColor;
  final Color? iconColor;
  final IconData? icon;
  final double? borderRadius;
  final TextStyle? textStyle;

  const ErrorMessageWidget({
    Key? key,
    required this.message,
    this.onClose,
    this.showCloseButton = true,
    this.margin,
    this.padding,
    this.backgroundColor,
    this.borderColor,
    this.textColor,
    this.iconColor,
    this.icon,
    this.borderRadius,
    this.textStyle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: margin ?? EdgeInsets.only(top: 8),
      padding: padding ?? EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.red.shade50,
        borderRadius: BorderRadius.circular(borderRadius ?? 8),
        border: Border.all(color: borderColor ?? Colors.red.shade200, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon ?? Icons.error_outline,
            color: iconColor ?? Colors.red.shade600,
            size: 20,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style:
                  textStyle ??
                  TextStyle(
                    color: textColor ?? Colors.red.shade700,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
          if (showCloseButton) ...[
            SizedBox(width: 8),
            GestureDetector(
              onTap: onClose,
              child: Icon(
                Icons.close,
                color: iconColor ?? Colors.red.shade600,
                size: 18,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A more advanced error message widget with animation support
class AnimatedErrorMessageWidget extends StatefulWidget {
  final String message;
  final VoidCallback? onClose;
  final bool showCloseButton;
  final Duration animationDuration;
  final Duration autoHideDuration;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final Color? borderColor;
  final Color? textColor;
  final Color? iconColor;
  final IconData? icon;
  final double? borderRadius;
  final TextStyle? textStyle;

  const AnimatedErrorMessageWidget({
    Key? key,
    required this.message,
    this.onClose,
    this.showCloseButton = true,
    this.animationDuration = const Duration(milliseconds: 300),
    this.autoHideDuration = const Duration(seconds: 5),
    this.margin,
    this.padding,
    this.backgroundColor,
    this.borderColor,
    this.textColor,
    this.iconColor,
    this.icon,
    this.borderRadius,
    this.textStyle,
  }) : super(key: key);

  @override
  State<AnimatedErrorMessageWidget> createState() =>
      _AnimatedErrorMessageWidgetState();
}

class _AnimatedErrorMessageWidgetState extends State<AnimatedErrorMessageWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, -0.5), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutBack,
          ),
        );

    // Start animation
    _animationController.forward();

    // Auto hide if duration is provided
    Future.delayed(widget.autoHideDuration, () {
      if (mounted) {
        _hideMessage();
      }
    });
  }

  void _hideMessage() {
    _animationController.reverse().then((_) {
      if (widget.onClose != null) {
        widget.onClose!();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: ErrorMessageWidget(
          message: widget.message,
          onClose: _hideMessage,
          showCloseButton: widget.showCloseButton,
          margin: widget.margin,
          padding: widget.padding,
          backgroundColor: widget.backgroundColor,
          borderColor: widget.borderColor,
          textColor: widget.textColor,
          iconColor: widget.iconColor,
          icon: widget.icon,
          borderRadius: widget.borderRadius,
          textStyle: widget.textStyle,
        ),
      ),
    );
  }
}

/// Success message widget (similar to error but green themed)
class SuccessMessageWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onClose;
  final bool showCloseButton;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;

  const SuccessMessageWidget({
    Key? key,
    required this.message,
    this.onClose,
    this.showCloseButton = true,
    this.margin,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: margin ?? EdgeInsets.only(top: 8),
      padding: padding ?? EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade200, width: 1),
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_outline,
            color: Colors.green.shade600,
            size: 20,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Colors.green.shade700,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (showCloseButton) ...[
            SizedBox(width: 8),
            GestureDetector(
              onTap: onClose,
              child: Icon(Icons.close, color: Colors.green.shade600, size: 18),
            ),
          ],
        ],
      ),
    );
  }
}

/// Warning message widget (similar to error but orange/yellow themed)
class WarningMessageWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onClose;
  final bool showCloseButton;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;

  const WarningMessageWidget({
    Key? key,
    required this.message,
    this.onClose,
    this.showCloseButton = true,
    this.margin,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: margin ?? EdgeInsets.only(top: 8),
      padding: padding ?? EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade200, width: 1),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_outlined,
            color: Colors.orange.shade600,
            size: 20,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Colors.orange.shade700,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (showCloseButton) ...[
            SizedBox(width: 8),
            GestureDetector(
              onTap: onClose,
              child: Icon(Icons.close, color: Colors.orange.shade600, size: 18),
            ),
          ],
        ],
      ),
    );
  }
}

/// Info message widget (blue themed)
class InfoMessageWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onClose;
  final bool showCloseButton;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;

  const InfoMessageWidget({
    Key? key,
    required this.message,
    this.onClose,
    this.showCloseButton = true,
    this.margin,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: margin ?? EdgeInsets.only(top: 8),
      padding: padding ?? EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200, width: 1),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blue.shade600, size: 20),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Colors.blue.shade700,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (showCloseButton) ...[
            SizedBox(width: 8),
            GestureDetector(
              onTap: onClose,
              child: Icon(Icons.close, color: Colors.blue.shade600, size: 18),
            ),
          ],
        ],
      ),
    );
  }
}
