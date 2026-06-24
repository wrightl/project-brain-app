import 'package:flutter/material.dart';
import 'package:projectbrain/authentication/auth_provider.dart';
import 'package:projectbrain/helpers/themes/app_spacing.dart';
import 'package:provider/provider.dart';

class ProfileLoadErrorPage extends StatelessWidget {
  const ProfileLoadErrorPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: theme.colorScheme.error,
              ),
              SizedBox(height: AppSpacing.lg),
              Text(
                'Couldn\'t load your profile',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: AppSpacing.sm),
              Text(
                authProvider.errorMessage ??
                    'Check your connection and try again.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              SizedBox(height: AppSpacing.xl),
              if (authProvider.isLoading)
                const CircularProgressIndicator()
              else
                FilledButton(
                  onPressed: () => authProvider.refreshUserData(),
                  child: const Text('Retry'),
                ),
              SizedBox(height: AppSpacing.md),
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
