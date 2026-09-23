import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:projectbrain/core/di/injection_container.dart';
import 'package:projectbrain/helpers/themes/app_spacing.dart';
import 'package:projectbrain/helpers/themes/app_theme_extension.dart';
import 'package:projectbrain/models/community.dart';
import 'package:projectbrain/services/community_service.dart';

const _feedLimit = 20;

class CommunityHubPage extends StatefulWidget {
  const CommunityHubPage({super.key});

  @override
  State<CommunityHubPage> createState() => _CommunityHubPageState();
}

class _CommunityHubPageState extends State<CommunityHubPage> {
  final _service = sl<CommunityService>();
  final _scrollController = ScrollController();

  List<CommunityChannel> _channels = [];
  List<CommunityPost> _posts = [];
  String? _nextCursor;
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _load();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _service.getChannels(),
        _service.getLatestFeed(limit: _feedLimit),
      ]);
      if (!mounted) return;
      final channels = results[0] as List<CommunityChannel>;
      final feed = results[1] as CommunityPostsPage;
      setState(() {
        _channels = channels;
        _posts = feed.items;
        _nextCursor = feed.nextCursor;
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

  Future<void> _loadMore() async {
    final cursor = _nextCursor;
    if (cursor == null || _loadingMore || _loading) return;
    setState(() => _loadingMore = true);
    try {
      final feed = await _service.getLatestFeed(
        cursor: cursor,
        limit: _feedLimit,
      );
      if (!mounted) return;
      setState(() {
        final seen = _posts.map((p) => p.id).toSet();
        _posts = [
          ..._posts,
          ...feed.items.where((p) => !seen.contains(p.id)),
        ];
        _nextCursor = feed.nextCursor;
        _loadingMore = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingMore = false);
    }
  }

  String _preview(String body) {
    final trimmed = body.trim();
    if (trimmed.length <= 180) return trimmed;
    return '${trimmed.substring(0, 180).trimRight()}…';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appTheme = context.appTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Community')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Text(
              'Join the conversation across channels — share wins, tips, and support.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text('Latest', style: theme.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.md),
            if (_loading) const Center(child: CircularProgressIndicator()),
            if (_error != null)
              Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
            if (!_loading && _error == null && _posts.isEmpty)
              Text(
                'No posts yet. Be the first to share in a channel.',
                style: theme.textTheme.bodyMedium,
              ),
            ..._posts.map(
              (post) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Material(
                  color: theme.colorScheme.surface,
                  borderRadius: AppRadius.circularLg,
                  child: InkWell(
                    onTap: () =>
                        context.push('/community/${post.channelSlug}'),
                    borderRadius: AppRadius.circularLg,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        borderRadius: AppRadius.circularLg,
                        border: Border.all(color: appTheme.borderColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            post.authorDisplayName,
                            style: theme.textTheme.titleSmall,
                          ),
                          Text(
                            '#${post.channelSlug} · ${post.createdAt.toLocal()}',
                            style: theme.textTheme.bodySmall,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(_preview(post.body)),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            '${post.reactionCount} likes',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (_loadingMore)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Center(child: CircularProgressIndicator()),
              ),
            const SizedBox(height: AppSpacing.xl),
            Text('Channels', style: theme.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.md),
            ..._channels.map(
              (channel) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Material(
                  color: theme.colorScheme.surface,
                  borderRadius: AppRadius.circularLg,
                  child: InkWell(
                    onTap: () => context.push('/community/${channel.slug}'),
                    borderRadius: AppRadius.circularLg,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        borderRadius: AppRadius.circularLg,
                        border: Border.all(color: appTheme.borderColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(channel.name,
                              style: theme.textTheme.titleMedium),
                          if (channel.description != null) ...[
                            const SizedBox(height: AppSpacing.xs),
                            Text(channel.description!,
                                style: theme.textTheme.bodySmall),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
