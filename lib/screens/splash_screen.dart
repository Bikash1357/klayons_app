import 'package:flutter/material.dart';
import '../services/auth/signup_service.dart';
import '../utils/colour.dart';
import '../utils/styles/klayonsFont.dart';
import '../utils/styles/fonts.dart';

class KlayonsSplashScreen extends StatefulWidget {
  const KlayonsSplashScreen({super.key});

  @override
  State<KlayonsSplashScreen> createState() => _KlayonsSplashScreenState();
}

class _KlayonsSplashScreenState extends State<KlayonsSplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  _checkAuthAndNavigate() async {
    // Record start time
    DateTime startTime = DateTime.now();

    // Start token check immediately
    String? token = await TokenStorage.getToken();

    // Calculate elapsed time
    DateTime currentTime = DateTime.now();
    int elapsedMilliseconds = currentTime.difference(startTime).inMilliseconds;

    // Calculate remaining wait time to ensure minimum 3 seconds
    int remainingWaitTime = 3000 - elapsedMilliseconds;

    // If less than 3 seconds have passed, wait for the remaining time
    if (remainingWaitTime > 0) {
      await Future.delayed(Duration(milliseconds: remainingWaitTime));
    }

    // Navigate based on token availability
    if (mounted) {
      if (token != null && token.isNotEmpty) {
        // Token exists - go to home
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        // No token - go to login
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(color: Color(0xFFFF6B35)),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      KlayonsText(),
                      const SizedBox(height: 16),
                      Text(
                        'Fun and Engaging Activities for Kids',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.titleMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w300,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 60),
                child: Column(
                  children: [
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 2.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Loading...',
                      style: AppTextStyles.titleSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
