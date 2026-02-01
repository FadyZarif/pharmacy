import 'package:flutter/material.dart';
import 'package:pharmacy/core/helpers/constants.dart';
import 'package:pharmacy/core/themes/colors.dart';
import 'package:pharmacy/features/branch/ui/branch_selection_screen.dart';
import 'package:pharmacy/features/employee/ui/employee_layout.dart';
import 'package:pharmacy/features/login/ui/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _controller;

  // Intro animations (drop + fade + settle)
  late final Animation<Offset> _logoOffset;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _logoSettleScale;

  // Loop animations (pulse + subtle tilt + background motion)
  late final AnimationController _loopController;
  late final Animation<double> _pulse;
  late final Animation<double> _tilt;
  late final Animation<double> _bgT;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _logoOffset = Tween<Offset>(
      begin: const Offset(0.0, -0.9),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _logoSettleScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.72, end: 1.08)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 65,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.08, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOutCubic)),
        weight: 35,
      ),
    ]).animate(_controller);

    _loopController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _pulse = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _loopController, curve: Curves.easeInOut),
    );

    _tilt = Tween<double>(begin: -0.02, end: 0.02).animate(
      CurvedAnimation(parent: _loopController, curve: Curves.easeInOut),
    );

    _bgT = CurvedAnimation(parent: _loopController, curve: Curves.easeInOut);

    _controller.forward().whenComplete(() {
      if (!mounted) return;
      _loopController.repeat(reverse: true);
    });

    // Keep existing app logic; just show animated splash first.
    Future.delayed(const Duration(milliseconds: 2300), _goNext);
  }

  void _goNext() {
    if (!mounted) return;

    final Widget next = isLogged
        ? (!currentUser.isStaff ? const BranchSelectionScreen() : const EmployeeLayout())
        : const LoginScreen();

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => next,
        transitionsBuilder: (_, animation, __, child) {
          final fade = CurvedAnimation(parent: animation, curve: Curves.easeOut);
          return FadeTransition(opacity: fade, child: child);
        },
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _loopController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: Listenable.merge([_controller, _loopController]),
        builder: (context, _) {
          final introT = _controller.value;
          final t = _bgT.value; // loop

          // Richer background palette.
          final bgA = const Color(0xFFF6F8FF);
          final bgB = const Color(0xFFEAFBFF);
          final bgC = const Color(0xFFF2ECFF);
          final bg1 = Color.lerp(bgA, bgB, (0.2 + 0.8 * t).clamp(0.0, 1.0))!;
          final bg2 = Color.lerp(bgC, bgA, (0.1 + 0.9 * (1 - t)).clamp(0.0, 1.0))!;

          final accent = Color.lerp(
            ColorsManger.primary,
            const Color(0xFF17D5E6),
            (0.35 + 0.65 * t).clamp(0.0, 1.0),
          )!;

          final blob1Pos = Offset(
            40 + 18 * (t - 0.5),
            110 + 26 * (t - 0.5),
          );
          final blob2Pos = Offset(
            240 - 24 * (t - 0.5),
            520 + 20 * (t - 0.5),
          );
          final blob3Pos = Offset(
            -40 + 22 * (t - 0.5),
            540 - 18 * (t - 0.5),
          );

          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment(-0.95 + 0.35 * t, -1.0),
                end: Alignment(0.95 - 0.35 * t, 1.0),
                colors: [bg1, bg2, bg1],
                stops: const [0.0, 0.55, 1.0],
              ),
            ),
            child: SafeArea(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Animated blobs behind the logo to make background more attractive.
                    SizedBox(
                      width: 320,
                      height: 320,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned(
                            left: blob1Pos.dx,
                            top: blob1Pos.dy,
                            child: _GlowBlob(
                              size: 160,
                              color: accent.withValues(alpha: 0.45),
                            ),
                          ),
                          Positioned(
                            right: blob2Pos.dx,
                            top: blob2Pos.dy,
                            child: _GlowBlob(
                              size: 190,
                              color: const Color(0xFF4B39EF).withValues(alpha: 0.22),
                            ),
                          ),
                          Positioned(
                            left: blob3Pos.dx,
                            bottom: -30,
                            child: _GlowBlob(
                              size: 210,
                              color: const Color(0xFFFF5BC5).withValues(alpha: 0.10),
                            ),
                          ),
                          Align(
                            alignment: Alignment.center,
                            child: SlideTransition(
                              position: _logoOffset,
                              child: Transform.rotate(
                                angle: _tilt.value,
                                child: Transform.scale(
                                  scale: _logoSettleScale.value * _pulse.value,
                                  child: Opacity(
                                    opacity: _logoOpacity.value,
                                    child: Container(
                                      width: 144,
                                      height: 144,
                                      padding: const EdgeInsets.all(18),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.86),
                                        borderRadius: BorderRadius.circular(38),
                                        border: Border.all(
                                          color: Colors.white.withValues(alpha: 0.7),
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: accent.withValues(alpha: 0.22),
                                            blurRadius: 30,
                                            offset: const Offset(0, 18),
                                          ),
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.05),
                                            blurRadius: 18,
                                            offset: const Offset(0, 10),
                                          ),
                                        ],
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(28),
                                        child: Image.asset(
                                          'assets/images/app_launcher_icon.png',
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Opacity(
                      opacity: _logoOpacity.value,
                      child: Text(
                        'Emad Fawzy Pharmacy',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: Colors.black.withValues(alpha: 0.88),
                            ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Opacity(
                      opacity: (_logoOpacity.value * 0.9).clamp(0.0, 1.0),
                      child: Text(
                        'Loading…',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: ColorsManger.grey,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Opacity(
                      opacity: (introT * 0.65).clamp(0.0, 0.65),
                      child: Container(
                        width: 34,
                        height: 4,
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _GlowBlob extends StatelessWidget {
  final double size;
  final Color color;

  const _GlowBlob({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color,
            color.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 1.0],
        ),
      ),
    );
  }
}

