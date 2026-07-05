import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:projectbrain/journal/journal_provider.dart';
import 'package:projectbrain/journal/journal_localizations.dart';
import 'package:intl/intl.dart';
import 'package:projectbrain/helpers/themes/app_spacing.dart';
import 'package:projectbrain/helpers/themes/app_theme_extension.dart';
import 'package:projectbrain/widgets/ds/ds_widgets.dart';

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
    final appTheme = context.appTheme;
    final l10n = JournalLocalizations.of(context);

    return Scaffold(
      body: SafeArea(
        child: Consumer<JournalProvider>(
          builder: (context, provider, _) {
            final entry = provider.currentEntry;

            if (provider.isLoading && entry == null) {
              return const Center(child: CircularProgressIndicator());
            }
            if (provider.errorMessage != null && entry == null) {
              return Center(
                child: Padding(
                  padding: AppInsets.page,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(provider.errorMessage!, textAlign: TextAlign.center),
                      const SizedBox(height: AppSpacing.lg),
                      FilledButton(
                        onPressed: () => provider.fetchEntry(widget.entryId),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );
            }
            if (entry == null) {
              return Center(child: Text(l10n.entryNotFound));
            }

            return Column(
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
                    children: [
                      IconButton(
                        onPressed: () => context.pop(),
                        icon: const Icon(Icons.arrow_back),
                      ),
                      Expanded(
                        child: Text(
                          l10n.viewEntry,
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                      IconButton(
                        onPressed: () =>
                            context.push('/journal/${widget.entryId}/edit'),
                        style: IconButton.styleFrom(
                          backgroundColor: appTheme.coralSoft,
                        ),
                        icon: Icon(Icons.edit_outlined, color: appTheme.coral),
                        tooltip: l10n.edit,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: AppInsets.page,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat.yMMMd().add_Hm().format(entry.createdAt),
                          style: theme.textTheme.labelSmall,
                        ),
                        if (entry.summary != null &&
                            entry.summary!.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            entry.summary!,
                            style: theme.textTheme.titleMedium,
                          ),
                        ],
                        if ((entry.tags?.isNotEmpty ?? false) ||
                            (entry.systemTags?.isNotEmpty ?? false)) ...[
                          const SizedBox(height: AppSpacing.md),
                          Wrap(
                            spacing: AppSpacing.sm,
                            runSpacing: AppSpacing.sm,
                            children: [
                              ...?entry.tags?.map(
                                (t) => AccentTag(
                                  label: t.name,
                                  color: appTheme.coral,
                                  backgroundColor: appTheme.coralSoft,
                                ),
                              ),
                              ...?entry.systemTags?.map(
                                (t) => AccentTag(
                                  label: t.name,
                                  color: appTheme.sky,
                                  backgroundColor: appTheme.skySoft,
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: AppSpacing.lg),
                        DsSurfaceCard(
                          child: Text(
                            entry.content,
                            style: theme.textTheme.bodyLarge,
                          ),
                        ),
                        if (entry.systemTags != null)
                          ...entry.systemTags!
                              .where((t) =>
                                  t.responses != null &&
                                  t.responses!.isNotEmpty)
                              .map(
                                (st) => Padding(
                                  padding: const EdgeInsets.only(
                                    top: AppSpacing.lg,
                                  ),
                                  child: DsSurfaceCard(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          st.name,
                                          style: theme.textTheme.titleSmall,
                                        ),
                                        const SizedBox(height: AppSpacing.sm),
                                        ...st.responses!.entries.map(
                                          (e) => Padding(
                                            padding: const EdgeInsets.only(
                                              bottom: AppSpacing.micro,
                                            ),
                                            child: Text(
                                              '${e.key}: ${e.value}',
                                              style: theme.textTheme.bodyMedium,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
