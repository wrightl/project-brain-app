import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:projectbrain/subscription/subscription_provider.dart';
import 'package:projectbrain/subscription/widgets/usage_meter.dart';
import 'package:projectbrain/models/subscription.dart';
import 'package:projectbrain/helpers/themes/app_spacing.dart';

/// Usage dashboard page showing detailed usage statistics
class UsageDashboardPage extends StatelessWidget {
  const UsageDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Usage Dashboard'),
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
              subscriptionProvider.usage == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (subscriptionProvider.hasError &&
              subscriptionProvider.usage == null) {
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
                    subscriptionProvider.errorMessage ?? 'Error loading usage',
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

          final usage = subscriptionProvider.usage;
          if (usage == null) {
            return const Center(child: Text('No usage data available'));
          }

          return SingleChildScrollView(
            padding: AppInsets.screen,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // AI Queries Section
                _buildSection(
                  context,
                  'AI Queries',
                  Icons.chat_bubble_outline,
                  [
                    UsageMeter(
                      label: 'Daily Queries',
                      current: usage.aiQueries.daily,
                      limit: subscriptionProvider.getDailyAIQueryLimit(),
                      unit: '',
                    ),
                    SizedBox(height: AppSpacing.lg),
                    UsageMeter(
                      label: 'Monthly Queries',
                      current: usage.aiQueries.monthly,
                      limit: subscriptionProvider.getMonthlyAIQueryLimit(),
                      unit: '',
                    ),
                  ],
                ),

                SizedBox(height: AppSpacing.xl),

                // Coach Messages Section
                _buildSection(
                  context,
                  'Coach Messages',
                  Icons.message_outlined,
                  [
                    UsageMeter(
                      label: 'Monthly Messages',
                      current: usage.coachMessages.monthly,
                      limit: subscriptionProvider.getMonthlyCoachMessageLimit(),
                      unit: '',
                    ),
                  ],
                ),

                SizedBox(height: AppSpacing.xl),

                // File Storage Section
                _buildSection(
                  context,
                  'File Storage',
                  Icons.folder_outlined,
                  [
                    UsageMeter(
                      label: 'Storage Used',
                      current: usage.fileStorage.megabytes.toInt(),
                      limit:
                          subscriptionProvider.getFileStorageLimitMB()?.toInt(),
                      unit: ' MB',
                    ),
                    SizedBox(height: AppSpacing.sm),
                    Text(
                      '${usage.fileStorage.bytes} bytes total',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: AppSpacing.xl),

                // Research Reports Section (if applicable)
                if (subscriptionProvider.canUseResearchReports())
                  _buildSection(
                    context,
                    'Research Reports',
                    Icons.description_outlined,
                    [
                      UsageMeter(
                        label: 'Monthly Reports',
                        current: usage.researchReports.monthly,
                        limit: subscriptionProvider
                            .getMonthlyResearchReportLimit(),
                        unit: '',
                      ),
                    ],
                  ),

                SizedBox(height: AppSpacing.xl),

                // Upgrade prompt if on free tier
                if (subscriptionProvider.currentTier == SubscriptionTier.free)
                  Card(
                    color: theme.colorScheme.primaryContainer,
                    child: Padding(
                      padding: AppInsets.screen,
                      child: Column(
                        children: [
                          Icon(
                            Icons.upgrade,
                            size: 48,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                          SizedBox(height: AppSpacing.md),
                          Text(
                            'Upgrade to unlock unlimited usage',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: AppSpacing.sm),
                          Text(
                            'Get unlimited AI queries, coach connections, and more',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: AppSpacing.lg),
                          ElevatedButton(
                            onPressed: () {
                              // Navigate to pricing page
                              context.push('/subscriptions/pricing');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: theme.colorScheme.onPrimary,
                            ),
                            child: const Text('View Plans'),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    IconData icon,
    List<Widget> children,
  ) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: AppInsets.screen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: theme.colorScheme.primary),
                SizedBox(width: AppSpacing.sm),
                Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: AppSpacing.lg),
            ...children,
          ],
        ),
      ),
    );
  }
}
