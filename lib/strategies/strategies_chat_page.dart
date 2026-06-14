import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:projectbrain/authentication/auth_provider.dart';
import 'package:projectbrain/core/logging/app_logger.dart';
import 'package:projectbrain/core/security/url_security.dart';
import 'package:projectbrain/models/strategies/suggested_strategy.dart';
import 'package:projectbrain/strategies/strategies_chat_provider.dart';
import 'package:projectbrain/strategies/strategies_localizations.dart';
import 'package:projectbrain/strategies/strategies_provider.dart';
import 'package:projectbrain/widgets/chat/typing_indicator.dart';
import 'package:projectbrain/helpers/themes/app_spacing.dart';

/// Strategies chat screen: greeting, example prompts, send message, show suggested strategies, select & save.
class StrategiesChatPage extends StatefulWidget {
  const StrategiesChatPage({super.key});

  @override
  State<StrategiesChatPage> createState() => _StrategiesChatPageState();
}

class _StrategiesChatPageState extends State<StrategiesChatPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = StrategiesLocalizations.of(context);
    final authProvider = context.watch<AuthProvider>();
    final name = authProvider.profile?.name ?? 'User';

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.getNewStrategies),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: l10n.newConversation,
            onPressed: () {
              context.read<StrategiesChatProvider>().startNewConversation();
            },
          ),
          TextButton.icon(
            onPressed: () => context.go('/strategies'),
            icon: const Icon(Icons.library_books, size: 20),
            label: Text(l10n.viewLibrary),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Consumer<StrategiesChatProvider>(
              builder: (context, chatProvider, _) {
                if (chatProvider.errorMessage != null) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(chatProvider.errorMessage!)),
                    );
                    chatProvider.clearError();
                  });
                }
                if (chatProvider.turns.isEmpty) {
                  return SingleChildScrollView(
                    padding: AppInsets.page,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.formatGreeting(name),
                          style: theme.textTheme.bodyLarge,
                        ),
                        SizedBox(height: AppSpacing.xl),
                        Text(
                          'Try one of these:',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: AppSpacing.md),
                        _ExampleChip(
                          label: l10n.examplePrompt1,
                          onTap: () => chatProvider.sendMessage(l10n.examplePrompt1),
                        ),
                        SizedBox(height: AppSpacing.sm),
                        _ExampleChip(
                          label: l10n.examplePrompt2,
                          onTap: () => chatProvider.sendMessage(l10n.examplePrompt2),
                        ),
                        SizedBox(height: AppSpacing.sm),
                        _ExampleChip(
                          label: l10n.examplePrompt3,
                          onTap: () => chatProvider.sendMessage(l10n.examplePrompt3),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  controller: _scrollController,
                  padding: AppInsets.screen,
                  itemCount: chatProvider.turns.length,
                  itemBuilder: (context, index) {
                    final turn = chatProvider.turns[index];
                    return _TurnTile(
                      turn: turn,
                      selectedStrategies: chatProvider.selectedStrategies,
                      onToggleStrategy: chatProvider.toggleStrategySelection,
                      onLearnMore: _openLink,
                    );
                  },
                );
              },
            ),
          ),
          if (context.watch<StrategiesChatProvider>().isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: TypingIndicator(),
            ),
          Consumer<StrategiesChatProvider>(
            builder: (context, chatProvider, _) {
              final hasSelection = chatProvider.selectedStrategies.isNotEmpty;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (hasSelection)
                    Padding(
                      padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 0),
                      child: FilledButton.icon(
                        onPressed: chatProvider.isLoading
                            ? null
                            : () => _saveSelected(context, chatProvider),
                        icon: const Icon(Icons.save),
                        label: Text(
                          l10n.formatSaveCount(chatProvider.selectedStrategies.length),
                        ),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(double.infinity, 44),
                        ),
                      ),
                    ),
                  SafeArea(
                    child: Padding(
                      padding: EdgeInsets.all(AppSpacing.sm),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              decoration: const InputDecoration(
                                hintText: 'Tell me what you\'re dealing with...',
                                border: OutlineInputBorder(),
                              ),
                              enabled: !chatProvider.isLoading,
                              onSubmitted: (text) => _send(context, text),
                            ),
                          ),
                          SizedBox(width: AppSpacing.sm),
                          IconButton.filled(
                            onPressed: chatProvider.isLoading
                                ? null
                                : () => _send(context, _controller.text),
                            icon: const Icon(Icons.send),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  void _send(BuildContext context, String text) {
    final t = text.trim();
    if (t.isEmpty) return;
    _controller.clear();
    context.read<StrategiesChatProvider>().sendMessage(t);
  }

  Future<void> _saveSelected(BuildContext context, StrategiesChatProvider chatProvider) async {
    final n = await chatProvider.saveSelectedStrategies();
    if (!context.mounted) return;
    if (n > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(StrategiesLocalizations.of(context).strategiesSaved),
        ),
      );
      context.read<StrategiesProvider>().loadLibrary();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(StrategiesLocalizations.of(context).couldNotSaveStrategies),
        ),
      );
    }
  }

  Future<void> _openLink(String url) async {
    if (!UrlSecurity.isSafeExternalUrl(url)) {
      logWarning('[StrategiesChatPage] Blocked unsafe link: $url');
      return;
    }
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _ExampleChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _ExampleChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.circularPill,
      child: Container(
        padding: AppInsets.card,
        decoration: BoxDecoration(
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.5),
          ),
          borderRadius: AppRadius.circularPill,
        ),
        child: Row(
          children: [
            Icon(Icons.chat_bubble_outline, size: 20, color: theme.colorScheme.primary),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TurnTile extends StatelessWidget {
  final StrategyChatTurn turn;
  final Set<SuggestedStrategy> selectedStrategies;
  final ValueChanged<SuggestedStrategy> onToggleStrategy;
  final ValueChanged<String> onLearnMore;

  const _TurnTile({
    required this.turn,
    required this.selectedStrategies,
    required this.onToggleStrategy,
    required this.onLearnMore,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = StrategiesLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // User message
        Align(
          alignment: Alignment.centerRight,
          child: Container(
            margin: EdgeInsets.only(bottom: AppSpacing.sm),
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.s10),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: AppRadius.circularLg,
            ),
            child: Text(
              turn.userMessage,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ),
        // Assistant text
        if (turn.assistantText.isNotEmpty)
          Container(
            margin: AppInsets.listItemBottom,
            padding: EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: AppRadius.circularMd,
            ),
            child: Text(
              turn.assistantText,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        // Strategy cards
        if (turn.strategies != null && turn.strategies!.isNotEmpty)
          ...turn.strategies!.map((s) => _StrategyCard(
                strategy: s,
                isSelected: selectedStrategies.contains(s),
                onTap: () => onToggleStrategy(s),
                onLearnMore: s.articleUrl != null
                    ? () => onLearnMore(s.articleUrl!)
                    : null,
                l10n: l10n,
              )),
        SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}

class _StrategyCard extends StatelessWidget {
  final SuggestedStrategy strategy;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onLearnMore;
  final StrategiesLocalizations l10n;

  const _StrategyCard({
    required this.strategy,
    required this.isSelected,
    required this.onTap,
    this.onLearnMore,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final icon = _iconFor(strategy.iconKey);
    return Card(
      margin: EdgeInsets.only(bottom: AppSpacing.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.circularMd,
        child: Container(
          padding: AppInsets.screen,
          decoration: BoxDecoration(
            borderRadius: AppRadius.circularMd,
            border: isSelected
                ? Border.all(color: theme.colorScheme.primary, width: 2)
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (icon != null)
                    Padding(
                      padding: EdgeInsets.only(right: AppSpacing.md),
                      child: Icon(icon, color: theme.colorScheme.primary),
                    ),
                  Expanded(
                    child: Text(
                      strategy.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (isSelected)
                    Icon(Icons.check_circle, color: theme.colorScheme.primary),
                ],
              ),
              SizedBox(height: AppSpacing.sm),
              Text(
                strategy.description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                ),
              ),
              if (onLearnMore != null) ...[
                SizedBox(height: AppSpacing.sm),
                TextButton(
                  onPressed: onLearnMore,
                  child: Text(l10n.learnMore),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static IconData? _iconFor(String? iconKey) {
    if (iconKey == null || iconKey.isEmpty) return null;
    switch (iconKey.toLowerCase()) {
      case 'sparkles':
        return Icons.auto_awesome;
      case 'lightbulb':
        return Icons.lightbulb_outline;
      case 'heart':
        return Icons.favorite_border;
      case 'fitness':
        return Icons.fitness_center;
      case 'nature':
        return Icons.nature;
      default:
        return Icons.psychology_outlined;
    }
  }
}
