import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:projectbrain/models/chatmessage.dart';
import 'package:projectbrain/widgets/chat/typing_indicator.dart';

/// Reusable message bubble widget for displaying chat messages
class MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const MessageBubble({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = message.role == 'user';
    final isEmpty = message.content.isEmpty && !isUser;

    // Show typing indicator for empty assistant messages
    if (isEmpty) {
      return Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.all(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: TypingIndicator(
            dotColor: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return Container(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      padding: isUser
          ? const EdgeInsets.all(8).add(const EdgeInsets.only(left: 20))
          : const EdgeInsets.all(8).add(const EdgeInsets.only(right: 20)),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUser
              ? theme.colorScheme.primary
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: MarkdownBody(
          data: message.content,
          styleSheet: MarkdownStyleSheet(
            p: TextStyle(
              color: isUser
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}
