import 'package:flutter/material.dart';
import 'package:projectbrain/subscription/subscription_provider.dart';
import 'package:projectbrain/subscription/widgets/upgrade_prompt.dart';
import 'package:projectbrain/models/subscription.dart';
import 'package:provider/provider.dart';

/// Widget that gates features based on subscription tier
class FeatureGate extends StatelessWidget {
  final Widget child;
  final bool Function(SubscriptionProvider) canAccess;
  final SubscriptionTier requiredTier;
  final String? featureName;

  const FeatureGate({
    super.key,
    required this.child,
    required this.canAccess,
    required this.requiredTier,
    this.featureName,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<SubscriptionProvider>(
      builder: (context, subscriptionProvider, _) {
        if (canAccess(subscriptionProvider)) {
          return child;
        }

        // Show upgrade prompt if feature is not available
        return UpgradePrompt(
          requiredTier: requiredTier,
          featureName: featureName ?? 'This feature',
        );
      },
    );
  }
}

/// Convenience widget for speech input feature gate
class SpeechInputGate extends StatelessWidget {
  final Widget child;

  const SpeechInputGate({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return FeatureGate(
      canAccess: (provider) => provider.canUseSpeechInput(),
      requiredTier: SubscriptionTier.pro,
      featureName: 'Speech input',
      child: child,
    );
  }
}

/// Convenience widget for external integrations feature gate
class ExternalIntegrationsGate extends StatelessWidget {
  final Widget child;

  const ExternalIntegrationsGate({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return FeatureGate(
      canAccess: (provider) => provider.canUseExternalIntegrations(),
      requiredTier: SubscriptionTier.ultimate,
      featureName: 'External integrations',
      child: child,
    );
  }
}

/// Convenience widget for research reports feature gate
class ResearchReportsGate extends StatelessWidget {
  final Widget child;

  const ResearchReportsGate({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return FeatureGate(
      canAccess: (provider) => provider.canUseResearchReports(),
      requiredTier: SubscriptionTier.pro,
      featureName: 'Research reports',
      child: child,
    );
  }
}
