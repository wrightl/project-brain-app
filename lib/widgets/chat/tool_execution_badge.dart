import 'package:flutter/material.dart';
import 'package:projectbrain/models/agent/tool_execution.dart';

class ToolExecutionBadge extends StatelessWidget {
  final ToolExecution tool;

  const ToolExecutionBadge({super.key, required this.tool});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.purple.shade200),
      ),
      child: Row(
        children: [
          Icon(
            tool.success ? Icons.check_circle : Icons.error,
            color: tool.success ? Colors.green : Colors.red,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              tool.displayName,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.purple.shade900,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
