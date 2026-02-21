import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:projectbrain/models/strategies/coping_strategy_library_item.dart';
import 'package:projectbrain/strategies/strategies_localizations.dart';
import 'package:projectbrain/strategies/strategies_provider.dart';

/// Strategies library screen: list saved strategies, rate, delete.
class StrategiesLibraryPage extends StatefulWidget {
  const StrategiesLibraryPage({super.key});

  @override
  State<StrategiesLibraryPage> createState() => _StrategiesLibraryPageState();
}

class _StrategiesLibraryPageState extends State<StrategiesLibraryPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StrategiesProvider>().loadLibrary();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = StrategiesLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.strategiesLibrary),
      ),
      body: Consumer<StrategiesProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.items.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.errorMessage != null && provider.items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    provider.errorMessage!,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => provider.loadLibrary(),
                    child: Text(l10n.retry),
                  ),
                ],
              ),
            );
          }
          if (provider.items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.psychology_outlined,
                      size: 64,
                      color: theme.colorScheme.primary.withValues(alpha: 0.6),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.emptyLibraryTitle,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.emptyLibraryMessage,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () => context.go('/strategies/chat'),
                      icon: const Icon(Icons.add),
                      label: Text(l10n.getNewStrategies),
                    ),
                  ],
                ),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () => provider.loadLibrary(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.items.length,
              itemBuilder: (context, index) {
                final item = provider.items[index];
                return _StrategyLibraryCard(
                  item: item,
                  onRatingChanged: (rating) =>
                      provider.updateRating(item.id, rating),
                  onDelete: () => _confirmDelete(context, provider, item, l10n),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    StrategiesProvider provider,
    CopingStrategyLibraryItem item,
    StrategiesLocalizations l10n,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.delete),
        content: Text(l10n.deleteStrategyConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final ok = await provider.deleteStrategy(item.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? l10n.strategyDeleted : l10n.couldNotDeleteStrategy),
        ),
      );
    }
  }
}

class _StrategyLibraryCard extends StatelessWidget {
  final CopingStrategyLibraryItem item;
  final ValueChanged<int> onRatingChanged;
  final VoidCallback onDelete;

  const _StrategyLibraryCard({
    required this.item,
    required this.onRatingChanged,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateStr = DateFormat.yMMMd().format(item.savedAt);
    final icon = _iconFor(item.iconKey);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (icon != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Icon(icon, color: theme.colorScheme.primary, size: 28),
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.description,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                        ),
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        dateStr,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'delete') onDelete();
                  },
                  itemBuilder: (ctx) => [
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline,
                              color: theme.colorScheme.error),
                          const SizedBox(width: 8),
                          Text(
                            StrategiesLocalizations.of(context).delete,
                            style: TextStyle(color: theme.colorScheme.error),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: List.generate(5, (i) {
                final star = i + 1;
                final isFilled = (item.rating ?? 0) >= star;
                return IconButton(
                  icon: Icon(
                    isFilled ? Icons.star : Icons.star_border,
                    color: isFilled
                        ? (theme.colorScheme.primary)
                        : theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                  onPressed: () => onRatingChanged(star),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                );
              }),
            ),
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
