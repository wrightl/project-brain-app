import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:projectbrain/core/di/injection_container.dart';
import 'package:projectbrain/models/connection.dart';
import 'package:projectbrain/services/connection_service.dart';
import 'package:projectbrain/helpers/themes/app_spacing.dart';

/// Talk to a Coach — list connected coaches with message and manage actions.
class CoachesListPage extends StatefulWidget {
  const CoachesListPage({super.key});

  @override
  State<CoachesListPage> createState() => _CoachesListPageState();
}

class _CoachesListPageState extends State<CoachesListPage> {
  final ConnectionService _connectionService = sl<ConnectionService>();
  List<Connection> _connections = [];
  final Set<String> _removingIds = {};
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadConnections();
  }

  Future<void> _loadConnections() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final connections = await _connectionService.getActiveConnections();
      setState(() {
        _connections = connections;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load coaches: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _navigateToChat(Connection connection) {
    context.go('/network/chat/${connection.id}');
  }

  void _navigateToProfile(Connection connection) {
    final profileId = connection.coachProfileId;
    if (profileId != null && profileId.isNotEmpty) {
      context.push('/network/coaches/$profileId');
    }
  }

  void _navigateToFindCoach() {
    context.go('/network/find');
  }

  Future<void> _confirmRemoveConnection(Connection connection) async {
    final isPending = connection.isPending;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isPending ? 'Cancel request?' : 'Remove connection?'),
        content: Text(
          isPending
              ? 'Cancel your connection request to ${connection.coachName ?? 'this coach'}?'
              : 'Remove your connection with ${connection.coachName ?? 'this coach'}? '
                  'You will no longer be able to message them.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(isPending ? 'Cancel request' : 'Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    await _removeConnection(connection);
  }

  Future<void> _removeConnection(Connection connection) async {
    setState(() {
      _removingIds.add(connection.id);
    });

    try {
      await _connectionService.deleteConnection(connection.id);
      if (!mounted) return;
      setState(() {
        _connections.removeWhere((c) => c.id == connection.id);
        _removingIds.remove(connection.id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            connection.isPending
                ? 'Connection request cancelled'
                : 'Connection removed',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _removingIds.remove(connection.id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update connection: ${e.toString()}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return DateFormat('d MMM yyyy').format(date);
  }

  Color _statusColor(Connection connection, ThemeData theme) {
    if (connection.isAccepted) return Colors.green;
    if (connection.isPending) return Colors.orange;
    return theme.colorScheme.onSurface.withValues(alpha: 0.6);
  }

  String _statusLabel(Connection connection) {
    if (connection.isAccepted) return 'Connected';
    if (connection.isPending) return 'Pending';
    return connection.status;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Talk to a Coach'),
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
              child: Text(
                'Your connected coaches. Send a message or manage your connections.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ),
            Padding(
              padding: AppInsets.screen,
              child: OutlinedButton.icon(
                onPressed: _navigateToFindCoach,
                icon: const Icon(Icons.person_add),
                label: const Text('Find a Coach'),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.s14),
                ),
              ),
            ),
            if (_errorMessage != null)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Container(
                  padding: AppInsets.screen,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer,
                    borderRadius: AppRadius.circularSm,
                  ),
                  child: Text(
                    _errorMessage!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onErrorContainer,
                    ),
                  ),
                ),
              ),
            if (_isLoading)
              const Expanded(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_connections.isEmpty)
              Expanded(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.xxl),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 64,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.3),
                        ),
                        SizedBox(height: AppSpacing.lg),
                        Text(
                          'No coaches connected yet',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.6),
                          ),
                        ),
                        SizedBox(height: AppSpacing.sm),
                        Text(
                          'Find and connect with a coach to start messaging.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.5),
                          ),
                        ),
                        SizedBox(height: AppSpacing.xl),
                        FilledButton.icon(
                          onPressed: _navigateToFindCoach,
                          icon: const Icon(Icons.search),
                          label: const Text('Find a Coach'),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _loadConnections,
                  child: ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    itemCount: _connections.length,
                    itemBuilder: (context, index) {
                      final connection = _connections[index];
                      final isRemoving = _removingIds.contains(connection.id);
                      final statusColor = _statusColor(connection, theme);

                      return Card(
                        margin: AppInsets.listItemBottom,
                        child: Padding(
                          padding: AppInsets.screen,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundColor:
                                        theme.colorScheme.primaryContainer,
                                    child: Icon(
                                      Icons.person,
                                      color:
                                          theme.colorScheme.onPrimaryContainer,
                                    ),
                                  ),
                                  SizedBox(width: AppSpacing.md),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          connection.coachName ?? 'Coach',
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        SizedBox(height: AppSpacing.xs),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: AppSpacing.sm,
                                            vertical: AppSpacing.micro,
                                          ),
                                          decoration: BoxDecoration(
                                            color: statusColor.withValues(
                                              alpha: 0.15,
                                            ),
                                            borderRadius:
                                                AppRadius.circularMd,
                                          ),
                                          child: Text(
                                            _statusLabel(connection),
                                            style: theme.textTheme.labelSmall
                                                ?.copyWith(
                                              color: statusColor,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              if (connection.isAccepted &&
                                  connection.respondedAt != null)
                                Padding(
                                  padding: EdgeInsets.only(top: AppSpacing.sm),
                                  child: Text(
                                    'Connected on ${_formatDate(connection.respondedAt)}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.6),
                                    ),
                                  ),
                                ),
                              if (connection.isPending &&
                                  connection.requestedAt != null)
                                Padding(
                                  padding: EdgeInsets.only(top: AppSpacing.sm),
                                  child: Text(
                                    'Requested on ${_formatDate(connection.requestedAt)}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.6),
                                    ),
                                  ),
                                ),
                              SizedBox(height: AppSpacing.md),
                              Wrap(
                                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                                children: [
                                  if (connection.isAccepted)
                                    FilledButton.icon(
                                      onPressed: isRemoving
                                          ? null
                                          : () => _navigateToChat(connection),
                                      icon: const Icon(Icons.chat, size: 18),
                                      label: const Text('Message'),
                                    ),
                                  if (connection.coachProfileId != null &&
                                      connection.coachProfileId!.isNotEmpty)
                                    OutlinedButton.icon(
                                      onPressed: isRemoving
                                          ? null
                                          : () =>
                                              _navigateToProfile(connection),
                                      icon: const Icon(Icons.person, size: 18),
                                      label: const Text('View profile'),
                                    ),
                                  OutlinedButton.icon(
                                    onPressed: isRemoving
                                        ? null
                                        : () =>
                                            _confirmRemoveConnection(connection),
                                    icon: isRemoving
                                        ? SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: theme.colorScheme.primary,
                                            ),
                                          )
                                        : Icon(
                                            Icons.link_off,
                                            size: 18,
                                            color: theme.colorScheme.error,
                                          ),
                                    label: Text(
                                      connection.isPending
                                          ? 'Cancel'
                                          : 'Remove',
                                      style: theme.textTheme.labelLarge?.copyWith(
                                        color: theme.colorScheme.error,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
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
