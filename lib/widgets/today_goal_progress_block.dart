import 'package:flutter/material.dart';
import 'package:projectbrain/helpers/theme.dart';

/// Block showing today's goal progress (X/3) with a primary CTA.
class TodayGoalProgressBlock extends StatelessWidget {
  final int completed;
  final int total;
  final bool hasGoals;
  final VoidCallback onTap;

  const TodayGoalProgressBlock({
    super.key,
    required this.completed,
    required this.total,
    required this.hasGoals,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ext = theme.extension<AppThemeExtension>();
    final achievementColor = ext?.achievementColor ?? theme.colorScheme.primary;
    final progress = total > 0 ? completed / total : 0.0;
    final allDone = total > 0 && completed >= total;

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
                    color: achievementColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.check_circle_outline,
                    color: achievementColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Today's goals",
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        hasGoals
                            ? '$completed / $total completed'
                            : 'No goals set for today',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (hasGoals) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    allDone ? Colors.green : achievementColor,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onTap,
                icon: Icon(hasGoals ? Icons.edit : Icons.add, size: 20),
                label: Text(hasGoals ? 'Complete goals' : 'Set goals'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
