import 'package:flutter/material.dart';
import 'package:projectbrain/helpers/themes/app_spacing.dart';
import 'package:projectbrain/helpers/themes/app_theme_extension.dart';
import 'package:projectbrain/widgets/ds/ds_widgets.dart';

/// Model for a navigation link
class NavigationLink {
  const NavigationLink({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.iconColor,
    this.iconBackgroundColor,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? iconBackgroundColor;
}

/// Reusable widget that displays a list of navigation links.
class LinkList extends StatelessWidget {
  const LinkList({
    super.key,
    required this.links,
    this.sectionTitle,
    this.spacing = AppSpacing.md,
  });

  final List<NavigationLink> links;
  final String? sectionTitle;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (sectionTitle != null) ...[
          SectionHeader(title: sectionTitle!),
          const SizedBox(height: AppSpacing.lg),
        ],
        ...links.asMap().entries.map((entry) {
          final index = entry.key;
          final link = entry.value;
          return Column(
            children: [
              _LinkRow(link: link),
              if (index < links.length - 1) SizedBox(height: spacing),
            ],
          );
        }),
      ],
    );
  }
}

class _LinkRow extends StatelessWidget {
  const _LinkRow({required this.link});

  final NavigationLink link;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appTheme = context.appTheme;
    final iconColor = link.iconColor ?? theme.colorScheme.primary;
    final iconBg = link.iconBackgroundColor ?? appTheme.primarySoft;

    return DsSurfaceCard(
      onTap: link.onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          IconBubble(
            icon: link.icon,
            color: iconColor,
            backgroundColor: iconBg,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  link.title,
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: AppSpacing.micro),
                Text(
                  link.subtitle,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: appTheme.textMuted, size: 20),
        ],
      ),
    );
  }
}
