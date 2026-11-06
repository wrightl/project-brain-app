import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:projectbrain/authentication/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:projectbrain/core/config/app_config.dart';
import 'package:projectbrain/core/security/url_security.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:projectbrain/helpers/app_themes.dart';
import 'package:projectbrain/helpers/theme.dart';
import 'package:projectbrain/helpers/theme_mode_provider.dart';
import 'package:projectbrain/services/auth/auth_exception.dart';
import 'package:projectbrain/helpers/themes/app_spacing.dart';
import 'package:projectbrain/helpers/themes/app_theme_extension.dart';
import 'package:projectbrain/widgets/ds/ds_widgets.dart';
import 'package:projectbrain/widgets/unsaved_changes_scope.dart';
import 'package:projectbrain/core/network/user_friendly_error.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _customPronounController =
      TextEditingController();

  String _pronoun = '';
  DateTime? _doB;
  Set<String> _selectedTraits = {};
  bool _isEditing = false;
  bool _isSaving = false;
  bool _isDeletingAccount = false;
  String? _snapshotAtEditStart;

  String _snapshot() => [
        _fullNameController.text.trim(),
        _pronoun,
        _customPronounController.text.trim(),
        _dobController.text,
        (_selectedTraits.toList()..sort()).join(','),
      ].join('|');

  bool _hasUnsavedEdits() => _isEditing && _snapshot() != _snapshotAtEditStart;

  // Common neurodiverse traits list (matching onboarding)
  final List<String> _neurodiverseTraits = [
    'ADHD',
    'Autism',
    'Dyslexia',
    'Dyscalculia',
    'Dyspraxia',
    'Dysgraphia',
    'Tourette Syndrome',
    'OCD',
    'Anxiety',
    'Depression',
    'Bipolar Disorder',
    'Other',
  ];

  // Common pronouns list (matching onboarding)
  final List<String> _pronouns = [
    'he/him',
    'she/her',
    'they/them',
    'he/they',
    'she/they',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _dobController.dispose();
    _customPronounController.dispose();
    super.dispose();
  }

  /// Debug-only: avoid calling [AuthService.getAccessToken] when logged out — a
  /// new [Future] is created on every rebuild, so after logout the token is
  /// cleared before this widget can disappear and [getAccessToken] would throw.
  Future<String?> _debugAccessTokenFuture(AuthProvider auth) async {
    if (!auth.isLoggedIn) return null;
    try {
      return await auth.authService.getAccessToken();
    } on AuthException {
      return null;
    }
  }

  void _loadUserData() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;

    if (user != null) {
      _fullNameController.text = user.fullName ?? user.name;
      _pronoun = user.preferredPronoun ?? '';

      if (user.doB != null && user.doB!.isNotEmpty) {
        final parsedDob = DateTime.tryParse(user.doB!);
        if (parsedDob != null) {
          _doB = parsedDob;
          final raw = user.doB!;
          _dobController.text = raw.length >= 10 ? raw.substring(0, 10) : raw;
        }
      }

      _selectedTraits = Set<String>.from(user.neurodiverseTraits ?? []);

      // Handle custom pronoun
      if (_pronoun.isNotEmpty && !_pronouns.contains(_pronoun)) {
        _customPronounController.text = _pronoun;
        _pronoun = 'Other';
      }
    }
  }

  void _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _doB ?? DateTime(now.year - 18),
      firstDate: DateTime(1900),
      lastDate: now,
    );

    if (picked != null) {
      setState(() {
        _doB = picked;
        _dobController.text = picked.toIso8601String().substring(0, 10);
      });
    }
  }

  void _toggleTrait(String trait) {
    setState(() {
      if (_selectedTraits.contains(trait)) {
        _selectedTraits.remove(trait);
      } else {
        _selectedTraits.add(trait);
      }
    });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      final pronoun =
          _pronoun == 'Other' && _customPronounController.text.isNotEmpty
              ? _customPronounController.text
              : _pronoun;

      final userData = {
        'fullName': _fullNameController.text.trim(),
        'preferredPronoun': pronoun,
        'doB': _dobController.text,
        'neurodiverseTraits': _selectedTraits.toList(),
      };

      await authProvider.updateUser(userData);

      if (mounted) {
        setState(() {
          _isEditing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profile updated successfully!'),
            backgroundColor: context.appTheme.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(userFriendlyError(e,
                fallback: "Couldn't update your profile.")),
            backgroundColor: context.appTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _cancelEdit() {
    _loadUserData();
    setState(() {
      _isEditing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final appColors = theme.extension<AppThemeExtension>();

    return UnsavedChangesScope(
      hasUnsavedChanges: _isEditing,
      isDirty: _hasUnsavedEdits,
      message: 'Your profile changes have not been saved.',
      child: _buildScaffold(authProvider, theme, colorScheme, appColors),
    );
  }

  Widget _buildScaffold(
    AuthProvider authProvider,
    ThemeData theme,
    ColorScheme colorScheme,
    AppThemeExtension? appColors,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                  _snapshotAtEditStart = _snapshot();
                });
              },
              tooltip: 'Edit Profile',
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppInsets.page,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildEnvironmentBadge(theme, colorScheme, appColors),
                SizedBox(height: AppSpacing.xl),
                _buildIdentityCard(authProvider, theme, colorScheme, appColors),
                SizedBox(height: AppSpacing.xxl),
                _buildFullNameField(theme),
                SizedBox(height: AppSpacing.lg),
                _buildDateOfBirthField(theme),
                SizedBox(height: AppSpacing.lg),
                _buildPronounField(theme),
                if (_pronoun == 'Other') ...[
                  SizedBox(height: AppSpacing.lg),
                  _buildCustomPronounField(theme),
                ],
                SizedBox(height: AppSpacing.xl),
                _buildThemeSection(theme),
                SizedBox(height: AppSpacing.xl),
                _buildNeurodiverseTraitsSection(theme, colorScheme),
                SizedBox(height: AppSpacing.xxl),
                if (_isEditing) ...[
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isSaving ? null : _cancelEdit,
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.lg),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _saveProfile,
                          child: _isSaving
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                      semanticsLabel: 'Loading',
                                      strokeWidth: 2),
                                )
                              : const Text('Save'),
                        ),
                      ),
                    ],
                  ),
                ],
                SizedBox(height: AppSpacing.xl),
                _buildSecuritySection(authProvider, theme),
                SizedBox(height: AppSpacing.xl),
                _buildDebugTokenSection(
                    authProvider, theme, colorScheme, appColors, context),
                SizedBox(height: AppSpacing.lg),
                _buildLogoutButton(authProvider, colorScheme),
                SizedBox(height: AppSpacing.xl),
                _buildAboutSection(theme),
                SizedBox(height: AppSpacing.lg),
                _buildDeleteAccountButton(authProvider, colorScheme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSecuritySection(AuthProvider authProvider, ThemeData theme) {
    final available = authProvider.biometricAvailable;
    final enabled = authProvider.biometricUnlockEnabled;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Security',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        DsSurfaceCard(
          child: SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Unlock with biometrics'),
            subtitle: Text(
              available
                  ? 'Require Face ID, fingerprint, or device passcode when opening the app.'
                  : 'Biometric unlock is not available on this device.',
              style: theme.textTheme.bodySmall,
            ),
            value: available && enabled,
            onChanged: !available
                ? null
                : (value) async {
                    try {
                      await authProvider.setBiometricUnlockEnabled(value);
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            value
                                ? 'Biometric unlock enabled'
                                : 'Biometric unlock disabled',
                          ),
                        ),
                      );
                    } catch (_) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            authProvider.errorMessage ??
                                'Could not update biometric unlock',
                          ),
                        ),
                      );
                    }
                  },
          ),
        ),
      ],
    );
  }

  /// Environment badge widget
  Widget _buildEnvironmentBadge(
    ThemeData theme,
    ColorScheme colorScheme,
    AppThemeExtension? appColors,
  ) {
    if (AppConfig.isProduction) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.lg),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: AppConfig.isDev
                ? appColors?.devBadgeColor ?? Colors.orange
                : appColors?.stagingBadgeColor ?? Colors.blue,
            borderRadius: AppRadius.circularPill,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                AppConfig.isDev ? Icons.code : Icons.science,
                color: colorScheme.onPrimary,
                size: 16,
              ),
              SizedBox(width: AppSpacing.sm),
              Text(
                AppConfig.environmentName.toUpperCase(),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Identity card with avatar and email.
  Widget _buildIdentityCard(
    AuthProvider authProvider,
    ThemeData theme,
    ColorScheme colorScheme,
    AppThemeExtension? appColors,
  ) {
    final picture = authProvider.profile?.picture;
    final hasPicture = picture != null && picture.isNotEmpty;
    final name = authProvider.profile?.name ?? 'Your profile';
    final email = authProvider.profile?.email ?? '';

    return DsSurfaceCard(
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor:
                appColors?.primarySoft ?? colorScheme.primaryContainer,
            backgroundImage:
                hasPicture ? CachedNetworkImageProvider(picture) : null,
            child: hasPicture
                ? null
                : Icon(Icons.person, size: 32, color: colorScheme.primary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: theme.textTheme.titleMedium),
                if (email.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.micro),
                  Text(
                    email,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color:
                          appColors?.textMuted ?? colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Theme mode selector (from [AppThemes] registry)
  Widget _buildThemeSection(ThemeData theme) {
    final appTheme = context.appTheme;

    return Consumer<ThemeModeProvider>(
      builder: (context, themeModeProvider, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Appearance',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: AppSpacing.sm),
            DsSurfaceCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: AppThemes.all.asMap().entries.map((entry) {
                  final index = entry.key;
                  final option = entry.value;
                  final isSelected = themeModeProvider.mode == option.id;
                  final isLast = index == AppThemes.all.length - 1;

                  return Material(
                    color: Colors.transparent,
                    child: Semantics(
                        selected: isSelected,
                        inMutuallyExclusiveGroup: true,
                        button: true,
                        child: InkWell(
                          onTap: () => themeModeProvider.setMode(option.id),
                          borderRadius: isLast
                              ? const BorderRadius.vertical(
                                  bottom: Radius.circular(16),
                                )
                              : null,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.lg,
                              vertical: AppSpacing.md,
                            ),
                            decoration: BoxDecoration(
                              border: isLast
                                  ? null
                                  : Border(
                                      bottom: BorderSide(
                                          color: appTheme.borderColor),
                                    ),
                            ),
                            child: Row(
                              children: [
                                IconBubble(
                                  icon: option.icon,
                                  color: isSelected
                                      ? theme.colorScheme.primary
                                      : appTheme.textMuted,
                                  backgroundColor: isSelected
                                      ? appTheme.primarySoft
                                      : appTheme.borderColor
                                          .withValues(alpha: 0.35),
                                  size: 40,
                                  iconSize: 20,
                                  borderRadius: 12,
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Text(
                                    option.label,
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  Icon(
                                    Icons.check_circle,
                                    color: theme.colorScheme.primary,
                                    size: 22,
                                  ),
                              ],
                            ),
                          ),
                        )),
                  );
                }).toList(),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Full name field
  Widget _buildFullNameField(ThemeData theme) {
    return TextFormField(
      controller: _fullNameController,
      decoration: const InputDecoration(
        labelText: 'Full Name',
        prefixIcon: Icon(Icons.person),
      ),
      enabled: _isEditing,
      validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
    );
  }

  /// Date of birth field
  Widget _buildDateOfBirthField(ThemeData theme) {
    return TextFormField(
      controller: _dobController,
      readOnly: true,
      decoration: const InputDecoration(
        labelText: 'Date of Birth',
        prefixIcon: Icon(Icons.calendar_today),
        suffixIcon: Icon(Icons.arrow_drop_down),
      ),
      enabled: _isEditing,
      onTap: _isEditing ? _pickDate : null,
    );
  }

  /// Pronoun field
  Widget _buildPronounField(ThemeData theme) {
    return DropdownButtonFormField<String>(
      decoration: const InputDecoration(
        labelText: 'Pronouns',
        prefixIcon: Icon(Icons.person_outline),
      ),
      initialValue: _pronoun.isEmpty ? null : _pronoun,
      items: _pronouns.map((pronoun) {
        return DropdownMenuItem<String>(
          value: pronoun,
          child: Text(pronoun),
        );
      }).toList(),
      onChanged: _isEditing
          ? (value) {
              setState(() {
                _pronoun = value ?? '';
                if (_pronoun != 'Other') {
                  _customPronounController.clear();
                }
              });
            }
          : null,
    );
  }

  /// Custom pronoun field
  Widget _buildCustomPronounField(ThemeData theme) {
    return TextFormField(
      controller: _customPronounController,
      decoration: const InputDecoration(
        labelText: 'Enter your pronouns',
        hintText: 'e.g., ze/zir, ey/em, etc.',
        prefixIcon: Icon(Icons.edit),
      ),
      enabled: _isEditing,
      validator: (value) {
        if (_pronoun == 'Other' && (value == null || value.trim().isEmpty)) {
          return 'Please enter your pronouns';
        }
        return null;
      },
    );
  }

  /// Neurodiverse traits section
  Widget _buildNeurodiverseTraitsSection(
      ThemeData theme, ColorScheme colorScheme) {
    final appTheme = context.appTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Neurodiverse Traits',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: AppSpacing.sm),
        Text(
          'Select any traits that apply to you.',
          style: theme.textTheme.bodySmall,
        ),
        SizedBox(height: AppSpacing.lg),
        DsSurfaceCard(
          child: Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: _neurodiverseTraits.map((trait) {
              final isSelected = _selectedTraits.contains(trait);
              return FilterChip(
                label: Text(trait),
                selected: isSelected,
                onSelected: _isEditing ? (_) => _toggleTrait(trait) : null,
                selectedColor: appTheme.primarySoft,
                checkmarkColor: theme.colorScheme.primary,
                side: BorderSide(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : appTheme.borderColor,
                ),
              );
            }).toList(),
          ),
        ),
        if (_selectedTraits.isNotEmpty) ...[
          SizedBox(height: AppSpacing.lg),
          Text(
            'Selected: ${_selectedTraits.join(', ')}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.primary,
            ),
          ),
        ],
      ],
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
      padding: EdgeInsets.only(bottom: AppSpacing.lg),
      child: FutureBuilder<String?>(
        future: _debugAccessTokenFuture(authProvider),
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
              SizedBox(height: AppSpacing.sm),
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
      label: const Text('Log out'),
      style: ElevatedButton.styleFrom(
        backgroundColor: colorScheme.error,
        foregroundColor: colorScheme.onError,
      ),
      onPressed: () => _confirmLogout(authProvider),
    );
  }

  Future<void> _confirmLogout(AuthProvider authProvider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You will need to sign in again to use the app.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (confirmed == true) await authProvider.logout();
  }

  /// Privacy policy and help links, when configured for this build.
  Widget _buildAboutSection(ThemeData theme) {
    final privacyUrl = AppConfig.privacyPolicyUrl;
    final supportUrl = AppConfig.supportUrl;
    if (privacyUrl.isEmpty && supportUrl.isEmpty) {
      return const SizedBox.shrink();
    }
    return DsSurfaceCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          if (privacyUrl.isNotEmpty)
            ListTile(
              leading: const Icon(Icons.privacy_tip_outlined),
              title: const Text('Privacy policy'),
              trailing: const Icon(Icons.open_in_new, size: 18),
              onTap: () => _openLink(privacyUrl),
            ),
          if (supportUrl.isNotEmpty)
            ListTile(
              leading: const Icon(Icons.help_outline),
              title: const Text('Help & support'),
              trailing: const Icon(Icons.open_in_new, size: 18),
              onTap: () => _openLink(supportUrl),
            ),
        ],
      ),
    );
  }

  Future<void> _openLink(String url) async {
    final uri = Uri.tryParse(url);
    final allowed = uri != null &&
        (UrlSecurity.isSafeExternalUrl(url) || uri.scheme == 'mailto');
    if (allowed && await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      return;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Couldn't open the link.")),
    );
  }

  Widget _buildDeleteAccountButton(
    AuthProvider authProvider,
    ColorScheme colorScheme,
  ) {
    return TextButton.icon(
      icon: const Icon(Icons.delete_forever_outlined),
      label: const Text('Delete account'),
      style: TextButton.styleFrom(foregroundColor: colorScheme.error),
      onPressed:
          _isDeletingAccount ? null : () => _confirmDeleteAccount(authProvider),
    );
  }

  Future<void> _confirmDeleteAccount(AuthProvider authProvider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete your account?'),
        content: const Text(
          'This permanently deletes your profile, goals, journal, chats, '
          'voice notes and resources, and cancels any subscription. '
          'It cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            child: const Text('Delete account'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isDeletingAccount = true);
    try {
      await authProvider.deleteAccount();
    } catch (e) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            "Your account couldn't be deleted. Please try again.",
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isDeletingAccount = false);
    }
  }
}
