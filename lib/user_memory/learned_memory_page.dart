import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:projectbrain/helpers/themes/app_spacing.dart';
import 'package:projectbrain/helpers/themes/app_theme_extension.dart';
import 'package:projectbrain/widgets/ds/ds_widgets.dart';
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
  String? _pinningId;

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
    final appTheme = context.appTheme;
    return Scaffold(
      body: SafeArea(
        child: Consumer<UserMemoryProvider>(
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
                      const SizedBox(height: AppSpacing.lg),
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
                  Text('Learned memories', style: theme.textTheme.headlineSmall),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Facts and experiences the assistant has learned from your conversations.',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  if (provider.isEmpty)
                    DsSurfaceCard(
                      child: Text(
                        'No learned memories yet. As you chat, the assistant may remember helpful facts and past experiences.',
                        style: theme.textTheme.bodyMedium,
                      ),
                    )
                  else ...[
                    if (provider.facts.isNotEmpty) ...[
                      SectionHeader(title: 'Facts'),
                      const SizedBox(height: AppSpacing.md),
                      ...provider.facts.map(
                        (fact) => _MemoryTile(
                          icon: Icons.lightbulb_outline,
                          iconColor: appTheme.amber,
                          iconBackground: appTheme.amberSoft,
                          title: fact.content,
                          subtitle: fact.isPinned
                              ? '${fact.category} · Pinned'
                              : fact.category,
                          deleting: _deletingId == fact.id,
                          pinning: _pinningId == fact.id,
                          isPinned: fact.isPinned,
                          onTogglePin: () async {
                            setState(() => _pinningId = fact.id);
                            await context
                                .read<UserMemoryProvider>()
                                .togglePinFact(
                                  fact.id,
                                  pin: !fact.isPinned,
                                );
                            if (mounted) setState(() => _pinningId = null);
                          },
                          onDelete: () => _confirmDeleteFact(fact),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                    ],
                    if (provider.episodes.isNotEmpty) ...[
                      SectionHeader(title: 'Past experiences'),
                      const SizedBox(height: AppSpacing.md),
                      ...provider.episodes.map(
                        (episode) => _MemoryTile(
                          icon: Icons.history,
                          iconColor: appTheme.sky,
                          iconBackground: appTheme.skySoft,
                          title: episode.summary,
                          subtitle: episode.isPinned
                              ? 'Topic: ${episode.topic} · Outcome: ${episode.outcome} · Pinned'
                              : 'Topic: ${episode.topic} · Outcome: ${episode.outcome}',
                          deleting: _deletingId == episode.id,
                          pinning: _pinningId == episode.id,
                          isPinned: episode.isPinned,
                          onTogglePin: () async {
                            setState(() => _pinningId = episode.id);
                            await context
                                .read<UserMemoryProvider>()
                                .togglePinEpisode(
                                  episode.id,
                                  pin: !episode.isPinned,
                                );
                            if (mounted) setState(() => _pinningId = null);
                          },
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
      ),
    );
  }
}

class _MemoryTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final String subtitle;
  final bool deleting;
  final bool pinning;
  final bool isPinned;
  final VoidCallback onTogglePin;
  final VoidCallback onDelete;

  const _MemoryTile({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    required this.subtitle,
    required this.deleting,
    required this.pinning,
    required this.isPinned,
    required this.onTogglePin,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: DsSurfaceCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconBubble(
              icon: icon,
              color: iconColor,
              backgroundColor: iconBackground,
              size: 40,
              iconSize: 20,
              borderRadius: 12,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.bodyLarge),
                  const SizedBox(height: AppSpacing.micro),
                  Text(subtitle, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: pinning ? null : onTogglePin,
                  child: pinning
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(isPinned ? 'Unpin' : 'Pin'),
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
          ],
        ),
      ),
    );
  }
}
