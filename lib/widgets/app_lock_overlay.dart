import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:projectbrain/authentication/auth_provider.dart';
import 'package:projectbrain/core/security/app_lock_controller.dart';
import 'package:projectbrain/helpers/themes/app_spacing.dart';

/// Covers [child] with an opaque screen while the app is backgrounded (so the
/// app-switcher snapshot shows no journal or chat content) and with an unlock
/// prompt while [AppLockController.isLocked].
class AppLockOverlay extends StatelessWidget {
  const AppLockOverlay({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final lock = context.watch<AppLockController>();
    final authProvider = context.watch<AuthProvider>();
    final locked = lock.isLocked && authProvider.isLoggedIn;
    final covered = locked || lock.isObscured;

    return Stack(
      children: [
        // A visual cover is not enough: screen readers would still read, and
        // could activate, the content underneath. Remove it from semantics
        // and hit testing while covered.
        ExcludeSemantics(
          excluding: covered,
          child: IgnorePointer(ignoring: covered, child: child),
        ),
        if (locked)
          Positioned.fill(
            child: BlockSemantics(
              child: _UnlockScreen(
                label: authProvider.biometricUnlockLabel,
                isUnlocking: lock.isUnlocking,
                onUnlock: lock.unlock,
              ),
            ),
          )
        else if (lock.isObscured)
          Positioned.fill(
            child: ColoredBox(color: Theme.of(context).colorScheme.surface),
          ),
      ],
    );
  }
}

class _UnlockScreen extends StatelessWidget {
  const _UnlockScreen({
    required this.label,
    required this.isUnlocking,
    required this.onUnlock,
  });

  final String label;
  final bool isUnlocking;
  final VoidCallback onUnlock;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              const Spacer(),
              Icon(
                Icons.lock_outline,
                size: 48,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: AppSpacing.md),
              Semantics(
                header: true,
                liveRegion: true,
                child: Text(
                  'Project Brain is locked',
                  style: theme.textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isUnlocking ? null : onUnlock,
                  icon: const Icon(Icons.fingerprint),
                  label: Text(label),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
