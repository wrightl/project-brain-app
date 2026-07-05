import 'package:flutter/material.dart';
import 'package:projectbrain/authentication/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:projectbrain/helpers/themes/app_spacing.dart';
import 'package:projectbrain/helpers/themes/app_theme_extension.dart';
import 'package:projectbrain/widgets/ds/ds_widgets.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final theme = Theme.of(context);
    final appTheme = context.appTheme;

    if (authProvider.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: AppInsets.page,
          child: Column(
            children: [
              const Spacer(),
              IconBubble(
                icon: Icons.psychology_outlined,
                color: theme.colorScheme.primary,
                backgroundColor: appTheme.primarySoft,
                size: 72,
                iconSize: 36,
                borderRadius: 20,
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'ProjectBrain',
                style: theme.textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Your AI companion for focus, goals, and growth.',
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              if (authProvider.hasError) ...[
                const SizedBox(height: AppSpacing.lg),
                DsSurfaceCard(
                  backgroundColor:
                      theme.colorScheme.errorContainer.withValues(alpha: 0.35),
                  borderColor: theme.colorScheme.error.withValues(alpha: 0.3),
                  child: Text(
                    authProvider.errorMessage!,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => authProvider.login(),
                  child: const Text('Login / Sign Up'),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}
