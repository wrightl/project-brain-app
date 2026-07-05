import 'package:flutter/material.dart';
import 'package:projectbrain/helpers/themes/app_spacing.dart';
import 'package:projectbrain/helpers/themes/app_theme_extension.dart';
import 'package:projectbrain/models/conversation.dart';
import 'package:projectbrain/widgets/ds/ds_widgets.dart';

/// Reusable conversation list item for the drawer.
class ConversationListItem extends StatelessWidget {
  final Conversation conversation;
  final bool isActive;
  final VoidCallback onTap;

  const ConversationListItem({
    super.key,
    required this.conversation,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appTheme = context.appTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.micro,
      ),
      child: Material(
        color: isActive ? appTheme.primarySoft : Colors.transparent,
        borderRadius: AppRadius.circularLg,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.circularLg,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: [
                IconBubble(
                  icon: Icons.chat_bubble_outline,
                  color:
                      isActive ? theme.colorScheme.primary : appTheme.textMuted,
                  backgroundColor: isActive
                      ? theme.colorScheme.surface
                      : appTheme.borderColor.withValues(alpha: 0.35),
                  size: 36,
                  iconSize: 18,
                  borderRadius: 10,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    conversation.title,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                      color: isActive
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface,
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
