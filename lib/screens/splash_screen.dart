import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:campusdrive/providers/auth_provider.dart';
import 'package:campusdrive/providers/settings_provider.dart';
import 'package:campusdrive/screens/auth/login_screen.dart';
import 'package:campusdrive/screens/main_app_screen.dart';
import 'package:campusdrive/screens/auth/onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Controllers
  late AnimationController _entranceController;
  late AnimationController _loopController;

  // Animations
  late Animation<double> _logoFade;
  late Animation<double> _logoScale;
  late Animation<Offset> _textSlide;
  late Animation<double> _textFade;

  // Background gradient shift
  late Animation<double> _bgShine;

  @override
  void initState() {
    super.initState();

    // 1. Entrance (0.5s total approx for sequence)
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000), // Longer to hold shine
    );

    // 2. Loop (2s duration as requested for float)
    _loopController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    // --- Definitions ---

    // Logo Fade: 0 -> 1 (0.3s)
    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
      ),
    );

    // Logo Scale: 100% -> 108% -> 100%
    _logoScale =
        TweenSequence<double>([
          TweenSequenceItem(
            tween: Tween<double>(
              begin: 0.8,
              end: 1.08,
            ).chain(CurveTween(curve: Curves.easeOut)),
            weight: 60, // 0.3s
          ),
          TweenSequenceItem(
            tween: Tween<double>(
              begin: 1.08,
              end: 1.0,
            ).chain(CurveTween(curve: Curves.elasticOut)),
            weight: 40, // Bounce back
          ),
        ]).animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: const Interval(0.0, 0.5),
          ),
        );

    // Text Animation: Delay 0.15s, Slide up
    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.15, 0.55, curve: Curves.easeOut),
      ),
    );

    _textSlide =
        Tween<Offset>(
          begin: const Offset(0, 0.5), // Approx 10px down relative to height
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: const Interval(0.15, 0.55, curve: Curves.easeOutQuad),
          ),
        );

    // Background Shine (0 -> 1 over 2.5s) works better on separate controller?
    // Or just part of entrance. Text said "Duration 2.5s".
    // We can use the main controller.
    _bgShine = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 1.0, curve: Curves.easeInOut),
      ),
    );

    _start();
  }

  void _start() async {
    await _entranceController.forward();
    // Total wait 2.5s from start
    // Controller is 2s, wait extra 0.5s ?
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) _checkNavigation();
  }

  void _checkNavigation() {
    final authProvider = context.read<AuthProvider>();
    final settingsProvider = context.read<SettingsProvider>();

    Widget nextScreen;
    if (!settingsProvider.hasSeenOnboarding) {
      nextScreen = const OnboardingScreen();
    } else if (authProvider.user == null) {
      nextScreen = const LoginScreen();
    } else {
      nextScreen = const MainAppScreen();
    }

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, _, _) => nextScreen,
        transitionDuration: const Duration(milliseconds: 800),
        transitionsBuilder: (_, animation, _, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _loopController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF6F1FF);
    final textColor = isDark ? Colors.white : const Color(0xFF7C3AED);

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // 1. Background Waves
          Positioned.fill(
            child: CustomPaint(painter: PremiumWavePainter(isDark: isDark)),
          ),

          // 2. Background Shine (Gradient overlay animated)
          AnimatedBuilder(
            animation: _bgShine,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment(_bgShine.value - 1, -1),
                    end: Alignment(_bgShine.value, 1),
                    colors: [
                      Colors.transparent,
                      Colors.white.withValues(alpha: isDark ? 0.05 : 0.4),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              );
            },
          ),

          // 3. Center Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                AnimatedBuilder(
                  animation: _loopController,
                  builder: (context, child) {
                    // Float: Up down 6px
                    // Controller repeats 0->1 linear. repeat(reverse: true) means 0->1->0
                    // _loopController value goes 0.0 -> 1.0 -> 0.0

                    final yOffset =
                        (_loopController.value - 0.5) * 12; // -6 to 6

                    return Transform.translate(
                      offset: Offset(0, yOffset),
                      child: child,
                    );
                  },
                  child: ScaleTransition(
                    scale: _logoScale,
                    child: FadeTransition(
                      opacity: _logoFade,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape
                              .circle, // Assuming icon fits in circle or rounded
                          // Optional Glow
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF7C3AED,
                              ).withValues(alpha: 0.3),
                              blurRadius: 40,
                              spreadRadius: -5,
                            ),
                          ],
                        ),
                        child: Image.asset(
                          'assets/icons/campusdrive_icon.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Text
                FadeTransition(
                  opacity: _textFade,
                  child: SlideTransition(
                    position: _textSlide,
                    child: Text(
                      "CampusDrive",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 32,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 4. Loading Indicator
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: _LoadingRipple(isDark: isDark),
          ),
        ],
      ),
    );
  }
}

class PremiumWavePainter extends CustomPainter {
  final bool isDark;

  PremiumWavePainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        colors: isDark
            ? [
                const Color(0xFF7C3AED).withValues(alpha: 0.15),
                Colors.transparent,
              ]
            : [const Color(0xFFE0CFFF), const Color(0xFFF6F1FF)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height * 0.4));

    // Top Wave
    final path = Path();
    path.lineTo(0, size.height * 0.25);
    path.cubicTo(
      size.width * 0.3,
      size.height * 0.35,
      size.width * 0.6,
      size.height * 0.15,
      size.width,
      size.height * 0.25,
    );
    path.lineTo(size.width, 0);
    path.close();
    canvas.drawPath(path, paint);

    // Bottom Wave
    final paintBottom = Paint()
      ..style = PaintingStyle.fill
      ..color = isDark
          ? const Color(0xFF7C3AED).withValues(alpha: 0.05)
          : const Color(0xFFE5D9FC).withValues(alpha: 0.5);

    final pathBottom = Path();
    pathBottom.moveTo(0, size.height);
    pathBottom.lineTo(0, size.height * 0.85);
    pathBottom.cubicTo(
      size.width * 0.4,
      size.height * 0.75,
      size.width * 0.7,
      size.height * 0.95,
      size.width,
      size.height * 0.8,
    );
    pathBottom.lineTo(size.width, size.height);
    pathBottom.close();
    canvas.drawPath(pathBottom, paintBottom);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LoadingRipple extends StatefulWidget {
  final bool isDark;
  const _LoadingRipple({required this.isDark});

  @override
  State<_LoadingRipple> createState() => _LoadingRippleState();
}

class _LoadingRippleState extends State<_LoadingRipple>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            // Staggered sine wave for each dot
            final t = (_controller.value - (index * 0.15)) % 1.0;
            // Opacity 0.3 -> 1 -> 0.3
            final opacity = 0.3 + (0.7 * math.sin(t * math.pi).abs());
            // Scale 0.9 -> 1.2 -> 0.9
            final scale = 0.9 + (0.3 * math.sin(t * math.pi).abs());

            return Transform.scale(
              scale: scale,
              child: Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.symmetric(horizontal: 5),
                decoration: BoxDecoration(
                  color:
                      (widget.isDark ? Colors.white : const Color(0xFF7C3AED))
                          .withValues(alpha: opacity),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(
                        0xFF7C3AED,
                      ).withValues(alpha: opacity * 0.5),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
