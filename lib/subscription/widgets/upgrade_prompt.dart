import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:projectbrain/models/subscription.dart';
import 'package:projectbrain/helpers/themes/app_spacing.dart';

/// Widget that displays an upgrade prompt
class UpgradePrompt extends StatelessWidget {
  final SubscriptionTier requiredTier;
  final String featureName;
  final bool isCompact;

  const UpgradePrompt({
    super.key,
    required this.requiredTier,
    this.featureName = 'This feature',
    this.isCompact = false,
  });

  String _getTierName() {
    switch (requiredTier) {
      case SubscriptionTier.free:
        return 'Free';
      case SubscriptionTier.pro:
        return 'Pro';
      case SubscriptionTier.ultimate:
        return 'Ultimate';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isCompact) {
      return InkWell(
        onTap: () => context.push('/subscriptions/pricing'),
        child: Container(
          padding: EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: AppRadius.circularSm,
            border: Border.all(
              color: theme.colorScheme.primary,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.lock_outline,
                size: 16,
                color: theme.colorScheme.primary,
              ),
              SizedBox(width: AppSpacing.sm),
              Text(
                'Upgrade to $_getTierName()',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: AppInsets.screen,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: AppRadius.circularMd,
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.lock_outline,
            size: 48,
            color: theme.colorScheme.primary,
          ),
          SizedBox(height: AppSpacing.md),
          Text(
            '$featureName requires $_getTierName() tier',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppSpacing.sm),
          Text(
            'Upgrade to unlock this feature and more',
            style: theme.textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppSpacing.lg),
          ElevatedButton(
            onPressed: () => context.push('/subscriptions/pricing'),
            child: const Text('Upgrade Now'),
          ),
        ],
      ),
    );
  }
}

/// Dialog version of upgrade prompt
class UpgradePromptDialog extends StatelessWidget {
  final SubscriptionTier requiredTier;
  final String featureName;

  const UpgradePromptDialog({
    super.key,
    required this.requiredTier,
    this.featureName = 'This feature',
  });

  String _getTierName() {
    switch (requiredTier) {
      case SubscriptionTier.free:
        return 'Free';
      case SubscriptionTier.pro:
        return 'Pro';
      case SubscriptionTier.ultimate:
        return 'Ultimate';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.lock_outline,
            color: theme.colorScheme.primary,
          ),
          SizedBox(width: AppSpacing.sm),
          const Text('Upgrade Required'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$featureName requires $_getTierName() tier',
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppSpacing.sm),
          Text(
            'Upgrade to unlock this feature and more',
            style: theme.textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            context.push('/subscriptions/pricing');
          },
          child: const Text('Upgrade Now'),
        ),
      ],
    );
  }
}
