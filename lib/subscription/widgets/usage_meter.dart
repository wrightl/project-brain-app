import 'package:flutter/material.dart';

/// Widget that displays usage vs limit with a progress bar
class UsageMeter extends StatelessWidget {
  final String label;
  final int current;
  final int? limit;
  final String unit;
  final Color? color;

  const UsageMeter({
    super.key,
    required this.label,
    required this.current,
    this.limit,
    this.unit = '',
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUnlimited = limit == null;
    final percentage = isUnlimited ? 0.0 : (current / limit!).clamp(0.0, 1.0);
    final isWarning = !isUnlimited && percentage >= 0.8;
    final isError = !isUnlimited && percentage >= 1.0;

    Color progressColor;
    if (color != null) {
      progressColor = color!;
    } else if (isError) {
      progressColor = theme.colorScheme.error;
    } else if (isWarning) {
      progressColor = Colors.orange;
    } else {
      progressColor = theme.colorScheme.primary;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: theme.textTheme.bodyMedium,
            ),
            Text(
              isUnlimited
                  ? '$current$unit (Unlimited)'
                  : '$current$unit / $limit$unit',
              style: theme.textTheme.bodySmall?.copyWith(
                color: isError
                    ? theme.colorScheme.error
                    : isWarning
                        ? Colors.orange
                        : null,
                fontWeight: isError || isWarning ? FontWeight.bold : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: isUnlimited ? null : percentage,
            minHeight: 8,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(progressColor),
          ),
        ),
        if (isError)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Limit reached',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          )
        else if (isWarning)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Approaching limit',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.orange,
              ),
            ),
          ),
      ],
    );
  }
}
