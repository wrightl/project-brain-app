import 'package:flutter/material.dart';
import 'package:projectbrain/helpers/themes/app_spacing.dart';
import 'package:projectbrain/helpers/themes/app_theme_extension.dart';
import 'package:projectbrain/widgets/ds/ds_widgets.dart';

/// Goal row with checkbox and optional status tag.
class GoalRow extends StatelessWidget {
  const GoalRow({
    super.key,
    required this.title,
    required this.completed,
    this.meta,
    this.onToggle,
  });

  final String title;
  final bool completed;
  final String? meta;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appTheme = context.appTheme;

    return DsSurfaceCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          _GoalCheckbox(completed: completed, onTap: onToggle),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    decoration: completed ? TextDecoration.lineThrough : null,
                    color: completed
                        ? appTheme.textMuted
                        : theme.colorScheme.onSurface,
                  ),
                ),
                if (meta != null) ...[
                  const SizedBox(height: AppSpacing.micro),
                  Text(meta!, style: theme.textTheme.bodySmall),
                ],
              ],
            ),
          ),
          AccentTag(
            label: completed ? 'Done' : 'To do',
            color: completed ? appTheme.green : appTheme.amber,
            backgroundColor:
                completed ? appTheme.greenSoft : appTheme.amberSoft,
          ),
        ],
      ),
    );
  }
}

class _GoalCheckbox extends StatelessWidget {
  const _GoalCheckbox({required this.completed, this.onTap});

  final bool completed;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final appTheme = context.appTheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: completed ? appTheme.green : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: completed ? appTheme.green : appTheme.borderColor,
            width: completed ? 0 : 2,
          ),
        ),
        child: completed
            ? const Icon(Icons.check, size: 16, color: Colors.white)
            : null,
      ),
    );
  }
}

/// Colorful feature tile for the home grid.
class FeatureTile extends StatelessWidget {
  const FeatureTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.backgroundColor,
    required this.iconColor,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color backgroundColor;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DsSurfaceCard(
      onTap: onTap,
      backgroundColor: backgroundColor,
      borderColor: Colors.transparent,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconBubble(
            icon: icon,
            color: Colors.white,
            backgroundColor: iconColor,
            size: 44,
            iconSize: 22,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
