import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:projectbrain/subscription/subscription_provider.dart';
import 'package:projectbrain/models/subscription.dart';
import 'package:projectbrain/subscription/widgets/tier_badge.dart';
import 'package:projectbrain/subscription/widgets/stripe_checkout_webview.dart';

/// Pricing/Upgrade page showing all subscription tiers
class PricingPage extends StatefulWidget {
  const PricingPage({super.key});

  @override
  State<PricingPage> createState() => _PricingPageState();
}

class _PricingPageState extends State<PricingPage> {
  bool _isAnnual = false;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upgrade Subscription'),
      ),
      body: Consumer<SubscriptionProvider>(
        builder: (context, subscriptionProvider, _) {
          final currentTier = subscriptionProvider.currentTier;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Billing period toggle
                _buildBillingToggle(),

                const SizedBox(height: 24),

                // Tier cards
                _buildTierCard(
                  context,
                  SubscriptionTier.free,
                  currentTier,
                  _isAnnual,
                ),
                const SizedBox(height: 16),
                _buildTierCard(
                  context,
                  SubscriptionTier.pro,
                  currentTier,
                  _isAnnual,
                  isPopular: true,
                ),
                const SizedBox(height: 16),
                _buildTierCard(
                  context,
                  SubscriptionTier.ultimate,
                  currentTier,
                  _isAnnual,
                ),

                const SizedBox(height: 32),

                // Feature comparison
                _buildFeatureComparison(context),

                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBillingToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _BillingOption(
              label: 'Monthly',
              isSelected: !_isAnnual,
              onTap: () => setState(() => _isAnnual = false),
            ),
          ),
          Expanded(
            child: _BillingOption(
              label: 'Annual',
              isSelected: _isAnnual,
              onTap: () => setState(() => _isAnnual = true),
              badge: 'Save 17%',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTierCard(
    BuildContext context,
    SubscriptionTier tier,
    SubscriptionTier currentTier,
    bool isAnnual, {
    bool isPopular = false,
  }) {
    final theme = Theme.of(context);
    final isCurrentTier = tier == currentTier;
    final price = _getPrice(tier, isAnnual);
    final period = isAnnual ? 'year' : 'month';

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrentTier
              ? theme.colorScheme.primary
              : isPopular
                  ? Colors.blue
                  : theme.colorScheme.outline,
          width: isCurrentTier || isPopular ? 2 : 1,
        ),
        boxShadow: isPopular
            ? [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isPopular
                  ? Colors.blue.withOpacity(0.1)
                  : theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          TierBadge(tier: tier),
                          if (isPopular) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Most Popular',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _getTierDescription(tier),
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Pricing
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '\$${price.toStringAsFixed(0)}',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '/$period',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
                if (isAnnual && tier != SubscriptionTier.free)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Billed annually (\$${_getAnnualTotal(tier)}/year)',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Features list
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: _getTierFeatures(tier).map((feature) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          feature,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),

          // Action button
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: isCurrentTier
                  ? OutlinedButton(
                      onPressed: null,
                      child: const Text('Current Plan'),
                    )
                  : ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : () => _handleUpgrade(context, tier),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              tier == SubscriptionTier.free
                                  ? 'Downgrade'
                                  : isCurrentTier == SubscriptionTier.free &&
                                          tier == SubscriptionTier.pro
                                      ? 'Start 7-Day Free Trial'
                                      : 'Upgrade to ${tier.displayName}',
                            ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureComparison(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Feature Comparison',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _FeatureComparisonTable(),
      ],
    );
  }

  double _getPrice(SubscriptionTier tier, bool isAnnual) {
    switch (tier) {
      case SubscriptionTier.free:
        return 0;
      case SubscriptionTier.pro:
        return isAnnual ? 10.0 : 12.0;
      case SubscriptionTier.ultimate:
        return isAnnual ? 20.0 : 24.0;
    }
  }

  double _getAnnualTotal(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.free:
        return 0;
      case SubscriptionTier.pro:
        return 120.0;
      case SubscriptionTier.ultimate:
        return 240.0;
    }
  }

  String _getTierDescription(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.free:
        return 'Perfect for getting started';
      case SubscriptionTier.pro:
        return 'For power users who need more';
      case SubscriptionTier.ultimate:
        return 'Everything you need and more';
    }
  }

  List<String> _getTierFeatures(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.free:
        return [
          '50 AI queries per day',
          '200 AI queries per month',
          'Up to 3 coach connections',
          '200 messages to coaches per month',
          'Up to 20 uploaded files',
          '100MB file storage',
        ];
      case SubscriptionTier.pro:
        return [
          'Unlimited AI queries',
          'Unlimited coach connections',
          'Unlimited messages to coaches',
          'Unlimited files',
          '500MB file storage',
          'Speech input for AI chat',
          '1 free research report per month',
          'Basic support',
        ];
      case SubscriptionTier.ultimate:
        return [
          'Everything in Pro',
          'Unlimited file storage',
          'External integrations',
          'Unlimited research reports',
          'Realtime chat support',
          '24x7 support',
        ];
    }
  }

  Future<void> _handleUpgrade(
      BuildContext context, SubscriptionTier tier) async {
    if (tier == SubscriptionTier.free) {
      // Handle downgrade
      return;
    }

    setState(() => _isLoading = true);

    try {
      final subscriptionProvider =
          Provider.of<SubscriptionProvider>(context, listen: false);
      final checkoutUrl = await subscriptionProvider.createCheckout(
        tier.displayName,
        _isAnnual,
      );

      if (!mounted) return;

      final result = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (context) => StripeCheckoutWebView(
            checkoutUrl: checkoutUrl,
            onSuccess: () {
              Navigator.of(context).pop(true);
            },
            onCancel: () {
              Navigator.of(context).pop(false);
            },
          ),
        ),
      );

      if (result == true && mounted) {
        // Refresh subscription data
        await subscriptionProvider.refresh();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Subscription upgraded successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate back
        if (mounted) {
          context.pop();
        }
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

class _BillingOption extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final String? badge;

  const _BillingOption({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (badge != null && isSelected)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  badge!,
                  style: TextStyle(
                    color: theme.colorScheme.onPrimary,
                    fontSize: 10,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FeatureComparisonTable extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final features = [
      _FeatureRow('AI Queries (Daily)', '50', 'Unlimited', 'Unlimited'),
      _FeatureRow('AI Queries (Monthly)', '200', 'Unlimited', 'Unlimited'),
      _FeatureRow('Coach Connections', '3', 'Unlimited', 'Unlimited'),
      _FeatureRow('Messages to Coaches', '200/month', 'Unlimited', 'Unlimited'),
      _FeatureRow('File Storage', '100MB', '500MB', 'Unlimited'),
      _FeatureRow('Speech Input', '❌', '✅', '✅'),
      _FeatureRow('Research Reports', '❌', '1/month', 'Unlimited'),
      _FeatureRow('External Integrations', '❌', '❌', '✅'),
      _FeatureRow('Support', 'Community', 'Basic', '24x7'),
    ];

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outline),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                    flex: 2,
                    child: Text('Feature',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(fontWeight: FontWeight.bold))),
                Expanded(
                    child: Text('Free',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center)),
                Expanded(
                    child: Text('Pro',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center)),
                Expanded(
                    child: Text('Ultimate',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center)),
              ],
            ),
          ),
          // Rows
          ...features.asMap().entries.map((entry) {
            final index = entry.key;
            final feature = entry.value;
            final isLast = index == features.length - 1;

            return Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: isLast
                      ? BorderSide.none
                      : BorderSide(
                          color: theme.colorScheme.outline.withOpacity(0.3)),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                        flex: 2,
                        child: Text(feature.feature,
                            style: theme.textTheme.bodySmall)),
                    Expanded(
                        child: Text(feature.free,
                            style: theme.textTheme.bodySmall,
                            textAlign: TextAlign.center)),
                    Expanded(
                        child: Text(feature.pro,
                            style: theme.textTheme.bodySmall,
                            textAlign: TextAlign.center)),
                    Expanded(
                        child: Text(feature.ultimate,
                            style: theme.textTheme.bodySmall,
                            textAlign: TextAlign.center)),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _FeatureRow {
  final String feature;
  final String free;
  final String pro;
  final String ultimate;

  _FeatureRow(this.feature, this.free, this.pro, this.ultimate);
}
