import 'package:flutter/material.dart';
import 'package:projectbrain/helpers/themes/app_spacing.dart';

/// Custom bottom navigation bar with outline icons for inactive items
/// and filled icons for active items, with a top border indicator
class CustomBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onDestinationSelected;

  const CustomBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          height: kBottomNavigationBarHeight,
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                context: context,
                index: 0,
                icon: Icons.home_outlined,
                selectedIcon: Icons.home,
                label: 'Home',
                colorScheme: colorScheme,
              ),
              _buildNavItem(
                context: context,
                index: 1,
                icon: Icons.assistant_outlined,
                selectedIcon: Icons.assistant,
                label: 'Chat',
                colorScheme: colorScheme,
              ),
              _buildNavItem(
                context: context,
                index: 2,
                icon: Icons.people_outline,
                selectedIcon: Icons.people,
                label: 'Network',
                colorScheme: colorScheme,
              ),
              _buildNavItem(
                context: context,
                index: 3,
                icon: Icons.person_outline,
                selectedIcon: Icons.person,
                label: 'Profile',
                colorScheme: colorScheme,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required int index,
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    required ColorScheme colorScheme,
  }) {
    final isSelected = selectedIndex == index;
    final theme = Theme.of(context);

    return Expanded(
      child: Semantics(
        button: true,
        selected: isSelected,
        label: label,
        child: GestureDetector(
          onTap: () => onDestinationSelected(index),
          behavior: HitTestBehavior.opaque,
          child: Container(
            // Ensure the tap target spans the full nav height (>= 48dp).
            constraints: const BoxConstraints(minHeight: 48),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: isSelected ? colorScheme.primary : Colors.transparent,
                  width: 3.0,
                ),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isSelected ? selectedIcon : icon,
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.onSurface.withValues(alpha: 0.6),
                  size: 24,
                ),
                SizedBox(height: AppSpacing.xs),
                // ExcludeSemantics: the label is already announced via the
                // Semantics wrapper above; avoid duplicate read-out.
                ExcludeSemantics(
                  child: Text(
                    label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.onSurface.withValues(alpha: 0.6),
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
