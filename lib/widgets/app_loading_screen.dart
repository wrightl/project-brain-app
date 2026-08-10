import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:projectbrain/helpers/themes/app_spacing.dart';
import 'package:projectbrain/helpers/themes/design_palette.dart';

/// Splash accent, aligned with the design system primary.
const Color kSplashAccent = DesignPalette.primary;

const String kSplashLogoAsset = 'assets/icon/appstore.png';

/// Full-screen animated loading UI: soft ambient blobs, logo tile with
/// breathing motion, shimmering progress pill, and a fade/scale exit.
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
  late final AnimationController _ambientController;
  late final AnimationController _exitController;
  late final Animation<double> _entranceScale;
  late final Animation<double> _entranceOpacity;
  late final Animation<double> _taglineOpacity;
  late final Animation<double> _exitOpacity;
  late final Animation<double> _exitScale;
  bool _exitStarted = false;
  bool _exitDone = false;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    // One long-running driver for blobs, breathing, dots, and shimmer.
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5200),
    )..repeat();
    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );

    _entranceScale = Tween<double>(begin: 0.86, end: 1.0).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOutBack),
    );
    _entranceOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.55, curve: Curves.easeOut),
      ),
    );
    _taglineOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.45, 1.0, curve: Curves.easeOut),
      ),
    );
    _exitOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeIn),
    );
    _exitScale = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeIn),
    );

    _entranceController.forward();

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
      _ambientController.stop();
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
    _exitController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _ambientController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.error != null) {
      return Scaffold(
        backgroundColor: DesignPalette.bg,
        body: Stack(
          children: [
            const _AmbientBlobs(t: 0.35),
            Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: DesignPalette.coralSoft,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.error_outline,
                        size: 36,
                        color: DesignPalette.coral,
                      ),
                    ),
                    SizedBox(height: AppSpacing.lg),
                    Text(
                      "Couldn't start the app",
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: DesignPalette.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    SizedBox(height: AppSpacing.sm),
                    Text(
                      'Check your connection and try again. If staging was asleep, it may still be waking up.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: DesignPalette.textSecondary,
                          ),
                    ),
                    SizedBox(height: AppSpacing.xl),
                    FilledButton(
                      onPressed: widget.onRetry,
                      style: FilledButton.styleFrom(
                        backgroundColor: DesignPalette.primary,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.xxl,
                          vertical: AppSpacing.md,
                        ),
                        shape: const StadiumBorder(),
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ],
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
        _ambientController,
        _exitController,
      ]),
      builder: (context, _) {
        final t = _ambientController.value;
        final breath = 1.0 + 0.03 * math.sin(t * 2 * math.pi);
        final logoScale = _entranceScale.value * breath;
        final opacity = _exitStarted
            ? _entranceOpacity.value * _exitOpacity.value
            : _entranceOpacity.value;
        final exitScaleMul = _exitStarted ? _exitScale.value : 1.0;

        return Scaffold(
          backgroundColor: DesignPalette.bg,
          body: Stack(
            children: [
              _AmbientBlobs(t: t),
              Center(
                child: Opacity(
                  opacity: opacity.clamp(0.0, 1.0),
                  child: Transform.scale(
                    scale: exitScaleMul,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Transform.scale(
                          scale: logoScale,
                          child: Container(
                            width: 108,
                            height: 108,
                            decoration: BoxDecoration(
                              color: DesignPalette.surface,
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(color: DesignPalette.border),
                              boxShadow: [
                                BoxShadow(
                                  color: DesignPalette.primary
                                      .withValues(alpha: 0.14),
                                  blurRadius: 36,
                                  offset: const Offset(0, 14),
                                ),
                              ],
                            ),
                            padding: EdgeInsets.all(AppSpacing.md),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: Image.asset(
                                kSplashLogoAsset,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.psychology_rounded,
                                  size: 56,
                                  color: DesignPalette.primary,
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: AppSpacing.xl),
                        Opacity(
                          opacity: _taglineOpacity.value,
                          child: Column(
                            children: [
                              Text(
                                'ProjectBrain',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(
                                      color: DesignPalette.textPrimary,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -0.3,
                                    ),
                              ),
                              SizedBox(height: AppSpacing.xs),
                              Text(
                                'Your space to focus and grow',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: DesignPalette.textMuted,
                                      letterSpacing: 0.1,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: AppSpacing.xxl),
                        Opacity(
                          opacity: _taglineOpacity.value,
                          child: _ShimmerBar(t: t),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Slowly drifting soft accent blobs behind the content.
class _AmbientBlobs extends StatelessWidget {
  const _AmbientBlobs({required this.t});

  final double t;

  @override
  Widget build(BuildContext context) {
    final phase = t * 2 * math.pi;

    return IgnorePointer(
      child: Stack(
        children: [
          _blob(
            alignment: Alignment(
              -0.9 + 0.12 * math.sin(phase),
              -0.75 + 0.08 * math.cos(phase),
            ),
            size: 260,
            color: DesignPalette.primarySoft,
          ),
          _blob(
            alignment: Alignment(
              1.1 - 0.1 * math.cos(phase * 0.8),
              -0.15 + 0.1 * math.sin(phase * 0.8),
            ),
            size: 220,
            color: DesignPalette.tealSoft,
          ),
          _blob(
            alignment: Alignment(
              -0.5 + 0.1 * math.cos(phase * 0.6),
              1.05 - 0.08 * math.sin(phase * 0.6),
            ),
            size: 280,
            color: DesignPalette.coralSoft,
          ),
        ],
      ),
    );
  }

  Widget _blob({
    required Alignment alignment,
    required double size,
    required Color color,
  }) {
    return Align(
      alignment: alignment,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: 0.85),
              color.withValues(alpha: 0.0),
            ],
          ),
        ),
      ),
    );
  }
}

/// Slim pill progress track with a shimmering sweep.
class _ShimmerBar extends StatelessWidget {
  const _ShimmerBar({required this.t});

  final double t;

  @override
  Widget build(BuildContext context) {
    // Sweep travels across twice per ambient cycle.
    final sweep = (t * 2) % 1.0;

    return SizedBox(
      width: 160,
      height: 6,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: Stack(
          children: [
            Container(color: DesignPalette.primarySoft),
            Align(
              alignment: Alignment(-1.5 + 3.0 * sweep, 0),
              child: FractionallySizedBox(
                widthFactor: 0.45,
                heightFactor: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        DesignPalette.primary.withValues(alpha: 0.0),
                        DesignPalette.primary,
                        DesignPalette.primary.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
