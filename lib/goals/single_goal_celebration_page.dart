import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:projectbrain/helpers/themes/app_spacing.dart';

/// Celebration page shown when user completes a single goal
class SingleGoalCelebrationPage extends StatelessWidget {
  const SingleGoalCelebrationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: AppInsets.page,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Celebration icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.green.withValues(alpha: 0.1),
                ),
                child: const Icon(
                  Icons.check_circle,
                  size: 80,
                  color: Colors.green,
                ),
              ),
              SizedBox(height: AppSpacing.xxl),

              // Congratulations message
              Text(
                'Great Job!',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppSpacing.lg),

              Text(
                'You completed one of your goals!',
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppSpacing.sm),

              Text(
                'Keep up the momentum and tackle the rest!',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppSpacing.xxxl),

              // Back to goals button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Pop back to goals list (will use reverse transition)
                    context.pop();
                  },
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                    backgroundColor: Colors.green,
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
