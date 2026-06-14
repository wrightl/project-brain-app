import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:projectbrain/core/logging/app_logger.dart';
import 'package:projectbrain/core/security/url_security.dart';
import 'package:projectbrain/models/citation.dart';
import 'package:projectbrain/models/chatmessage.dart';
import 'package:projectbrain/widgets/chat/typing_indicator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:projectbrain/helpers/themes/app_spacing.dart';

/// Reusable message bubble widget for displaying chat messages
class MessageBubble extends StatefulWidget {
  final ChatMessage message;

  const MessageBubble({
    super.key,
    required this.message,
  });

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  /// Cached citation-processed content so the regex only runs when the
  /// underlying content/citations change, not on every rebuild.
  late String _processedContent;

  @override
  void initState() {
    super.initState();
    _processedContent = _processCitationLinks(
      widget.message.content,
      widget.message.citations,
    );
  }

  @override
  void didUpdateWidget(covariant MessageBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.message.content != widget.message.content ||
        oldWidget.message.citations != widget.message.citations) {
      _processedContent = _processCitationLinks(
        widget.message.content,
        widget.message.citations,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final message = widget.message;
    final theme = Theme.of(context);
    final isUser = message.role == 'user';
    final isEmpty = message.content.isEmpty && !isUser;

    // Show typing indicator for empty assistant messages
    if (isEmpty) {
      return Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.all(AppSpacing.sm),
        child: Container(
          padding: AppInsets.card,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: AppRadius.circularSm,
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
          ? EdgeInsets.all(AppSpacing.sm).add(EdgeInsets.only(left: AppSpacing.s20))
          : EdgeInsets.all(AppSpacing.sm).add(EdgeInsets.only(right: AppSpacing.s20)),
      child: Container(
        padding: EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isUser
              ? theme.colorScheme.primary
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: AppRadius.circularSm,
        ),
        child: MarkdownBody(
          data: _processedContent,
          styleSheet: MarkdownStyleSheet(
            p: theme.textTheme.bodyMedium?.copyWith(
              color: isUser
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.onSurface,
            ),
            a: theme.textTheme.bodyMedium?.copyWith(
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

  /// Launch a URL in the browser.
  ///
  /// URLs originate from AI output, so only https links are allowed.
  Future<void> _launchUrl(String url) async {
    if (!UrlSecurity.isSafeExternalUrl(url)) {
      logWarning('[MessageBubble] Blocked unsafe link: $url');
      return;
    }
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
