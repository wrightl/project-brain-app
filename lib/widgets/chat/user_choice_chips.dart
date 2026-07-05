import 'package:flutter/material.dart';
import 'package:projectbrain/helpers/themes/app_spacing.dart';
import 'package:projectbrain/helpers/themes/app_theme_extension.dart';
import 'package:projectbrain/models/agent/user_choice_prompt.dart';

class UserChoiceChips extends StatelessWidget {
  final UserChoicePrompt choices;
  final bool disabled;
  final ValueChanged<String> onSelect;

  const UserChoiceChips({
    super.key,
    required this.choices,
    this.disabled = false,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    if (choices.options.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final appTheme = context.appTheme;

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (choices.prompt != null && choices.prompt!.isNotEmpty) ...[
            Text(
              choices.prompt!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: appTheme.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: choices.options.map((option) {
              return ActionChip(
                label: Text(option.label),
                onPressed: disabled ? null : () => onSelect(option.label),
                backgroundColor: theme.colorScheme.surface,
                side: BorderSide(color: appTheme.borderColor),
                labelStyle: theme.textTheme.bodyMedium,
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.circularPill,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
