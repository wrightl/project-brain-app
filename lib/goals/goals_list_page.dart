import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:projectbrain/goals/egg_goals_provider.dart';

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
                onRefresh: () =>
                    context.read<EggGoalsProvider>().syncFromAPI(),
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16.0),
                  itemCount: goalsProvider.goals.length,
                  itemBuilder: (context, index) {
                    final goal = goalsProvider.goals[index];
                    if (goal.message.isEmpty ||
                        goal.message == 'No Egg Goal Set') {
                      return const SizedBox.shrink();
                    }

                    return _buildGoalItem(
                        context, goal, index, goalsProvider);
                  },
                ),
              ),
            ),

            // Progress tracker at bottom
            _buildProgressTracker(context, goalsProvider),
          ],
        ),
      ),
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
      margin: const EdgeInsets.only(bottom: 12),
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
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
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
              const SizedBox(width: 16),
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
      padding: const EdgeInsets.all(24.0),
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
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: percentage,
              minHeight: 8,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(
                completed == total ? Colors.green : theme.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 12),
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
          const SizedBox(height: 8),
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
