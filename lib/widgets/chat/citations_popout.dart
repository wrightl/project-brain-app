import 'package:flutter/material.dart';
import 'package:projectbrain/core/logging/app_logger.dart';
import 'package:projectbrain/core/security/url_security.dart';
import 'package:projectbrain/models/citation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:projectbrain/helpers/themes/app_spacing.dart';

/// A collapsible popout widget that displays citations at the bottom of the chat
class CitationsPopout extends StatefulWidget {
  final List<Citation> citations;

  const CitationsPopout({
    super.key,
    required this.citations,
  });

  @override
  State<CitationsPopout> createState() => _CitationsPopoutState();
}

class _CitationsPopoutState extends State<CitationsPopout>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(CitationsPopout oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Auto-expand when new citations are added
    if (widget.citations.isNotEmpty && !_isExpanded) {
      _toggleExpanded();
    }
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  Future<void> _launchUrl(String url) async {
    if (!UrlSecurity.isSafeExternalUrl(url)) {
      logWarning('[CitationsPopout] Blocked unsafe link: $url');
      return;
    }
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.citations.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header bar
          InkWell(
            onTap: _toggleExpanded,
            child: Container(
              padding: AppInsets.card,
              child: Row(
                children: [
                  Icon(
                    Icons.library_books,
                    size: 20,
                    color: theme.colorScheme.onSurface,
                  ),
                  SizedBox(width: AppSpacing.sm),
                  Text(
                    'Citations (${widget.citations.length})',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: Icon(
                      Icons.keyboard_arrow_up,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Expandable content
          SizeTransition(
            sizeFactor: _expandAnimation,
            child: Container(
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: widget.citations.length,
                itemBuilder: (context, index) {
                  final citation = widget.citations[index];
                  return _CitationItem(
                    citation: citation,
                    index: index + 1,
                    onTap: () => _launchUrl(citation.url),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CitationItem extends StatelessWidget {
  final Citation citation;
  final int index;
  final VoidCallback onTap;

  const _CitationItem({
    required this.citation,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: AppInsets.card,
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(AppSpacing.xs),
              ),
              child: Center(
                child: Text(
                  '$index',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (citation.title != null && citation.title!.isNotEmpty)
                    Text(
                      citation.title!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (citation.description != null &&
                      citation.description!.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(top: AppSpacing.xs),
                      child: Text(
                        citation.description!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  Padding(
                    padding: EdgeInsets.only(top: AppSpacing.xs),
                    child: Text(
                      citation.url,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        decoration: TextDecoration.underline,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.open_in_new,
              size: 16,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

