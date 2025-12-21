import 'package:flutter/material.dart';
import 'package:projectbrain/authentication/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:projectbrain/core/config/app_config.dart';
import 'package:projectbrain/helpers/theme.dart';

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

  void _loadUserData() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;

    if (user != null) {
      _fullNameController.text = user.fullName ?? user.name;
      _pronoun = user.preferredPronoun ?? '';

      if (user.doB != null && user.doB!.isNotEmpty) {
        try {
          _doB = DateTime.parse(user.doB!);
          _dobController.text = user.doB!.substring(0, 10);
        } catch (e) {
          // Invalid date format, ignore
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
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildEnvironmentBadge(colorScheme, appColors),
                const SizedBox(height: 24),
                _buildProfileAvatar(authProvider),
                const SizedBox(height: 16),
                _buildProfileEmail(authProvider, theme, colorScheme),
                const SizedBox(height: 32),
                _buildFullNameField(theme),
                const SizedBox(height: 16),
                _buildDateOfBirthField(theme),
                const SizedBox(height: 16),
                _buildPronounField(theme),
                if (_pronoun == 'Other') ...[
                  const SizedBox(height: 16),
                  _buildCustomPronounField(theme),
                ],
                const SizedBox(height: 24),
                _buildNeurodiverseTraitsSection(theme, colorScheme),
                const SizedBox(height: 32),
                if (_isEditing) ...[
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isSaving ? null : _cancelEdit,
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 16),
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
                const SizedBox(height: 24),
                _buildDebugTokenSection(
                    authProvider, theme, colorScheme, appColors, context),
                const SizedBox(height: 16),
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
    ColorScheme colorScheme,
    AppThemeExtension? appColors,
  ) {
    if (AppConfig.isProduction) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Center(
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
      ),
    );
  }

  /// Profile avatar widget
  Widget _buildProfileAvatar(AuthProvider authProvider) {
    return Center(
      child: CircleAvatar(
        radius: 50,
        backgroundImage: authProvider.profile?.picture != null &&
                authProvider.profile!.picture.isNotEmpty
            ? NetworkImage(authProvider.profile!.picture)
            : null,
        child: authProvider.profile?.picture == null ||
                authProvider.profile!.picture.isEmpty
            ? const Icon(Icons.person, size: 50)
            : null,
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
        const SizedBox(height: 8),
        Text(
          'Select any traits that apply to you.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
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
          const SizedBox(height: 16),
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
