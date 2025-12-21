import 'package:flutter/material.dart';

/// Model for a navigation link
class NavigationLink {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const NavigationLink({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
}

/// Reusable widget that displays a list of navigation links
class LinkList extends StatelessWidget {
  final List<NavigationLink> links;
  final String? sectionTitle;
  final double spacing;

  const LinkList({
    super.key,
    required this.links,
    this.sectionTitle,
    this.spacing = 12.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (sectionTitle != null) ...[
          Text(
            sectionTitle!,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
        ],
        ...links.asMap().entries.map((entry) {
          final index = entry.key;
          final link = entry.value;
          return Column(
            children: [
              _buildLinkCard(
                context: context,
                icon: link.icon,
                title: link.title,
                subtitle: link.subtitle,
                onTap: link.onTap,
              ),
              if (index < links.length - 1) SizedBox(height: spacing),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildLinkCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return Card(
      elevation: 1,
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: theme.colorScheme.primary,
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
        ),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
      ),
    );
  }
}
