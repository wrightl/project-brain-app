import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:projectbrain/helpers/themes/app_spacing.dart';

/// Brand-aligned splash colors (match native [launch_background] / LaunchScreen).
const Color kSplashGradientTop = Color(0xFFF2ECFC);
const Color kSplashGradientMid = Color(0xFFE8DEF8);
const Color kSplashGradientBottom = Color(0xFFDDD0F4);
const Color kSplashAccent = Color(0xFF6750A4);

const String kSplashLogoAsset = 'assets/icon/appstore.png';

/// Full-screen animated loading UI: gradient, logo motion, dots, exit transition.
class AppLoadingScreen extends StatefulWidget {
  const AppLoadingScreen({
    super.key,
    required this.bootstrapComplete,
    required this.onExitComplete,
    this.error,
    this.onRetry,
  });

  final bool bootstrapComplete;
  final VoidCallback onExitComplete;
  final Object? error;
  final VoidCallback? onRetry;

  @override
  State<AppLoadingScreen> createState() => _AppLoadingScreenState();
}

class _AppLoadingScreenState extends State<AppLoadingScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final AnimationController _pulseController;
  late final AnimationController _gradientController;
  late final AnimationController _exitController;
  late final Animation<double> _entranceScale;
  late final Animation<double> _entranceOpacity;
  late final Animation<double> _exitOpacity;
  late final Animation<double> _exitScale;
  bool _exitStarted = false;
  bool _exitDone = false;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 780),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _gradientController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    )..repeat();

    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );

    _entranceScale = Tween<double>(begin: 0.82, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: Curves.easeOutCubic,
      ),
    );
    _entranceOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
      ),
    );
    _exitOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeIn),
    );
    _exitScale = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeIn),
    );

    _entranceController.forward();
    _entranceController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        _pulseController.repeat(reverse: true);
      }
    });

    _exitController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        _exitDone = true;
        widget.onExitComplete();
      }
    });
  }

  @override
  void didUpdateWidget(AppLoadingScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.error != null && oldWidget.error == null) {
      _entranceController.stop();
      _pulseController.stop();
      _gradientController.stop();
    }
    if (!oldWidget.bootstrapComplete &&
        widget.bootstrapComplete &&
        widget.error == null) {
      _maybeStartExit();
    }
  }

  void _maybeStartExit() {
    if (_exitStarted || _exitDone) return;
    _exitStarted = true;
    _pulseController.stop();
    _exitController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _pulseController.dispose();
    _gradientController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.error != null) {
      return Scaffold(
        body: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [kSplashGradientTop, kSplashGradientBottom],
            ),
          ),
          child: Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline,
                      size: 48, color: kSplashAccent.withValues(alpha: 0.9)),
                  SizedBox(height: AppSpacing.lg),
                  Text(
                    'Couldn\'t start the app',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: const Color(0xFF1C1B1F),
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  SizedBox(height: AppSpacing.sm),
                  Text(
                    'Check your connection and try again.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF49454F),
                        ),
                  ),
                  SizedBox(height: AppSpacing.xl),
                  FilledButton(
                    onPressed: widget.onRetry,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (widget.bootstrapComplete && !_exitStarted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _maybeStartExit();
      });
    }

    return AnimatedBuilder(
      animation: Listenable.merge([
        _entranceController,
        _pulseController,
        _gradientController,
        _exitController,
      ]),
      builder: (context, _) {
        final pulse = _pulseController.isAnimating
            ? _pulseController.value
            : 0.5;
        final breath = 1.0 + 0.045 * math.sin(pulse * math.pi);
        final logoScale = _entranceScale.value * breath;
        final opacity = _exitStarted
            ? _entranceOpacity.value * _exitOpacity.value
            : _entranceOpacity.value;
        final exitScaleMul = _exitStarted ? _exitScale.value : 1.0;

        return Scaffold(
          body: _GradientBackdrop(
            gradientT: _gradientController.value,
            child: Center(
              child: Transform.scale(
                scale: logoScale * exitScaleMul,
                child: Opacity(
                  opacity: opacity.clamp(0.0, 1.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 120,
                        height: 120,
                        child: Image.asset(
                          kSplashLogoAsset,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.psychology_rounded,
                            size: 88,
                            color: kSplashAccent.withValues(alpha: 0.85),
                          ),
                        ),
                      ),
                      SizedBox(height: AppSpacing.s28),
                      _LoadingDots(phase: _gradientController.value * 2 * math.pi),
                      SizedBox(height: AppSpacing.s20),
                      Text(
                        'Getting things ready…',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: const Color(0xFF49454F).withValues(alpha: 0.85),
                              letterSpacing: 0.2,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _GradientBackdrop extends StatelessWidget {
  const _GradientBackdrop({
    required this.gradientT,
    required this.child,
  });

  final double gradientT;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final shift = 0.08 * math.sin(gradientT * 2 * math.pi);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment(0, -1.0 + shift),
          end: Alignment(0, 1.0 - shift),
          colors: [
            Color.lerp(kSplashGradientTop, kSplashGradientMid, 0.5 + 0.5 * math.sin(gradientT * math.pi))!,
            kSplashGradientMid,
            kSplashGradientBottom,
          ],
          stops: const [0.0, 0.45, 1.0],
        ),
      ),
      child: child,
    );
  }
}

class _LoadingDots extends StatelessWidget {
  const _LoadingDots({required this.phase});

  final double phase;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        final t = phase + i * 0.85;
        final y = 4.0 * math.sin(t);
        final o = 0.35 + 0.65 * (0.5 + 0.5 * math.sin(t));
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.s5),
          child: Transform.translate(
            offset: Offset(0, -y),
            child: Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kSplashAccent.withValues(alpha: o.clamp(0.35, 1.0)),
              ),
            ),
          ),
        );
      }),
    );
  }
}
