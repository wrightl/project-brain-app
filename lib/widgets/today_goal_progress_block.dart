import 'package:flutter/material.dart';
import 'package:projectbrain/helpers/themes/app_spacing.dart';
import 'package:projectbrain/helpers/themes/app_theme_extension.dart';
import 'package:projectbrain/widgets/ds/ds_widgets.dart';

/// Block showing today's goal progress with a primary CTA.
class TodayGoalProgressBlock extends StatelessWidget {
  const TodayGoalProgressBlock({
    super.key,
    required this.completed,
    required this.total,
    required this.hasGoals,
    required this.onTap,
  });

  final int completed;
  final int total;
  final bool hasGoals;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appTheme = context.appTheme;
    final progress = total > 0 ? completed / total : 0.0;
    final allDone = total > 0 && completed >= total;

    return DsSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              IconBubble(
                icon: Icons.check_circle_outline,
                color: appTheme.green,
                backgroundColor: appTheme.greenSoft,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Today's goals", style: theme.textTheme.labelMedium),
                    const SizedBox(height: AppSpacing.micro),
                    Text(
                      hasGoals
                          ? '$completed / $total completed'
                          : 'No goals set for today',
                      style: theme.textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (hasGoals) ...[
            const SizedBox(height: AppSpacing.md),
            ClipRRect(
              borderRadius: AppRadius.circularPill,
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                backgroundColor: appTheme.primarySoft,
                valueColor: AlwaysStoppedAnimation<Color>(
                  allDone ? appTheme.green : theme.colorScheme.primary,
                ),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
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
    );
  }
}
