import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:projectbrain/authentication/auth_provider.dart';
import 'package:projectbrain/core/logging/app_logger.dart';
import 'package:projectbrain/onboarding/onboarding_provider.dart';
import 'package:projectbrain/onboarding/onboarding_localizations.dart';
import 'package:provider/provider.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  final Map<int, GlobalKey<FormState>> _formKeys = {};

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage(OnboardingProvider provider) {
    final currentStep = provider.currentStep;
    final formKey = _formKeys[currentStep];

    // Validate required fields on step 0 (Basic Info)
    if (currentStep == 0) {
      if (formKey?.currentState?.validate() ?? false) {
        formKey!.currentState!.save();
        _navigateToStep(provider, currentStep + 1);
      }
    } else {
      // Optional steps - just navigate
      _navigateToStep(provider, currentStep + 1);
    }
  }

  void _previousPage(OnboardingProvider provider) {
    if (provider.currentStep > 0) {
      _navigateToStep(provider, provider.currentStep - 1);
    }
  }

  void _navigateToStep(OnboardingProvider provider, int step) {
    final totalSteps = provider.getTotalSteps();
    if (step >= 0 && step < totalSteps) {
      provider.setCurrentStep(step);
          _pageController.animateToPage(
        step,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
    }
  }

  void _onStepTapped(OnboardingProvider provider, int step) {
    // Allow navigation to any step that has been completed (step <= currentStep)
    // or to the first step (Basic Info) which is always accessible
    if (step == 0 || step <= provider.currentStep) {
      _navigateToStep(provider, step);
    }
  }

  Future<void> _submitOnboarding(
      OnboardingProvider provider, AuthProvider authProvider) async {
    if (!provider.isBasicInfoValid) {
      // Navigate back to first step
      _navigateToStep(provider, 0);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please complete all required fields'),
              backgroundColor: Colors.red,
            ),
          );
      return;
    }

    provider.setSubmitting(true);
    provider.clearError();

    try {
      final localizations = OnboardingLocalizations.of(context);
      final onboardingData = provider.buildOnboardingData(
        authProvider.profile?.email ?? '',
        localizations,
      );

      await authProvider.completeOnboarding(onboardingData.toJson());

      if (!mounted) return;

      // Success - navigation will be handled by router redirect
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Onboarding complete!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (error) {
      logError('[OnboardingPage] Error during onboarding', error);
      if (!mounted) return;

      provider.setError('Failed to complete onboarding: ${error.toString()}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${error.toString()}'),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'Retry',
            onPressed: () => _submitOnboarding(provider, authProvider),
          ),
        ),
      );
    } finally {
      if (mounted) {
        provider.setSubmitting(false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final localizations = OnboardingLocalizations.of(context);

    return ChangeNotifierProvider(
      create: (_) => OnboardingProvider(),
      child: Consumer<OnboardingProvider>(
        builder: (context, provider, _) {
          final totalSteps = provider.getTotalSteps();
          final currentStep = provider.currentStep;
          final isLastStep = currentStep == totalSteps - 1;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Onboarding'),
              leading: currentStep > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                      onPressed: () => _previousPage(provider),
              )
            : null,
      ),
      body: Column(
        children: [
          // Progress indicator
                _buildProgressIndicator(provider, totalSteps, localizations),

                // Page content
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (index) {
                      provider.setCurrentStep(index);
                    },
                    children: _buildPages(provider, authProvider, localizations),
                  ),
                ),

                // Navigation buttons
                _buildNavigationButtons(
                  provider,
                  authProvider,
                  isLastStep,
                  localizations,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProgressIndicator(
      OnboardingProvider provider, int totalSteps, OnboardingLocalizations localizations) {
    return Padding(
            padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Progress bar
          Row(
              children: List.generate(
              totalSteps,
                (index) => Expanded(
                child: GestureDetector(
                  onTap: () => _onStepTapped(provider, index),
                  child: MouseRegion(
                    cursor: (index == 0 || index <= provider.currentStep)
                        ? SystemMouseCursors.click
                        : SystemMouseCursors.basic,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2.0),
                      height: 4.0,
                      decoration: BoxDecoration(
                        color: index <= provider.currentStep
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
          ),
          const SizedBox(height: 8),
          // Step indicator text
          Text(
            'Step ${provider.currentStep + 1} of $totalSteps',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons(
    OnboardingProvider provider,
    AuthProvider authProvider,
    bool isLastStep,
    OnboardingLocalizations localizations,
  ) {
    return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
          if (provider.currentStep > 0)
                  OutlinedButton(
              onPressed: provider.isSubmitting
                  ? null
                  : () => _previousPage(provider),
              child: Text(localizations.previous),
                  )
                else
                  const SizedBox.shrink(),
                ElevatedButton(
            onPressed: provider.isSubmitting
                ? null
                : () {
                    if (isLastStep) {
                      _submitOnboarding(provider, authProvider);
                    } else {
                      _nextPage(provider);
                    }
                  },
            child: provider.isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(isLastStep ? localizations.complete : localizations.next),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPages(
    OnboardingProvider provider,
    AuthProvider authProvider,
    OnboardingLocalizations localizations,
  ) {
    final pages = <Widget>[
      _buildBasicInfoPage(provider, authProvider, localizations),
      _buildNeurodiverseTraitsPage(provider, localizations),
      _buildWelcomePage(provider, localizations),
      _buildAboutYouPage(provider, localizations),
      _buildPreferencesPage(provider, localizations),
      _buildProfilePage(provider, localizations),
      _buildCoachingBuddyPage(provider, localizations),
      _buildClosingPage(provider, localizations),
    ];

    // Add follow-on questions page if needed
    if (provider.shouldShowFollowOnQuestions) {
      pages.add(_buildFollowOnQuestionsPage(provider, localizations));
    }

    return pages;
  }

  Widget _buildBasicInfoPage(
    OnboardingProvider provider,
    AuthProvider authProvider,
    OnboardingLocalizations localizations,
  ) {
    final formKey = _formKeys.putIfAbsent(0, () => GlobalKey<FormState>());
    final dobController = TextEditingController();

    if (provider.dateOfBirth != null) {
      dobController.text = '${provider.dateOfBirth!.year}-${provider.dateOfBirth!.month.toString().padLeft(2, '0')}-${provider.dateOfBirth!.day.toString().padLeft(2, '0')}';
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: formKey,
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
              decoration: InputDecoration(
                labelText: localizations.fullName,
                border: const OutlineInputBorder(),
              ),
              initialValue: provider.fullName.isEmpty
                  ? authProvider.profile?.name ?? ''
                  : provider.fullName,
              validator: (val) =>
                  val == null || val.isEmpty ? localizations.required : null,
              onSaved: (val) => provider.setFullName(val ?? ''),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: dobController,
              readOnly: true,
              decoration: InputDecoration(
                labelText: localizations.dateOfBirth,
                border: const OutlineInputBorder(),
                suffixIcon: const Icon(Icons.calendar_today),
              ),
              onTap: () async {
                final now = DateTime.now();
                final picked = await showDatePicker(
                  context: context,
                  initialDate: provider.dateOfBirth ?? DateTime(now.year - 18),
                  firstDate: DateTime(1900),
                  lastDate: now,
                );

                if (picked != null) {
                  provider.setDateOfBirth(picked);
                  dobController.text =
                      '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                }
              },
              validator: (value) => value == null || value.isEmpty
                  ? localizations.selectDateOfBirth
                  : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: localizations.preferredPronoun,
                border: const OutlineInputBorder(),
              ),
              initialValue: provider.preferredPronoun.isEmpty
                  ? null
                  : provider.preferredPronoun,
              items: localizations.pronounOptions.map((pronoun) {
                return DropdownMenuItem<String>(
                  value: pronoun,
                  child: Text(pronoun),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  provider.setPreferredPronoun(value);
                }
              },
              validator: (value) =>
                  value == null || value.isEmpty ? localizations.required : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNeurodiverseTraitsPage(
    OnboardingProvider provider,
    OnboardingLocalizations localizations,
  ) {
    final traits = [
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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            localizations.stepNeurodiverseTraits,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            localizations.selectTraits,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 32),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: traits.map((trait) {
              final isSelected = provider.selectedTraits.contains(trait);
              return FilterChip(
                label: Text(trait),
                selected: isSelected,
                onSelected: (_) => provider.toggleTrait(trait),
                selectedColor: Theme.of(context).colorScheme.primaryContainer,
                checkmarkColor:
                    Theme.of(context).colorScheme.onPrimaryContainer,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomePage(
    OnboardingProvider provider,
    OnboardingLocalizations localizations,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            localizations.stepWelcome,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 32),
          TextFormField(
            decoration: InputDecoration(
              labelText: localizations.preferredName,
              border: const OutlineInputBorder(),
              hintText: localizations.preferredName,
            ),
            initialValue: provider.preferredName,
            onChanged: (value) => provider.setPreferredName(value.isEmpty ? null : value),
          ),
          const SizedBox(height: 16),
          TextFormField(
            decoration: InputDecoration(
              labelText: localizations.inspiration,
              border: const OutlineInputBorder(),
              hintText: localizations.inspirationHint,
            ),
            initialValue: provider.inspiration,
            maxLines: 4,
            onChanged: (value) => provider.setInspiration(value.isEmpty ? null : value),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: localizations.currentFeeling,
              border: const OutlineInputBorder(),
            ),
            initialValue: provider.currentFeeling,
            items: localizations.currentFeelingOptions.map((feeling) {
              return DropdownMenuItem<String>(
                value: feeling,
                child: Text(localizations.formatLabel(feeling)),
              );
            }).toList(),
            onChanged: (value) => provider.setCurrentFeeling(value),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutYouPage(
    OnboardingProvider provider,
    OnboardingLocalizations localizations,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            localizations.stepAboutYou,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 32),
          Text(
            localizations.selfDescription,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: localizations.selfDescriptionOptions.map((option) {
              final isSelected = provider.selfDescription.contains(option);
              return FilterChip(
                label: Text(localizations.formatLabel(option)),
                selected: isSelected,
                onSelected: (_) => provider.toggleSelfDescription(option),
                selectedColor: Theme.of(context).colorScheme.primaryContainer,
                checkmarkColor:
                    Theme.of(context).colorScheme.onPrimaryContainer,
              );
            }).toList(),
          ),
            const SizedBox(height: 24),
          TextFormField(
            decoration: InputDecoration(
              labelText: localizations.businessType,
              border: const OutlineInputBorder(),
              hintText: localizations.businessTypeHint,
            ),
            initialValue: provider.businessType,
            maxLines: 3,
            onChanged: (value) => provider.setBusinessType(value.isEmpty ? null : value),
          ),
          const SizedBox(height: 16),
          TextFormField(
            decoration: InputDecoration(
              labelText: localizations.proudMoment,
              border: const OutlineInputBorder(),
              hintText: localizations.proudMomentHint,
            ),
            initialValue: provider.proudMoment,
            maxLines: 3,
            onChanged: (value) => provider.setProudMoment(value.isEmpty ? null : value),
          ),
          const SizedBox(height: 16),
            Text(
            localizations.challenge,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: localizations.challengeOptions.map((option) {
              final isSelected = provider.challenges.contains(option);
              return FilterChip(
                label: Text(localizations.formatLabel(option)),
                selected: isSelected,
                onSelected: (_) => provider.toggleChallenge(option),
                selectedColor: Theme.of(context).colorScheme.primaryContainer,
                checkmarkColor:
                    Theme.of(context).colorScheme.onPrimaryContainer,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesPage(
    OnboardingProvider provider,
    OnboardingLocalizations localizations,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            localizations.stepPreferences,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 32),
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: localizations.learningStyle,
              border: const OutlineInputBorder(),
            ),
            initialValue: provider.learningStyle,
            items: localizations.learningStyleOptions.map((option) {
              return DropdownMenuItem<String>(
                value: option,
                child: Text(localizations.formatLabel(option)),
              );
            }).toList(),
            onChanged: (value) => provider.setLearningStyle(value),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: localizations.informationDepth,
              border: const OutlineInputBorder(),
            ),
            initialValue: provider.informationDepth,
            items: localizations.informationDepthOptions.map((option) {
              return DropdownMenuItem<String>(
                value: option,
                child: Text(localizations.formatLabel(option)),
              );
            }).toList(),
            onChanged: (value) => provider.setInformationDepth(value),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: localizations.celebrationStyle,
              border: const OutlineInputBorder(),
            ),
            initialValue: provider.celebrationStyle,
            items: localizations.celebrationStyleOptions.map((option) {
              return DropdownMenuItem<String>(
                value: option,
                child: Text(localizations.formatLabel(option)),
              );
            }).toList(),
            onChanged: (value) => provider.setCelebrationStyle(value),
          ),
        ],
      ),
    );
  }

  Widget _buildProfilePage(
    OnboardingProvider provider,
    OnboardingLocalizations localizations,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            localizations.stepProfile,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 32),
          Text(
            localizations.strengths,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: localizations.strengthsOptions.map((option) {
              final isSelected = provider.strengths.contains(option);
              return FilterChip(
                label: Text(localizations.formatLabel(option)),
                selected: isSelected,
                onSelected: (_) => provider.toggleStrength(option),
                selectedColor: Theme.of(context).colorScheme.primaryContainer,
                checkmarkColor:
                    Theme.of(context).colorScheme.onPrimaryContainer,
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          Text(
            localizations.supportAreas,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: localizations.supportAreasOptions.map((option) {
              final isSelected = provider.supportAreas.contains(option);
              return FilterChip(
                label: Text(localizations.formatLabel(option)),
                selected: isSelected,
                onSelected: (_) => provider.toggleSupportArea(option),
                selectedColor: Theme.of(context).colorScheme.primaryContainer,
                checkmarkColor:
                    Theme.of(context).colorScheme.onPrimaryContainer,
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: localizations.motivationStyle,
              border: const OutlineInputBorder(),
            ),
            initialValue: provider.motivationStyle,
            items: localizations.motivationStyleOptions.map((option) {
              return DropdownMenuItem<String>(
                value: option,
                child: Text(localizations.formatLabel(option)),
              );
            }).toList(),
            onChanged: (value) => provider.setMotivationStyle(value),
          ),
          const SizedBox(height: 16),
          TextFormField(
            decoration: InputDecoration(
              labelText: localizations.neurodivergentUnderstanding,
              border: const OutlineInputBorder(),
              hintText: localizations.neurodivergentUnderstandingHint,
            ),
            initialValue: provider.neurodivergentUnderstanding,
            maxLines: 3,
            onChanged: (value) => provider.setNeurodivergentUnderstanding(value.isEmpty ? null : value),
          ),
          const SizedBox(height: 16),
          TextFormField(
            decoration: InputDecoration(
              labelText: localizations.biggestGoal,
              border: const OutlineInputBorder(),
              hintText: localizations.biggestGoalHint,
            ),
            initialValue: provider.biggestGoal,
            maxLines: 3,
            onChanged: (value) => provider.setBiggestGoal(value.isEmpty ? null : value),
          ),
        ],
      ),
    );
  }

  Widget _buildCoachingBuddyPage(
    OnboardingProvider provider,
    OnboardingLocalizations localizations,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            localizations.stepCoachingBuddy,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 32),
          Text(
            localizations.tasks,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: localizations.tasksOptions.map((option) {
              final isSelected = provider.tasks.contains(option);
              return FilterChip(
                label: Text(localizations.formatLabel(option)),
                selected: isSelected,
                onSelected: (_) => provider.toggleTask(option),
                selectedColor: Theme.of(context).colorScheme.primaryContainer,
                checkmarkColor:
                    Theme.of(context).colorScheme.onPrimaryContainer,
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: localizations.communicationStyle,
              border: const OutlineInputBorder(),
            ),
            initialValue: provider.communicationStyle,
            items: localizations.communicationStyleOptions.map((option) {
              return DropdownMenuItem<String>(
                value: option,
                child: Text(localizations.formatLabel(option)),
              );
            }).toList(),
            onChanged: (value) => provider.setCommunicationStyle(value),
          ),
          const SizedBox(height: 16),
          TextFormField(
            decoration: InputDecoration(
              labelText: localizations.toolsIntegration,
              border: const OutlineInputBorder(),
              hintText: localizations.toolsIntegrationHint,
            ),
            initialValue: provider.toolsIntegration,
            maxLines: 3,
            onChanged: (value) => provider.setToolsIntegration(value.isEmpty ? null : value),
          ),
          const SizedBox(height: 16),
          TextFormField(
            decoration: InputDecoration(
              labelText: localizations.workingStyle,
              border: const OutlineInputBorder(),
              hintText: localizations.workingStyleHint,
            ),
            initialValue: provider.workingStyle,
            maxLines: 3,
            onChanged: (value) => provider.setWorkingStyle(value.isEmpty ? null : value),
          ),
          const SizedBox(height: 16),
          TextFormField(
            decoration: InputDecoration(
              labelText: localizations.additionalInfo,
              border: const OutlineInputBorder(),
              hintText: localizations.additionalInfoHint,
            ),
            initialValue: provider.additionalInfo,
            maxLines: 3,
            onChanged: (value) => provider.setAdditionalInfo(value.isEmpty ? null : value),
          ),
        ],
      ),
    );
  }

  Widget _buildClosingPage(
    OnboardingProvider provider,
    OnboardingLocalizations localizations,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            localizations.stepClosing,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 32),
          TextFormField(
            decoration: InputDecoration(
              labelText: localizations.safeSpace,
              border: const OutlineInputBorder(),
              hintText: localizations.safeSpaceHint,
            ),
            initialValue: provider.safeSpace,
            maxLines: 4,
            onChanged: (value) => provider.setSafeSpace(value.isEmpty ? null : value),
          ),
          const SizedBox(height: 24),
          CheckboxListTile(
            title: Text(localizations.tipsOptInLabel),
            value: provider.tipsOptIn ?? false,
            onChanged: (value) => provider.setTipsOptIn(value),
          ),
        ],
      ),
    );
  }

  Widget _buildFollowOnQuestionsPage(
    OnboardingProvider provider,
    OnboardingLocalizations localizations,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            localizations.stepFollowOnQuestions,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 32),
          // Strengths Questions
          if (provider.shouldShowStrengthsQuestions) ...[
            _buildSectionTitle(localizations.strengthsQuestions),
            _buildTextArea(
              localizations.howDoYouUseStrengths,
              (value) => provider.setFollowOnQuestion(
                'strengths',
                'howDoYouUseStrengths',
                value,
              ),
              provider.followOnQuestions['strengths']?['howDoYouUseStrengths'] ?? '',
            ),
            const SizedBox(height: 16),
            _buildTextArea(
              localizations.whatHelpsTapStrengths,
              (value) => provider.setFollowOnQuestion(
                'strengths',
                'whatHelpsTapStrengths',
                value,
              ),
              provider.followOnQuestions['strengths']?['whatHelpsTapStrengths'] ?? '',
            ),
            const SizedBox(height: 16),
            _buildTextArea(
              localizations.howBuildOnStrengths,
              (value) => provider.setFollowOnQuestion(
                'strengths',
                'howBuildOnStrengths',
                value,
              ),
              provider.followOnQuestions['strengths']?['howBuildOnStrengths'] ?? '',
            ),
            const SizedBox(height: 24),
          ],
          // Challenges Questions
          if (provider.shouldShowChallengesQuestions) ...[
            _buildSectionTitle(localizations.challengesQuestions),
            _buildTextArea(
              localizations.whatsHardestToManage,
              (value) => provider.setFollowOnQuestion(
                'challenges',
                'whatsHardestToManage',
                value,
              ),
              provider.followOnQuestions['challenges']?['whatsHardestToManage'] ?? '',
            ),
            const SizedBox(height: 16),
            _buildTextArea(
              localizations.whatToolsHaveHelped,
              (value) => provider.setFollowOnQuestion(
                'challenges',
                'whatToolsHaveHelped',
                value,
              ),
              provider.followOnQuestions['challenges']?['whatToolsHaveHelped'] ?? '',
            ),
            const SizedBox(height: 16),
            _buildCheckbox(
              localizations.wouldLikeToolSuggestions,
              (value) => provider.setFollowOnQuestion(
                'challenges',
                'wouldLikeToolSuggestions',
                value ?? false,
              ),
              provider.followOnQuestions['challenges']?['wouldLikeToolSuggestions'] ?? false,
            ),
            const SizedBox(height: 16),
            _buildTextArea(
              localizations.whatHelpsRecharge,
              (value) => provider.setFollowOnQuestion(
                'challenges',
                'whatHelpsRecharge',
                value,
              ),
              provider.followOnQuestions['challenges']?['whatHelpsRecharge'] ?? '',
            ),
            const SizedBox(height: 24),
          ],
          // Learning Questions
          if (provider.shouldShowLearningQuestions) ...[
            _buildSectionTitle(localizations.learningQuestions),
            _buildTextArea(
              localizations.shareLearningExample,
              (value) => provider.setFollowOnQuestion(
                'learning',
                'shareLearningExample',
                value,
              ),
              provider.followOnQuestions['learning']?['shareLearningExample'] ?? '',
            ),
            const SizedBox(height: 16),
            _buildCheckbox(
              localizations.preferSpecificFormat,
              (value) => provider.setFollowOnQuestion(
                'learning',
                'preferSpecificFormat',
                value ?? false,
              ),
              provider.followOnQuestions['learning']?['preferSpecificFormat'] ?? false,
            ),
            const SizedBox(height: 16),
            _buildTextArea(
              localizations.howBreakDownTasks,
              (value) => provider.setFollowOnQuestion(
                'learning',
                'howBreakDownTasks',
                value,
              ),
              provider.followOnQuestions['learning']?['howBreakDownTasks'] ?? '',
            ),
            const SizedBox(height: 24),
          ],
          // Motivation Questions
          if (provider.shouldShowMotivationQuestions) ...[
            _buildSectionTitle(localizations.motivationQuestions),
            _buildTextArea(
              localizations.whatMotivatesYou,
              (value) => provider.setFollowOnQuestion(
                'motivation',
                'whatMotivatesYou',
                value,
              ),
              provider.followOnQuestions['motivation']?['whatMotivatesYou'] ?? '',
            ),
            const SizedBox(height: 16),
            _buildTextArea(
              localizations.howSetGoals,
              (value) => provider.setFollowOnQuestion(
                'motivation',
                'howSetGoals',
                value,
              ),
              provider.followOnQuestions['motivation']?['howSetGoals'] ?? '',
            ),
            const SizedBox(height: 16),
            _buildTextArea(
              localizations.whatRemindersWork,
              (value) => provider.setFollowOnQuestion(
                'motivation',
                'whatRemindersWork',
                value,
              ),
              provider.followOnQuestions['motivation']?['whatRemindersWork'] ?? '',
            ),
            const SizedBox(height: 16),
            _buildTextArea(
              localizations.howCelebrateProgress,
              (value) => provider.setFollowOnQuestion(
                'motivation',
                'howCelebrateProgress',
                value,
              ),
              provider.followOnQuestions['motivation']?['howCelebrateProgress'] ?? '',
            ),
            const SizedBox(height: 24),
          ],
          // Coping Questions
          if (provider.shouldShowCopingQuestions) ...[
            _buildSectionTitle(localizations.copingQuestions),
            _buildTextArea(
              localizations.sensoryFriendlyEnvironment,
              (value) => provider.setFollowOnQuestion(
                'coping',
                'sensoryFriendlyEnvironment',
                value,
              ),
              provider.followOnQuestions['coping']?['sensoryFriendlyEnvironment'] ?? '',
            ),
            const SizedBox(height: 16),
            _buildTextArea(
              localizations.howManageTime,
              (value) => provider.setFollowOnQuestion(
                'coping',
                'howManageTime',
                value,
              ),
              provider.followOnQuestions['coping']?['howManageTime'] ?? '',
            ),
            const SizedBox(height: 16),
            _buildTextArea(
              localizations.whatHelpsOverwhelmed,
              (value) => provider.setFollowOnQuestion(
                'coping',
                'whatHelpsOverwhelmed',
                value,
              ),
              provider.followOnQuestions['coping']?['whatHelpsOverwhelmed'] ?? '',
            ),
            const SizedBox(height: 16),
            _buildCheckbox(
              localizations.exploreCopingStrategies,
              (value) => provider.setFollowOnQuestion(
                'coping',
                'exploreCopingStrategies',
                value ?? false,
              ),
              provider.followOnQuestions['coping']?['exploreCopingStrategies'] ?? false,
            ),
            const SizedBox(height: 24),
          ],
          // Support Questions
          if (provider.shouldShowSupportQuestions) ...[
            _buildSectionTitle(localizations.supportQuestions),
            _buildTextArea(
              localizations.whatWouldMakeDifference,
              (value) => provider.setFollowOnQuestion(
                'support',
                'whatWouldMakeDifference',
                value,
              ),
              provider.followOnQuestions['support']?['whatWouldMakeDifference'] ?? '',
            ),
            const SizedBox(height: 16),
            _buildTextArea(
              localizations.whatDoesSupportLookLike,
              (value) => provider.setFollowOnQuestion(
                'support',
                'whatDoesSupportLookLike',
                value,
              ),
              provider.followOnQuestions['support']?['whatDoesSupportLookLike'] ?? '',
            ),
            const SizedBox(height: 16),
            _buildTextArea(
              localizations.specificSkillsToDevelop,
              (value) => provider.setFollowOnQuestion(
                'support',
                'specificSkillsToDevelop',
                value,
              ),
              provider.followOnQuestions['support']?['specificSkillsToDevelop'] ?? '',
            ),
            const SizedBox(height: 16),
            _buildTextArea(
              localizations.howBalanceWorkSelfCare,
              (value) => provider.setFollowOnQuestion(
                'support',
                'howBalanceWorkSelfCare',
                value,
              ),
              provider.followOnQuestions['support']?['howBalanceWorkSelfCare'] ?? '',
            ),
            const SizedBox(height: 24),
          ],
          // Coaching Buddy Questions
          if (provider.shouldShowCoachingBuddyQuestions) ...[
            _buildSectionTitle(localizations.coachingBuddyQuestions),
            _buildTextArea(
              localizations.whatTaskTakeOffPlate,
              (value) => provider.setFollowOnQuestion(
                'coachingBuddy',
                'whatTaskTakeOffPlate',
                value,
              ),
              provider.followOnQuestions['coachingBuddy']?['whatTaskTakeOffPlate'] ?? '',
            ),
            const SizedBox(height: 16),
            _buildTextArea(
              localizations.whatWouldLikeHelpWith,
              (value) => provider.setFollowOnQuestion(
                'coachingBuddy',
                'whatWouldLikeHelpWith',
                value,
              ),
              provider.followOnQuestions['coachingBuddy']?['whatWouldLikeHelpWith'] ?? '',
            ),
            const SizedBox(height: 16),
            _buildTextArea(
              localizations.howAdaptCommunication,
              (value) => provider.setFollowOnQuestion(
                'coachingBuddy',
                'howAdaptCommunication',
                value,
              ),
              provider.followOnQuestions['coachingBuddy']?['howAdaptCommunication'] ?? '',
            ),
            const SizedBox(height: 16),
            _buildTextArea(
              localizations.specificRemindersPrompts,
              (value) => provider.setFollowOnQuestion(
                'coachingBuddy',
                'specificRemindersPrompts',
                value,
              ),
              provider.followOnQuestions['coachingBuddy']?['specificRemindersPrompts'] ?? '',
            ),
            const SizedBox(height: 24),
          ],
          // Emotional Questions
          if (provider.shouldShowEmotionalQuestions) ...[
            _buildSectionTitle(localizations.emotionalQuestions),
            _buildTextArea(
              localizations.whatHelpsGrounded,
              (value) => provider.setFollowOnQuestion(
                'emotional',
                'whatHelpsGrounded',
                value,
              ),
              provider.followOnQuestions['emotional']?['whatHelpsGrounded'] ?? '',
            ),
            const SizedBox(height: 16),
            _buildTextArea(
              localizations.howProcessChallenges,
              (value) => provider.setFollowOnQuestion(
                'emotional',
                'howProcessChallenges',
                value,
              ),
              provider.followOnQuestions['emotional']?['howProcessChallenges'] ?? '',
            ),
            const SizedBox(height: 16),
            _buildTextArea(
              localizations.whatHelpsBuildCalm,
              (value) => provider.setFollowOnQuestion(
                'emotional',
                'whatHelpsBuildCalm',
                value,
              ),
              provider.followOnQuestions['emotional']?['whatHelpsBuildCalm'] ?? '',
            ),
            const SizedBox(height: 16),
            _buildTextArea(
              localizations.whatWouldHelpSupported,
              (value) => provider.setFollowOnQuestion(
                'emotional',
                'whatWouldHelpSupported',
                value,
              ),
              provider.followOnQuestions['emotional']?['whatWouldHelpSupported'] ?? '',
            ),
            const SizedBox(height: 24),
          ],
          // Celebrating Questions
          if (provider.shouldShowCelebratingQuestions) ...[
            _buildSectionTitle(localizations.celebratingQuestions),
            _buildTextArea(
              localizations.recentWinToCelebrate,
              (value) => provider.setFollowOnQuestion(
                'celebrating',
                'recentWinToCelebrate',
                value,
              ),
              provider.followOnQuestions['celebrating']?['recentWinToCelebrate'] ?? '',
            ),
            const SizedBox(height: 16),
            _buildTextArea(
              localizations.howAcknowledgeProgress,
              (value) => provider.setFollowOnQuestion(
                'celebrating',
                'howAcknowledgeProgress',
                value,
              ),
              provider.followOnQuestions['celebrating']?['howAcknowledgeProgress'] ?? '',
            ),
            const SizedBox(height: 16),
            _buildCheckbox(
              localizations.wouldLikeCelebrationIdeas,
              (value) => provider.setFollowOnQuestion(
                'celebrating',
                'wouldLikeCelebrationIdeas',
                value ?? false,
              ),
              provider.followOnQuestions['celebrating']?['wouldLikeCelebrationIdeas'] ?? false,
            ),
            const SizedBox(height: 16),
            _buildTextArea(
              localizations.howRecognizeProgress,
              (value) => provider.setFollowOnQuestion(
                'celebrating',
                'howRecognizeProgress',
                value,
              ),
              provider.followOnQuestions['celebrating']?['howRecognizeProgress'] ?? '',
            ),
            const SizedBox(height: 24),
          ],
          // Customization Questions
          if (provider.shouldShowCustomizationQuestions) ...[
            _buildSectionTitle(localizations.customizationQuestions),
            _buildTextArea(
              localizations.specificToolsToIntegrate,
              (value) => provider.setFollowOnQuestion(
                'customization',
                'specificToolsToIntegrate',
                value,
              ),
              provider.followOnQuestions['customization']?['specificToolsToIntegrate'] ?? '',
            ),
            const SizedBox(height: 16),
            _buildTextArea(
              localizations.howCustomizeCommunication,
              (value) => provider.setFollowOnQuestion(
                'customization',
                'howCustomizeCommunication',
                value,
              ),
              provider.followOnQuestions['customization']?['howCustomizeCommunication'] ?? '',
            ),
            const SizedBox(height: 16),
            _buildTextArea(
              localizations.tailoredNeeds,
              (value) => provider.setFollowOnQuestion(
                'customization',
                'tailoredNeeds',
                value,
              ),
              provider.followOnQuestions['customization']?['tailoredNeeds'] ?? '',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildTextArea(
    String label,
    Function(String) onChanged,
    String initialValue,
  ) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      initialValue: initialValue,
      maxLines: 4,
      onChanged: onChanged,
    );
  }

  Widget _buildCheckbox(
    String label,
    Function(bool?) onChanged,
    bool initialValue,
  ) {
    return CheckboxListTile(
      title: Text(label),
      value: initialValue,
      onChanged: onChanged,
    );
  }
}
