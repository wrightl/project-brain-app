import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:projectbrain/core/di/injection_container.dart';
import 'package:projectbrain/goals/egg_goals_provider.dart';
import 'package:projectbrain/services/egg_goals_service.dart';

/// Page for entering/editing daily goals
class GoalEntryPage extends StatefulWidget {
  const GoalEntryPage({super.key});

  @override
  State<GoalEntryPage> createState() => _GoalEntryPageState();
}

class _GoalEntryPageState extends State<GoalEntryPage> {
  final List<TextEditingController> _controllers = [
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
  ];

  bool _suggestingGoals = false;

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final goalsProvider = Provider.of<EggGoalsProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Set Your Daily Goals'),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            final provider = context.read<EggGoalsProvider>();
            await provider.syncFromAPI();
            if (!mounted) return;
            final goals = await provider.getTodaysGoals();
            for (int i = 0; i < 3 && i < goals.length; i++) {
              _controllers[i].text = goals[i].message == 'No Egg Goal Set'
                  ? ''
                  : goals[i].message;
            }
            setState(() {});
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24.0),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'What would you like to accomplish today?',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Set up to 3 goals for today. You can mark them as complete as you finish them.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 16),

              OutlinedButton.icon(
                onPressed: (goalsProvider.isLoading || _suggestingGoals)
                    ? null
                    : () async {
                        setState(() => _suggestingGoals = true);
                        try {
                          final suggested =
                              await sl<EggGoalsService>().fetchGoalSuggestions();
                          if (!context.mounted) return;
                          if (suggested.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'No suggestions available right now. Try again later.',
                                ),
                              ),
                            );
                            return;
                          }
                          var si = 0;
                          for (var i = 0; i < 3 && si < suggested.length; i++) {
                            if (_controllers[i].text.trim().isEmpty) {
                              _controllers[i].text = suggested[si++];
                            }
                          }
                          setState(() {});
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Could not load suggestions: $e'),
                              ),
                            );
                          }
                        } finally {
                          if (mounted) {
                            setState(() => _suggestingGoals = false);
                          }
                        }
                      },
                icon: _suggestingGoals
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_awesome_outlined),
                label: Text(_suggestingGoals ? 'Suggesting…' : 'Suggest goals for today'),
              ),

              const SizedBox(height: 24),

              // Goal input fields
              for (int i = 0; i < 3; i++) ...[
                TextField(
                  controller: _controllers[i],
                  decoration: InputDecoration(
                    labelText: 'Goal ${i + 1}',
                    hintText: 'Enter your goal here...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.check_circle_outline),
                  ),
                  maxLines: 2,
                ),
                if (i < 2) const SizedBox(height: 16),
              ],

              const SizedBox(height: 32),

              // Save button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (goalsProvider.isLoading || _suggestingGoals)
                      ? null
                      : () async {
                          final goals = _controllers
                              .map((c) => c.text.trim())
                              .where((text) => text.isNotEmpty)
                              .toList();

                          if (goals.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please enter at least one goal'),
                              ),
                            );
                            return;
                          }

                          // Pad to 3 goals if needed
                          while (goals.length < 3) {
                            goals.add('');
                          }

                          await goalsProvider.setGoals(goals);
                          if (context.mounted) {
                            context.go('/goals/list');
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: goalsProvider.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          'Save Goals',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }
}

