import 'package:flutter/material.dart';
import 'package:projectbrain/models/agent/action_card.dart';

class ActionCardWidget extends StatelessWidget {
  final ActionCard card;

  const ActionCardWidget({super.key, required this.card});

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
          if (card.description != null) ...[
            const SizedBox(height: 4),
            Text(card.description!, style: Theme.of(context).textTheme.bodySmall),
          ],
          if (card.filename != null) ...[
            const SizedBox(height: 4),
            Text(card.filename!, style: Theme.of(context).textTheme.bodySmall),
          ],
        ],
      ),
    );
  }

  String _titleFor(ActionCard card) {
    switch (card.cardType) {
      case 'goals_created':
        return 'Daily goals created';
      case 'strategy_saved':
        return card.title != null ? 'Strategy saved: ${card.title}' : 'Strategy saved';
      case 'coaches_found':
        return 'Coaches found';
      case 'document_uploaded':
        return 'Document uploaded';
      default:
        return card.title ?? 'Action completed';
    }
  }
}
