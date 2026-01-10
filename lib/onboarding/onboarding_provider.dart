import 'package:flutter/material.dart';
import 'package:projectbrain/models/onboarding_data.dart';
import 'package:projectbrain/onboarding/onboarding_localizations.dart';

/// Provider for managing onboarding wizard state
class OnboardingProvider extends ChangeNotifier {
  // Basic Info (required)
  String _fullName = '';
  DateTime? _dateOfBirth;
  String _preferredPronoun = '';

  // Neurodiverse Traits (optional)
  final Set<String> _selectedTraits = {};

  // Welcome Section (optional)
  String? _preferredName;
  String? _inspiration;
  String? _currentFeeling;

  // About You Section (optional)
  final Set<String> _selfDescription = {};
  String? _businessType;
  String? _proudMoment;
  final Set<String> _challenges = {};

  // Preferences Section (optional)
  String? _learningStyle;
  String? _informationDepth;
  String? _celebrationStyle;

  // Profile Section (optional)
  final Set<String> _strengths = {};
  final Set<String> _supportAreas = {};
  String? _motivationStyle;
  String? _neurodivergentUnderstanding;
  String? _biggestGoal;

  // Coaching Buddy Section (optional)
  final Set<String> _tasks = {};
  String? _communicationStyle;
  String? _toolsIntegration;
  String? _workingStyle;
  String? _additionalInfo;

  // Closing Section (optional)
  String? _safeSpace;
  bool? _tipsOptIn;

  // Follow-On Questions (conditional)
  final Map<String, dynamic> _followOnQuestions = {};

  // Navigation state
  int _currentStep = 0;
  final Set<int> _visitedSteps = {0}; // Track visited steps
  bool _isSubmitting = false;
  String? _errorMessage;

  // Getters
  String get fullName => _fullName;
  DateTime? get dateOfBirth => _dateOfBirth;
  String get preferredPronoun => _preferredPronoun;
  Set<String> get selectedTraits => Set.unmodifiable(_selectedTraits);
  String? get preferredName => _preferredName;
  String? get inspiration => _inspiration;
  String? get currentFeeling => _currentFeeling;
  Set<String> get selfDescription => Set.unmodifiable(_selfDescription);
  String? get businessType => _businessType;
  String? get proudMoment => _proudMoment;
  Set<String> get challenges => Set.unmodifiable(_challenges);
  String? get learningStyle => _learningStyle;
  String? get informationDepth => _informationDepth;
  String? get celebrationStyle => _celebrationStyle;
  Set<String> get strengths => Set.unmodifiable(_strengths);
  Set<String> get supportAreas => Set.unmodifiable(_supportAreas);
  String? get motivationStyle => _motivationStyle;
  String? get neurodivergentUnderstanding => _neurodivergentUnderstanding;
  String? get biggestGoal => _biggestGoal;
  Set<String> get tasks => Set.unmodifiable(_tasks);
  String? get communicationStyle => _communicationStyle;
  String? get toolsIntegration => _toolsIntegration;
  String? get workingStyle => _workingStyle;
  String? get additionalInfo => _additionalInfo;
  String? get safeSpace => _safeSpace;
  bool? get tipsOptIn => _tipsOptIn;
  Map<String, dynamic> get followOnQuestions =>
      Map.unmodifiable(_followOnQuestions);
  int get currentStep => _currentStep;
  Set<int> get visitedSteps => Set.unmodifiable(_visitedSteps);
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;

  /// Check if basic info step is valid
  bool get isBasicInfoValid {
    return _fullName.isNotEmpty &&
        _dateOfBirth != null &&
        _preferredPronoun.isNotEmpty;
  }

  /// Check if follow-on questions step should be shown
  bool get shouldShowFollowOnQuestions {
    return shouldShowStrengthsQuestions ||
        shouldShowChallengesQuestions ||
        shouldShowLearningQuestions ||
        shouldShowMotivationQuestions ||
        shouldShowCopingQuestions ||
        shouldShowSupportQuestions ||
        shouldShowCoachingBuddyQuestions ||
        shouldShowEmotionalQuestions ||
        shouldShowCelebratingQuestions ||
        shouldShowCustomizationQuestions;
  }

  bool get shouldShowStrengthsQuestions => _strengths.isNotEmpty;
  bool get shouldShowChallengesQuestions =>
      _challenges.isNotEmpty || _supportAreas.isNotEmpty;
  bool get shouldShowLearningQuestions => _learningStyle != null;
  bool get shouldShowMotivationQuestions => _motivationStyle != null;
  bool get shouldShowCopingQuestions =>
      _challenges.contains('organization') ||
      _challenges.contains('organisation') ||
      _challenges.contains('focus') ||
      _challenges.contains('energy-management');
  bool get shouldShowSupportQuestions => _supportAreas.isNotEmpty;
  bool get shouldShowCoachingBuddyQuestions => _tasks.isNotEmpty;
  bool get shouldShowEmotionalQuestions =>
      _currentFeeling == 'overwhelmed' ||
      _currentFeeling == 'stuck' ||
      _currentFeeling == 'uncertain';
  bool get shouldShowCelebratingQuestions => _celebrationStyle != null;
  bool get shouldShowCustomizationQuestions =>
      _toolsIntegration != null && _toolsIntegration!.isNotEmpty;

  /// Get total number of steps (including conditional follow-on questions)
  int getTotalSteps() {
    int steps = 8; // Basic steps: Basic Info, Traits, Welcome, About You, Preferences, Profile, Coaching Buddy, Closing
    if (shouldShowFollowOnQuestions) {
      steps += 1; // Add follow-on questions step
    }
    return steps;
  }

  /// Get step index for follow-on questions (if applicable)
  int? getFollowOnQuestionsStepIndex() {
    if (!shouldShowFollowOnQuestions) return null;
    return 8; // Follow-on questions is step 8 (0-indexed)
  }

  // Setters
  void setFullName(String value) {
    _fullName = value;
    notifyListeners();
  }

  void setDateOfBirth(DateTime? value) {
    _dateOfBirth = value;
    notifyListeners();
  }

  void setPreferredPronoun(String value) {
    _preferredPronoun = value;
    notifyListeners();
  }

  void toggleTrait(String trait) {
    if (_selectedTraits.contains(trait)) {
      _selectedTraits.remove(trait);
    } else {
      _selectedTraits.add(trait);
    }
    notifyListeners();
  }

  void setPreferredName(String? value) {
    _preferredName = value;
    notifyListeners();
  }

  void setInspiration(String? value) {
    _inspiration = value;
    notifyListeners();
  }

  void setCurrentFeeling(String? value) {
    _currentFeeling = value;
    notifyListeners();
  }

  void toggleSelfDescription(String value) {
    if (_selfDescription.contains(value)) {
      _selfDescription.remove(value);
    } else {
      _selfDescription.add(value);
    }
    notifyListeners();
  }

  void setBusinessType(String? value) {
    _businessType = value;
    notifyListeners();
  }

  void setProudMoment(String? value) {
    _proudMoment = value;
    notifyListeners();
  }

  void toggleChallenge(String value) {
    if (_challenges.contains(value)) {
      _challenges.remove(value);
    } else {
      _challenges.add(value);
    }
    notifyListeners();
  }

  void setLearningStyle(String? value) {
    _learningStyle = value;
    notifyListeners();
  }

  void setInformationDepth(String? value) {
    _informationDepth = value;
    notifyListeners();
  }

  void setCelebrationStyle(String? value) {
    _celebrationStyle = value;
    notifyListeners();
  }

  void toggleStrength(String value) {
    if (_strengths.contains(value)) {
      _strengths.remove(value);
    } else {
      _strengths.add(value);
    }
    notifyListeners();
  }

  void toggleSupportArea(String value) {
    if (_supportAreas.contains(value)) {
      _supportAreas.remove(value);
    } else {
      _supportAreas.add(value);
    }
    notifyListeners();
  }

  void setMotivationStyle(String? value) {
    _motivationStyle = value;
    notifyListeners();
  }

  void setNeurodivergentUnderstanding(String? value) {
    _neurodivergentUnderstanding = value;
    notifyListeners();
  }

  void setBiggestGoal(String? value) {
    _biggestGoal = value;
    notifyListeners();
  }

  void toggleTask(String value) {
    if (_tasks.contains(value)) {
      _tasks.remove(value);
    } else {
      _tasks.add(value);
    }
    notifyListeners();
  }

  void setCommunicationStyle(String? value) {
    _communicationStyle = value;
    notifyListeners();
  }

  void setToolsIntegration(String? value) {
    _toolsIntegration = value;
    notifyListeners();
  }

  void setWorkingStyle(String? value) {
    _workingStyle = value;
    notifyListeners();
  }

  void setAdditionalInfo(String? value) {
    _additionalInfo = value;
    notifyListeners();
  }

  void setSafeSpace(String? value) {
    _safeSpace = value;
    notifyListeners();
  }

  void setTipsOptIn(bool? value) {
    _tipsOptIn = value;
    notifyListeners();
  }

  void setFollowOnQuestion(String category, String question, dynamic value) {
    if (!_followOnQuestions.containsKey(category)) {
      _followOnQuestions[category] = {};
    }
    _followOnQuestions[category][question] = value;
    notifyListeners();
  }

  void setCurrentStep(int step) {
    _currentStep = step;
    _visitedSteps.add(step);
    notifyListeners();
  }

  void setSubmitting(bool value) {
    _isSubmitting = value;
    notifyListeners();
  }

  void setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Build the complete onboarding data structure
  UserOnboardingData buildOnboardingData(
      String email, OnboardingLocalizations localizations) {
    // Build follow-on questions map
    final followOnQuestions = <String, dynamic>{};

    if (shouldShowStrengthsQuestions) {
      followOnQuestions['strengths'] = {
        'howDoYouUseStrengths': _followOnQuestions['strengths']
                ?['howDoYouUseStrengths'] ??
            '',
        'whatHelpsTapStrengths': _followOnQuestions['strengths']
                ?['whatHelpsTapStrengths'] ??
            '',
        'howBuildOnStrengths':
            _followOnQuestions['strengths']?['howBuildOnStrengths'] ?? '',
      };
    }

    if (shouldShowChallengesQuestions) {
      followOnQuestions['challenges'] = {
        'whatsHardestToManage':
            _followOnQuestions['challenges']?['whatsHardestToManage'] ?? '',
        'whatToolsHaveHelped':
            _followOnQuestions['challenges']?['whatToolsHaveHelped'] ?? '',
        'wouldLikeToolSuggestions':
            _followOnQuestions['challenges']?['wouldLikeToolSuggestions'] ??
                false,
        'whatHelpsRecharge':
            _followOnQuestions['challenges']?['whatHelpsRecharge'] ?? '',
      };
    }

    if (shouldShowLearningQuestions) {
      followOnQuestions['learning'] = {
        'shareLearningExample':
            _followOnQuestions['learning']?['shareLearningExample'] ?? '',
        'preferSpecificFormat':
            _followOnQuestions['learning']?['preferSpecificFormat'] ?? false,
        'howBreakDownTasks':
            _followOnQuestions['learning']?['howBreakDownTasks'] ?? '',
      };
    }

    if (shouldShowMotivationQuestions) {
      followOnQuestions['motivation'] = {
        'whatMotivatesYou':
            _followOnQuestions['motivation']?['whatMotivatesYou'] ?? '',
        'howSetGoals': _followOnQuestions['motivation']?['howSetGoals'] ?? '',
        'whatRemindersWork':
            _followOnQuestions['motivation']?['whatRemindersWork'] ?? '',
        'howCelebrateProgress':
            _followOnQuestions['motivation']?['howCelebrateProgress'] ?? '',
      };
    }

    if (shouldShowCopingQuestions) {
      followOnQuestions['coping'] = {
        'sensoryFriendlyEnvironment':
            _followOnQuestions['coping']?['sensoryFriendlyEnvironment'] ?? '',
        'howManageTime': _followOnQuestions['coping']?['howManageTime'] ?? '',
        'whatHelpsOverwhelmed':
            _followOnQuestions['coping']?['whatHelpsOverwhelmed'] ?? '',
        'exploreCopingStrategies':
            _followOnQuestions['coping']?['exploreCopingStrategies'] ?? false,
      };
    }

    if (shouldShowSupportQuestions) {
      followOnQuestions['support'] = {
        'whatWouldMakeDifference':
            _followOnQuestions['support']?['whatWouldMakeDifference'] ?? '',
        'whatDoesSupportLookLike':
            _followOnQuestions['support']?['whatDoesSupportLookLike'] ?? '',
        'specificSkillsToDevelop':
            _followOnQuestions['support']?['specificSkillsToDevelop'] ?? '',
        'howBalanceWorkSelfCare':
            _followOnQuestions['support']?['howBalanceWorkSelfCare'] ?? '',
      };
    }

    if (shouldShowCoachingBuddyQuestions) {
      followOnQuestions['coachingBuddy'] = {
        'whatTaskTakeOffPlate':
            _followOnQuestions['coachingBuddy']?['whatTaskTakeOffPlate'] ?? '',
        'whatWouldLikeHelpWith':
            _followOnQuestions['coachingBuddy']?['whatWouldLikeHelpWith'] ?? '',
        'howAdaptCommunication':
            _followOnQuestions['coachingBuddy']?['howAdaptCommunication'] ?? '',
        'specificRemindersPrompts':
            _followOnQuestions['coachingBuddy']?['specificRemindersPrompts'] ??
                '',
      };
    }

    if (shouldShowEmotionalQuestions) {
      followOnQuestions['emotional'] = {
        'whatHelpsGrounded':
            _followOnQuestions['emotional']?['whatHelpsGrounded'] ?? '',
        'howProcessChallenges':
            _followOnQuestions['emotional']?['howProcessChallenges'] ?? '',
        'whatHelpsBuildCalm':
            _followOnQuestions['emotional']?['whatHelpsBuildCalm'] ?? '',
        'whatWouldHelpSupported':
            _followOnQuestions['emotional']?['whatWouldHelpSupported'] ?? '',
      };
    }

    if (shouldShowCelebratingQuestions) {
      followOnQuestions['celebrating'] = {
        'recentWinToCelebrate':
            _followOnQuestions['celebrating']?['recentWinToCelebrate'] ?? '',
        'howAcknowledgeProgress':
            _followOnQuestions['celebrating']?['howAcknowledgeProgress'] ?? '',
        'wouldLikeCelebrationIdeas':
            _followOnQuestions['celebrating']?['wouldLikeCelebrationIdeas'] ??
                false,
        'howRecognizeProgress':
            _followOnQuestions['celebrating']?['howRecognizeProgress'] ?? '',
      };
    }

    if (shouldShowCustomizationQuestions) {
      followOnQuestions['customization'] = {
        'specificToolsToIntegrate':
            _followOnQuestions['customization']?['specificToolsToIntegrate'] ??
                '',
        'howCustomizeCommunication':
            _followOnQuestions['customization']?['howCustomizeCommunication'] ??
                '',
        'tailoredNeeds':
            _followOnQuestions['customization']?['tailoredNeeds'] ?? '',
      };
    }

    // Build onboarding data
    final onboarding = OnboardingData(
      locale: localizations.localeString,
      welcome: WelcomeSection(
        preferredName: _preferredName,
        inspiration: _inspiration,
        currentFeeling: _currentFeeling,
      ),
      aboutYou: AboutYouSection(
        selfDescription: _selfDescription.isEmpty ? null : _selfDescription.toList(),
        businessType: _businessType,
        proudMoment: _proudMoment,
        challenge: _challenges.isEmpty ? null : _challenges.toList(),
      ),
      preferences: PreferencesSection(
        learningStyle: _learningStyle,
        informationDepth: _informationDepth,
        celebrationStyle: _celebrationStyle,
      ),
      profile: ProfileSection(
        strengths: _strengths.isEmpty ? null : _strengths.toList(),
        supportAreas: _supportAreas.isEmpty ? null : _supportAreas.toList(),
        motivationStyle: _motivationStyle,
        neurodivergentUnderstanding: _neurodivergentUnderstanding,
        biggestGoal: _biggestGoal,
      ),
      coachingBuddy: CoachingBuddySection(
        tasks: _tasks.isEmpty ? null : _tasks.toList(),
        communicationStyle: _communicationStyle,
        toolsIntegration: _toolsIntegration,
        workingStyle: _workingStyle,
        additionalInfo: _additionalInfo,
      ),
      closing: ClosingSection(
        safeSpace: _safeSpace,
        tipsOptIn: _tipsOptIn,
      ),
      followOnQuestions:
          followOnQuestions.isEmpty ? null : followOnQuestions,
    );

    // Format date of birth as YYYY-MM-DD
    final dobString = _dateOfBirth != null
        ? '${_dateOfBirth!.year}-${_dateOfBirth!.month.toString().padLeft(2, '0')}-${_dateOfBirth!.day.toString().padLeft(2, '0')}'
        : '';

    return UserOnboardingData(
      email: email,
      fullName: _fullName,
      doB: dobString,
      preferredPronoun: _preferredPronoun,
      neurodiverseTraits:
          _selectedTraits.isEmpty ? null : _selectedTraits.toList(),
      onboarding: onboarding,
    );
  }
}

