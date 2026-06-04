import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../core/widgets/yard_sale_logo.dart';
import '../../routes/app_routes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    _scaleAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      // Send signed-in users straight to home; otherwise to login.
      final loggedIn = FirebaseAuth.instance.currentUser != null;
      context.goNamed(loggedIn ? AppRoutes.nHome : AppRoutes.nLogin);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF3A5FA0),
      body: Center(
        child: ScaleTransition(
          scale: _scaleAnim,
          child: Container(
            width: 180,
            height: 180,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Center(
              child: YardSaleLogo(
                size: 100,
                wordmarkSize: 16,
                gap: 4,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
