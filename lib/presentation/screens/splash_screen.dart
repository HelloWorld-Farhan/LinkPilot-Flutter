import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'home_screen.dart';
import '../../core/theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 2800), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, animation, __) => const HomeScreen(),
            transitionsBuilder: (_, animation, __, child) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.06),
                  end: Offset.zero,
                ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
                child: child,
              ),
            ),
            transitionDuration: const Duration(milliseconds: 600),
          ),
        );
      }
    });
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
            colors: [
              Color(0xFF091413), // ink
              Color(0xFF285A48), // forest
              Color(0xFF408A71), // teal
            ],
            stops: [0.0, 0.55, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo circle with glow
              Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.mint.withOpacity(0.4),
                      blurRadius: 50,
                      spreadRadius: 10,
                    ),
                    BoxShadow(
                      color: AppTheme.teal.withOpacity(0.3),
                      blurRadius: 25,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/Logo.png',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.link_rounded,
                      size: 64,
                      color: AppTheme.forest,
                    ),
                  ),
                ),
              )
                  .animate()
                  .scale(
                    begin: const Offset(0.5, 0.5),
                    duration: 800.ms,
                    curve: Curves.easeOutBack,
                  )
                  .fadeIn(duration: 600.ms),

              const SizedBox(height: 32),

              // App name
              const Text(
                'LinkPilot',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -1.5,
                ),
              )
                  .animate()
                  .fadeIn(delay: 350.ms, duration: 600.ms)
                  .slideY(begin: 0.2, end: 0, delay: 350.ms),

              const SizedBox(height: 12),

              // Tagline pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 9),
                decoration: BoxDecoration(
                  color: AppTheme.mint.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: AppTheme.mint.withOpacity(0.35)),
                ),
                child: const Text(
                  'Collect · Convert · Deliver',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.mint,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              )
                  .animate()
                  .fadeIn(delay: 650.ms, duration: 500.ms)
                  .slideY(begin: 0.2, end: 0, delay: 650.ms),

              const SizedBox(height: 70),

              // Thin loading bar
              SizedBox(
                width: 48,
                height: 4,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    backgroundColor: Colors.white.withOpacity(0.15),
                    color: AppTheme.mint,
                  ),
                ),
              )
                  .animate()
                  .fadeIn(delay: 900.ms, duration: 400.ms),
            ],
          ),
        ),
      ),
    );
  }
}
