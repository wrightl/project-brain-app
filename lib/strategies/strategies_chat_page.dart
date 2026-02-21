import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:projectbrain/authentication/auth_provider.dart';
import 'package:projectbrain/models/strategies/suggested_strategy.dart';
import 'package:projectbrain/strategies/strategies_chat_provider.dart';
import 'package:projectbrain/strategies/strategies_localizations.dart';
import 'package:projectbrain/strategies/strategies_provider.dart';
import 'package:projectbrain/widgets/chat/typing_indicator.dart';

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
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.formatGreeting(name),
                          style: theme.textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Try one of these:',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _ExampleChip(
                          label: l10n.examplePrompt1,
                          onTap: () => chatProvider.sendMessage(l10n.examplePrompt1),
                        ),
                        const SizedBox(height: 8),
                        _ExampleChip(
                          label: l10n.examplePrompt2,
                          onTap: () => chatProvider.sendMessage(l10n.examplePrompt2),
                        ),
                        const SizedBox(height: 8),
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
                  padding: const EdgeInsets.all(16),
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
              padding: EdgeInsets.symmetric(vertical: 8),
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
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
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
                      padding: const EdgeInsets.all(8),
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
                          const SizedBox(width: 8),
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
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
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
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.5),
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(Icons.chat_bubble_outline, size: 20, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
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
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(16),
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
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
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
        const SizedBox(height: 16),
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
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
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
                      padding: const EdgeInsets.only(right: 12),
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
              const SizedBox(height: 8),
              Text(
                strategy.description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                ),
              ),
              if (onLearnMore != null) ...[
                const SizedBox(height: 8),
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
