import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:projectbrain/helpers/themes/app_spacing.dart';
import 'package:projectbrain/helpers/themes/app_theme_extension.dart';
import 'package:projectbrain/widgets/ds/ds_widgets.dart';

/// Getting Started page for first-time users of the daily goals feature.
class GettingStartedPage extends StatelessWidget {
  const GettingStartedPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appTheme = context.appTheme;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppInsets.page,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Daily Goals', style: theme.textTheme.headlineSmall),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Set and track 3 daily goals to help you stay focused.',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.xl),
              DsSurfaceCard(
                backgroundColor: appTheme.greenSoft,
                borderColor: appTheme.green.withValues(alpha: 0.25),
                child: Row(
                  children: [
                    IconBubble(
                      icon: Icons.flag_outlined,
                      color: appTheme.green,
                      backgroundColor: theme.colorScheme.surface,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        'Welcome! Start with three small, achievable goals each day.',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              SectionHeader(title: 'How it works'),
              const SizedBox(height: AppSpacing.lg),
              _buildFeatureItem(
                context,
                icon: Icons.edit_outlined,
                color: appTheme.green,
                backgroundColor: appTheme.greenSoft,
                title: 'Set Your Goals',
                description:
                    'Define up to 3 goals you want to accomplish today.',
              ),
              const SizedBox(height: AppSpacing.md),
              _buildFeatureItem(
                context,
                icon: Icons.check_circle_outline,
                color: appTheme.amber,
                backgroundColor: appTheme.amberSoft,
                title: 'Track Progress',
                description:
                    'Mark goals as complete as you finish them throughout the day.',
              ),
              const SizedBox(height: AppSpacing.md),
              _buildFeatureItem(
                context,
                icon: Icons.phone_iphone_outlined,
                color: appTheme.sky,
                backgroundColor: appTheme.skySoft,
                title: 'Widget Support',
                description:
                    'View your goals at a glance with the iOS widget on your home screen.',
              ),
              const SizedBox(height: AppSpacing.xxl),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.go('/goals/entry'),
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
    required Color color,
    required Color backgroundColor,
    required String title,
    required String description,
  }) {
    final theme = Theme.of(context);

    return DsSurfaceCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconBubble(
            icon: icon,
            color: color,
            backgroundColor: backgroundColor,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleSmall),
                const SizedBox(height: AppSpacing.micro),
                Text(description, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
