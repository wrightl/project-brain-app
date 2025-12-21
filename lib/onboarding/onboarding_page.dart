// lib/onboarding/onboarding_page.dart
import 'package:flutter/material.dart';
import 'package:projectbrain/authentication/auth_provider.dart';
import 'package:projectbrain/core/logging/app_logger.dart';
import 'package:provider/provider.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Basic user information
  final _formKey = GlobalKey<FormState>();
  String _fullName = '';
  DateTime? _doB;
  final TextEditingController _dobController = TextEditingController();
  String _pronoun = '';
  final TextEditingController _customPronounController =
      TextEditingController();

  // Neurodiverse traits
  final Set<String> _selectedTraits = {};

  // Preferences
  String _themePreference = 'system'; // 'light', 'dark', or 'system'

  // Common neurodiverse traits list
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

  // Common pronouns list
  final List<String> _pronouns = [
    'he/him',
    'she/her',
    'they/them',
    'he/they',
    'she/they',
    'Other',
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _dobController.dispose();
    _customPronounController.dispose();
    super.dispose();
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

  void _nextPage() {
    if (_currentPage == 0) {
      // Validate basic information when using Next button
      final formState = _formKey.currentState;
      if (formState != null && formState.validate()) {
        formState.save();
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    } else if (_currentPage == 1) {
      // Neurodiverse traits - no validation required, can skip
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Last page - validate form if accessible, then submit onboarding
      final formState = _formKey.currentState;
      if (formState != null) {
        if (formState.validate()) {
          formState.save();
          _submitOnboarding();
        }
      } else {
        // Form not accessible (user swiped to last page), validate required fields manually
        if (_fullName.isEmpty ||
            _pronoun.isEmpty ||
            _dobController.text.isEmpty) {
          // Navigate back to first page to show validation errors
          _pageController.animateToPage(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please complete all required fields'),
              backgroundColor: Colors.red,
            ),
          );
        } else {
          _submitOnboarding();
        }
      }
    }
  }

  void _previousPage() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
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

  void _submitOnboarding() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final pronoun =
        _pronoun == 'Other' && _customPronounController.text.isNotEmpty
            ? _customPronounController.text
            : _pronoun;

    final formData = {
      'email': authProvider.profile?.email,
      'fullName': _fullName,
      'preferredPronoun': pronoun,
      'doB': _dobController.text,
      'neurodiverseTraits': _selectedTraits.toList(),
      // 'preferences': {
      //   'theme': _themePreference,
      // },
    };

    try {
      await authProvider.completeOnboarding(formData);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Onboarding complete!')),
      );
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final totalPages = 3;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Onboarding'),
        leading: _currentPage > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _previousPage,
              )
            : null,
      ),
      body: Column(
        children: [
          // Progress indicator
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: List.generate(
                totalPages,
                (index) => Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4.0),
                    height: 4.0,
                    decoration: BoxDecoration(
                      color: index <= _currentPage
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(2.0),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Page content
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              physics: const BouncingScrollPhysics(),
              children: [
                _buildBasicInfoPage(authProvider),
                _buildNeurodiverseTraitsPage(),
                _buildPreferencesPage(),
              ],
            ),
          ),

          // Navigation buttons
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_currentPage > 0)
                  OutlinedButton(
                    onPressed: _previousPage,
                    child: const Text('Back'),
                  )
                else
                  const SizedBox.shrink(),
                ElevatedButton(
                  onPressed: _nextPage,
                  child: Text(
                      _currentPage == totalPages - 1 ? 'Complete' : 'Next'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoPage(AuthProvider authProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome ${authProvider.profile?.name ?? 'there'}!',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Please complete your profile.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 32),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Full Name',
                border: OutlineInputBorder(),
              ),
              onSaved: (val) => _fullName = val ?? '',
              initialValue: authProvider.profile?.name ?? '',
              validator: (val) =>
                  val == null || val.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _dobController,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Date of Birth',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.calendar_today),
              ),
              onTap: _pickDate,
              validator: (value) => value == null || value.isEmpty
                  ? 'Please select your date of birth'
                  : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Pronouns',
                border: OutlineInputBorder(),
              ),
              initialValue: _pronoun.isEmpty ? null : _pronoun,
              items: _pronouns.map((pronoun) {
                return DropdownMenuItem<String>(
                  value: pronoun,
                  child: Text(pronoun),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _pronoun = value ?? '';
                  if (_pronoun != 'Other') {
                    _customPronounController.clear();
                  }
                });
              },
              onSaved: (value) => _pronoun = value ?? '',
              validator: (value) =>
                  value == null || value.isEmpty ? 'Required' : null,
            ),
            if (_pronoun == 'Other') ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _customPronounController,
                decoration: const InputDecoration(
                  labelText: 'Enter your pronouns',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., ze/zir, ey/em, etc.',
                ),
                validator: (value) {
                  if (_pronoun == 'Other' && (value == null || value.isEmpty)) {
                    return 'Please enter your pronouns';
                  }
                  return null;
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNeurodiverseTraitsPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Neurodiverse Traits',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Select any traits that apply to you. You can select multiple or skip this step.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 32),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _neurodiverseTraits.map((trait) {
              final isSelected = _selectedTraits.contains(trait);
              return FilterChip(
                label: Text(trait),
                selected: isSelected,
                onSelected: (_) => _toggleTrait(trait),
                selectedColor: Theme.of(context).colorScheme.primaryContainer,
                checkmarkColor:
                    Theme.of(context).colorScheme.onPrimaryContainer,
              );
            }).toList(),
          ),
          if (_selectedTraits.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              'Selected: ${_selectedTraits.join(', ')}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPreferencesPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Preferences',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Customize your app experience.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 32),
          Text(
            'Theme Preference',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          RadioListTile<String>(
            title: const Text('Light'),
            subtitle: const Text('Always use light theme'),
            value: 'light',
            groupValue: _themePreference,
            onChanged: (value) {
              setState(() {
                _themePreference = value!;
              });
            },
          ),
          RadioListTile<String>(
            title: const Text('Dark'),
            subtitle: const Text('Always use dark theme'),
            value: 'dark',
            groupValue: _themePreference,
            onChanged: (value) {
              setState(() {
                _themePreference = value!;
              });
            },
          ),
          RadioListTile<String>(
            title: const Text('System'),
            subtitle: const Text('Follow system settings'),
            value: 'system',
            groupValue: _themePreference,
            onChanged: (value) {
              setState(() {
                _themePreference = value!;
              });
            },
          ),
        ],
      ),
    );
  }
}
