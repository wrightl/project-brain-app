import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:projectbrain/authentication/auth_provider.dart';
import 'package:projectbrain/goals/egg_goals_provider.dart';
import 'package:projectbrain/goals/getting_started_page.dart';
import 'package:projectbrain/goals/goal_entry_page.dart';
import 'package:projectbrain/goals/goals_list_page.dart';

/// Main goals page that handles routing based on user state
class GoalsPage extends StatelessWidget {
  const GoalsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final goalsProvider = Provider.of<EggGoalsProvider>(context, listen: false);

    return FutureBuilder<bool>(
      future: _determineRoute(context, goalsProvider),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final hasEverSetGoals = snapshot.data ?? false;

        if (!hasEverSetGoals) {
          return const GettingStartedPage();
        }

        return FutureBuilder<bool>(
          future: goalsProvider.hasGoalsForToday(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final hasGoalsToday = snapshot.data ?? false;

            if (hasGoalsToday) {
              return const GoalsListPage();
            } else {
              return const GoalEntryPage();
            }
          },
        );
      },
    );
  }

  Future<bool> _determineRoute(
      BuildContext context, EggGoalsProvider provider) async {
    await provider.init();
    if (!context.mounted) return false;
    final isLoggedIn =
        Provider.of<AuthProvider>(context, listen: false).isLoggedIn;
    if (isLoggedIn) {
      await provider.syncFromAPI();
    }
    return await provider.hasEverSetGoals();
  }
}
