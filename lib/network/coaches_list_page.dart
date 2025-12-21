import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:projectbrain/core/di/injection_container.dart';
import 'package:projectbrain/models/coach.dart';
import 'package:projectbrain/services/coach_service.dart';

/// Page for listing connected coaches
class CoachesListPage extends StatefulWidget {
  const CoachesListPage({super.key});

  @override
  State<CoachesListPage> createState() => _CoachesListPageState();
}

class _CoachesListPageState extends State<CoachesListPage> {
  final CoachService _coachService = sl<CoachService>();
  List<Coach> _coaches = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadConnectedCoaches();
  }

  Future<void> _loadConnectedCoaches() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final coaches = await _coachService.getConnectedCoaches();
      setState(() {
        _coaches = coaches;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load coaches: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _navigateToChat(Coach coach) {
    context.go('/network/chat/${coach.id}');
  }

  void _navigateToFindCoach() {
    context.go('/network/find');
  }

  Color _getConnectionStatusColor(ConnectionStatus status, ThemeData theme) {
    switch (status) {
      case ConnectionStatus.connected:
        return Colors.green;
      case ConnectionStatus.pending:
        return Colors.orange;
      case ConnectionStatus.none:
        return theme.colorScheme.onSurface.withValues(alpha: 0.6);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Coaches'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _navigateToFindCoach,
            tooltip: 'Find a Coach',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Find Coach Button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _navigateToFindCoach,
                  icon: const Icon(Icons.person_add),
                  label: const Text('Find a Coach'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ),

            // Error message
            if (_errorMessage != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: theme.colorScheme.onErrorContainer),
                ),
              ),

            // Loading indicator
            if (_isLoading)
              const Expanded(
                child: Center(child: CircularProgressIndicator()),
              )
            // Empty state
            else if (_coaches.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 64,
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No coaches connected',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Find and connect with coaches to get started',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            // Coaches list
            else
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _loadConnectedCoaches,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _coaches.length,
                    itemBuilder: (context, index) {
                      final coach = _coaches[index];
                      final isOnline = coach.isOnline ?? false;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          leading: Stack(
                            children: [
                              CircleAvatar(
                                radius: 28,
                                backgroundColor:
                                    theme.colorScheme.primaryContainer,
                                child: Icon(
                                  Icons.person,
                                  size: 32,
                                  color: theme.colorScheme.onPrimaryContainer,
                                ),
                              ),
                              // Online indicator
                              if (isOnline)
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: theme.colorScheme.surface,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  coach.fullName,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Connection status
                              if (coach.connectionStatus != null)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getConnectionStatusColor(
                                              coach.connectionStatus!, theme)
                                          .withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      coach.connectionStatus!.displayName,
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color: _getConnectionStatusColor(
                                            coach.connectionStatus!, theme),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                              // Specialisms
                              if (coach.specialisms != null &&
                                  coach.specialisms!.isNotEmpty)
                                Wrap(
                                  spacing: 4,
                                  runSpacing: 4,
                                  children:
                                      coach.specialisms!.take(3).map((spec) {
                                    return Chip(
                                      label: Text(
                                        spec,
                                        style: theme.textTheme.bodySmall,
                                      ),
                                      padding: EdgeInsets.zero,
                                      visualDensity: VisualDensity.compact,
                                    );
                                  }).toList(),
                                ),
                            ],
                          ),
                          trailing: Icon(
                            Icons.chevron_right,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.5),
                          ),
                          onTap: () => _navigateToChat(coach),
                        ),
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
