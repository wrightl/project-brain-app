import 'package:flutter/material.dart';
import 'package:projectbrain/services/connectivity_service.dart';
import 'package:provider/provider.dart';
import 'package:projectbrain/helpers/themes/app_spacing.dart';

/// Wraps the app content and shows a thin banner at the bottom when the device
/// is offline. Placed via `MaterialApp.router`'s builder so it is visible on
/// every route.
class OfflineBanner extends StatelessWidget {
  final Widget? child;

  const OfflineBanner({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final content = child ?? const SizedBox.shrink();
    final isOnline = context.select<ConnectivityService, bool>(
      (service) => service.isOnline,
    );

    return Material(
      type: MaterialType.transparency,
      child: Column(
        children: [
          Expanded(child: content),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            child: isOnline
                ? const SizedBox.shrink()
                : _OfflineBar(),
          ),
        ],
      ),
    );
  }
}

class _OfflineBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      top: false,
      child: Container(
        width: double.infinity,
        color: theme.colorScheme.errorContainer,
        padding: EdgeInsets.symmetric(vertical: AppSpacing.sm, horizontal: AppSpacing.lg),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off,
              size: 18,
              color: theme.colorScheme.onErrorContainer,
            ),
            SizedBox(width: AppSpacing.sm),
            Flexible(
              child: Text(
                'You are offline. Some features may be unavailable.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onErrorContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
