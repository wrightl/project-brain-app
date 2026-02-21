import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:projectbrain/journal/journal_provider.dart';
import 'package:projectbrain/journal/journal_localizations.dart';
import 'package:projectbrain/models/journal/journal_entry.dart';
import 'package:intl/intl.dart';

/// View a single journal entry (read-only) with Edit button.
class JournalViewPage extends StatefulWidget {
  final String entryId;

  const JournalViewPage({super.key, required this.entryId});

  @override
  State<JournalViewPage> createState() => _JournalViewPageState();
}

class _JournalViewPageState extends State<JournalViewPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<JournalProvider>().fetchEntry(widget.entryId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = JournalLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.viewEntry),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => context.push('/journal/${widget.entryId}/edit'),
            tooltip: l10n.edit,
          ),
        ],
      ),
      body: Consumer<JournalProvider>(
        builder: (context, provider, _) {
          final entry = provider.currentEntry;
          if (provider.isLoading && entry == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.errorMessage != null && entry == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(provider.errorMessage!, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => provider.fetchEntry(widget.entryId),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          if (entry == null) {
            return Center(child: Text(l10n.entryNotFound));
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (entry.summary != null && entry.summary!.isNotEmpty) ...[
                  Text(
                    entry.summary!,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                Text(
                  entry.content,
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
                Text(
                  DateFormat.yMMMd().add_Hm().format(entry.createdAt),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                if ((entry.tags?.isNotEmpty ?? false) ||
                    (entry.systemTags?.isNotEmpty ?? false)) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      ...?entry.tags?.map((t) => Chip(
                            label: Text(t.name),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          )),
                      ...?entry.systemTags?.map((t) => Chip(
                            label: Text(t.name),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          )),
                    ],
                  ),
                ],
                if (entry.systemTags != null)
                  ...entry.systemTags!
                      .where((t) => t.responses != null && t.responses!.isNotEmpty)
                      .map((st) => Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  st.name,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                ...st.responses!.entries.map((e) => Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Text(
                                        '${e.key}: ${e.value}',
                                        style: theme.textTheme.bodyMedium,
                                      ),
                                    )),
                              ],
                            ),
                          )),
              ],
            ),
          );
        },
      ),
    );
  }
}
