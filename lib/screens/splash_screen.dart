import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/colour.dart';
import '../utils/styles/klayonsFont.dart';

// Alternaminimal splash scrtive een
class MinimalSplashScreen extends StatelessWidget {
  const MinimalSplashScreen({Key? key}) : super(key: key);

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
              const SizedBox(height: 15),

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

              Spacer(flex: 3),
            ],
          ),
        ),
      ),
    );
  }
}
