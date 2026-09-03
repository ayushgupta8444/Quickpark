import 'dart:async';

import 'package:flutter/material.dart';

import '../auth/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  Timer? _timer;

  late AnimationController _mainController;
  late AnimationController _logoController;
  late AnimationController _progressController;

  late Animation<double> _logoScale;
  late Animation<double> _logoFade;

  late Animation<Offset> _nameSlide;
  late Animation<double> _nameFade;

  late Animation<Offset> _taglineSlide;
  late Animation<double> _taglineFade;

  @override
  void initState() {
    super.initState();

    // ==========================================================
    // MAIN CONTENT ANIMATION
    // ==========================================================

    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    // ==========================================================
    // LOGO ANIMATION
    // ==========================================================

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    _logoScale = TweenSequence<double>(
      [
        TweenSequenceItem(
          tween: Tween<double>(
            begin: 0.70,
            end: 1.08,
          ).chain(
            CurveTween(
              curve: Curves.easeOutCubic,
            ),
          ),
          weight: 75,
        ),
        TweenSequenceItem(
          tween: Tween<double>(
            begin: 1.08,
            end: 1.0,
          ).chain(
            CurveTween(
              curve: Curves.easeOutBack,
            ),
          ),
          weight: 25,
        ),
      ],
    ).animate(_logoController);

    _logoFade = CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeIn,
    );

    // ==========================================================
    // QUICKPARK NAME ANIMATION
    // ==========================================================

    _nameSlide = Tween<Offset>(
      begin: const Offset(0, 0.35),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(
          0.25,
          0.65,
          curve: Curves.easeOutCubic,
        ),
      ),
    );

    _nameFade = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(
        0.25,
        0.60,
        curve: Curves.easeOut,
      ),
    );

    // ==========================================================
    // TAGLINE ANIMATION
    // ==========================================================

    _taglineSlide = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(
          0.50,
          0.95,
          curve: Curves.easeOutCubic,
        ),
      ),
    );

    _taglineFade = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(
        0.50,
        0.90,
        curve: Curves.easeOut,
      ),
    );

    // ==========================================================
    // PROGRESS ANIMATION
    // ==========================================================

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    // ==========================================================
    // START ANIMATIONS
    // ==========================================================

    _logoController.forward();

    Future.delayed(
      const Duration(milliseconds: 120),
      () {
        if (!mounted) return;

        _mainController.forward();
      },
    );

    _progressController.forward();

    // ==========================================================
    // NAVIGATE TO LOGIN
    // ==========================================================

    _timer = Timer(
      const Duration(seconds: 2),
      () {
        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            transitionDuration: const Duration(
              milliseconds: 500,
            ),
            pageBuilder: (
              context,
              animation,
              secondaryAnimation,
            ) {
              return const LoginScreen();
            },
            transitionsBuilder: (
              context,
              animation,
              secondaryAnimation,
              child,
            ) {
              return FadeTransition(
                opacity: CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOut,
                ),
                child: child,
              );
            },
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();

    _mainController.dispose();
    _logoController.dispose();
    _progressController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEF0038),

      body: SafeArea(
        child: Stack(
          children: [
            // ==================================================
            // CENTER CONTENT
            // ==================================================

            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // =================================================
                  // ORIGINAL QUICKPARK LOGO
                  // =================================================

                  AnimatedBuilder(
                    animation: _logoController,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _logoFade.value,
                        child: Transform.scale(
                          scale: _logoScale.value,
                          child: child,
                        ),
                      );
                    },

                    child: Image.asset(
                      'assets/images/quickpark_logo.png',

                      width: 170,
                      height: 170,

                      fit: BoxFit.contain,
                    ),
                  ),

                  const SizedBox(height: 22),

                  // =================================================
                  // QUICKPARK NAME
                  // =================================================

                  FadeTransition(
                    opacity: _nameFade,
                    child: SlideTransition(
                      position: _nameSlide,
                      child: const Text(
                        'QuickPark',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.8,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // =================================================
                  // TAGLINE
                  // =================================================

                  FadeTransition(
                    opacity: _taglineFade,
                    child: SlideTransition(
                      position: _taglineSlide,
                      child: const Text(
                        'Valet parking, simplified.',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ==================================================
            // BOTTOM PROGRESS BAR
            // ==================================================

            Positioned(
              left: 0,
              right: 0,
              bottom: 30,
              child: Center(
                child: AnimatedBuilder(
                  animation: _progressController,
                  builder: (context, child) {
                    return Container(
                      width: 68,
                      height: 3,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          width: 68 * _progressController.value,
                          height: 3,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}