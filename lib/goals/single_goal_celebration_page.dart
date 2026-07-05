import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:projectbrain/helpers/themes/app_spacing.dart';
import 'package:projectbrain/helpers/themes/app_theme_extension.dart';
import 'package:projectbrain/widgets/ds/ds_widgets.dart';

/// Celebration page shown when user completes a single goal.
class SingleGoalCelebrationPage extends StatelessWidget {
  const SingleGoalCelebrationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appTheme = context.appTheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: AppInsets.page,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconBubble(
                icon: Icons.check_circle,
                color: appTheme.green,
                backgroundColor: appTheme.greenSoft,
                size: 96,
                iconSize: 48,
                borderRadius: 24,
              ),
              const SizedBox(height: AppSpacing.xxl),
              Text(
                'Great Job!',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: appTheme.green,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'You completed one of your goals!',
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Keep up the momentum and tackle the rest!',
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xxxl),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: appTheme.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Back to Goals'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
