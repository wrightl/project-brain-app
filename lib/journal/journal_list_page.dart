import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:projectbrain/journal/journal_provider.dart';
import 'package:projectbrain/journal/journal_localizations.dart';
import 'package:projectbrain/models/journal/journal_entry.dart';
import 'package:intl/intl.dart';
import 'package:projectbrain/helpers/themes/app_spacing.dart';

/// Journal list screen with pagination, pull-to-refresh, and FAB.
class JournalListPage extends StatefulWidget {
  const JournalListPage({super.key});

  @override
  State<JournalListPage> createState() => _JournalListPageState();
}

class _JournalListPageState extends State<JournalListPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<JournalProvider>().refresh();
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final provider = context.read<JournalProvider>();
    if (!provider.hasNextPage || provider.isLoadingMore) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 200) {
      provider.loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = JournalLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.journal),
      ),
      body: Consumer<JournalProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.items.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.errorMessage != null && provider.items.isEmpty) {
            return Center(
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
                    onPressed: () => provider.refresh(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          if (provider.items.isEmpty) {
            // Successful fetch with no entries: show a friendly empty state
            // (still scrollable so pull-to-refresh works).
            return RefreshIndicator(
              onRefresh: () => provider.refresh(),
              child: ListView(
                controller: _scrollController,
                padding: AppInsets.page,
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                  Icon(
                    Icons.menu_book_outlined,
                    size: 64,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  SizedBox(height: AppSpacing.lg),
                  Text(
                    'No journal entries yet',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium,
                  ),
                  SizedBox(height: AppSpacing.sm),
                  Text(
                    'Tap the button below to write your first entry.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () => provider.refresh(),
            child: ListView.builder(
              controller: _scrollController,
              padding: AppInsets.screen,
              itemCount: provider.items.length + (provider.hasNextPage ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= provider.items.length) {
                  return const Padding(
                    padding: AppInsets.screen,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final entry = provider.items[index];
                return _JournalListItem(entry: entry);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/journal/new'),
        icon: const Icon(Icons.add),
        label: Text(l10n.newEntry),
      ),
    );
  }
}

class _JournalListItem extends StatelessWidget {
  final JournalEntry entry;

  const _JournalListItem({required this.entry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final preview = entry.summary ?? entry.content;
    final displayText = preview.length > 100 ? '${preview.substring(0, 100)}...' : preview;
    final dateStr = DateFormat.yMMMd().add_Hm().format(entry.createdAt);

    return Card(
      margin: AppInsets.listItemBottom,
      child: InkWell(
        onTap: () => context.push('/journal/${entry.id}'),
        borderRadius: AppRadius.circularMd,
        child: Padding(
          padding: AppInsets.screen,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                displayText,
                style: theme.textTheme.bodyMedium,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: AppSpacing.sm),
              Text(
                dateStr,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              if ((entry.tags?.isNotEmpty ?? false) ||
                  (entry.systemTags?.isNotEmpty ?? false)) ...[
                SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.s6,
                  runSpacing: AppSpacing.xs,
                  children: [
                    ...?entry.tags?.map((t) => Chip(
                          label: Text(t.name),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        )),
                    ...?entry.systemTags?.map((t) => Chip(
                          label: Text(t.name),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        )),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
