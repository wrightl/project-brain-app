import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:projectbrain/core/di/injection_container.dart';
import 'package:projectbrain/models/coach.dart';
import 'package:projectbrain/services/coach_service.dart';
import 'package:projectbrain/subscription/subscription_provider.dart';
import 'package:projectbrain/subscription/widgets/upgrade_prompt.dart';
import 'package:projectbrain/models/subscription.dart';

/// Page showing detailed information about a coach
class CoachDetailsPage extends StatefulWidget {
  final String coachId;

  const CoachDetailsPage({
    super.key,
    required this.coachId,
  });

  @override
  State<CoachDetailsPage> createState() => _CoachDetailsPageState();
}

class _CoachDetailsPageState extends State<CoachDetailsPage> {
  final CoachService _coachService = sl<CoachService>();

  Coach? _coach;
  ConnectionStatus _connectionStatus = ConnectionStatus.none;
  String? _connectionId;
  bool _isLoading = true;
  bool _isUpdatingConnection = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCoachDetails();
  }

  Future<void> _loadCoachDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Load coach details and connection status in parallel
      final results = await Future.wait([
        _coachService.getCoachById(widget.coachId),
        _coachService.getConnectionStatus(widget.coachId),
      ]);

      setState(() {
        _coach = results[0] as Coach;
        final statusResult = results[1] as CoachConnectionStatusResult;
        _connectionStatus = statusResult.status;
        _connectionId = statusResult.connectionId;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load coach details: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _sendConnectionRequest() async {
    // Check connection limit
    final subscriptionProvider = Provider.of<SubscriptionProvider>(context, listen: false);
    final connectionLimit = subscriptionProvider.getCoachConnectionLimit();
    
    if (connectionLimit != null) {
      // Get current connection count
      try {
        final connectedCoaches = await _coachService.getConnectedCoaches();
        final currentCount = connectedCoaches.length;
        
        if (currentCount >= connectionLimit) {
          // Show upgrade prompt
          if (mounted) {
            showDialog(
              context: context,
              builder: (context) => UpgradePromptDialog(
                requiredTier: SubscriptionTier.pro,
                featureName: 'Coach connections',
              ),
            );
          }
          return;
        }
      } catch (e) {
        // If we can't fetch connections, proceed anyway (backend will enforce)
        debugPrint('Could not fetch connection count: $e');
      }
    }

    setState(() {
      _isUpdatingConnection = true;
      _errorMessage = null;
    });

    try {
      final status = await _coachService.sendConnectionRequest(widget.coachId);
      setState(() {
        _connectionStatus = status;
        _isUpdatingConnection = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              status == ConnectionStatus.connected
                  ? 'Connected successfully'
                  : 'Connection request sent successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to send connection request: ${e.toString()}';
        _isUpdatingConnection = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _cancelConnectionRequest() async {
    setState(() {
      _isUpdatingConnection = true;
      _errorMessage = null;
    });

    try {
      await _coachService.cancelConnectionRequest(widget.coachId);
      setState(() {
        _connectionStatus = ConnectionStatus.none;
        _isUpdatingConnection = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Connection request cancelled'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to cancel connection request: ${e.toString()}';
        _isUpdatingConnection = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildConnectionButton() {
    if (_isUpdatingConnection) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    switch (_connectionStatus) {
      case ConnectionStatus.none:
        return Consumer<SubscriptionProvider>(
          builder: (context, subscriptionProvider, _) {
            final connectionLimit = subscriptionProvider.getCoachConnectionLimit();
            
            // Show connection count if limited
            Widget? connectionInfo;
            if (connectionLimit != null) {
              // We'll need to fetch this, but for now show the limit
              connectionInfo = FutureBuilder<List<Coach>>(
                future: _coachService.getConnectedCoaches(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    final currentCount = snapshot.data!.length;
                    final isAtLimit = currentCount >= connectionLimit;
                    
                    if (isAtLimit) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          'Connection limit reached ($currentCount/$connectionLimit)',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.error,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      );
                    }
                    
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        '$currentCount/$connectionLimit connections',
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              );
            }
            
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (connectionInfo != null) connectionInfo,
                ElevatedButton.icon(
                  onPressed: _sendConnectionRequest,
                  icon: const Icon(Icons.person_add),
                  label: const Text('Connect'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            );
          },
        );
      case ConnectionStatus.pending:
        return OutlinedButton.icon(
          onPressed: _cancelConnectionRequest,
          icon: const Icon(Icons.pending),
          label: const Text('Pending'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        );
      case ConnectionStatus.connected:
        return ElevatedButton.icon(
          onPressed: _connectionId != null
              ? () {
                  context.go('/network/chat/$_connectionId');
                }
              : null,
          icon: const Icon(Icons.chat),
          label: const Text('Message'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            backgroundColor: Colors.green,
          ),
        );
    }
  }

  Widget _buildInfoSection({
    required String title,
    required Widget content,
  }) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            content,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_coach?.fullName ?? 'Coach Details'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _coach == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: theme.colorScheme.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage ?? 'Failed to load coach details',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadCoachDetails,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Error message
                      if (_errorMessage != null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(
                              color: theme.colorScheme.onErrorContainer,
                            ),
                          ),
                        ),

                      // Connection status and button
                      Card(
                        color: _connectionStatus == ConnectionStatus.connected
                            ? theme.colorScheme.primaryContainer
                            : theme.colorScheme.surfaceContainerHighest,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Connection Status',
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.7),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _connectionStatus.displayName,
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              _buildConnectionButton(),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Profile header
                      _buildInfoSection(
                        title: 'Profile',
                        content: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 40,
                                  backgroundColor:
                                      theme.colorScheme.primaryContainer,
                                  child: Icon(
                                    Icons.person,
                                    size: 40,
                                    color: theme.colorScheme.onPrimaryContainer,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _coach!.fullName,
                                        style: theme.textTheme.headlineSmall
                                            ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (_coach!.email != null) ...[
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.email,
                                              size: 16,
                                              color: theme.colorScheme.onSurface
                                                  .withValues(alpha: 0.6),
                                            ),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                _coach!.email!,
                                                style: theme.textTheme.bodyMedium
                                                    ?.copyWith(
                                                  color: theme.colorScheme
                                                      .onSurface
                                                      .withValues(alpha: 0.7),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (_coach!.phone != null) ...[
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Icon(
                                    Icons.phone,
                                    size: 16,
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.6),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _coach!.phone!,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.7),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),

                      // Location
                      if (_coach!.postalCode != null ||
                          _coach!.city != null ||
                          _coach!.streetAddress != null)
                        _buildInfoSection(
                          title: 'Location',
                          content: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (_coach!.streetAddress != null)
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.home,
                                      size: 16,
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.6),
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        _coach!.streetAddress!,
                                        style: theme.textTheme.bodyMedium,
                                      ),
                                    ),
                                  ],
                                ),
                              if (_coach!.city != null) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.location_city,
                                      size: 16,
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.6),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _coach!.city!,
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                  ],
                                ),
                              ],
                              if (_coach!.postalCode != null) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.location_on,
                                      size: 16,
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.6),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _coach!.postalCode!,
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),

                      // Specialisms
                      if (_coach!.specialisms != null &&
                          _coach!.specialisms!.isNotEmpty)
                        _buildInfoSection(
                          title: 'Specialisms',
                          content: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _coach!.specialisms!.map((spec) {
                              return Chip(
                                label: Text(spec),
                                backgroundColor:
                                    theme.colorScheme.primaryContainer,
                                labelStyle: TextStyle(
                                  color: theme.colorScheme.onPrimaryContainer,
                                ),
                              );
                            }).toList(),
                          ),
                        ),

                      // Qualifications
                      if (_coach!.qualifications != null &&
                          _coach!.qualifications!.isNotEmpty)
                        _buildInfoSection(
                          title: 'Qualifications',
                          content: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: _coach!.qualifications!.map((qual) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.school,
                                      size: 16,
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.6),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        qual,
                                        style: theme.textTheme.bodyMedium,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),

                      // Age Groups
                      if (_coach!.ageGroups != null &&
                          _coach!.ageGroups!.isNotEmpty)
                        _buildInfoSection(
                          title: 'Age Groups',
                          content: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _coach!.ageGroups!.map((ageGroup) {
                              return Chip(
                                label: Text(ageGroup),
                                backgroundColor:
                                    theme.colorScheme.secondaryContainer,
                                labelStyle: TextStyle(
                                  color: theme.colorScheme.onSecondaryContainer,
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }
}

