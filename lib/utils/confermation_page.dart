import 'package:flutter/material.dart';
import 'dart:math' as math;

class ConfirmationPage extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? idLabel;
  final String? idValue;
  final String buttonText;
  final VoidCallback? onButtonPressed;
  final Color primaryColor;
  final Color backgroundColor;

  const ConfirmationPage({
    Key? key,
    required this.title,
    required this.subtitle,
    this.idLabel,
    this.idValue,
    this.buttonText = "Back to Home",
    this.onButtonPressed,
    this.primaryColor = const Color(0xFFFF5722),
    this.backgroundColor = const Color(0xFFFFF3F0),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Success Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(60),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: _buildStarBadge(),
              ),

              const SizedBox(height: 40),

              // Title
              Text(
                title,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              // Subtitle
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 18,
                  color: Color(0xFF718096),
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

              // ID Section (if provided)
              if (idLabel != null && idValue != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$idLabel: ',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2D3748),
                        ),
                      ),
                      Text(
                        idValue!,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF718096),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ] else
                const SizedBox(height: 40),

              // Action Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed:
                      onButtonPressed ?? () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    buttonText,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStarBadge() {
    return CustomPaint(
      size: const Size(120, 120),
      painter: StarBadgePainter(color: primaryColor),
      child: const Center(
        child: Icon(Icons.check, color: Colors.white, size: 40, weight: 3),
      ),
    );
  }
}

class StarBadgePainter extends CustomPainter {
  final Color color;

  StarBadgePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final double centerX = size.width / 2;
    final double centerY = size.height / 2;
    final double outerRadius = size.width / 2.2;
    final double innerRadius = outerRadius * 0.7;

    const int points = 14;
    final Path path = Path();

    for (int i = 0; i < points * 2; i++) {
      final double angle = (i * math.pi) / points - math.pi / 2;
      final double radius = i.isEven ? outerRadius : innerRadius;
      final double x = centerX + radius * math.cos(angle);
      final double y = centerY + radius * math.sin(angle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Usage Examples:
class ExampleUsage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Booking Confirmation
        ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ConfirmationPage(
                  title: "Booking Confirmed",
                  subtitle: "Great learnings are on the way!",
                  idLabel: "Booking ID",
                  idValue: "7F8G2H9K",
                  buttonText: "Back to Home",
                ),
              ),
            );
          },
          child: const Text("Show Booking Confirmation"),
        ),

        // Transaction Completed
        ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ConfirmationPage(
                  title: "Transaction Completed",
                  subtitle: "Your payment has been processed successfully!",
                  idLabel: "Transaction ID",
                  idValue: "TXN123456789",
                  buttonText: "View Details",
                  primaryColor: Colors.green,
                ),
              ),
            );
          },
          child: const Text("Show Transaction Confirmation"),
        ),

        // Order Placed
        ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ConfirmationPage(
                  title: "Order Placed",
                  subtitle: "Your order will be delivered soon!",
                  idLabel: "Order ID",
                  idValue: "ORD987654321",
                  buttonText: "Track Order",
                  primaryColor: Colors.blue,
                ),
              ),
            );
          },
          child: const Text("Show Order Confirmation"),
        ),

        // Simple Success (without ID)
        ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ConfirmationPage(
                  title: "Success!",
                  subtitle: "Your action was completed successfully.",
                  buttonText: "Continue",
                  primaryColor: Colors.purple,
                ),
              ),
            );
          },
          child: const Text("Show Simple Success"),
        ),
      ],
    );
  }
}
