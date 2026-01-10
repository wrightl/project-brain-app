import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:projectbrain/goals/egg_goals_provider.dart';

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
        child: SingleChildScrollView(
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
              const SizedBox(height: 32),

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
                  onPressed: goalsProvider.isLoading
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
    );
  }
}

