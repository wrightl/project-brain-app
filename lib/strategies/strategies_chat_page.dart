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
import 'package:projectbrain/helpers/themes/app_theme_extension.dart';
import 'package:projectbrain/widgets/ds/ds_widgets.dart';

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
    final appTheme = context.appTheme;
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
                          color: appTheme.amber,
                          backgroundColor: appTheme.amberSoft,
                          onTap: () =>
                              chatProvider.sendMessage(l10n.examplePrompt1),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _ExampleChip(
                          label: l10n.examplePrompt2,
                          color: appTheme.coral,
                          backgroundColor: appTheme.coralSoft,
                          onTap: () =>
                              chatProvider.sendMessage(l10n.examplePrompt2),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _ExampleChip(
                          label: l10n.examplePrompt3,
                          color: appTheme.teal,
                          backgroundColor: appTheme.tealSoft,
                          onTap: () =>
                              chatProvider.sendMessage(l10n.examplePrompt3),
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
                      padding: EdgeInsets.fromLTRB(
                          AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 0),
                      child: FilledButton.icon(
                        onPressed: chatProvider.isLoading
                            ? null
                            : () => _saveSelected(context, chatProvider),
                        icon: const Icon(Icons.save),
                        label: Text(
                          l10n.formatSaveCount(
                              chatProvider.selectedStrategies.length),
                        ),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(double.infinity, 44),
                        ),
                      ),
                    ),
                  SafeArea(
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        AppSpacing.sm,
                        AppSpacing.md,
                        AppSpacing.md,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        border: Border(
                            top: BorderSide(color: appTheme.borderColor)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              decoration: InputDecoration(
                                hintText: "Tell me what you're dealing with...",
                                filled: true,
                                fillColor: theme.scaffoldBackgroundColor,
                                border: OutlineInputBorder(
                                  borderRadius: AppRadius.circularPill,
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              enabled: !chatProvider.isLoading,
                              onSubmitted: (text) => _send(context, text),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Material(
                            color: theme.colorScheme.primary,
                            shape: const CircleBorder(),
                            child: InkWell(
                              onTap: chatProvider.isLoading
                                  ? null
                                  : () => _send(context, _controller.text),
                              customBorder: const CircleBorder(),
                              child: SizedBox(
                                width: 44,
                                height: 44,
                                child: Icon(
                                  Icons.arrow_upward,
                                  color: theme.colorScheme.onPrimary,
                                  size: 20,
                                ),
                              ),
                            ),
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

  Future<void> _saveSelected(
      BuildContext context, StrategiesChatProvider chatProvider) async {
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
          content:
              Text(StrategiesLocalizations.of(context).couldNotSaveStrategies),
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
  final Color color;
  final Color backgroundColor;
  final VoidCallback onTap;

  const _ExampleChip({
    required this.label,
    required this.color,
    required this.backgroundColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DsSurfaceCard(
      onTap: onTap,
      child: Row(
        children: [
          IconBubble(
            icon: Icons.chat_bubble_outline,
            color: color,
            backgroundColor: backgroundColor,
            size: 36,
            iconSize: 18,
            borderRadius: 10,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(label, style: theme.textTheme.bodyMedium),
          ),
        ],
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
    final appTheme = context.appTheme;
    final l10n = StrategiesLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(4),
              ),
            ),
            child: Text(
              turn.userMessage,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onPrimary,
              ),
            ),
          ),
        ),
        if (turn.assistantText.isNotEmpty)
          Container(
            margin: AppInsets.listItemBottom,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
              ),
              border: Border.all(color: appTheme.borderColor),
            ),
            child: Text(
              turn.assistantText,
              style: theme.textTheme.bodyMedium,
            ),
          ),
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
    final appTheme = context.appTheme;
    final icon = _iconFor(strategy.iconKey);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: DsSurfaceCard(
        onTap: onTap,
        borderColor:
            isSelected ? theme.colorScheme.primary : appTheme.borderColor,
        backgroundColor:
            isSelected ? appTheme.primarySoft : theme.colorScheme.surface,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null)
                  IconBubble(
                    icon: icon,
                    color: appTheme.amber,
                    backgroundColor: appTheme.amberSoft,
                    size: 36,
                    iconSize: 18,
                    borderRadius: 10,
                  ),
                if (icon != null) const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    strategy.title,
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check_circle, color: theme.colorScheme.primary),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(strategy.description, style: theme.textTheme.bodySmall),
            if (onLearnMore != null) ...[
              const SizedBox(height: AppSpacing.sm),
              TextButton(
                onPressed: onLearnMore,
                child: Text(l10n.learnMore),
              ),
            ],
          ],
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
