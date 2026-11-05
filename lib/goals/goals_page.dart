import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:projectbrain/authentication/auth_provider.dart';
import 'package:projectbrain/goals/egg_goals_provider.dart';
import 'package:projectbrain/goals/getting_started_page.dart';
import 'package:projectbrain/goals/goal_entry_page.dart';
import 'package:projectbrain/goals/goals_list_page.dart';

enum _GoalsRoute { gettingStarted, list, entry }

/// Main goals page that handles routing based on user state
class GoalsPage extends StatefulWidget {
  const GoalsPage({super.key});

  @override
  State<GoalsPage> createState() => _GoalsPageState();
}

class _GoalsPageState extends State<GoalsPage> {
  // Created once: building it in build() re-synced with the API (and showed
  // two spinners in a row) on every rebuild, e.g. a theme change.
  late final Future<_GoalsRoute> _route;

  @override
  void initState() {
    super.initState();
    _route = _determineRoute();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_GoalsRoute>(
      future: _route,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        switch (snapshot.data ?? _GoalsRoute.gettingStarted) {
          case _GoalsRoute.gettingStarted:
            return const GettingStartedPage();
          case _GoalsRoute.list:
            return const GoalsListPage();
          case _GoalsRoute.entry:
            return const GoalEntryPage();
        }
      },
    );
  }

  Future<_GoalsRoute> _determineRoute() async {
    final provider = context.read<EggGoalsProvider>();
    final isLoggedIn = context.read<AuthProvider>().isLoggedIn;
    await provider.init();
    if (isLoggedIn) {
      await provider.syncFromAPI();
    }
    if (!await provider.hasEverSetGoals()) return _GoalsRoute.gettingStarted;
    return await provider.hasGoalsForToday()
        ? _GoalsRoute.list
        : _GoalsRoute.entry;
  }
}
