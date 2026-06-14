import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:projectbrain/core/config/app_config.dart';
import 'package:projectbrain/subscription/subscription_provider.dart';
import 'package:projectbrain/models/subscription.dart';
import 'package:projectbrain/subscription/widgets/tier_badge.dart';
import 'package:projectbrain/subscription/widgets/stripe_checkout_webview.dart';
import 'package:projectbrain/helpers/themes/app_spacing.dart';

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
            padding: AppInsets.screen,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) ...[
                  _IosWebBillingNotice(theme: Theme.of(context)),
                  SizedBox(height: AppSpacing.lg),
                ],
                // Billing period toggle
                _buildBillingToggle(),

                SizedBox(height: AppSpacing.xl),

                // Tier cards
                _buildTierCard(
                  context,
                  SubscriptionTier.free,
                  currentTier,
                  _isAnnual,
                ),
                SizedBox(height: AppSpacing.lg),
                _buildTierCard(
                  context,
                  SubscriptionTier.pro,
                  currentTier,
                  _isAnnual,
                  isPopular: true,
                ),
                SizedBox(height: AppSpacing.lg),
                _buildTierCard(
                  context,
                  SubscriptionTier.ultimate,
                  currentTier,
                  _isAnnual,
                ),

                SizedBox(height: AppSpacing.xxl),

                // Feature comparison
                _buildFeatureComparison(context),

                SizedBox(height: AppSpacing.xxl),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBillingToggle() {
    return Container(
      padding: EdgeInsets.all(AppSpacing.xs),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: AppRadius.circularMd,
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
        borderRadius: AppRadius.circularLg,
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
                  color: Colors.blue.withValues(alpha: 0.2),
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
            padding: AppInsets.screen,
            decoration: BoxDecoration(
              color: isPopular
                  ? Colors.blue.withValues(alpha: 0.1)
                  : theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.5),
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
                            SizedBox(width: AppSpacing.sm),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                                vertical: AppSpacing.xs,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                borderRadius: AppRadius.circularMd,
                              ),
                              child: Text(
                                'Most Popular',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      SizedBox(height: AppSpacing.sm),
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
            padding: AppInsets.screen,
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
                      padding: EdgeInsets.only(top: AppSpacing.sm),
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
                    padding: EdgeInsets.only(top: AppSpacing.xs),
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
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Column(
              children: _getTierFeatures(tier).map((feature) {
                return Padding(
                  padding: EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                      SizedBox(width: AppSpacing.sm),
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
            padding: AppInsets.screen,
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
                        padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
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
                                  : currentTier == SubscriptionTier.free &&
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
        SizedBox(height: AppSpacing.lg),
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

      // App Store policy: complete paid subscriptions on the web (Safari), not in-app Stripe.
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
        final billingUrl = AppConfig.subscriptionBillingWebUrl.trim();
        if (billingUrl.isEmpty) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Billing URL is not configured. Add SUBSCRIPTION_BILLING_WEB_URL to your environment.',
              ),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }
        final uri = Uri.tryParse(billingUrl);
        if (uri == null || uri.scheme != 'https') {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'SUBSCRIPTION_BILLING_WEB_URL must be a valid https:// URL.',
              ),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        if (!context.mounted) return;
        if (!launched) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open the billing page.'),
              backgroundColor: Colors.red,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Finish your purchase in the browser, then return to the app. Use Refresh on the subscription screen if your plan does not update.',
              ),
            ),
          );
        }
        return;
      }

      final checkoutUrl = await subscriptionProvider.createCheckout(
        tier.displayName,
        _isAnnual,
      );

      if (!context.mounted) return;

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

      if (result == true) {
        if (!context.mounted) return;
        // Refresh subscription data
        await subscriptionProvider.refresh();

        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Subscription upgraded successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        context.pop();
      }
    } catch (e) {
      if (!context.mounted) return;

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

class _IosWebBillingNotice extends StatelessWidget {
  final ThemeData theme;

  const _IosWebBillingNotice({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      borderRadius: AppRadius.circularMd,
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline, color: theme.colorScheme.primary),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                'On iPhone, upgrades and checkout open in your browser (App Store guidelines). '
                'Sign in with the same account you use in the app.',
                style: theme.textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
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
        padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary : Colors.transparent,
          borderRadius: AppRadius.circularSm,
        ),
        child: Column(
          children: [
            Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: isSelected
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (badge != null && isSelected)
              Padding(
                padding: EdgeInsets.only(top: AppSpacing.xs),
                child: Text(
                  badge!,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onPrimary,
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
        borderRadius: AppRadius.circularSm,
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(AppSpacing.md),
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
                          color:
                              theme.colorScheme.outline.withValues(alpha: 0.3)),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.md),
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
