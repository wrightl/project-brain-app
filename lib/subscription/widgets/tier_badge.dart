import 'package:flutter/material.dart';
import 'package:projectbrain/models/subscription.dart';

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
    final color = _getTierColor();

    if (isCompact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color, width: 1),
        ),
        child: Text(
          tier.displayName,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
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
          const SizedBox(width: 4),
          Text(
            tier.displayName,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

