import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:projectbrain/journal/journal_provider.dart';
import 'package:projectbrain/journal/journal_localizations.dart';
import 'package:projectbrain/models/journal/journal_entry.dart';
import 'package:intl/intl.dart';
import 'package:projectbrain/helpers/themes/app_spacing.dart';
import 'package:projectbrain/helpers/themes/app_theme_extension.dart';
import 'package:projectbrain/widgets/ds/ds_widgets.dart';

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
    final appTheme = context.appTheme;
    final l10n = JournalLocalizations.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(l10n.journal, style: theme.textTheme.headlineSmall),
                  FilledButton(
                    onPressed: () => context.push('/journal/new'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(44, 44),
                      padding: EdgeInsets.zero,
                      shape: const CircleBorder(),
                    ),
                    child: const Icon(Icons.add, size: 22),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Consumer<JournalProvider>(
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
                          const SizedBox(height: AppSpacing.lg),
                          FilledButton(
                            onPressed: () => provider.refresh(),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }
                  if (provider.items.isEmpty) {
                    return RefreshIndicator(
                      onRefresh: () => provider.refresh(),
                      child: ListView(
                        controller: _scrollController,
                        padding: AppInsets.page,
                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.15,
                          ),
                          Center(
                            child: Container(
                              width: 140,
                              height: 140,
                              decoration: BoxDecoration(
                                color: appTheme.coralSoft,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.menu_book_outlined,
                                size: 56,
                                color: appTheme.coral,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          Text(
                            "No entries yet — and that's fine",
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'One sentence counts. Start with today\'s win, worry, or random thought.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall,
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          FilledButton.icon(
                            onPressed: () => context.push('/journal/new'),
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            label: const Text('Write your first entry'),
                          ),
                        ],
                      ),
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () => provider.refresh(),
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        0,
                        AppSpacing.lg,
                        AppSpacing.xxl,
                      ),
                      itemCount: provider.items.length +
                          (provider.hasNextPage ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index >= provider.items.length) {
                          return const Padding(
                            padding: AppInsets.screen,
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: _JournalListItem(entry: provider.items[index]),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _JournalListItem extends StatelessWidget {
  const _JournalListItem({required this.entry});

  final JournalEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appTheme = context.appTheme;
    final preview = entry.summary ?? entry.content;
    final displayText =
        preview.length > 120 ? '${preview.substring(0, 120)}...' : preview;
    final dateStr =
        DateFormat('EEE d MMM').format(entry.createdAt).toUpperCase();
    final titleLine = preview.split('\n').first;
    final moodTag = entry.systemTags?.isNotEmpty == true
        ? entry.systemTags!.first.name
        : (entry.tags?.isNotEmpty == true ? entry.tags!.first.name : null);

    return DsSurfaceCard(
      onTap: () => context.push('/journal/${entry.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                dateStr,
                style: theme.textTheme.labelSmall?.copyWith(
                  letterSpacing: 1,
                  color: appTheme.textMuted,
                ),
              ),
              if (moodTag != null)
                AccentTag(
                  label: moodTag,
                  color: appTheme.coral,
                  backgroundColor: appTheme.coralSoft,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            titleLine.length > 60
                ? '${titleLine.substring(0, 60)}…'
                : titleLine,
            style: theme.textTheme.titleSmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            displayText,
            style: theme.textTheme.bodySmall,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
