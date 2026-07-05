import 'package:flutter/material.dart';
import 'package:projectbrain/helpers/themes/app_spacing.dart';
import 'package:projectbrain/helpers/themes/app_theme_extension.dart';

/// Floating capsule bottom navigation bar (ProjectBrain design system).
class CustomBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  const CustomBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  static const _destinations = [
    _NavDestination(
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
      label: 'Home',
    ),
    _NavDestination(
      icon: Icons.flag_outlined,
      selectedIcon: Icons.flag,
      label: 'Goals',
    ),
    _NavDestination(
      icon: Icons.assistant_outlined,
      selectedIcon: Icons.assistant,
      label: 'Chat',
    ),
    _NavDestination(
      icon: Icons.forum_outlined,
      selectedIcon: Icons.forum,
      label: 'Coach',
    ),
    _NavDestination(
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
      label: 'Profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final appTheme = context.appTheme;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.md,
        ),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.xs + 2),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: AppRadius.circularPill,
            border: Border.all(color: appTheme.borderColor),
            boxShadow: [
              BoxShadow(
                color: colorScheme.onSurface.withValues(alpha: 0.08),
                blurRadius: 24,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              for (var i = 0; i < _destinations.length; i++)
                Expanded(
                  child: _NavTab(
                    destination: _destinations[i],
                    isSelected: selectedIndex == i,
                    onTap: () => onDestinationSelected(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavDestination {
  const _NavDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

class _NavTab extends StatelessWidget {
  const _NavTab({
    required this.destination,
    required this.isSelected,
    required this.onTap,
  });

  final _NavDestination destination;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final appTheme = context.appTheme;
    final activeColor = colorScheme.primary;
    final inactiveColor = appTheme.textMuted;

    return Semantics(
      button: true,
      selected: isSelected,
      label: destination.label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.circularPill,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.sm,
              horizontal: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: isSelected ? appTheme.primarySoft : Colors.transparent,
              borderRadius: AppRadius.circularPill,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isSelected ? destination.selectedIcon : destination.icon,
                  size: 22,
                  color: isSelected ? activeColor : inactiveColor,
                ),
                const SizedBox(height: AppSpacing.xs),
                ExcludeSemantics(
                  child: Text(
                    destination.label,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontSize: 10,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? activeColor : inactiveColor,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
