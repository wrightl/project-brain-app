import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:projectbrain/goals/egg_goals_provider.dart';
import 'package:projectbrain/helpers/themes/app_spacing.dart';
import 'package:projectbrain/helpers/themes/app_theme_extension.dart';
import 'package:projectbrain/widgets/ds/ds_widgets.dart';
import 'package:projectbrain/widgets/ds/goal_row.dart';

/// Page displaying the list of daily goals with checkboxes and progress.
class GoalsListPage extends StatelessWidget {
  const GoalsListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final goalsProvider = Provider.of<EggGoalsProvider>(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => context.read<EggGoalsProvider>().syncFromAPI(),
                child: _buildBody(context, goalsProvider),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, EggGoalsProvider provider) {
    final theme = Theme.of(context);
    final appTheme = context.appTheme;
    final visibleGoals = <({int index, EggGoal goal})>[];

    for (var i = 0; i < provider.goals.length; i++) {
      final g = provider.goals[i];
      if (g.message.isNotEmpty && g.message != 'No Egg Goal Set') {
        visibleGoals.add((index: i, goal: g));
      }
    }

    final progress = provider.getCompletionProgress();
    final completed = progress['completed'] ?? 0;
    final total = progress['total'] ?? 3;
    final pct = total > 0 ? completed / total : 0.0;
    final dateLabel = DateFormat('EEEE d MMMM').format(DateTime.now());

    if (provider.isLoading && visibleGoals.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: AppSpacing.emptyStateTop),
          Center(child: CircularProgressIndicator()),
        ],
      );
    }

    if (provider.hasError && visibleGoals.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: AppInsets.page,
        children: [
          SizedBox(height: AppSpacing.emptyStateOffset),
          Icon(Icons.error_outline, size: 56, color: theme.colorScheme.error),
          const SizedBox(height: AppSpacing.lg),
          Text(
            provider.errorMessage ?? 'Failed to load goals',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: AppSpacing.lg),
          Center(
            child: FilledButton(
              onPressed: () => context.read<EggGoalsProvider>().syncFromAPI(),
              child: const Text('Retry'),
            ),
          ),
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.xxl,
      ),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Daily goals', style: theme.textTheme.headlineSmall),
                  Text(dateLabel, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            Consumer<EggGoalsProvider>(
              builder: (context, p, _) {
                final streak = p.goalStreakSummary?.currentStreak ?? 0;
                if (streak <= 0) return const SizedBox.shrink();
                return AccentTag(
                  label: '$streak day streak',
                  color: appTheme.amber,
                  backgroundColor: appTheme.amberSoft,
                  icon: Icons.local_fire_department,
                );
              },
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        DsSurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$completed of $total done',
                    style: theme.textTheme.titleSmall,
                  ),
                  Text(
                    '${(pct * 100).round()}%',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              ClipRRect(
                borderRadius: AppRadius.circularPill,
                child: LinearProgressIndicator(
                  value: pct,
                  minHeight: 10,
                  backgroundColor: appTheme.primarySoft,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (visibleGoals.isEmpty)
          DsSurfaceCard(
            child: Column(
              children: [
                Icon(Icons.flag_outlined, size: 48, color: appTheme.textMuted),
                const SizedBox(height: AppSpacing.md),
                Text('No goals set yet', style: theme.textTheme.titleMedium),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Add your first goal to get started.',
                  style: theme.textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          ...visibleGoals.map((entry) {
            final goal = entry.goal;
            final index = entry.index;
            final isToggling = provider.isGoalToggling(index);

            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Opacity(
                opacity: isToggling ? 0.6 : 1,
                child: GoalRow(
                  title: goal.message,
                  completed: goal.completed,
                  meta: 'Daily goal',
                  onToggle: isToggling
                      ? null
                      : () => _toggleGoal(context, provider, goal, index),
                ),
              ),
            );
          }),
        const SizedBox(height: AppSpacing.lg),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () => context.go('/goals/entry'),
            icon: const Icon(Icons.add, size: 20),
            label: const Text('Add a goal'),
          ),
        ),
      ],
    );
  }

  Future<void> _toggleGoal(
    BuildContext context,
    EggGoalsProvider provider,
    EggGoal goal,
    int index,
  ) async {
    await provider.toggleGoalCompletion(index);
    if (!context.mounted) return;

    final progress = provider.getCompletionProgress();
    final wasCompleted = goal.completed;
    final nowCompleted = !wasCompleted;

    if (nowCompleted && !wasCompleted) {
      HapticFeedback.mediumImpact();
      if (progress['completed'] == 3) {
        context.push('/goals/celebration/all');
      } else {
        context.push('/goals/celebration/single');
      }
    }
  }
}
