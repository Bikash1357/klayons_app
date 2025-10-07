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

class _KlayonsSplashScreenState extends State<KlayonsSplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animation controller
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Fade animation for the tagline
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    // Slide animation for the tagline (from bottom to top)
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );

    // Start the tagline animation after a short delay
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        _animationController.forward();
      }
    });

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
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(color: AppColors.primaryOrange),
        child: SafeArea(
          child: Transform.translate(
            offset: const Offset(0, -20),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Klayons logo (appears immediately)
                  KlayonsText(),
                  // Animated tagline
                  SlideTransition(
                    position: _slideAnimation,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Text(
                        'Growing Curious, Creative and \n Confident Kids',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.titleMedium(context).copyWith(
                          color: AppColors.background,
                          fontWeight: FontWeight.w500,
                          fontStyle: FontStyle.italic,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
