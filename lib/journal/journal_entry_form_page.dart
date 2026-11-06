import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:projectbrain/journal/journal_provider.dart';
import 'package:projectbrain/journal/journal_localizations.dart';
import 'package:projectbrain/journal/widgets/system_tag_field_builder.dart';
import 'package:projectbrain/models/journal/journal_request_dtos.dart';
import 'package:projectbrain/models/journal/system_tag.dart';
import 'package:projectbrain/core/util/app_date_format.dart';
import 'package:projectbrain/helpers/themes/app_spacing.dart';
import 'package:projectbrain/helpers/themes/app_theme_extension.dart';
import 'package:projectbrain/widgets/unsaved_changes_scope.dart';

/// Create or edit journal entry (same form).
class JournalEntryFormPage extends StatefulWidget {
  final String? entryId;

  const JournalEntryFormPage({super.key, this.entryId});

  @override
  State<JournalEntryFormPage> createState() => _JournalEntryFormPageState();
}

class _JournalEntryFormPageState extends State<JournalEntryFormPage> {
  final _contentController = TextEditingController();
  final _newTagController = TextEditingController();
  final Set<String> _selectedSystemTagIds = {};
  final Map<String, Map<String, dynamic>> _systemTagResponses = {};
  final Set<String> _selectedUserTagIds = {};
  bool _isSaving = false;
  bool _loaded = false;
  // Set when an existing entry could not be loaded. The form stays hidden so
  // saving cannot overwrite the entry with empty content.
  bool _loadFailed = false;
  bool _saved = false;
  DateTime _entryDate = DateTime.now();
  String? _initialSnapshot;

  bool get _isEdit => widget.entryId != null;

  String _snapshot() => [
        _contentController.text.trim(),
        (_selectedUserTagIds.toList()..sort()).join(','),
        (_selectedSystemTagIds.toList()..sort()).join(','),
        _systemTagResponses.toString(),
      ].join('|');

  bool get _hasUnsavedChanges =>
      !_saved && _initialSnapshot != null && _snapshot() != _initialSnapshot;

  @override
  void initState() {
    super.initState();
    // Rebuild on typing so the unsaved-changes guard sees the new text.
    _contentController.addListener(_onContentChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  void _onContentChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _contentController.dispose();
    _newTagController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    if (!mounted) return;
    setState(() {
      _loaded = false;
      _loadFailed = false;
    });
    final provider = context.read<JournalProvider>();
    await provider.loadSystemTags();
    await provider.loadUserTags();
    if (_isEdit && widget.entryId != null) {
      final entry = await provider.fetchEntry(widget.entryId!);
      if (!mounted) return;
      if (entry == null) {
        setState(() {
          _loaded = true;
          _loadFailed = true;
        });
        return;
      }
      _contentController.text = entry.content;
      _entryDate = entry.createdAt;
      for (final t in entry.tags ?? []) {
        _selectedUserTagIds.add(t.id);
      }
      for (final st in entry.systemTags ?? []) {
        _selectedSystemTagIds.add(st.id);
        if (st.responses != null && st.responses!.isNotEmpty) {
          _systemTagResponses[st.id] = Map.from(st.responses!);
        }
      }
    }
    if (mounted) {
      setState(() {
        _loaded = true;
        _initialSnapshot = _snapshot();
      });
    }
  }

  Future<void> _save() async {
    final content = _contentController.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(JournalLocalizations.of(context).contentRequired)),
      );
      return;
    }
    final provider = context.read<JournalProvider>();
    final l10n = JournalLocalizations.of(context);

    final tagIds = _selectedUserTagIds.toList();
    final systemTagIds = _selectedSystemTagIds.toList();
    final systemTagResponses = _selectedSystemTagIds
        .where((id) =>
            _systemTagResponses[id] != null &&
            _systemTagResponses[id]!.isNotEmpty)
        .map((id) => SystemTagResponseItem(
              systemTagId: id,
              responses: _systemTagResponses[id] ?? {},
            ))
        .toList();

    setState(() => _isSaving = true);
    try {
      if (_isEdit && widget.entryId != null) {
        final request = JournalUpdateRequest(
          content: content,
          tagIds: tagIds.isEmpty ? null : tagIds,
          systemTagIds: systemTagIds.isEmpty ? null : systemTagIds,
          systemTagResponses:
              systemTagResponses.isEmpty ? null : systemTagResponses,
        );
        await provider.updateEntry(widget.entryId!, request);
        if (!mounted) return;
        _saved = true;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.entrySaved)),
        );
        context.pop();
      } else {
        final request = JournalCreateRequest(
          content: content,
          tagIds: tagIds.isEmpty ? null : tagIds,
          systemTagIds: systemTagIds.isEmpty ? null : systemTagIds,
          systemTagResponses:
              systemTagResponses.isEmpty ? null : systemTagResponses,
        );
        final entry = await provider.createEntry(request);
        if (!mounted) return;
        _saved = true;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.entrySaved)),
        );
        // Swap the form for the new entry.
        context.pushReplacement('/journal/${entry.id}');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.couldNotSaveEntry)),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _setSystemTagResponse(
      String systemTagId, String fieldKey, dynamic value) {
    setState(() {
      _systemTagResponses[systemTagId] ??= {};
      _systemTagResponses[systemTagId]![fieldKey] = value;
    });
  }

  Future<void> _addNewTag() async {
    final name = _newTagController.text.trim();
    if (name.isEmpty) return;
    final provider = context.read<JournalProvider>();
    try {
      final tag = await provider.createTag(name);
      setState(() {
        _selectedUserTagIds.add(tag.id);
        _newTagController.clear();
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not create tag')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = JournalLocalizations.of(context);
    return UnsavedChangesScope(
      hasUnsavedChanges: _hasUnsavedChanges,
      message: 'Your journal entry has not been saved.',
      child: _buildScaffold(context, theme, l10n),
    );
  }

  /// Spinner while loading, or an error with Retry when the entry could not
  /// be loaded.
  Widget _buildNotReady(ThemeData theme, JournalLocalizations l10n) {
    if (!_loaded) {
      return const Center(
        child: CircularProgressIndicator(semanticsLabel: 'Loading'),
      );
    }
    return Center(
      child: Padding(
        padding: AppInsets.screen,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.couldNotLoadEntry,
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton(onPressed: _init, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }

  Widget _buildScaffold(
    BuildContext context,
    ThemeData theme,
    JournalLocalizations l10n,
  ) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Close',
          // maybePop so the unsaved-changes check runs.
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(_isEdit ? l10n.editEntry : l10n.newEntry),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: FilledButton(
              onPressed: (_isSaving || _loadFailed) ? null : _save,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                          semanticsLabel: 'Loading', strokeWidth: 2),
                    )
                  : Text(l10n.save),
            ),
          ),
        ],
      ),
      body: !_loaded || _loadFailed
          ? _buildNotReady(theme, l10n)
          : Consumer<JournalProvider>(
              builder: (context, provider, _) {
                final appTheme = context.appTheme;
                final systemTags = provider.systemTags;
                final userTags = provider.userTags;
                final sortedSystemTags = List<SystemTag>.from(systemTags)
                  ..sort((a, b) => a.name.compareTo(b.name));
                return SingleChildScrollView(
                  padding: AppInsets.screen,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        // The entry's own date when editing, not today's.
                        '${AppDateFormat.weekdayDate(_entryDate)} · '
                                '${AppDateFormat.time(_entryDate)}'
                            .toUpperCase(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          letterSpacing: 1,
                          color: appTheme.textMuted,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      TextField(
                        controller: _contentController,
                        maxLines: 8,
                        style: theme.textTheme.bodyLarge,
                        decoration: InputDecoration(
                          hintText: l10n.pleaseEnterContent,
                          border: InputBorder.none,
                          filled: false,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Text(
                        l10n.suggestedTags,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: sortedSystemTags.map((st) {
                          final selected =
                              _selectedSystemTagIds.contains(st.id);
                          return FilterChip(
                            label: Text(st.name),
                            selected: selected,
                            onSelected: (v) {
                              setState(() {
                                if (v) {
                                  _selectedSystemTagIds.add(st.id);
                                } else {
                                  _selectedSystemTagIds.remove(st.id);
                                  _systemTagResponses.remove(st.id);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                      ...sortedSystemTags
                          .where((st) => _selectedSystemTagIds.contains(st.id))
                          .map((st) {
                        final defs = List.of(st.fieldDefinitions)
                          ..sort(
                              (a, b) => a.fieldOrder.compareTo(b.fieldOrder));
                        return Padding(
                          padding: EdgeInsets.only(top: AppSpacing.lg),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                st.name,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              ...defs.map((def) {
                                final resp = _systemTagResponses[st.id];
                                final value = resp?[def.fieldKey];
                                return Padding(
                                  padding: EdgeInsets.only(top: AppSpacing.md),
                                  child: SystemTagFieldBuilder(
                                    definition: def,
                                    value: value,
                                    onChanged: (v) => _setSystemTagResponse(
                                        st.id, def.fieldKey, v),
                                  ),
                                );
                              }),
                            ],
                          ),
                        );
                      }),
                      SizedBox(height: AppSpacing.xl),
                      Text(
                        l10n.customTags,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: userTags.map((t) {
                          final selected = _selectedUserTagIds.contains(t.id);
                          return FilterChip(
                            label: Text(t.name),
                            selected: selected,
                            onSelected: (v) {
                              setState(() {
                                if (v) {
                                  _selectedUserTagIds.add(t.id);
                                } else {
                                  _selectedUserTagIds.remove(t.id);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                      SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _newTagController,
                              decoration: InputDecoration(
                                labelText: l10n.addTag,
                                hintText: 'New tag name',
                                border: const OutlineInputBorder(),
                                isDense: true,
                              ),
                              onSubmitted: (_) => _addNewTag(),
                            ),
                          ),
                          SizedBox(width: AppSpacing.sm),
                          FilledButton(
                            onPressed: _addNewTag,
                            child: Text(l10n.addTag),
                          ),
                        ],
                      ),
                      SizedBox(height: AppSpacing.xxl),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _isSaving ? null : _save,
                          child: _isSaving
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                      semanticsLabel: 'Loading',
                                      strokeWidth: 2),
                                )
                              : Text(l10n.save),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
