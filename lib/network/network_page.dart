import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:projectbrain/helpers/themes/app_spacing.dart';
import 'package:projectbrain/helpers/themes/app_theme_extension.dart';
import 'package:projectbrain/widgets/link_list.dart';

/// Network page for connecting with coaches.
class NetworkPage extends StatelessWidget {
  const NetworkPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appTheme = context.appTheme;

    final links = [
      NavigationLink(
        icon: Icons.chat_bubble_outline,
        title: 'Talk to a Coach',
        subtitle: 'Message and manage your connected coaches',
        iconColor: appTheme.teal,
        iconBackgroundColor: appTheme.tealSoft,
        onTap: () => context.go('/network/coaches'),
      ),
      NavigationLink(
        icon: Icons.location_on_outlined,
        title: 'Find a Nearby Coach',
        subtitle: 'Search for coaches by postcode, address, or location',
        iconColor: appTheme.sky,
        iconBackgroundColor: appTheme.skySoft,
        onTap: () => context.go('/network/find'),
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppInsets.page,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Coach', style: theme.textTheme.headlineSmall),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Connect with coaches to get support and guidance.',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.xxl),
              LinkList(links: links),
            ],
          ),
        ),
      ),
    );
  }
}
