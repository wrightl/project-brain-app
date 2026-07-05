import 'package:flutter/material.dart';
import 'package:projectbrain/helpers/themes/app_spacing.dart';
import 'package:projectbrain/helpers/themes/app_theme_extension.dart';

/// Rounded square icon container with soft accent background.
class IconBubble extends StatelessWidget {
  const IconBubble({
    super.key,
    required this.icon,
    required this.color,
    required this.backgroundColor,
    this.size = 44,
    this.iconSize = 22,
    this.borderRadius = 14,
  });

  final IconData icon;
  final Color color;
  final Color backgroundColor;
  final double size;
  final double iconSize;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Icon(icon, color: color, size: iconSize),
    );
  }
}

/// Soft pill label for categories, moods, and status.
class AccentTag extends StatelessWidget {
  const AccentTag({
    super.key,
    required this.label,
    required this.color,
    required this.backgroundColor,
    this.icon,
  });

  final String label;
  final Color color;
  final Color backgroundColor;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs + 1,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: AppRadius.circularPill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: AppSpacing.xs),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

/// Section title with optional trailing action.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (actionLabel != null && onAction != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(actionLabel!),
                const SizedBox(width: AppSpacing.xs),
                Icon(
                  Icons.arrow_forward,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Bordered surface card matching the design system.
class DsSurfaceCard extends StatelessWidget {
  const DsSurfaceCard({
    super.key,
    required this.child,
    this.padding = AppInsets.card,
    this.backgroundColor,
    this.borderColor,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? backgroundColor;
  final Color? borderColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appTheme = Theme.of(context).extension<AppThemeExtension>();

    final card = Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? theme.colorScheme.surface,
        borderRadius: AppRadius.circularLg,
        border: Border.all(
          color: borderColor ?? appTheme?.borderColor ?? theme.dividerColor,
        ),
      ),
      child: child,
    );

    if (onTap == null) return card;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.circularLg,
        child: card,
      ),
    );
  }
}
