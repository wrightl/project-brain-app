import 'package:flutter/material.dart';
import 'package:projectbrain/helpers/theme.dart';

/// Compact card for displaying a streak (e.g. journal or goal streak).
/// Shows current streak, optional "best" streak, and optional CTA.
class StreakCard extends StatelessWidget {
  final String title;
  final int currentStreak;
  final int bestStreak;
  final String? noStreakMessage;
  final String? ctaLabel;
  final VoidCallback? onCtaTap;

  const StreakCard({
    super.key,
    required this.title,
    required this.currentStreak,
    required this.bestStreak,
    this.noStreakMessage,
    this.ctaLabel,
    this.onCtaTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ext = theme.extension<AppThemeExtension>();
    final streakColor = ext?.streakColor ?? theme.colorScheme.primary;
    final hasStreak = currentStreak > 0 || bestStreak > 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: streakColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.local_fire_department, color: streakColor, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        hasStreak
                            ? '$currentStreak day${currentStreak == 1 ? '' : 's'} streak'
                            : (noStreakMessage ?? 'No streak yet'),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: hasStreak ? streakColor : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                      if (hasStreak && bestStreak > 0)
                        Text(
                          'Best: $bestStreak days',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (ctaLabel != null && onCtaTap != null) ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: onCtaTap,
                child: Text(ctaLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
