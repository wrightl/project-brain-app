import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:projectbrain/authentication/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:projectbrain/core/config/app_config.dart';
import 'package:projectbrain/helpers/app_themes.dart';
import 'package:projectbrain/helpers/theme.dart';
import 'package:projectbrain/helpers/theme_mode_provider.dart';
import 'package:projectbrain/services/auth/auth_exception.dart';
import 'package:projectbrain/helpers/themes/app_spacing.dart';

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
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: $e'),
            backgroundColor: Colors.red,
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
                _buildProfileAvatar(authProvider),
                SizedBox(height: AppSpacing.lg),
                _buildProfileEmail(authProvider, theme, colorScheme),
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
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Save'),
                        ),
                      ),
                    ],
                  ),
                ],
                SizedBox(height: AppSpacing.xl),
                _buildDebugTokenSection(
                    authProvider, theme, colorScheme, appColors, context),
                SizedBox(height: AppSpacing.lg),
                _buildLogoutButton(authProvider, colorScheme),
              ],
            ),
          ),
        ),
      ),
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

  /// Theme mode selector (from [AppThemes] registry)
  Widget _buildThemeSection(ThemeData theme) {
    return Consumer<ThemeModeProvider>(
      builder: (context, themeModeProvider, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Appearance',
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: AppSpacing.sm),
            Card(
              child: Column(
                children: AppThemes.all.map((option) {
                  final isSelected = themeModeProvider.mode == option.id;
                  return ListTile(
                    leading: Icon(option.icon),
                    title: Text(option.label),
                    trailing: isSelected
                        ? Icon(Icons.check, color: theme.colorScheme.primary)
                        : null,
                    onTap: () => themeModeProvider.setMode(option.id),
                  );
                }).toList(),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Profile avatar widget
  Widget _buildProfileAvatar(AuthProvider authProvider) {
    final picture = authProvider.profile?.picture;
    final hasPicture = picture != null && picture.isNotEmpty;
    return Center(
      child: CircleAvatar(
        radius: 50,
        // CachedNetworkImageProvider caches avatars across rebuilds/sessions.
        backgroundImage:
            hasPicture ? CachedNetworkImageProvider(picture) : null,
        child: hasPicture ? null : const Icon(Icons.person, size: 50),
      ),
    );
  }

  /// Profile email widget (read-only)
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

  /// Full name field
  Widget _buildFullNameField(ThemeData theme) {
    return TextFormField(
      controller: _fullNameController,
      decoration: const InputDecoration(
        labelText: 'Full Name',
        border: OutlineInputBorder(),
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
        border: OutlineInputBorder(),
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
        border: OutlineInputBorder(),
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
        border: OutlineInputBorder(),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Neurodiverse Traits',
          style: theme.textTheme.titleMedium,
        ),
        SizedBox(height: AppSpacing.sm),
        Text(
          'Select any traits that apply to you.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: AppSpacing.lg),
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: _neurodiverseTraits.map((trait) {
            final isSelected = _selectedTraits.contains(trait);
            return FilterChip(
              label: Text(trait),
              selected: isSelected,
              onSelected: _isEditing ? (_) => _toggleTrait(trait) : null,
              selectedColor: colorScheme.primaryContainer,
              checkmarkColor: colorScheme.onPrimaryContainer,
            );
          }).toList(),
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
