import 'package:flutter/material.dart';
import 'package:projectbrain/models/subscription.dart';
import 'package:projectbrain/helpers/themes/app_spacing.dart';

/// Widget that displays a tier badge with appropriate styling
class TierBadge extends StatelessWidget {
  final SubscriptionTier tier;
  final bool isCompact;

  const TierBadge({
    super.key,
    required this.tier,
    this.isCompact = false,
  });

  Color _getTierColor() {
    switch (tier) {
      case SubscriptionTier.free:
        return Colors.grey;
      case SubscriptionTier.pro:
        return Colors.blue;
      case SubscriptionTier.ultimate:
        return Colors.deepPurple;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _getTierColor();

    if (isCompact) {
      return Container(
        padding: AppInsets.chip,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: AppRadius.circularMd,
          border: Border.all(color: color, width: 1),
        ),
        child: Text(
          tier.displayName,
          style: theme.textTheme.labelMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.s6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppRadius.circularLg,
        border: Border.all(color: color, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.star,
            color: color,
            size: 16,
          ),
          SizedBox(width: AppSpacing.xs),
          Text(
            tier.displayName,
            style: theme.textTheme.labelLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

