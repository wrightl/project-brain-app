import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:projectbrain/authentication/auth_provider.dart';
import 'package:projectbrain/goals/egg_goals_provider.dart';
import 'package:projectbrain/journal/journal_provider.dart';
import 'package:projectbrain/strategies/strategies_localizations.dart';
import 'package:projectbrain/strategies/strategies_provider.dart';
import 'package:projectbrain/helpers/themes/app_spacing.dart';
import 'package:projectbrain/helpers/themes/app_theme_extension.dart';
import 'package:projectbrain/widgets/ds/ds_widgets.dart';
import 'package:projectbrain/widgets/ds/goal_row.dart';
import 'package:projectbrain/widgets/today_goal_progress_block.dart';
import 'package:provider/provider.dart';
import 'package:projectbrain/services/feature_flag_service.dart';
import 'package:projectbrain/core/di/injection_container.dart';

/// Home page of the application.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _showContent = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<JournalProvider>().loadStreakSummary();
      context.read<JournalProvider>().loadEntryCount();
      context.read<JournalProvider>().loadRecentEntries(count: 3);
      context.read<StrategiesProvider>().loadLibrary();
      context.read<EggGoalsProvider>().getTodaysGoals();
      context.read<EggGoalsProvider>().loadGoalStreakSummary();
      Future.delayed(const Duration(milliseconds: 80), () {
        if (mounted) setState(() => _showContent = true);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final firstName = authProvider.profile?.name.split(' ').first ?? 'there';
    final strategiesL10n = StrategiesLocalizations.of(context);

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
          child: AnimatedOpacity(
            opacity: _showContent ? 1 : 0,
            duration: const Duration(milliseconds: 250),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.xxl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HomeHeader(firstName: firstName),
                  const SizedBox(height: AppSpacing.xl),
                  Consumer2<EggGoalsProvider, JournalProvider>(
                    builder: (context, goalsProvider, journalProvider, _) {
                      final progress = goalsProvider.getCompletionProgress();
                      final completed = progress['completed'] ?? 0;
                      final total = progress['total'] ?? 3;
                      final goalStreak =
                          goalsProvider.goalStreakSummary?.currentStreak ?? 0;
                      final pct =
                          total > 0 ? (completed / total).clamp(0.0, 1.0) : 0.0;

                      return _HeroCard(
                        firstName: firstName,
                        completed: completed,
                        total: total > 0 ? total : 3,
                        streakDays: goalStreak,
                        progress: pct,
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _FeatureGrid(
                    strategiesLabel: strategiesL10n.copingStrategies,
                    strategiesSubtitle: strategiesL10n.getNewStrategies,
                  ),
                  if (sl<FeatureFlagService>().communityFeatureEnabled) ...[
                    const SizedBox(height: AppSpacing.md),
                    _CommunityEntryCard(),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                  Consumer<EggGoalsProvider>(
                    builder: (context, goalsProvider, _) {
                      final visibleGoals = goalsProvider.goals
                          .where((g) =>
                              g.message.isNotEmpty &&
                              g.message != 'No Egg Goal Set')
                          .take(2)
                          .toList();

                      if (visibleGoals.isEmpty) {
                        return TodayGoalProgressBlock(
                          completed: 0,
                          total: 3,
                          hasGoals: false,
                          onTap: () => context.go('/goals'),
                        );
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SectionHeader(
                            title: "Today's goals",
                            actionLabel: 'See all',
                            onAction: () => context.go('/goals'),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          ...visibleGoals.map(
                            (goal) => Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppSpacing.sm,
                              ),
                              child: GoalRow(
                                title: goal.message,
                                completed: goal.completed,
                                meta: 'Daily goal',
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CommunityEntryCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appTheme = context.appTheme;

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: AppRadius.circularLg,
      child: InkWell(
        onTap: () => context.push('/community'),
        borderRadius: AppRadius.circularLg,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: AppRadius.circularLg,
            border: Border.all(color: appTheme.borderColor),
          ),
          child: Row(
            children: [
              Icon(Icons.groups_outlined, color: appTheme.teal),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Community', style: theme.textTheme.titleMedium),
                    Text(
                      'Channels for wins, tips, and support — plus Skool.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: appTheme.borderColor),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.firstName});

  final String firstName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appTheme = context.appTheme;
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
            ? 'Good afternoon'
            : 'Good evening';

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(greeting, style: theme.textTheme.bodySmall),
              Text(
                firstName,
                style: theme.textTheme.headlineSmall,
              ),
            ],
          ),
        ),
        Semantics(
          button: true,
          label: 'Profile',
          child: InkWell(
            onTap: () => context.go('/user'),
            customBorder: const CircleBorder(),
            child: CircleAvatar(
              radius: 22,
              backgroundColor: appTheme.primarySoft,
              child: Text(
                firstName.isNotEmpty ? firstName[0].toUpperCase() : '?',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.firstName,
    required this.completed,
    required this.total,
    required this.streakDays,
    required this.progress,
  });

  final String firstName;
  final int completed;
  final int total;
  final int streakDays;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pctLabel = '${(progress * 100).round()}%';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: AppRadius.circularXl,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (streakDays > 0)
                  Row(
                    children: [
                      const Icon(Icons.local_fire_department,
                          color: Color(0xFFFFD79A), size: 16),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        '$streakDays day streak',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: const Color(0xFFFFD79A),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                if (streakDays > 0) const SizedBox(height: AppSpacing.sm),
                Text(
                  streakDays > 0
                      ? "You're on a roll, $firstName"
                      : "Ready when you are, $firstName",
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '$completed of $total goals done today',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 72,
            height: 72,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 6,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
                Text(
                  pctLabel,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureGrid extends StatelessWidget {
  const _FeatureGrid({
    required this.strategiesLabel,
    required this.strategiesSubtitle,
  });

  final String strategiesLabel;
  final String strategiesSubtitle;

  @override
  Widget build(BuildContext context) {
    final appTheme = context.appTheme;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: FeatureTile(
                icon: Icons.forum_outlined,
                title: 'Coaching',
                subtitle: 'Chat with your coach anytime.',
                backgroundColor: appTheme.tealSoft,
                iconColor: appTheme.teal,
                onTap: () => context.go('/network'),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: FeatureTile(
                icon: Icons.air,
                title: 'Coping',
                subtitle: 'Quick strategies for tough moments.',
                backgroundColor: appTheme.amberSoft,
                iconColor: appTheme.amber,
                onTap: () => context.go('/strategies/chat'),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: FeatureTile(
                icon: Icons.book_outlined,
                title: 'Journal',
                subtitle: 'Capture wins and reflections.',
                backgroundColor: appTheme.coralSoft,
                iconColor: appTheme.coral,
                onTap: () => context.go('/journal'),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: FeatureTile(
                icon: Icons.flag_outlined,
                title: 'Goals',
                subtitle: 'Small steps, every day.',
                backgroundColor: appTheme.greenSoft,
                iconColor: appTheme.green,
                onTap: () => context.go('/goals'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
