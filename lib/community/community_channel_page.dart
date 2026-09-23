import 'package:flutter/material.dart';
import 'package:projectbrain/core/di/injection_container.dart';
import 'package:projectbrain/helpers/themes/app_spacing.dart';
import 'package:projectbrain/helpers/themes/app_theme_extension.dart';
import 'package:projectbrain/models/community.dart';
import 'package:projectbrain/services/community_service.dart';

class CommunityChannelPage extends StatefulWidget {
  final String slug;

  const CommunityChannelPage({super.key, required this.slug});

  @override
  State<CommunityChannelPage> createState() => _CommunityChannelPageState();
}

class _CommunityChannelPageState extends State<CommunityChannelPage> {
  final _service = sl<CommunityService>();
  final _controller = TextEditingController();
  List<CommunityPost> _posts = [];
  String? _nextCursor;
  bool _loading = true;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _load({String? cursor, bool append = false}) async {
    if (!append) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final page = await _service.getPosts(widget.slug, cursor: cursor);
      if (!mounted) return;
      setState(() {
        _posts = append ? [..._posts, ...page.items] : page.items;
        _nextCursor = page.nextCursor;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _submit() async {
    final body = _controller.text.trim();
    if (body.isEmpty) return;
    setState(() => _submitting = true);
    try {
      await _service.createPost(widget.slug, body);
      _controller.clear();
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to post: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _toggleReaction(CommunityPost post) async {
    try {
      if (post.reactedByCurrentUser) {
        await _service.removeReaction(post.id);
      } else {
        await _service.addReaction(post.id);
      }
      setState(() {
        _posts = _posts
            .map(
              (p) => p.id == post.id
                  ? p.copyWith(
                      reactedByCurrentUser: !p.reactedByCurrentUser,
                      reactionCount: p.reactedByCurrentUser
                          ? (p.reactionCount - 1).clamp(0, 999999)
                          : p.reactionCount + 1,
                    )
                  : p,
            )
            .toList();
      });
    } catch (_) {}
  }

  Future<void> _delete(CommunityPost post) async {
    try {
      await _service.deletePost(post.id);
      setState(() => _posts = _posts.where((p) => p.id != post.id).toList());
    } catch (_) {}
  }

  Future<void> _report(CommunityPost post) async {
    final reasonController = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report post'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(hintText: 'Reason'),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, reasonController.text),
            child: const Text('Report'),
          ),
        ],
      ),
    );
    if (reason == null || reason.trim().isEmpty) return;
    try {
      await _service.reportPost(post.id, reason.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report submitted')),
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appTheme = context.appTheme;
    final title = widget.slug.replaceAll('-', ' ');

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _load(),
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  if (_loading)
                    const Center(child: CircularProgressIndicator()),
                  if (_error != null)
                    Text(_error!,
                        style: TextStyle(color: theme.colorScheme.error)),
                  ..._posts.map(
                    (post) => Container(
                      margin: const EdgeInsets.only(bottom: AppSpacing.md),
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: AppRadius.circularLg,
                        border: Border.all(color: appTheme.borderColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(post.authorDisplayName,
                              style: theme.textTheme.titleSmall),
                          Text(
                            post.createdAt.toLocal().toString(),
                            style: theme.textTheme.bodySmall,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(post.body),
                          const SizedBox(height: AppSpacing.sm),
                          Wrap(
                            spacing: AppSpacing.sm,
                            children: [
                              TextButton(
                                onPressed: () => _toggleReaction(post),
                                child: Text(
                                  '${post.reactedByCurrentUser ? 'Unlike' : 'Like'} (${post.reactionCount})',
                                ),
                              ),
                              TextButton(
                                onPressed: () => _report(post),
                                child: const Text('Report'),
                              ),
                              if (post.isOwnPost)
                                TextButton(
                                  onPressed: () => _delete(post),
                                  child: Text(
                                    'Delete',
                                    style: TextStyle(
                                      color: theme.colorScheme.error,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_nextCursor != null)
                    TextButton(
                      onPressed: () =>
                          _load(cursor: _nextCursor, append: true),
                      child: const Text('Load more'),
                    ),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      maxLength: 2000,
                      maxLines: 3,
                      minLines: 1,
                      decoration: const InputDecoration(
                        hintText: 'Share with the community…',
                        counterText: '',
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  IconButton.filled(
                    onPressed: _submitting ? null : _submit,
                    icon: _submitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
