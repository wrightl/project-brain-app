import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:projectbrain/helpers/themes/app_spacing.dart';

/// Getting Started page for first-time users of the daily goals feature
class GettingStartedPage extends StatelessWidget {
  const GettingStartedPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Goals'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppInsets.page,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'Welcome to Daily Goals!',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: AppSpacing.xl),

              // Feature description
              Text(
                'Set and track 3 daily goals to help you stay focused and productive.',
                style: theme.textTheme.bodyLarge,
              ),
              SizedBox(height: AppSpacing.xxl),

              // How it works section
              Text(
                'How it works:',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: AppSpacing.lg),

              _buildFeatureItem(
                context,
                icon: Icons.edit,
                title: 'Set Your Goals',
                description: 'Define up to 3 goals you want to accomplish today.',
              ),
              SizedBox(height: AppSpacing.lg),

              _buildFeatureItem(
                context,
                icon: Icons.check_circle,
                title: 'Track Progress',
                description: 'Mark goals as complete as you finish them throughout the day.',
              ),
              SizedBox(height: AppSpacing.lg),

              _buildFeatureItem(
                context,
                icon: Icons.phone_android,
                title: 'Widget Support',
                description: 'View your goals at a glance with the iOS widget on your home screen.',
              ),
              SizedBox(height: AppSpacing.xxl),

              // Get Started button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    context.go('/goals/entry');
                  },
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  ),
                  child: const Text('Get Started'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: AppRadius.circularMd,
          ),
          child: Icon(
            icon,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: AppSpacing.xs),
              Text(
                description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

