import 'package:flutter/material.dart';
import 'package:projectbrain/helpers/themes/app_theme_extension.dart';
import 'package:projectbrain/helpers/themes/contrast.dart';
import 'package:projectbrain/models/agent/tool_execution.dart';

class ToolExecutionBadge extends StatelessWidget {
  final ToolExecution tool;

  const ToolExecutionBadge({super.key, required this.tool});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appTheme = context.appTheme;
    final background = appTheme.primarySoft;
    final statusColor = readableOn(
      tool.success ? appTheme.green : theme.colorScheme.error,
      background,
      minRatio: 3,
    );

    // Success/failure is also spoken, not only shown by icon colour.
    return Semantics(
      label: '${tool.displayName}, ${tool.success ? 'done' : 'failed'}',
      excludeSemantics: true,
      child: Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          children: [
            Icon(
              tool.success ? Icons.check_circle : Icons.error,
              color: statusColor,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                tool.displayName,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: readableOn(theme.colorScheme.primary, background),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
