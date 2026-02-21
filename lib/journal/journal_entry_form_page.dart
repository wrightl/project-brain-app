import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:projectbrain/journal/journal_provider.dart';
import 'package:projectbrain/journal/journal_localizations.dart';
import 'package:projectbrain/journal/widgets/system_tag_field_builder.dart';
import 'package:projectbrain/models/journal/journal_request_dtos.dart';
import 'package:projectbrain/models/journal/system_tag.dart';

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

  bool get _isEdit => widget.entryId != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  @override
  void dispose() {
    _contentController.dispose();
    _newTagController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final provider = context.read<JournalProvider>();
    await provider.loadSystemTags();
    await provider.loadUserTags();
    if (_isEdit && widget.entryId != null) {
      final entry = await provider.fetchEntry(widget.entryId!);
      if (entry != null && mounted) {
        _contentController.text = entry.content;
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
    }
    if (mounted) {
      setState(() => _loaded = true);
    }
  }

  Future<void> _save() async {
    final content = _contentController.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(JournalLocalizations.of(context).contentRequired)),
      );
      return;
    }
    final provider = context.read<JournalProvider>();
    final l10n = JournalLocalizations.of(context);

    final tagIds = _selectedUserTagIds.toList();
    final systemTagIds = _selectedSystemTagIds.toList();
    final systemTagResponses = _selectedSystemTagIds
        .where((id) => _systemTagResponses[id] != null && _systemTagResponses[id]!.isNotEmpty)
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
          systemTagResponses: systemTagResponses.isEmpty ? null : systemTagResponses,
        );
        await provider.updateEntry(widget.entryId!, request);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.entrySaved)),
        );
        context.pop();
      } else {
        final request = JournalCreateRequest(
          content: content,
          tagIds: tagIds.isEmpty ? null : tagIds,
          systemTagIds: systemTagIds.isEmpty ? null : systemTagIds,
          systemTagResponses: systemTagResponses.isEmpty ? null : systemTagResponses,
        );
        final entry = await provider.createEntry(request);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.entrySaved)),
        );
        context.pop();
        context.push('/journal/${entry.id}');
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

  void _setSystemTagResponse(String systemTagId, String fieldKey, dynamic value) {
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
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? l10n.editEntry : l10n.newEntry),
      ),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : Consumer<JournalProvider>(
              builder: (context, provider, _) {
                final systemTags = provider.systemTags;
                final userTags = provider.userTags;
                final sortedSystemTags = List<SystemTag>.from(systemTags)
                  ..sort((a, b) => a.name.compareTo(b.name));
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _contentController,
                        maxLines: 6,
                        decoration: InputDecoration(
                          labelText: l10n.content,
                          hintText: l10n.pleaseEnterContent,
                          border: const OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        l10n.suggestedTags,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: sortedSystemTags.map((st) {
                          final selected = _selectedSystemTagIds.contains(st.id);
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
                          ..sort((a, b) => a.fieldOrder.compareTo(b.fieldOrder));
                        return Padding(
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
                              ...defs.map((def) {
                                final resp = _systemTagResponses[st.id];
                                final value = resp?[def.fieldKey];
                                return Padding(
                                  padding: const EdgeInsets.only(top: 12),
                                  child: SystemTagFieldBuilder(
                                    definition: def,
                                    value: value,
                                    onChanged: (v) =>
                                        _setSystemTagResponse(st.id, def.fieldKey, v),
                                  ),
                                );
                              }),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 24),
                      Text(
                        l10n.customTags,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
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
                      const SizedBox(height: 12),
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
                          const SizedBox(width: 8),
                          FilledButton(
                            onPressed: _addNewTag,
                            child: Text(l10n.addTag),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _isSaving ? null : _save,
                          child: _isSaving
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
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
