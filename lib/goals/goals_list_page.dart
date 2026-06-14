import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:projectbrain/goals/egg_goals_provider.dart';
import 'package:projectbrain/helpers/themes/app_spacing.dart';

/// Page displaying the list of daily goals with checkboxes and progress
class GoalsListPage extends StatelessWidget {
  const GoalsListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final goalsProvider = Provider.of<EggGoalsProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Goals'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              context.go('/goals/entry');
            },
            tooltip: 'Edit Goals',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => context.read<EggGoalsProvider>().syncFromAPI(),
                child: _buildBody(context, goalsProvider),
              ),
            ),

            // Progress tracker at bottom
            _buildProgressTracker(context, goalsProvider),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, EggGoalsProvider provider) {
    final theme = Theme.of(context);

    // Keep the original index so toggleGoalCompletion targets the right goal.
    final visibleGoals = <({int index, EggGoal goal})>[];
    for (var i = 0; i < provider.goals.length; i++) {
      final g = provider.goals[i];
      if (g.message.isNotEmpty && g.message != 'No Egg Goal Set') {
        visibleGoals.add((index: i, goal: g));
      }
    }

    // First load with nothing cached yet.
    if (provider.isLoading && visibleGoals.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: AppSpacing.emptyStateTop),
          Center(child: CircularProgressIndicator()),
        ],
      );
    }

    // Error with nothing to show.
    if (provider.hasError && visibleGoals.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: AppInsets.page,
        children: [
          SizedBox(height: AppSpacing.emptyStateOffset),
          Icon(Icons.error_outline, size: 56, color: theme.colorScheme.error),
          SizedBox(height: AppSpacing.lg),
          Text(
            provider.errorMessage ?? 'Failed to load goals',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge,
          ),
          SizedBox(height: AppSpacing.lg),
          Center(
            child: FilledButton(
              onPressed: () => context.read<EggGoalsProvider>().syncFromAPI(),
              child: const Text('Retry'),
            ),
          ),
        ],
      );
    }

    // Empty state after a successful fetch.
    if (visibleGoals.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: AppInsets.page,
        children: [
          SizedBox(height: AppSpacing.emptyStateOffset),
          Icon(Icons.flag_outlined,
              size: 64, color: theme.colorScheme.onSurfaceVariant),
          SizedBox(height: AppSpacing.lg),
          Text(
            'No goals set yet',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium,
          ),
          SizedBox(height: AppSpacing.sm),
          Text(
            'Tap the edit icon to set your daily goals.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: AppInsets.screen,
      itemCount: visibleGoals.length,
      itemBuilder: (context, index) {
        final entry = visibleGoals[index];
        return _buildGoalItem(context, entry.goal, entry.index, provider);
      },
    );
  }

  Widget _buildGoalItem(
    BuildContext context,
    EggGoal goal,
    int index,
    EggGoalsProvider provider,
  ) {
    final theme = Theme.of(context);

    return Card(
      margin: AppInsets.listItemBottom,
      child: InkWell(
        onTap: () async {
          await provider.toggleGoalCompletion(index);
          if (context.mounted) {
            final progress = provider.getCompletionProgress();
            final wasCompleted = goal.completed;
            final nowCompleted = !wasCompleted;

            // Navigate to celebration if completing a goal
            if (nowCompleted && !wasCompleted) {
              HapticFeedback.mediumImpact();
              if (progress['completed'] == 3) {
                // All goals completed
                context.push('/goals/celebration/all');
              } else {
                // Single goal completed
                context.push('/goals/celebration/single');
              }
            }
          }
        },
        borderRadius: AppRadius.circularMd,
        child: Padding(
          padding: AppInsets.screen,
          child: Row(
            children: [
              // Custom checkbox with egg theme
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: goal.completed ? Colors.green : Colors.orange,
                    width: 3,
                  ),
                  color: goal.completed
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.transparent,
                ),
                child: goal.completed
                    ? const Icon(
                        Icons.check,
                        color: Colors.green,
                        size: 20,
                      )
                    : null,
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Text(
                  goal.message,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    decoration:
                        goal.completed ? TextDecoration.lineThrough : null,
                    color: goal.completed
                        ? theme.colorScheme.onSurface.withValues(alpha: 0.5)
                        : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressTracker(
    BuildContext context,
    EggGoalsProvider provider,
  ) {
    final theme = Theme.of(context);
    final progress = provider.getCompletionProgress();
    final completed = progress['completed'] ?? 0;
    final total = progress['total'] ?? 3;
    final percentage = total > 0 ? (completed / total) : 0.0;

    String message;
    if (completed == 0) {
      message = 'Get started on your goals!';
    } else if (completed == total) {
      message = 'Amazing! You completed all your goals! 🎉';
    } else {
      message = 'Great progress! Keep going!';
    }

    return Container(
      padding: AppInsets.page,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Progress bar
          ClipRRect(
            borderRadius: AppRadius.circularSm,
            child: LinearProgressIndicator(
              value: percentage,
              minHeight: 8,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(
                completed == total ? Colors.green : theme.colorScheme.primary,
              ),
            ),
          ),
          SizedBox(height: AppSpacing.md),
          // Progress text
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$completed / $total goals completed',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${(percentage * 100).toInt()}%',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.sm),
          // Encouraging message
          Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
