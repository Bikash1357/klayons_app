import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/colour.dart';
import '../utils/styles/klayonsFont.dart';
import '../services/login_auth_service.dart';

class KlayonsSplashScreen extends StatefulWidget {
  const KlayonsSplashScreen({super.key});

  @override
  State<KlayonsSplashScreen> createState() => _KlayonsSplashScreenState();
}

class _KlayonsSplashScreenState extends State<KlayonsSplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  void _initializeApp() async {
    // Show splash screen for minimum 3 seconds
    await Future.delayed(const Duration(seconds: 3));

    if (mounted) {
      await _checkAuthenticationAndNavigate();
    }
  }

  Future<void> _checkAuthenticationAndNavigate() async {
    try {
      print('Starting authentication check...');

      // First check if user is logged in locally
      final isLoggedInLocal = await LoginAuthService.isLoggedInLocally();
      print('Local login status: $isLoggedInLocal');

      if (!isLoggedInLocal) {
        print('User not logged in locally, navigating to login');
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
        return;
      }

      // Get token for debugging
      final token = await LoginAuthService.getToken();
      print(
        'Token exists: ${token != null ? "Yes (${token!.length} chars)" : "No"}',
      );

      // Check full authentication (including backend verification)
      final isAuthenticated = await LoginAuthService.isAuthenticated();
      print('Full authentication status: $isAuthenticated');

      if (mounted) {
        if (isAuthenticated) {
          print('User is authenticated, navigating to home');
          Navigator.pushReplacementNamed(context, '/home');
        } else {
          print('User authentication failed, navigating to login');
          Navigator.pushReplacementNamed(context, '/login');
        }
      }
    } catch (e) {
      print('Authentication check error: $e');
      // On error, default to login page
      if (mounted) {
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
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFFBF5), Color(0xFFFF6B35)],
          ),
        ),
        child: const SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Spacer(flex: 2),
              // Logo
              SizedBox(height: 15),
              SizedBox(height: 30),
              // App Name
              KlayonsText(),
              SizedBox(height: 20),
              // Tagline
              Text(
                'Fun and Engaging Activities for Kids',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.w400,
                  height: 1.5,
                ),
              ),
              SizedBox(height: 60),
              // Loading Indicator
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 3.0,
              ),
              SizedBox(height: 20),
              // Loading Text
              Text(
                'Loading...',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                  fontWeight: FontWeight.w300,
                ),
              ),
              Spacer(flex: 3),
            ],
          ),
        ),
      ),
    );
  }
}
