import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:confetti/confetti.dart';
import 'package:projectbrain/helpers/themes/app_spacing.dart';
import 'package:projectbrain/helpers/themes/app_theme_extension.dart';
import 'package:projectbrain/widgets/ds/ds_widgets.dart';

/// Celebration page shown when user completes all goals for the day.
class AllGoalsCelebrationPage extends StatefulWidget {
  const AllGoalsCelebrationPage({super.key});

  @override
  State<AllGoalsCelebrationPage> createState() =>
      _AllGoalsCelebrationPageState();
}

class _AllGoalsCelebrationPageState extends State<AllGoalsCelebrationPage> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));
    _confettiController.play();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appTheme = context.appTheme;

    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: AppInsets.page,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconBubble(
                    icon: Icons.celebration,
                    color: appTheme.green,
                    backgroundColor: appTheme.greenSoft,
                    size: 112,
                    iconSize: 56,
                    borderRadius: 28,
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  Text(
                    'Amazing!',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: appTheme.green,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'You completed all your goals for today!',
                    style: theme.textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    "You're on fire! Keep up this amazing momentum!",
                    style: theme.textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xxxl),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => context.go('/'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: appTheme.green,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Home'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: 3.14 / 2,
              maxBlastForce: 5,
              minBlastForce: 2,
              emissionFrequency: 0.05,
              numberOfParticles: 50,
              gravity: 0.1,
              colors: [
                appTheme.green,
                appTheme.amber,
                theme.colorScheme.primary,
                appTheme.coral,
              ],
            ),
          ),
        ],
      ),
    );
  }
}
