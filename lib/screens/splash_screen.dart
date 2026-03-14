import 'dart:async';

import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import 'auth_gate.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _navTimer;

  @override
  void initState() {
    super.initState();
    _navTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder<void>(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const AuthGate(),
            transitionDuration: const Duration(milliseconds: 320),
            reverseTransitionDuration: const Duration(milliseconds: 220),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  final eased = CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                    reverseCurve: Curves.easeInCubic,
                  );

                  return FadeTransition(opacity: eased, child: child);
                },
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _navTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryOrange,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo icon
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.child_care,
                  size: 64,
                  color: AppTheme.primaryOrange,
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'Child Connect',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 10),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  'Every Child Deserves a Loving Home',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 60),
              const SizedBox(
                width: 30,
                height: 30,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
