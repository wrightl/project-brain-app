import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:projectbrain/subscription/subscription_provider.dart';
import 'package:projectbrain/subscription/widgets/usage_meter.dart';
import 'package:projectbrain/models/subscription.dart';

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
          if (subscriptionProvider.isLoading && subscriptionProvider.usage == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (subscriptionProvider.hasError && subscriptionProvider.usage == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    subscriptionProvider.errorMessage ?? 'Error loading usage',
                    style: theme.textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
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
            padding: const EdgeInsets.all(16),
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
                    const SizedBox(height: 16),
                    UsageMeter(
                      label: 'Monthly Queries',
                      current: usage.aiQueries.monthly,
                      limit: subscriptionProvider.getMonthlyAIQueryLimit(),
                      unit: '',
                    ),
                  ],
                ),

                const SizedBox(height: 24),

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

                const SizedBox(height: 24),

                // File Storage Section
                _buildSection(
                  context,
                  'File Storage',
                  Icons.folder_outlined,
                  [
                    UsageMeter(
                      label: 'Storage Used',
                      current: usage.fileStorage.megabytes.toInt(),
                      limit: subscriptionProvider.getFileStorageLimitMB()?.toInt(),
                      unit: ' MB',
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${usage.fileStorage.bytes} bytes total',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

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
                        limit: subscriptionProvider.getMonthlyResearchReportLimit(),
                        unit: '',
                      ),
                    ],
                  ),

                const SizedBox(height: 24),

                // Upgrade prompt if on free tier
                if (subscriptionProvider.currentTier == SubscriptionTier.free)
                  Card(
                    color: theme.colorScheme.primaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Icon(
                            Icons.upgrade,
                            size: 48,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Upgrade to unlock unlimited usage',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Get unlimited AI queries, coach connections, and more',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}

