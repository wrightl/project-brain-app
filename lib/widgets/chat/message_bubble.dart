import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:projectbrain/models/citation.dart';
import 'package:projectbrain/models/chatmessage.dart';
import 'package:projectbrain/widgets/chat/typing_indicator.dart';
import 'package:url_launcher/url_launcher.dart';

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
          data: _processCitationLinks(message.content, message.citations),
          styleSheet: MarkdownStyleSheet(
            p: TextStyle(
              color: isUser
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.onSurface,
            ),
            a: TextStyle(
              color: isUser
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.primary,
              decoration: TextDecoration.underline,
            ),
          ),
          onTapLink: (text, href, title) {
            if (href != null) {
              _launchUrl(href);
            }
          },
        ),
      ),
    );
  }

  /// Process citation references [ 1 ] and convert them to markdown links
  String _processCitationLinks(String content, List<Citation> citations) {
    if (citations.isEmpty) {
      return content;
    }

    // Convert citation references [ 1 ], [ 2 ], etc. to markdown links
    final regex = RegExp(r'\[\s*(\d+)\s*\]');
    return content.replaceAllMapped(regex, (match) {
      final citationIndex = int.tryParse(match.group(1) ?? '');
      if (citationIndex != null && 
          citationIndex > 0 && 
          citationIndex <= citations.length) {
        final citation = citations[citationIndex - 1];
        final url = citation.url;
        if (url.isNotEmpty) {
          return '[[${match.group(0)}]]($url)';
        }
      }
      return match.group(0) ?? '';
    });
  }

  /// Launch a URL in the browser
  Future<void> _launchUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
