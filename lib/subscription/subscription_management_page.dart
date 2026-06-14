import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:projectbrain/subscription/subscription_provider.dart';
import 'package:projectbrain/subscription/widgets/tier_badge.dart';
import 'package:projectbrain/models/subscription.dart';
import 'package:projectbrain/helpers/themes/app_spacing.dart';

/// Subscription management page showing current subscription details
class SubscriptionManagementPage extends StatelessWidget {
  const SubscriptionManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscription'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              Provider.of<SubscriptionProvider>(context, listen: false)
                  .refresh();
            },
          ),
        ],
      ),
      body: Consumer<SubscriptionProvider>(
        builder: (context, subscriptionProvider, _) {
          if (subscriptionProvider.isLoading &&
              subscriptionProvider.subscription == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (subscriptionProvider.hasError &&
              subscriptionProvider.subscription == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: theme.colorScheme.error,
                  ),
                  SizedBox(height: AppSpacing.lg),
                  Text(
                    subscriptionProvider.errorMessage ??
                        'Error loading subscription',
                    style: theme.textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: AppSpacing.lg),
                  ElevatedButton(
                    onPressed: () => subscriptionProvider.refresh(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final subscription = subscriptionProvider.subscription;
          final usage = subscriptionProvider.usage;

          if (subscription == null) {
            return const Center(child: Text('No subscription found'));
          }

          return SingleChildScrollView(
            padding: AppInsets.screen,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Current tier card
                _buildCurrentTierCard(
                    context, subscription, subscriptionProvider),

                SizedBox(height: AppSpacing.lg),

                // Subscription status
                _buildStatusCard(context, subscription),

                SizedBox(height: AppSpacing.lg),

                // Quick actions
                _buildQuickActions(context, subscription, subscriptionProvider),

                SizedBox(height: AppSpacing.lg),

                // Usage summary
                if (usage != null) ...[
                  _buildUsageSummary(context, usage, subscriptionProvider),
                  SizedBox(height: AppSpacing.lg),
                ],

                // View usage dashboard button
                ElevatedButton.icon(
                  onPressed: () => context.push('/subscriptions/usage'),
                  icon: const Icon(Icons.bar_chart),
                  label: const Text('View Usage Dashboard'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  ),
                ),

                SizedBox(height: AppSpacing.lg),

                // Upgrade button
                if (subscription.tier != SubscriptionTier.ultimate)
                  OutlinedButton.icon(
                    onPressed: () => context.push('/subscriptions/pricing'),
                    icon: const Icon(Icons.upgrade),
                    label: const Text('Upgrade Plan'),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCurrentTierCard(
    BuildContext context,
    Subscription subscription,
    SubscriptionProvider provider,
  ) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: AppInsets.screen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TierBadge(tier: subscription.tier),
                if (subscription.isTrialing)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: AppRadius.circularMd,
                    ),
                    child: Text(
                      'Trial',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: AppSpacing.sm),
            Text(
              'Current Plan',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: AppSpacing.xs),
            Text(
              _getTierDescription(subscription.tier),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(
    BuildContext context,
    Subscription subscription,
  ) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM d, yyyy');

    return Card(
      child: Padding(
        padding: AppInsets.screen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Subscription Status',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: AppSpacing.md),
            _StatusRow(
              label: 'Status',
              value: subscription.status.displayName,
              valueColor: _getStatusColor(subscription.status, theme),
            ),
            if (subscription.isTrialing && subscription.trialEndsAt != null)
              _StatusRow(
                label: 'Trial Ends',
                value: dateFormat.format(subscription.trialEndsAt!),
              ),
            _StatusRow(
              label: 'Current Period',
              value: (subscription.currentPeriodStart != null &&
                      subscription.currentPeriodEnd != null)
                  ? '${dateFormat.format(subscription.currentPeriodStart!)} - ${dateFormat.format(subscription.currentPeriodEnd!)}'
                  : 'N/A',
            ),
            if (subscription.canceledAt != null)
              _StatusRow(
                label: 'Canceled On',
                value: dateFormat.format(subscription.canceledAt!),
                valueColor: theme.colorScheme.error,
              ),
            if (!subscription.isCanceled && !subscription.isExpired)
              _StatusRow(
                label: 'Next Billing Date',
                value: (subscription.currentPeriodEnd != null)
                    ? dateFormat.format(subscription.currentPeriodEnd!)
                    : 'N/A',
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(
    BuildContext context,
    Subscription subscription,
    SubscriptionProvider provider,
  ) {
    return Card(
      child: Padding(
        padding: AppInsets.screen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            SizedBox(height: AppSpacing.md),
            if (subscription.tier != SubscriptionTier.free &&
                !subscription.isCanceled)
              ListTile(
                leading: const Icon(Icons.cancel),
                title: const Text('Cancel Subscription'),
                subtitle: const Text('Cancel at the end of current period'),
                onTap: () => _showCancelDialog(context, provider),
              ),
            ListTile(
              leading: const Icon(Icons.upgrade),
              title: const Text('Change Plan'),
              subtitle: const Text('Upgrade or downgrade your plan'),
              onTap: () => context.push('/subscriptions/pricing'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsageSummary(
    BuildContext context,
    UsageStats usage,
    SubscriptionProvider provider,
  ) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: AppInsets.screen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Usage Summary',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () => context.push('/subscriptions/usage'),
                  child: const Text('View Details'),
                ),
              ],
            ),
            SizedBox(height: AppSpacing.md),
            _UsageSummaryRow(
              label: 'AI Queries (Today)',
              value: '${usage.aiQueries.daily}',
              limit: provider.getDailyAIQueryLimit(),
            ),
            _UsageSummaryRow(
              label: 'AI Queries (This Month)',
              value: '${usage.aiQueries.monthly}',
              limit: provider.getMonthlyAIQueryLimit(),
            ),
            _UsageSummaryRow(
              label: 'Coach Messages (This Month)',
              value: '${usage.coachMessages.monthly}',
              limit: provider.getMonthlyCoachMessageLimit(),
            ),
            _UsageSummaryRow(
              label: 'File Storage',
              value: '${usage.fileStorage.megabytes.toStringAsFixed(1)} MB',
              limit: provider.getFileStorageLimitMB()?.toInt(),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(SubscriptionStatus status, ThemeData theme) {
    switch (status) {
      case SubscriptionStatus.active:
        return Colors.green;
      case SubscriptionStatus.trialing:
        return Colors.orange;
      case SubscriptionStatus.canceled:
        return theme.colorScheme.error;
      case SubscriptionStatus.expired:
        return Colors.grey;
    }
  }

  String _getTierDescription(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.free:
        return 'Free tier with basic features';
      case SubscriptionTier.pro:
        return 'Pro tier with advanced features';
      case SubscriptionTier.ultimate:
        return 'Ultimate tier with all features';
    }
  }

  void _showCancelDialog(
    BuildContext context,
    SubscriptionProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Subscription'),
        content: const Text(
          'Are you sure you want to cancel your subscription? '
          'You will continue to have access until the end of your current billing period.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Keep Subscription'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await provider.cancelSubscription();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Subscription canceled successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: Text(
              'Cancel Subscription',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _StatusRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: valueColor,
              fontWeight: valueColor != null ? FontWeight.bold : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _UsageSummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final int? limit;

  const _UsageSummaryRow({
    required this.label,
    required this.value,
    this.limit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium,
          ),
          Text(
            limit != null ? '$value / $limit' : '$value (Unlimited)',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
