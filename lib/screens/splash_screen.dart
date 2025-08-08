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
  String _statusText = 'Checking authentication...';

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  void _initializeApp() async {
    try {
      // Show splash screen for minimum 2 seconds for better UX
      final Future<void> splashDelay = Future.delayed(
        const Duration(seconds: 2),
      );
      final Future<void> authCheck = _checkAuthenticationAndNavigate();

      // Wait for both splash delay and auth check to complete
      await Future.wait([splashDelay, authCheck]);
    } catch (e) {
      print('🚨 App initialization error: $e');
      // Fallback to login on any initialization error
      _navigateToLogin();
    }
  }

  Future<void> _checkAuthenticationAndNavigate() async {
    try {
      if (mounted) {
        setState(() {
          _statusText = 'Checking authentication...';
        });
      }

      print('🔍 Starting authentication check...');

      // Use the simplified authentication check
      final isAuthenticated = await LoginAuthService.isAuthenticated();

      if (isAuthenticated) {
        print('✅ User is authenticated, navigating to home');

        if (mounted) {
          setState(() {
            _statusText = 'Welcome back!';
          });
        }

        // Small delay to show welcome message
        await Future.delayed(const Duration(milliseconds: 500));
        _navigateToHome();
      } else {
        print('❌ User not authenticated, navigating to login');

        if (mounted) {
          setState(() {
            _statusText = 'Please log in to continue';
          });
        }

        // Small delay to show login message
        await Future.delayed(const Duration(milliseconds: 500));
        _navigateToLogin();
      }
    } catch (e) {
      print('🚨 Authentication check error: $e');

      if (mounted) {
        setState(() {
          _statusText = 'Loading...';
        });
      }

      // On any error, clear auth data and go to login
      try {
        await LoginAuthService.clearAuthData();
      } catch (clearError) {
        print('Error clearing auth data: $clearError');
      }

      _navigateToLogin();
    }
  }

  void _navigateToHome() {
    if (mounted) {
      try {
        Navigator.pushReplacementNamed(context, '/home');
      } catch (e) {
        print('Navigation to home failed: $e');
        // Fallback navigation
        _navigateToLogin();
      }
    }
  }

  void _navigateToLogin() {
    if (mounted) {
      try {
        Navigator.pushReplacementNamed(context, '/login');
      } catch (e) {
        print('Navigation to login failed: $e');
        // If navigation fails completely, exit app gracefully
        SystemNavigator.pop();
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
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),

              // Logo placeholder - replace with your actual logo
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.child_care,
                  size: 50,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 30),

              // App Name
              const KlayonsText(),
              const SizedBox(height: 20),

              // Tagline
              const Text(
                'Fun and Engaging Activities for Kids',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.w400,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 60),

              // Loading Indicator
              const SizedBox(
                width: 30,
                height: 30,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 3.0,
                ),
              ),
              const SizedBox(height: 20),

              // Dynamic Loading Text
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  _statusText,
                  key: ValueKey(_statusText),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ),
              const Spacer(flex: 3),

              // Version info (optional)
              const Padding(
                padding: EdgeInsets.only(bottom: 20),
                child: Text(
                  'Version 1.0.0',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white38,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
