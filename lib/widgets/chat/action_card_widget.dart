import 'package:flutter/material.dart';
import 'package:projectbrain/helpers/coach_agent_actions.dart';
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
          if (card.cardType == 'coaches_found' && card.coaches.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            ...card.coaches.take(3).map((coach) {
              final coachProfileId =
                  coach['coachProfileId']?.toString() ?? '';
              final name = coach['name']?.toString() ?? 'Coach';
              final bio = coach['bio']?.toString();
              final connectionStatus =
                  coach['connectionStatus']?.toString();
              final connectionId = coach['connectionId']?.toString();
              final canMessage = connectionStatus == 'connected' &&
                  connectionId != null &&
                  connectionId.isNotEmpty;

              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bio != null && bio.isNotEmpty ? '$name — $bio' : name,
                      style: theme.textTheme.bodySmall,
                    ),
                    if (coachProfileId.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: [
                          if (canMessage)
                            FilledButton.icon(
                              onPressed: () => CoachAgentActions.messageCoach(
                                context,
                                coachProfileId: coachProfileId,
                                connectionId: connectionId,
                                connectionStatus: connectionStatus,
                              ),
                              icon: const Icon(Icons.chat, size: 18),
                              label: const Text('Message'),
                            ),
                          OutlinedButton.icon(
                            onPressed: () => CoachAgentActions.viewCoachProfile(
                              context,
                              coachProfileId,
                            ),
                            icon: const Icon(Icons.person, size: 18),
                            label: const Text('View profile'),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              );
            }),
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
        return card.title != null
            ? 'Remembered: ${card.title}'
            : 'Memory saved';
      case 'memory_deleted':
        return 'Memory forgotten';
      case 'pending_confirmation':
        return 'Confirm this action';
      default:
        return card.title ?? 'Action completed';
    }
  }
}
