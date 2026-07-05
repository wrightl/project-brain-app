import 'package:flutter/material.dart';
import 'package:projectbrain/helpers/themes/app_spacing.dart';
import 'package:projectbrain/helpers/themes/app_theme_extension.dart';
import 'package:projectbrain/models/agent/action_card.dart';
import 'package:projectbrain/widgets/ds/ds_widgets.dart';

typedef PendingActionCallback = Future<void> Function(ActionCard card);

class ActionCardWidget extends StatelessWidget {
  final ActionCard card;
  final PendingActionCallback? onConfirmPendingAction;
  final PendingActionCallback? onCancelPendingAction;

  const ActionCardWidget({
    super.key,
    required this.card,
    this.onConfirmPendingAction,
    this.onCancelPendingAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appTheme = context.appTheme;

    return DsSurfaceCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      backgroundColor: appTheme.primarySoft,
      borderColor: theme.colorScheme.primary.withValues(alpha: 0.25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconBubble(
                icon: Icons.auto_awesome,
                color: theme.colorScheme.primary,
                backgroundColor: theme.colorScheme.surface,
                size: 32,
                iconSize: 16,
                borderRadius: 8,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  _titleFor(card),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          if (card.preview != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(card.preview!, style: theme.textTheme.bodySmall),
          ],
          if (card.description != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(card.description!, style: theme.textTheme.bodySmall),
          ],
          if (card.message != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(card.message!, style: theme.textTheme.bodySmall),
          ],
          if (card.summary != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(card.summary!, style: theme.textTheme.bodySmall),
          ],
          if (card.filename != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(card.filename!, style: theme.textTheme.bodySmall),
          ],
          if (card.cardType == 'pending_confirmation') ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                FilledButton(
                  onPressed: onConfirmPendingAction == null
                      ? null
                      : () => onConfirmPendingAction!(card),
                  child: const Text('Confirm'),
                ),
                const SizedBox(width: AppSpacing.sm),
                OutlinedButton(
                  onPressed: onCancelPendingAction == null
                      ? null
                      : () => onCancelPendingAction!(card),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _titleFor(ActionCard card) {
    switch (card.cardType) {
      case 'goals_created':
        return 'Daily goals created';
      case 'goals_suggested':
        return 'Suggested daily goals';
      case 'goal_streak':
        return 'Goal streak';
      case 'strategy_saved':
        return card.title != null
            ? 'Strategy saved: ${card.title}'
            : 'Strategy saved';
      case 'coaches_found':
        return 'Coaches found';
      case 'document_uploaded':
        return 'Document uploaded';
      case 'document_deleted':
        return 'Document deleted';
      case 'journal_entry_created':
        return 'Journal entry created';
      case 'memory_saved':
        return card.title != null ? 'Remembered: ${card.title}' : 'Memory saved';
      case 'memory_deleted':
        return 'Memory forgotten';
      case 'pending_confirmation':
        return 'Confirm this action';
      default:
        return card.title ?? 'Action completed';
    }
  }
}
