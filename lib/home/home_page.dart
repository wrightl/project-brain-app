import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:projectbrain/authentication/auth_provider.dart';
import 'package:projectbrain/widgets/link_list.dart';
import 'package:provider/provider.dart';

/// Home page of the application
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final name = authProvider.profile?.name ?? 'User';
    final theme = Theme.of(context);

    // Define the list of navigation links
    final links = [
      NavigationLink(
        icon: Icons.person,
        title: 'User',
        subtitle: 'Manage your account and resources',
        onTap: () => context.go('/user'),
      ),
      NavigationLink(
        icon: Icons.assistant,
        title: 'Chat',
        subtitle: 'Start a conversation with your AI assistant',
        onTap: () => context.go('/ai'),
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
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Welcome message
              Text(
                'Welcome, $name!',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Get started by exploring the different areas of the app.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 32),

              // Quick links section using reusable component
              LinkList(
                links: links,
                sectionTitle: 'Quick Links',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
