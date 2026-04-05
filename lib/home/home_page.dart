import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:projectbrain/authentication/auth_provider.dart';
import 'package:projectbrain/goals/egg_goals_provider.dart';
import 'package:projectbrain/journal/journal_localizations.dart';
import 'package:projectbrain/journal/journal_provider.dart';
import 'package:projectbrain/strategies/strategies_localizations.dart';
import 'package:projectbrain/strategies/strategies_provider.dart';
import 'package:projectbrain/widgets/link_list.dart';
import 'package:projectbrain/widgets/streak_card.dart';
import 'package:projectbrain/widgets/today_goal_progress_block.dart';
import 'package:provider/provider.dart';

/// Home page of the application
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _showToday = false;
  bool _showLinks = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final journalProvider = context.read<JournalProvider>();
      journalProvider.loadStreakSummary();
      journalProvider.loadEntryCount();
      journalProvider.loadRecentEntries(count: 3);
      context.read<StrategiesProvider>().loadLibrary();
      context.read<EggGoalsProvider>().getTodaysGoals();
      context.read<EggGoalsProvider>().loadGoalStreakSummary();
      // Staggered entrance
      Future.delayed(const Duration(milliseconds: 50), () {
        if (mounted) setState(() => _showToday = true);
      });
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted) setState(() => _showLinks = true);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final name = authProvider.profile?.name ?? 'User';
    final theme = Theme.of(context);
    final l10n = JournalLocalizations.of(context);
    final strategiesL10n = StrategiesLocalizations.of(context);

    // Short list of high-value actions (3–5 items); rest moved to Profile
    final links = [
      NavigationLink(
        icon: Icons.check_circle,
        title: 'Goals',
        subtitle: 'Set and track your 3 daily goals',
        onTap: () => context.go('/goals'),
      ),
      NavigationLink(
        icon: Icons.book,
        title: l10n.journal,
        subtitle: 'Write and reflect with journal entries',
        onTap: () => context.go('/journal'),
      ),
      NavigationLink(
        icon: Icons.assistant,
        title: 'Chat',
        subtitle: 'Start a conversation with your AI assistant',
        onTap: () => context.go('/ai'),
      ),
      NavigationLink(
        icon: Icons.psychology,
        title: strategiesL10n.copingStrategies,
        subtitle: strategiesL10n.getNewStrategies,
        onTap: () => context.go('/strategies/chat'),
      ),
      NavigationLink(
        icon: Icons.person,
        title: 'Profile',
        subtitle: 'Account, resources, quizzes & more',
        onTap: () => context.go('/user'),
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            final goalsProvider = context.read<EggGoalsProvider>();
            final journalProvider = context.read<JournalProvider>();
            final strategiesProvider = context.read<StrategiesProvider>();
            if (authProvider.isLoggedIn) {
              await goalsProvider.syncFromAPI();
            }
            journalProvider.loadStreakSummary();
            journalProvider.loadEntryCount();
            journalProvider.loadRecentEntries(count: 3);
            strategiesProvider.loadLibrary();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // Welcome
                Text(
                  'Welcome, $name!',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Here’s your progress today.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 24),

                // Today block: goals + journal streak (entrance animation)
                AnimatedOpacity(
                  opacity: _showToday ? 1 : 0,
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOut,
                  child: AnimatedSlide(
                    offset: _showToday ? Offset.zero : const Offset(0, 0.05),
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOut,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Today',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Consumer<EggGoalsProvider>(
                          builder: (context, goalsProvider, _) {
                            final progress = goalsProvider.getCompletionProgress();
                            final completed = progress['completed'] ?? 0;
                            final total = progress['total'] ?? 3;
                            final hasGoals = goalsProvider.goals.any((g) =>
                                g.message.isNotEmpty &&
                                g.message != 'No Egg Goal Set');
                            return TodayGoalProgressBlock(
                              completed: completed,
                              total: total > 0 ? total : 3,
                              hasGoals: hasGoals,
                              onTap: () => context.go('/goals'),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        Consumer<JournalProvider>(
                          builder: (context, journalProvider, _) {
                            final streak = journalProvider.streakSummary;
                            if (streak == null) return const SizedBox.shrink();
                            return StreakCard(
                              title: l10n.journalStreak,
                              currentStreak: streak.currentStreak,
                              bestStreak: streak.longestStreak,
                              noStreakMessage: l10n.noStreakYet,
                              ctaLabel: 'Write today',
                              onCtaTap: () => context.go('/journal'),
                            );
                          },
                        ),
                        Consumer<EggGoalsProvider>(
                          builder: (context, goalsProvider, _) {
                            final summary = goalsProvider.goalStreakSummary;
                            if (summary == null) return const SizedBox.shrink();
                            return Column(
                              children: [
                                const SizedBox(height: 12),
                                StreakCard(
                                  title: 'Goal streak',
                                  currentStreak: summary.currentStreak,
                                  bestStreak: summary.longestStreak,
                                  ctaLabel: 'View goals',
                                  onCtaTap: () => context.go('/goals'),
                                ),
                              ],
                            );
                          },
                        ),
                        Consumer<JournalProvider>(
                          builder: (context, journalProvider, _) {
                            final recent = journalProvider.recentEntries;
                            if (recent.isEmpty) return const SizedBox.shrink();
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 12),
                                Text(
                                  l10n.recentEntries,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                ...recent.take(3).map((e) => ListTile(
                                      title: Text(
                                        e.summary ?? e.content,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      trailing: const Icon(Icons.chevron_right),
                                      onTap: () =>
                                          context.go('/journal/${e.id}'),
                                    )),
                                TextButton(
                                  onPressed: () => context.go('/journal'),
                                  child: Text(l10n.seeAll),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Quick links (short list, entrance animation)
                AnimatedOpacity(
                  opacity: _showLinks ? 1 : 0,
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOut,
                  child: AnimatedSlide(
                    offset: _showLinks ? Offset.zero : const Offset(0, 0.05),
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOut,
                    child: LinkList(
                      links: links,
                      sectionTitle: 'Quick links',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/goals'),
        icon: const Icon(Icons.check_circle),
        label: const Text('Goals'),
      ),
    );
  }
}
