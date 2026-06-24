import 'package:flutter/material.dart';
import 'package:projectbrain/models/agent/action_card.dart';

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
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.indigo.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.indigo.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _titleFor(card),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.indigo.shade900,
                ),
          ),
          if (card.preview != null) ...[
            const SizedBox(height: 4),
            Text(card.preview!, style: Theme.of(context).textTheme.bodySmall),
          ],
          if (card.description != null) ...[
            const SizedBox(height: 4),
            Text(card.description!, style: Theme.of(context).textTheme.bodySmall),
          ],
          if (card.message != null) ...[
            const SizedBox(height: 4),
            Text(card.message!, style: Theme.of(context).textTheme.bodySmall),
          ],
          if (card.summary != null) ...[
            const SizedBox(height: 4),
            Text(card.summary!, style: Theme.of(context).textTheme.bodySmall),
          ],
          if (card.filename != null) ...[
            const SizedBox(height: 4),
            Text(card.filename!, style: Theme.of(context).textTheme.bodySmall),
          ],
          if (card.cardType == 'pending_confirmation') ...[
            const SizedBox(height: 8),
            Row(
              children: [
                FilledButton(
                  onPressed: onConfirmPendingAction == null
                      ? null
                      : () => onConfirmPendingAction!(card),
                  child: const Text('Confirm'),
                ),
                const SizedBox(width: 8),
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
        return card.title != null ? 'Strategy saved: ${card.title}' : 'Strategy saved';
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
