import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:projectbrain/widgets/link_list.dart';
import 'package:projectbrain/helpers/themes/app_spacing.dart';

/// User page that provides navigation to user-related sections
class UserPage extends StatelessWidget {
  const UserPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final todayLinks = [
      NavigationLink(
        icon: Icons.check_circle,
        title: 'Daily Goals',
        subtitle: 'Set and track your 3 daily goals',
        onTap: () => context.go('/goals'),
      ),
    ];
    final accountLinks = [
      NavigationLink(
        icon: Icons.person,
        title: 'Profile',
        subtitle: 'View and manage your profile settings',
        onTap: () => context.go('/profile'),
      ),
      NavigationLink(
        icon: Icons.folder,
        title: 'Resources',
        subtitle: 'Manage your files and resources',
        onTap: () => context.go('/resources'),
      ),
      NavigationLink(
        icon: Icons.mic,
        title: 'Voice Notes',
        subtitle: 'Record and manage your voice notes',
        onTap: () => context.go('/voicenotes'),
      ),
      NavigationLink(
        icon: Icons.quiz,
        title: 'Quizzes',
        subtitle: 'Take quizzes to identify neurodiverse traits',
        onTap: () => context.go('/quizzes'),
      ),
      NavigationLink(
        icon: Icons.people,
        title: 'Network',
        subtitle: 'Connect with coaches for support',
        onTap: () => context.go('/network'),
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppInsets.page,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Profile',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: AppSpacing.sm),
              Text(
                'Manage your account and resources.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              SizedBox(height: AppSpacing.xxl),

              LinkList(links: todayLinks, sectionTitle: 'Today'),
              SizedBox(height: AppSpacing.xl),
              LinkList(links: accountLinks, sectionTitle: 'Account & tools'),
            ],
          ),
        ),
      ),
    );
  }
}
