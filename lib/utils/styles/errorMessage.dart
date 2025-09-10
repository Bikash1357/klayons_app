// File: lib/widgets/bottom_error_message.dart
import 'package:flutter/material.dart';
import 'package:klayons/utils/colour.dart';

class BottomErrorMessage extends StatefulWidget {
  final String message;
  final bool isVisible;
  final VoidCallback? onDismiss;

  const BottomErrorMessage({
    Key? key,
    required this.message,
    required this.isVisible,
    this.onDismiss,
  }) : super(key: key);

  @override
  _BottomErrorMessageState createState() => _BottomErrorMessageState();
}

class _BottomErrorMessageState extends State<BottomErrorMessage> {
  @override
  void didUpdateWidget(BottomErrorMessage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isVisible && !oldWidget.isVisible) {
      // Auto-hide after 3 seconds
      Future.delayed(Duration(seconds: 3), () {
        if (mounted && widget.isVisible) {
          widget.onDismiss?.call();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) {
      return SizedBox.shrink();
    }

    return Positioned(
      bottom: 20,
      left: 16,
      right: 16,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.errorState, // Light red background
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Color(0xFFE57373), width: 1),
        ),
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Text(
                widget.message,
                style: TextStyle(
                  color: Color(0xFFD32F2F), // Dark red text
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            GestureDetector(
              onTap: widget.onDismiss,
              child: Icon(Icons.close, color: Color(0xFFD32F2F), size: 18),
            ),
          ],
        ),
      ),
    );
  }
}

// Simple mixin for error handling
mixin BottomErrorHandler<T extends StatefulWidget> on State<T> {
  bool _showBottomError = false;
  String _bottomErrorMessage = '';

  void showBottomError(String message) {
    setState(() {
      _showBottomError = true;
      _bottomErrorMessage = message;
    });
  }

  void hideBottomError() {
    setState(() {
      _showBottomError = false;
      _bottomErrorMessage = '';
    });
  }

  Widget buildBottomErrorMessage() {
    return BottomErrorMessage(
      message: _bottomErrorMessage,
      isVisible: _showBottomError,
      onDismiss: hideBottomError,
    );
  }
}
