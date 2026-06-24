import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:projectbrain/helpers/themes/app_spacing.dart';
import 'package:projectbrain/models/user_memory/user_episode_memory.dart';
import 'package:projectbrain/models/user_memory/user_fact_memory.dart';
import 'package:projectbrain/user_memory/user_memory_provider.dart';

/// Screen listing learned facts and episodes with delete support.
class LearnedMemoryPage extends StatefulWidget {
  const LearnedMemoryPage({super.key});

  @override
  State<LearnedMemoryPage> createState() => _LearnedMemoryPageState();
}

class _LearnedMemoryPageState extends State<LearnedMemoryPage> {
  String? _deletingId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserMemoryProvider>().loadMemories();
    });
  }

  Future<void> _confirmDeleteFact(UserFactMemory fact) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove memory?'),
        content: const Text(
          'Remove this learned fact? The assistant will no longer use it in future chats.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _deletingId = fact.id);
    await context.read<UserMemoryProvider>().deleteFact(fact.id);
    if (mounted) setState(() => _deletingId = null);
  }

  Future<void> _confirmDeleteEpisode(UserEpisodeMemory episode) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove memory?'),
        content: const Text(
          'Remove this past experience? The assistant will no longer use it in future chats.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _deletingId = episode.id);
    await context.read<UserMemoryProvider>().deleteEpisode(episode.id);
    if (mounted) setState(() => _deletingId = null);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Learned memories'),
      ),
      body: Consumer<UserMemoryProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.errorMessage != null && provider.isEmpty) {
            return Center(
              child: Padding(
                padding: AppInsets.page,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      provider.errorMessage!,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge,
                    ),
                    SizedBox(height: AppSpacing.lg),
                    FilledButton(
                      onPressed: () => provider.loadMemories(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          return SingleChildScrollView(
            padding: AppInsets.page,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Facts and experiences the assistant has learned from your conversations. Only active memories are shown.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                SizedBox(height: AppSpacing.xl),
                if (provider.isEmpty)
                  Text(
                    'No learned memories yet. As you chat, the assistant may remember helpful facts and past experiences across conversations.',
                    style: theme.textTheme.bodyMedium,
                  )
                else ...[
                  if (provider.facts.isNotEmpty) ...[
                    Text(
                      'Facts',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: AppSpacing.sm),
                    ...provider.facts.map(
                      (fact) => _MemoryTile(
                        title: fact.content,
                        subtitle: fact.category,
                        deleting: _deletingId == fact.id,
                        onDelete: () => _confirmDeleteFact(fact),
                      ),
                    ),
                    SizedBox(height: AppSpacing.xl),
                  ],
                  if (provider.episodes.isNotEmpty) ...[
                    Text(
                      'Past experiences',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: AppSpacing.sm),
                    ...provider.episodes.map(
                      (episode) => _MemoryTile(
                        title: episode.summary,
                        subtitle:
                            'Topic: ${episode.topic} · Outcome: ${episode.outcome}',
                        deleting: _deletingId == episode.id,
                        onDelete: () => _confirmDeleteEpisode(episode),
                      ),
                    ),
                  ],
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MemoryTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool deleting;
  final VoidCallback onDelete;

  const _MemoryTile({
    required this.title,
    required this.subtitle,
    required this.deleting,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: AppInsets.card,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.bodyLarge),
                  SizedBox(height: AppSpacing.xs),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: deleting ? null : onDelete,
              child: deleting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      'Remove',
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
