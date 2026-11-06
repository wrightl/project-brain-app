import 'package:flutter/material.dart';
import 'package:projectbrain/authentication/auth_provider.dart';
import 'package:projectbrain/core/logging/app_logger.dart';
import 'package:projectbrain/onboarding/onboarding_provider.dart';
import 'package:projectbrain/onboarding/onboarding_localizations.dart';
import 'package:provider/provider.dart';
import 'package:projectbrain/helpers/themes/app_spacing.dart';
import 'package:projectbrain/helpers/themes/app_theme_extension.dart';
import 'package:projectbrain/widgets/ds/ds_widgets.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  final Map<int, GlobalKey<FormState>> _formKeys = {};
  final TextEditingController _dobController = TextEditingController();

  @override
  void dispose() {
    _pageController.dispose();
    _dobController.dispose();
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
    // Allow navigation to any completed step, or the always-accessible first.
    if (step == 0 || step <= provider.currentStep) {
      _navigateToStep(provider, step);
    }
  }

  Future<void> _submitOnboarding(
      OnboardingProvider provider, AuthProvider authProvider) async {
    if (!provider.isBasicInfoValid) {
      _navigateToStep(provider, 0);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please complete all required fields'),
          backgroundColor: context.appTheme.errorColor,
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
        SnackBar(
          content: const Text('Onboarding complete!'),
          backgroundColor: context.appTheme.green,
        ),
      );
    } catch (error) {
      logError('[OnboardingPage] Error during onboarding', error);
      if (!mounted) return;

      provider.setError('Failed to complete onboarding: ${error.toString()}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${error.toString()}'),
          backgroundColor: context.appTheme.errorColor,
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

          return _stepBackOnPop(provider,
              child: Scaffold(
                body: SafeArea(
                  child: Column(
                    children: [
                      _buildHeader(provider, totalSteps),
                      Expanded(
                        child: PageView(
                          controller: _pageController,
                          physics: const NeverScrollableScrollPhysics(),
                          onPageChanged: (index) {
                            provider.setCurrentStep(index);
                          },
                          children: _buildPages(
                              provider, authProvider, localizations),
                        ),
                      ),
                      _buildNavigationButtons(
                        provider,
                        authProvider,
                        isLastStep,
                        localizations,
                      ),
                    ],
                  ),
                ),
              ));
        },
      ),
    );
  }

  /// System back steps back through onboarding instead of leaving it (which
  /// would lose every answer so far).
  Widget _stepBackOnPop(OnboardingProvider provider, {required Widget child}) {
    return PopScope(
      canPop: provider.currentStep == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _previousPage(provider);
      },
      child: child,
    );
  }

  /// Header: back button, step-count pill, and segmented progress bar.
  Widget _buildHeader(OnboardingProvider provider, int totalSteps) {
    final theme = Theme.of(context);
    final appTheme = context.appTheme;
    final currentStep = provider.currentStep;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Column(
        children: [
          Row(
            children: [
              if (currentStep > 0)
                IconButton(
                  tooltip: 'Previous step',
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => _previousPage(provider),
                  style: IconButton.styleFrom(
                    backgroundColor: theme.colorScheme.surface,
                    side: BorderSide(color: appTheme.borderColor),
                  ),
                )
              else
                const SizedBox(width: 48),
              Expanded(
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: appTheme.primarySoft,
                      borderRadius: AppRadius.circularPill,
                    ),
                    child: Text(
                      'Step ${currentStep + 1} of $totalSteps',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
          // Read as one "Step n of m" instead of a row of unlabelled bars.
          // The 6dp bars get a taller transparent hit area.
          Semantics(
            label: 'Step ${currentStep + 1} of $totalSteps',
            child: ExcludeSemantics(
              child: Row(
                children: List.generate(
                  totalSteps,
                  (index) => Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _onStepTapped(provider, index),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        child: MouseRegion(
                          cursor: (index == 0 || index <= currentStep)
                              ? SystemMouseCursors.click
                              : SystemMouseCursors.basic,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            margin: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.micro,
                            ),
                            height: 6.0,
                            decoration: BoxDecoration(
                              color: index <= currentStep
                                  ? theme.colorScheme.primary
                                  : appTheme.primarySoft,
                              borderRadius: AppRadius.circularPill,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
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
    final theme = Theme.of(context);
    final appTheme = context.appTheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(top: BorderSide(color: appTheme.borderColor)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Everything after Basic Info is optional; let people start using
          // the app now instead of facing every remaining step.
          if (provider.currentStep > 0 && !isLastStep)
            TextButton(
              onPressed: provider.isSubmitting
                  ? null
                  : () => _submitOnboarding(provider, authProvider),
              child: const Text('Skip the rest and get started'),
            ),
          Row(
            children: [
              if (provider.currentStep > 0) ...[
                Expanded(
                  child: OutlinedButton(
                    onPressed: provider.isSubmitting
                        ? null
                        : () => _previousPage(provider),
                    child: Text(localizations.previous),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
              ],
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: provider.isSubmitting
                      ? null
                      : () {
                          if (isLastStep) {
                            _submitOnboarding(provider, authProvider);
                          } else {
                            _nextPage(provider);
                          }
                        },
                  icon: provider.isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              semanticsLabel: 'Loading', strokeWidth: 2),
                        )
                      : Icon(isLastStep ? Icons.check : Icons.arrow_forward,
                          size: 18),
                  label: Text(
                    isLastStep ? localizations.complete : localizations.next,
                  ),
                ),
              ),
            ],
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

  /// Step intro: accent icon bubble, title, and optional subtitle.
  Widget _stepHeader({
    required IconData icon,
    required Color color,
    required Color backgroundColor,
    required String title,
    String? subtitle,
  }) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconBubble(
          icon: icon,
          color: color,
          backgroundColor: backgroundColor,
          size: 56,
          iconSize: 28,
          borderRadius: 16,
        ),
        const SizedBox(height: AppSpacing.lg),
        Semantics(
            header: true,
            child: Text(title, style: theme.textTheme.headlineSmall)),
        if (subtitle != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(subtitle, style: theme.textTheme.bodySmall),
        ],
      ],
    );
  }

  /// Design-system chip group for multi-select options.
  Widget _choiceChips({
    required List<String> options,
    required bool Function(String) isSelected,
    required void Function(String) onToggle,
    String Function(String)? format,
  }) {
    final theme = Theme.of(context);
    final appTheme = context.appTheme;

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: options.map((option) {
        final selected = isSelected(option);
        return FilterChip(
          label: Text(format?.call(option) ?? option),
          selected: selected,
          onSelected: (_) => onToggle(option),
          backgroundColor: theme.colorScheme.surface,
          selectedColor: appTheme.primarySoft,
          checkmarkColor: theme.colorScheme.primary,
          labelStyle: theme.textTheme.labelMedium?.copyWith(
            color: selected
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
          side: BorderSide(
            color: selected ? theme.colorScheme.primary : appTheme.borderColor,
          ),
        );
      }).toList(),
    );
  }

  Widget _fieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        label,
        style: Theme.of(context).textTheme.titleSmall,
      ),
    );
  }

  Widget _buildBasicInfoPage(
    OnboardingProvider provider,
    AuthProvider authProvider,
    OnboardingLocalizations localizations,
  ) {
    final appTheme = context.appTheme;
    final formKey = _formKeys.putIfAbsent(0, () => GlobalKey<FormState>());
    final dobController = _dobController;

    if (provider.dateOfBirth != null) {
      dobController.text =
          '${provider.dateOfBirth!.year}-${provider.dateOfBirth!.month.toString().padLeft(2, '0')}-${provider.dateOfBirth!.day.toString().padLeft(2, '0')}';
    }

    return SingleChildScrollView(
      padding: AppInsets.page,
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _stepHeader(
              icon: Icons.waving_hand_outlined,
              color: Theme.of(context).colorScheme.primary,
              backgroundColor: appTheme.primarySoft,
              title: 'Welcome ${authProvider.profile?.name ?? 'there'}!',
              subtitle: 'Please complete your profile.',
            ),
            const SizedBox(height: AppSpacing.xl),
            TextFormField(
              decoration: InputDecoration(
                labelText: localizations.fullName,
                prefixIcon: const Icon(Icons.person_outline),
              ),
              initialValue: provider.fullName.isEmpty
                  ? authProvider.profile?.name ?? ''
                  : provider.fullName,
              validator: (val) =>
                  val == null || val.isEmpty ? localizations.required : null,
              onSaved: (val) => provider.setFullName(val ?? ''),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextFormField(
              controller: dobController,
              readOnly: true,
              decoration: InputDecoration(
                labelText: '${localizations.dateOfBirth} (optional)',
                prefixIcon: const Icon(Icons.cake_outlined),
                suffixIcon: const Icon(Icons.calendar_today, size: 18),
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
            ),
            const SizedBox(height: AppSpacing.lg),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: '${localizations.preferredPronoun} (optional)',
                prefixIcon: const Icon(Icons.badge_outlined),
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
    final appTheme = context.appTheme;
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
      padding: AppInsets.page,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepHeader(
            icon: Icons.psychology_outlined,
            color: appTheme.sky,
            backgroundColor: appTheme.skySoft,
            title: localizations.stepNeurodiverseTraits,
            subtitle: localizations.selectTraits,
          ),
          const SizedBox(height: AppSpacing.xl),
          DsSurfaceCard(
            child: _choiceChips(
              options: traits,
              isSelected: (t) => provider.selectedTraits.contains(t),
              onToggle: provider.toggleTrait,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomePage(
    OnboardingProvider provider,
    OnboardingLocalizations localizations,
  ) {
    final appTheme = context.appTheme;

    return SingleChildScrollView(
      padding: AppInsets.page,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepHeader(
            icon: Icons.favorite_outline,
            color: appTheme.coral,
            backgroundColor: appTheme.coralSoft,
            title: localizations.stepWelcome,
          ),
          const SizedBox(height: AppSpacing.xl),
          TextFormField(
            decoration: InputDecoration(
              labelText: localizations.preferredName,
              hintText: localizations.preferredName,
              prefixIcon: const Icon(Icons.emoji_people_outlined),
            ),
            initialValue: provider.preferredName,
            onChanged: (value) =>
                provider.setPreferredName(value.isEmpty ? null : value),
          ),
          const SizedBox(height: AppSpacing.lg),
          TextFormField(
            decoration: InputDecoration(
              labelText: localizations.inspiration,
              hintText: localizations.inspirationHint,
            ),
            initialValue: provider.inspiration,
            maxLines: 4,
            onChanged: (value) =>
                provider.setInspiration(value.isEmpty ? null : value),
          ),
          const SizedBox(height: AppSpacing.lg),
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: localizations.currentFeeling,
              prefixIcon: const Icon(Icons.mood_outlined),
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
    final appTheme = context.appTheme;

    return SingleChildScrollView(
      padding: AppInsets.page,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepHeader(
            icon: Icons.person_search_outlined,
            color: appTheme.amber,
            backgroundColor: appTheme.amberSoft,
            title: localizations.stepAboutYou,
          ),
          const SizedBox(height: AppSpacing.xl),
          _fieldLabel(localizations.selfDescription),
          DsSurfaceCard(
            child: _choiceChips(
              options: localizations.selfDescriptionOptions,
              isSelected: (o) => provider.selfDescription.contains(o),
              onToggle: provider.toggleSelfDescription,
              format: localizations.formatLabel,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          TextFormField(
            decoration: InputDecoration(
              labelText: localizations.businessType,
              hintText: localizations.businessTypeHint,
            ),
            initialValue: provider.businessType,
            maxLines: 3,
            onChanged: (value) =>
                provider.setBusinessType(value.isEmpty ? null : value),
          ),
          const SizedBox(height: AppSpacing.lg),
          TextFormField(
            decoration: InputDecoration(
              labelText: localizations.proudMoment,
              hintText: localizations.proudMomentHint,
            ),
            initialValue: provider.proudMoment,
            maxLines: 3,
            onChanged: (value) =>
                provider.setProudMoment(value.isEmpty ? null : value),
          ),
          const SizedBox(height: AppSpacing.xl),
          _fieldLabel(localizations.challenge),
          DsSurfaceCard(
            child: _choiceChips(
              options: localizations.challengeOptions,
              isSelected: (o) => provider.challenges.contains(o),
              onToggle: provider.toggleChallenge,
              format: localizations.formatLabel,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesPage(
    OnboardingProvider provider,
    OnboardingLocalizations localizations,
  ) {
    final appTheme = context.appTheme;

    return SingleChildScrollView(
      padding: AppInsets.page,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepHeader(
            icon: Icons.tune_outlined,
            color: appTheme.teal,
            backgroundColor: appTheme.tealSoft,
            title: localizations.stepPreferences,
          ),
          const SizedBox(height: AppSpacing.xl),
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: localizations.learningStyle,
              prefixIcon: const Icon(Icons.school_outlined),
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
          const SizedBox(height: AppSpacing.lg),
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: localizations.informationDepth,
              prefixIcon: const Icon(Icons.layers_outlined),
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
          const SizedBox(height: AppSpacing.lg),
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: localizations.celebrationStyle,
              prefixIcon: const Icon(Icons.celebration_outlined),
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
    final appTheme = context.appTheme;

    return SingleChildScrollView(
      padding: AppInsets.page,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepHeader(
            icon: Icons.star_outline,
            color: appTheme.green,
            backgroundColor: appTheme.greenSoft,
            title: localizations.stepProfile,
          ),
          const SizedBox(height: AppSpacing.xl),
          _fieldLabel(localizations.strengths),
          DsSurfaceCard(
            child: _choiceChips(
              options: localizations.strengthsOptions,
              isSelected: (o) => provider.strengths.contains(o),
              onToggle: provider.toggleStrength,
              format: localizations.formatLabel,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          _fieldLabel(localizations.supportAreas),
          DsSurfaceCard(
            child: _choiceChips(
              options: localizations.supportAreasOptions,
              isSelected: (o) => provider.supportAreas.contains(o),
              onToggle: provider.toggleSupportArea,
              format: localizations.formatLabel,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: localizations.motivationStyle,
              prefixIcon: const Icon(Icons.rocket_launch_outlined),
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
          const SizedBox(height: AppSpacing.lg),
          TextFormField(
            decoration: InputDecoration(
              labelText: localizations.neurodivergentUnderstanding,
              hintText: localizations.neurodivergentUnderstandingHint,
            ),
            initialValue: provider.neurodivergentUnderstanding,
            maxLines: 3,
            onChanged: (value) => provider
                .setNeurodivergentUnderstanding(value.isEmpty ? null : value),
          ),
          const SizedBox(height: AppSpacing.lg),
          TextFormField(
            decoration: InputDecoration(
              labelText: localizations.biggestGoal,
              hintText: localizations.biggestGoalHint,
            ),
            initialValue: provider.biggestGoal,
            maxLines: 3,
            onChanged: (value) =>
                provider.setBiggestGoal(value.isEmpty ? null : value),
          ),
        ],
      ),
    );
  }

  Widget _buildCoachingBuddyPage(
    OnboardingProvider provider,
    OnboardingLocalizations localizations,
  ) {
    final theme = Theme.of(context);
    final appTheme = context.appTheme;

    return SingleChildScrollView(
      padding: AppInsets.page,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepHeader(
            icon: Icons.smart_toy_outlined,
            color: theme.colorScheme.primary,
            backgroundColor: appTheme.primarySoft,
            title: localizations.stepCoachingBuddy,
          ),
          const SizedBox(height: AppSpacing.xl),
          _fieldLabel(localizations.tasks),
          DsSurfaceCard(
            child: _choiceChips(
              options: localizations.tasksOptions,
              isSelected: (o) => provider.tasks.contains(o),
              onToggle: provider.toggleTask,
              format: localizations.formatLabel,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: localizations.communicationStyle,
              prefixIcon: const Icon(Icons.chat_bubble_outline),
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
          const SizedBox(height: AppSpacing.lg),
          TextFormField(
            decoration: InputDecoration(
              labelText: localizations.toolsIntegration,
              hintText: localizations.toolsIntegrationHint,
            ),
            initialValue: provider.toolsIntegration,
            maxLines: 3,
            onChanged: (value) =>
                provider.setToolsIntegration(value.isEmpty ? null : value),
          ),
          const SizedBox(height: AppSpacing.lg),
          TextFormField(
            decoration: InputDecoration(
              labelText: localizations.workingStyle,
              hintText: localizations.workingStyleHint,
            ),
            initialValue: provider.workingStyle,
            maxLines: 3,
            onChanged: (value) =>
                provider.setWorkingStyle(value.isEmpty ? null : value),
          ),
          const SizedBox(height: AppSpacing.lg),
          TextFormField(
            decoration: InputDecoration(
              labelText: localizations.additionalInfo,
              hintText: localizations.additionalInfoHint,
            ),
            initialValue: provider.additionalInfo,
            maxLines: 3,
            onChanged: (value) =>
                provider.setAdditionalInfo(value.isEmpty ? null : value),
          ),
        ],
      ),
    );
  }

  Widget _buildClosingPage(
    OnboardingProvider provider,
    OnboardingLocalizations localizations,
  ) {
    final appTheme = context.appTheme;

    return SingleChildScrollView(
      padding: AppInsets.page,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepHeader(
            icon: Icons.spa_outlined,
            color: appTheme.coral,
            backgroundColor: appTheme.coralSoft,
            title: localizations.stepClosing,
          ),
          const SizedBox(height: AppSpacing.xl),
          TextFormField(
            decoration: InputDecoration(
              labelText: localizations.safeSpace,
              hintText: localizations.safeSpaceHint,
            ),
            initialValue: provider.safeSpace,
            maxLines: 4,
            onChanged: (value) =>
                provider.setSafeSpace(value.isEmpty ? null : value),
          ),
          const SizedBox(height: AppSpacing.xl),
          _buildCheckbox(
            localizations.tipsOptInLabel,
            (value) => provider.setTipsOptIn(value),
            provider.tipsOptIn ?? false,
          ),
        ],
      ),
    );
  }

  /// Follow-on questions, in display order. Each section shows when its
  /// provider flag is set; answers are stored under its category and key.
  List<_FollowOnSection> _followOnSections(
    OnboardingProvider provider,
    OnboardingLocalizations l,
  ) =>
      [
        _FollowOnSection(
          visible: provider.shouldShowStrengthsQuestions,
          title: l.strengthsQuestions,
          category: 'strengths',
          questions: [
            _FollowOnQuestion('howDoYouUseStrengths', l.howDoYouUseStrengths),
            _FollowOnQuestion('whatHelpsTapStrengths', l.whatHelpsTapStrengths),
            _FollowOnQuestion('howBuildOnStrengths', l.howBuildOnStrengths),
          ],
        ),
        _FollowOnSection(
          visible: provider.shouldShowChallengesQuestions,
          title: l.challengesQuestions,
          category: 'challenges',
          questions: [
            _FollowOnQuestion('whatsHardestToManage', l.whatsHardestToManage),
            _FollowOnQuestion('whatToolsHaveHelped', l.whatToolsHaveHelped),
            _FollowOnQuestion.yesNo(
                'wouldLikeToolSuggestions', l.wouldLikeToolSuggestions),
            _FollowOnQuestion('whatHelpsRecharge', l.whatHelpsRecharge),
          ],
        ),
        _FollowOnSection(
          visible: provider.shouldShowLearningQuestions,
          title: l.learningQuestions,
          category: 'learning',
          questions: [
            _FollowOnQuestion('shareLearningExample', l.shareLearningExample),
            _FollowOnQuestion.yesNo(
                'preferSpecificFormat', l.preferSpecificFormat),
            _FollowOnQuestion('howBreakDownTasks', l.howBreakDownTasks),
          ],
        ),
        _FollowOnSection(
          visible: provider.shouldShowMotivationQuestions,
          title: l.motivationQuestions,
          category: 'motivation',
          questions: [
            _FollowOnQuestion('whatMotivatesYou', l.whatMotivatesYou),
            _FollowOnQuestion('howSetGoals', l.howSetGoals),
            _FollowOnQuestion('whatRemindersWork', l.whatRemindersWork),
            _FollowOnQuestion('howCelebrateProgress', l.howCelebrateProgress),
          ],
        ),
        _FollowOnSection(
          visible: provider.shouldShowCopingQuestions,
          title: l.copingQuestions,
          category: 'coping',
          questions: [
            _FollowOnQuestion(
                'sensoryFriendlyEnvironment', l.sensoryFriendlyEnvironment),
            _FollowOnQuestion('howManageTime', l.howManageTime),
            _FollowOnQuestion('whatHelpsOverwhelmed', l.whatHelpsOverwhelmed),
            _FollowOnQuestion.yesNo(
                'exploreCopingStrategies', l.exploreCopingStrategies),
          ],
        ),
        _FollowOnSection(
          visible: provider.shouldShowSupportQuestions,
          title: l.supportQuestions,
          category: 'support',
          questions: [
            _FollowOnQuestion(
                'whatWouldMakeDifference', l.whatWouldMakeDifference),
            _FollowOnQuestion(
                'whatDoesSupportLookLike', l.whatDoesSupportLookLike),
            _FollowOnQuestion(
                'specificSkillsToDevelop', l.specificSkillsToDevelop),
            _FollowOnQuestion(
                'howBalanceWorkSelfCare', l.howBalanceWorkSelfCare),
          ],
        ),
        _FollowOnSection(
          visible: provider.shouldShowCoachingBuddyQuestions,
          title: l.coachingBuddyQuestions,
          category: 'coachingBuddy',
          questions: [
            _FollowOnQuestion('whatTaskTakeOffPlate', l.whatTaskTakeOffPlate),
            _FollowOnQuestion('whatWouldLikeHelpWith', l.whatWouldLikeHelpWith),
            _FollowOnQuestion('howAdaptCommunication', l.howAdaptCommunication),
            _FollowOnQuestion(
                'specificRemindersPrompts', l.specificRemindersPrompts),
          ],
        ),
        _FollowOnSection(
          visible: provider.shouldShowEmotionalQuestions,
          title: l.emotionalQuestions,
          category: 'emotional',
          questions: [
            _FollowOnQuestion('whatHelpsGrounded', l.whatHelpsGrounded),
            _FollowOnQuestion('howProcessChallenges', l.howProcessChallenges),
            _FollowOnQuestion('whatHelpsBuildCalm', l.whatHelpsBuildCalm),
            _FollowOnQuestion(
                'whatWouldHelpSupported', l.whatWouldHelpSupported),
          ],
        ),
        _FollowOnSection(
          visible: provider.shouldShowCelebratingQuestions,
          title: l.celebratingQuestions,
          category: 'celebrating',
          questions: [
            _FollowOnQuestion('recentWinToCelebrate', l.recentWinToCelebrate),
            _FollowOnQuestion(
                'howAcknowledgeProgress', l.howAcknowledgeProgress),
            _FollowOnQuestion.yesNo(
                'wouldLikeCelebrationIdeas', l.wouldLikeCelebrationIdeas),
            _FollowOnQuestion('howRecognizeProgress', l.howRecognizeProgress),
          ],
        ),
        _FollowOnSection(
          visible: provider.shouldShowCustomizationQuestions,
          title: l.customizationQuestions,
          category: 'customization',
          questions: [
            _FollowOnQuestion(
                'specificToolsToIntegrate', l.specificToolsToIntegrate),
            _FollowOnQuestion(
                'howCustomizeCommunication', l.howCustomizeCommunication),
            _FollowOnQuestion('tailoredNeeds', l.tailoredNeeds),
          ],
        ),
      ];

  Widget _buildFollowOnQuestionsPage(
    OnboardingProvider provider,
    OnboardingLocalizations localizations,
  ) {
    final appTheme = context.appTheme;
    final answers = provider.followOnQuestions;

    return SingleChildScrollView(
      padding: AppInsets.page,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepHeader(
            icon: Icons.question_answer_outlined,
            color: appTheme.sky,
            backgroundColor: appTheme.skySoft,
            title: localizations.stepFollowOnQuestions,
          ),
          const SizedBox(height: AppSpacing.xl),
          for (final section in _followOnSections(provider, localizations))
            if (section.visible) ...[
              _buildSectionTitle(section.title),
              for (final (index, question) in section.questions.indexed) ...[
                if (index > 0) const SizedBox(height: AppSpacing.lg),
                if (question.isYesNo)
                  _buildCheckbox(
                    question.label,
                    (value) => provider.setFollowOnQuestion(
                      section.category,
                      question.key,
                      value ?? false,
                    ),
                    answers[section.category]?[question.key] ?? false,
                  )
                else
                  _buildTextArea(
                    question.label,
                    (value) => provider.setFollowOnQuestion(
                      section.category,
                      question.key,
                      value,
                    ),
                    answers[section.category]?[question.key] ?? '',
                  ),
              ],
              const SizedBox(height: AppSpacing.xl),
            ],
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: SectionHeader(title: title),
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
        alignLabelWithHint: true,
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
    final theme = Theme.of(context);
    final appTheme = context.appTheme;

    return DsSurfaceCard(
      onTap: () => onChanged(!initialValue),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      backgroundColor:
          initialValue ? appTheme.primarySoft : theme.colorScheme.surface,
      borderColor: initialValue
          ? theme.colorScheme.primary.withValues(alpha: 0.4)
          : appTheme.borderColor,
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: initialValue
                  ? theme.colorScheme.primary
                  : theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: initialValue
                    ? theme.colorScheme.primary
                    : appTheme.textMuted,
                width: 1.5,
              ),
            ),
            child: initialValue
                ? const Icon(Icons.check, size: 16, color: Colors.white)
                : null,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(label, style: theme.textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

class _FollowOnSection {
  const _FollowOnSection({
    required this.visible,
    required this.title,
    required this.category,
    required this.questions,
  });

  final bool visible;
  final String title;
  final String category;
  final List<_FollowOnQuestion> questions;
}

class _FollowOnQuestion {
  const _FollowOnQuestion(this.key, this.label) : isYesNo = false;
  const _FollowOnQuestion.yesNo(this.key, this.label) : isYesNo = true;

  final String key;
  final String label;
  final bool isYesNo;
}
