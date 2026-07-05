import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:projectbrain/authentication/auth_provider.dart';
import 'package:projectbrain/goals/egg_goals_provider.dart';
import 'package:projectbrain/helpers/themes/app_spacing.dart';
import 'package:projectbrain/helpers/themes/app_theme_extension.dart';
import 'package:projectbrain/journal/journal_provider.dart';
import 'package:projectbrain/widgets/ds/ds_widgets.dart';
import 'package:projectbrain/widgets/link_list.dart';
import 'package:provider/provider.dart';

/// Profile hub with identity, stats, and navigation links.
class UserPage extends StatefulWidget {
  const UserPage({super.key});

  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EggGoalsProvider>().loadGoalStreakSummary();
      context.read<JournalProvider>().loadStreakSummary();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appTheme = context.appTheme;
    final authProvider = context.watch<AuthProvider>();
    final profile = authProvider.profile;
    final displayName = profile?.name ?? 'Your profile';
    final email = profile?.email ?? '';
    final picture = profile?.picture;
    final hasPicture = picture != null && picture.isNotEmpty;

    final todayLinks = [
      NavigationLink(
        icon: Icons.check_circle,
        title: 'Daily Goals',
        subtitle: 'Set and track your 3 daily goals',
        iconColor: appTheme.green,
        iconBackgroundColor: appTheme.greenSoft,
        onTap: () => context.go('/goals'),
      ),
      NavigationLink(
        icon: Icons.auto_stories_outlined,
        title: 'Journal',
        subtitle: 'Reflect and track your streak',
        iconColor: appTheme.coral,
        iconBackgroundColor: appTheme.coralSoft,
        onTap: () => context.go('/journal'),
      ),
    ];
    final accountLinks = [
      NavigationLink(
        icon: Icons.psychology_outlined,
        title: 'Learned memories',
        subtitle: 'Facts and experiences from your chats',
        iconColor: appTheme.sky,
        iconBackgroundColor: appTheme.skySoft,
        onTap: () => context.go('/learned-memories'),
      ),
      NavigationLink(
        icon: Icons.person,
        title: 'Profile settings',
        subtitle: 'View and manage your profile settings',
        iconColor: theme.colorScheme.primary,
        iconBackgroundColor: appTheme.primarySoft,
        onTap: () => context.go('/profile'),
      ),
      NavigationLink(
        icon: Icons.folder,
        title: 'Resources',
        subtitle: 'Manage your files and resources',
        iconColor: appTheme.amber,
        iconBackgroundColor: appTheme.amberSoft,
        onTap: () => context.go('/resources'),
      ),
      NavigationLink(
        icon: Icons.mic,
        title: 'Voice Notes',
        subtitle: 'Record and manage your voice notes',
        iconColor: appTheme.teal,
        iconBackgroundColor: appTheme.tealSoft,
        onTap: () => context.go('/voicenotes'),
      ),
      NavigationLink(
        icon: Icons.quiz,
        title: 'Quizzes',
        subtitle: 'Take quizzes to identify neurodiverse traits',
        iconColor: appTheme.sky,
        iconBackgroundColor: appTheme.skySoft,
        onTap: () => context.go('/quizzes'),
      ),
      NavigationLink(
        icon: Icons.people,
        title: 'Network',
        subtitle: 'Connect with coaches for support',
        iconColor: appTheme.teal,
        iconBackgroundColor: appTheme.tealSoft,
        onTap: () => context.go('/network'),
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppInsets.page,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Profile', style: theme.textTheme.headlineSmall),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Manage your account and resources.',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.xl),
              DsSurfaceCard(
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: appTheme.primarySoft,
                      backgroundImage: hasPicture
                          ? CachedNetworkImageProvider(picture)
                          : null,
                      child: hasPicture
                          ? null
                          : Text(
                              displayName.isNotEmpty
                                  ? displayName[0].toUpperCase()
                                  : '?',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.primary,
                              ),
                            ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(displayName, style: theme.textTheme.titleMedium),
                          if (email.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.micro),
                            Text(
                              email,
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => context.go('/profile'),
                      style: IconButton.styleFrom(
                        backgroundColor: appTheme.primarySoft,
                      ),
                      icon: Icon(
                        Icons.edit_outlined,
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Consumer2<EggGoalsProvider, JournalProvider>(
                builder: (context, goalsProvider, journalProvider, _) {
                  final goalStreak =
                      goalsProvider.goalStreakSummary?.currentStreak ?? 0;
                  final journalStreak =
                      journalProvider.streakSummary?.currentStreak ?? 0;

                  return Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          label: 'Goal streak',
                          value: '$goalStreak',
                          unit: goalStreak == 1 ? 'day' : 'days',
                          icon: Icons.local_fire_department,
                          color: appTheme.amber,
                          backgroundColor: appTheme.amberSoft,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: _StatCard(
                          label: 'Journal streak',
                          value: '$journalStreak',
                          unit: journalStreak == 1 ? 'day' : 'days',
                          icon: Icons.auto_stories_outlined,
                          color: appTheme.coral,
                          backgroundColor: appTheme.coralSoft,
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: AppSpacing.xxl),
              LinkList(links: todayLinks, sectionTitle: 'Today'),
              const SizedBox(height: AppSpacing.xl),
              LinkList(links: accountLinks, sectionTitle: 'Account & tools'),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
    required this.backgroundColor,
  });

  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DsSurfaceCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconBubble(
            icon: icon,
            color: color,
            backgroundColor: backgroundColor,
            size: 36,
            iconSize: 18,
            borderRadius: 10,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(label, style: theme.textTheme.labelSmall),
          const SizedBox(height: AppSpacing.micro),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(unit, style: theme.textTheme.labelSmall),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
