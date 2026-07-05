import 'package:flutter/material.dart';
import 'package:projectbrain/authentication/auth_provider.dart';
import 'package:projectbrain/helpers/themes/app_spacing.dart';
import 'package:projectbrain/helpers/themes/app_theme_extension.dart';
import 'package:projectbrain/widgets/ds/ds_widgets.dart';
import 'package:provider/provider.dart';

class ProfileLoadErrorPage extends StatelessWidget {
  const ProfileLoadErrorPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final theme = Theme.of(context);
    final appTheme = context.appTheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: AppInsets.page,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconBubble(
                icon: Icons.error_outline,
                color: theme.colorScheme.error,
                backgroundColor:
                    theme.colorScheme.errorContainer.withValues(alpha: 0.35),
                size: 72,
                iconSize: 36,
                borderRadius: 20,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                "Couldn't load your profile",
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                authProvider.errorMessage ??
                    'Check your connection and try again.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: appTheme.textMuted,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              if (authProvider.isLoading)
                const CircularProgressIndicator()
              else
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => authProvider.refreshUserData(),
                    child: const Text('Retry'),
                  ),
                ),
              const SizedBox(height: AppSpacing.md),
              if (!authProvider.isLoading)
                TextButton(
                  onPressed: () => authProvider.logout(),
                  child: const Text('Log out'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
