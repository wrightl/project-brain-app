import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:projectbrain/widgets/link_list.dart';
import 'package:projectbrain/helpers/themes/app_spacing.dart';

/// Network page for connecting with coaches
class NetworkPage extends StatelessWidget {
  const NetworkPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Define the list of navigation links
    final links = [
      NavigationLink(
        icon: Icons.chat,
        title: 'Talk to a Coach',
        subtitle: 'Message and manage your connected coaches',
        onTap: () => context.go('/network/coaches'),
      ),
      NavigationLink(
        icon: Icons.location_on,
        title: 'Find a Nearby Coach',
        subtitle: 'Search for coaches by postcode, address, or location',
        onTap: () => context.go('/network/find'),
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppInsets.page,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Page title
              Text(
                'Network',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: AppSpacing.sm),
              Text(
                'Connect with coaches to get support and guidance.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              SizedBox(height: AppSpacing.xxl),

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
