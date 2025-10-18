import 'package:flutter/material.dart';
import 'package:projectbrain/authentication/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:projectbrain/core/config/app_config.dart';
import 'package:projectbrain/helpers/theme.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final appColors = theme.extension<AppThemeExtension>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Determine if we're in landscape mode
            final isLandscape = constraints.maxWidth > constraints.maxHeight;

            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: isLandscape
                        ? _buildLandscapeLayout(authProvider, theme,
                            colorScheme, appColors, context)
                        : _buildPortraitLayout(authProvider, theme, colorScheme,
                            appColors, context),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Portrait layout - vertical column centered
  Widget _buildPortraitLayout(
    AuthProvider authProvider,
    ThemeData theme,
    ColorScheme colorScheme,
    AppThemeExtension? appColors,
    BuildContext context,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildEnvironmentBadge(colorScheme, appColors),
        _buildProfileAvatar(authProvider),
        const SizedBox(height: 16),
        _buildProfileName(authProvider),
        const SizedBox(height: 8),
        _buildProfileEmail(authProvider, theme, colorScheme),
        const SizedBox(height: 32),
        _buildDebugTokenSection(
            authProvider, theme, colorScheme, appColors, context),
        _buildLogoutButton(authProvider, colorScheme),
      ],
    );
  }

  /// Landscape layout - horizontal with scrolling
  Widget _buildLandscapeLayout(
    AuthProvider authProvider,
    ThemeData theme,
    ColorScheme colorScheme,
    AppThemeExtension? appColors,
    BuildContext context,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Left side - Profile info
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildEnvironmentBadge(colorScheme, appColors),
              _buildProfileAvatar(authProvider),
              const SizedBox(height: 16),
              _buildProfileName(authProvider),
              const SizedBox(height: 8),
              _buildProfileEmail(authProvider, theme, colorScheme),
            ],
          ),
        ),
        const SizedBox(width: 24),
        // Right side - Actions
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildDebugTokenSection(
                  authProvider, theme, colorScheme, appColors, context),
              _buildLogoutButton(authProvider, colorScheme),
            ],
          ),
        ),
      ],
    );
  }

  /// Environment badge widget
  Widget _buildEnvironmentBadge(
    ColorScheme colorScheme,
    AppThemeExtension? appColors,
  ) {
    if (AppConfig.isProduction) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: AppConfig.isDev
              ? appColors?.devBadgeColor ?? Colors.orange
              : appColors?.stagingBadgeColor ?? Colors.blue,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              AppConfig.isDev ? Icons.code : Icons.science,
              color: colorScheme.onPrimary,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              AppConfig.environmentName.toUpperCase(),
              style: TextStyle(
                color: colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Profile avatar widget
  Widget _buildProfileAvatar(AuthProvider authProvider) {
    return CircleAvatar(
      radius: 50,
      backgroundImage: NetworkImage(authProvider.profile?.picture ?? ''),
    );
  }

  /// Profile name widget
  Widget _buildProfileName(AuthProvider authProvider) {
    return Text(
      authProvider.profile?.name ?? '',
      style: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
      ),
      textAlign: TextAlign.center,
    );
  }

  /// Profile email widget
  Widget _buildProfileEmail(
    AuthProvider authProvider,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Text(
      authProvider.profile?.email ?? '',
      style: theme.textTheme.bodyMedium?.copyWith(
        color: colorScheme.onSurfaceVariant,
      ),
      textAlign: TextAlign.center,
    );
  }

  /// Debug token section widget
  Widget _buildDebugTokenSection(
    AuthProvider authProvider,
    ThemeData theme,
    ColorScheme colorScheme,
    AppThemeExtension? appColors,
    BuildContext context,
  ) {
    if (!kDebugMode) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: FutureBuilder<String?>(
        future: authProvider.authService.getAccessToken(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Text('Loading access token...');
          }
          if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          }
          final token = snapshot.data ?? "";
          String truncated = token.length > 32
              ? '${token.substring(0, 16)}...${token.substring(token.length - 8)}'
              : token;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SelectableText(
                'Access Token:\n$truncated',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: appColors?.debugTextColor ?? colorScheme.error,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                icon: const Icon(Icons.copy),
                label: const Text('Copy Full Token'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  foregroundColor: colorScheme.onSurface,
                ),
                onPressed: token.isEmpty
                    ? null
                    : () async {
                        await Clipboard.setData(ClipboardData(text: token));
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Token copied to clipboard')),
                          );
                        }
                      },
              ),
            ],
          );
        },
      ),
    );
  }

  /// Logout button widget
  Widget _buildLogoutButton(
    AuthProvider authProvider,
    ColorScheme colorScheme,
  ) {
    return ElevatedButton.icon(
      icon: const Icon(Icons.logout),
      label: const Text('Logout'),
      style: ElevatedButton.styleFrom(
        backgroundColor: colorScheme.error,
        foregroundColor: colorScheme.onError,
      ),
      onPressed: () {
        authProvider.logout();
      },
    );
  }
}
