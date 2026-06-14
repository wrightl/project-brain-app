import 'package:flutter/material.dart';
import 'package:projectbrain/models/journal/system_tag_field_definition.dart';
import 'package:projectbrain/helpers/themes/app_spacing.dart';

/// Builds a form field from a system tag field definition.
class SystemTagFieldBuilder extends StatefulWidget {
  final SystemTagFieldDefinition definition;
  final dynamic value;
  final ValueChanged<dynamic> onChanged;

  const SystemTagFieldBuilder({
    super.key,
    required this.definition,
    required this.value,
    required this.onChanged,
  });

  @override
  State<SystemTagFieldBuilder> createState() => _SystemTagFieldBuilderState();
}

class _SystemTagFieldBuilderState extends State<SystemTagFieldBuilder> {
  TextEditingController? _textController;

  @override
  void initState() {
    super.initState();
    if (widget.definition.inputType == 'text' ||
        widget.definition.inputType == 'textarea') {
      _textController = TextEditingController(
          text: widget.value is String ? widget.value as String : '');
    }
  }

  @override
  void didUpdateWidget(SystemTagFieldBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value &&
        _textController != null &&
        widget.value is String &&
        _textController!.text != widget.value) {
      _textController!.text = widget.value as String;
    }
  }

  @override
  void dispose() {
    _textController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final definition = widget.definition;
    final value = widget.value;
    final onChanged = widget.onChanged;
    switch (definition.inputType) {
      case 'textarea':
        return TextField(
          maxLines: 4,
          decoration: InputDecoration(
            labelText: definition.label,
            hintText: definition.placeholder ?? definition.hint,
            border: const OutlineInputBorder(),
          ),
          controller: _textController,
          onChanged: (s) => onChanged(s),
        );
      case 'number':
        return TextFormField(
          initialValue: value?.toString(),
          decoration: InputDecoration(
            labelText: definition.label,
            hintText: definition.placeholder ?? definition.hint,
            border: const OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          onChanged: (s) {
            final n = num.tryParse(s);
            onChanged(n);
          },
        );
      case 'rating':
        final min = (definition.minValue ?? 1).toInt();
        final max = (definition.maxValue ?? 5).toInt();
        final current = value is num ? value.toInt() : null;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(definition.label, style: theme.textTheme.labelLarge),
            if (definition.hint != null)
              Text(definition.hint!,
                  style: theme.textTheme.bodySmall?.copyWith(
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.6))),
            SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              children: List.generate(max - min + 1, (i) {
                final v = min + i;
                final selected = current == v;
                return ChoiceChip(
                  label: Text('$v'),
                  selected: selected,
                  onSelected: (_) => onChanged(v),
                );
              }),
            ),
          ],
        );
      case 'select':
        final options = definition.options ?? [];
        return DropdownButtonFormField<String>(
          decoration: InputDecoration(
            labelText: definition.label,
            border: const OutlineInputBorder(),
          ),
          initialValue: value is String ? value : null,
          items: options
              .map((o) => DropdownMenuItem(value: o, child: Text(o)))
              .toList(),
          onChanged: (v) => onChanged(v),
        );
      case 'time':
        return ListTile(
          title: Text(definition.label),
          subtitle:
              Text(value is String ? value : (definition.placeholder ?? '')),
          trailing: const Icon(Icons.access_time),
          onTap: () async {
            final initial = value is String ? value : null;
            TimeOfDay? initialTime;
            if (initial != null && initial.contains(':')) {
              final parts = initial.split(':');
              if (parts.length >= 2) {
                initialTime = TimeOfDay(
                  hour: int.tryParse(parts[0]) ?? 0,
                  minute: int.tryParse(parts[1]) ?? 0,
                );
              }
            }
            final time = await showTimePicker(
              context: context,
              initialTime: initialTime ?? TimeOfDay.now(),
            );
            if (time != null) {
              onChanged(
                  '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}');
            }
          },
        );
      case 'text':
      default:
        return TextFormField(
          controller: _textController,
          decoration: InputDecoration(
            labelText: definition.label,
            hintText: definition.placeholder ?? definition.hint,
            border: const OutlineInputBorder(),
          ),
          onChanged: (s) => onChanged(s),
        );
    }
  }
}
