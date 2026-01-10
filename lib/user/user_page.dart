import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:projectbrain/widgets/link_list.dart';

/// User page that provides navigation to user-related sections
class UserPage extends StatelessWidget {
  const UserPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Define the list of navigation links
    final links = [
      NavigationLink(
        icon: Icons.check_circle,
        title: 'Daily Goals',
        subtitle: 'Set and track your 3 daily goals',
        onTap: () => context.go('/goals'),
      ),
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
    ];

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Page title
              Text(
                'User',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Manage your account and resources.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 32),

              // Links list using reusable component
              LinkList(
                links: links,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
