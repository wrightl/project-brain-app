import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:projectbrain/authentication/auth_provider.dart';
import 'package:projectbrain/journal/journal_localizations.dart';
import 'package:projectbrain/journal/journal_provider.dart';
import 'package:projectbrain/strategies/strategies_localizations.dart';
import 'package:projectbrain/strategies/strategies_provider.dart';
import 'package:projectbrain/widgets/link_list.dart';
import 'package:provider/provider.dart';

/// Home page of the application
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final journalProvider = context.read<JournalProvider>();
      journalProvider.loadStreakSummary();
      journalProvider.loadEntryCount();
      journalProvider.loadRecentEntries(count: 3);
      context.read<StrategiesProvider>().loadLibrary();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final name = authProvider.profile?.name ?? 'User';
    final theme = Theme.of(context);
    final l10n = JournalLocalizations.of(context);
    final strategiesL10n = StrategiesLocalizations.of(context);

    // Define the list of navigation links
    final links = [
      NavigationLink(
        icon: Icons.check_circle,
        title: 'Eggs',
        subtitle: 'Set and track your 3 daily goals',
        onTap: () => context.go('/goals'),
      ),
      NavigationLink(
        icon: Icons.book,
        title: l10n.journal,
        subtitle: 'Write and reflect with journal entries',
        onTap: () => context.go('/journal'),
      ),
      NavigationLink(
        icon: Icons.psychology,
        title: strategiesL10n.copingStrategies,
        subtitle: strategiesL10n.getNewStrategies,
        onTap: () => context.go('/strategies/chat'),
      ),
      NavigationLink(
        icon: Icons.library_books,
        title: strategiesL10n.viewLibrary,
        subtitle: strategiesL10n.formatYouHaveNSavedStrategies(
          context.watch<StrategiesProvider>().items.length,
        ),
        onTap: () => context.go('/strategies'),
      ),
      NavigationLink(
        icon: Icons.person,
        title: 'User',
        subtitle: 'Manage your account and resources',
        onTap: () => context.go('/user'),
      ),
      NavigationLink(
        icon: Icons.assistant,
        title: 'Chat',
        subtitle: 'Start a conversation with your AI assistant',
        onTap: () => context.go('/ai'),
      ),
      NavigationLink(
        icon: Icons.quiz,
        title: 'Quizzes',
        subtitle: 'Take quizzes to identify neurodiverse traits',
        onTap: () => context.go('/quizzes'),
      ),
      NavigationLink(
        icon: Icons.people,
        title: 'Network',
        subtitle: 'Connect with coaches for support',
        onTap: () => context.go('/network'),
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Welcome message
              Text(
                'Welcome, $name!',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Get started by exploring the different areas of the app.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 32),

              // Journal streak and summary
              Consumer<JournalProvider>(
                builder: (context, journalProvider, _) {
                  final streak = journalProvider.streakSummary;
                  final count = journalProvider.entryCount;
                  final recent = journalProvider.recentEntries;
                  final hasAny = streak != null ||
                      (count != null && count > 0) ||
                      recent.isNotEmpty;
                  if (!hasAny) return const SizedBox.shrink();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (streak != null) ...[
                        Text(
                          l10n.journalStreak,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          streak.currentStreak == 0 && streak.longestStreak == 0
                              ? l10n.noStreakYet
                              : '${l10n.formatStreakDays(streak.currentStreak)} (${l10n.formatBest(streak.longestStreak)})',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      if (count != null && count > 0)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            l10n.formatYouHaveNEntries(count),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ),
                      if (recent.isNotEmpty) ...[
                        Text(
                          l10n.recentEntries,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        ...recent.take(3).map((e) => ListTile(
                              title: Text(
                                e.summary ?? e.content,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => context.go('/journal/${e.id}'),
                            )),
                        TextButton(
                          onPressed: () => context.go('/journal'),
                          child: Text(l10n.seeAll),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ],
                  );
                },
              ),

              // Quick links section using reusable component
              LinkList(
                links: links,
                sectionTitle: 'Quick Links',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
