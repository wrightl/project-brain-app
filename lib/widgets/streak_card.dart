import 'package:flutter/material.dart';
import 'package:projectbrain/helpers/themes/app_spacing.dart';
import 'package:projectbrain/helpers/themes/app_theme_extension.dart';
import 'package:projectbrain/widgets/ds/ds_widgets.dart';

/// Compact card for displaying a streak (e.g. journal or goal streak).
class StreakCard extends StatelessWidget {
  const StreakCard({
    super.key,
    required this.title,
    required this.currentStreak,
    required this.bestStreak,
    this.noStreakMessage,
    this.ctaLabel,
    this.onCtaTap,
  });

  final String title;
  final int currentStreak;
  final int bestStreak;
  final String? noStreakMessage;
  final String? ctaLabel;
  final VoidCallback? onCtaTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appTheme = context.appTheme;
    final streakColor = appTheme.streakColor;
    final hasStreak = currentStreak > 0 || bestStreak > 0;

    return DsSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              IconBubble(
                icon: Icons.local_fire_department,
                color: streakColor,
                backgroundColor: appTheme.amberSoft,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.labelMedium,
                    ),
                    const SizedBox(height: AppSpacing.micro),
                    Text(
                      hasStreak
                          ? '$currentStreak day${currentStreak == 1 ? '' : 's'} streak'
                          : (noStreakMessage ?? 'No streak yet'),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: hasStreak ? streakColor : theme.colorScheme.onSurface,
                      ),
                    ),
                    if (hasStreak && bestStreak > 0)
                      Text(
                        'Best: $bestStreak days',
                        style: theme.textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (ctaLabel != null && onCtaTap != null) ...[
            const SizedBox(height: AppSpacing.md),
            TextButton(onPressed: onCtaTap, child: Text(ctaLabel!)),
          ],
        ],
      ),
    );
  }
}
