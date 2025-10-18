import 'package:flutter/material.dart';
import 'package:projectbrain/models/conversation.dart';

/// Reusable conversation list item for the drawer
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

    return ListTile(
      title: Text(
        conversation.title,
        overflow: TextOverflow.ellipsis,
      ),
      tileColor: isActive
          ? theme.colorScheme.primary.withValues(alpha: 0.1)
          : null,
      onTap: onTap,
    );
  }
}
