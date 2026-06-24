import 'package:flutter/material.dart';
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

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (choices.prompt != null && choices.prompt!.isNotEmpty) ...[
            Text(
              choices.prompt!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
            ),
            const SizedBox(height: 8),
          ],
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: choices.options.map((option) {
              return ActionChip(
                label: Text(option.label),
                onPressed: disabled ? null : () => onSelect(option.label),
                backgroundColor: Colors.white,
                side: BorderSide(color: Colors.grey.shade300),
                labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade800,
                    ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
