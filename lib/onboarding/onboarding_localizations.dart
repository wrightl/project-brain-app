import 'package:flutter/material.dart';

/// Localization helper for onboarding wizard
/// Supports en-US (default) and en-GB locales
class OnboardingLocalizations {
  final Locale locale;

  OnboardingLocalizations(this.locale);

  static OnboardingLocalizations of(BuildContext context) {
    final locale = Localizations.localeOf(context);
    return OnboardingLocalizations(locale);
  }

  /// Get the locale string (en-US or en-GB)
  String get localeString {
    if (locale.languageCode == 'en') {
      if (locale.countryCode == 'GB') {
        return 'en-GB';
      }
    }
    return 'en-US'; // Default
  }

  /// Check if using UK English
  bool get isUK => localeString == 'en-GB';

  // Common strings
  String get next => 'Next';
  String get previous => 'Previous';
  String get complete => 'Complete';
  String get skip => 'Skip';
  String get required => 'Required';
  String get optional => 'Optional';

  // Step titles
  String get stepBasicInfo => 'Basic Information';
  String get stepNeurodiverseTraits => 'Neurodiverse Traits';
  String get stepWelcome => 'Welcome';
  String get stepAboutYou => 'About You';
  String get stepPreferences => 'Your Preferences';
  String get stepProfile => 'Building Your Profile';
  String get stepCoachingBuddy => 'Training Your Personal Coaching Buddy';
  String get stepClosing => 'Closing';
  String get stepFollowOnQuestions => 'Follow-On Questions';

  // Basic Info
  String get fullName => 'Full Name';
  String get dateOfBirth => 'Date of Birth';
  String get preferredPronoun => 'Preferred Pronoun';
  String get selectDateOfBirth => 'Please select your date of birth';

  // Neurodiverse Traits
  String get selectTraits =>
      'Select any traits that apply to you. You can select multiple or skip this step.';

  // Welcome
  String get preferredName => 'Preferred Name';
  String get inspiration => 'Inspiration';
  String get currentFeeling => 'Current Feeling';
  String get inspirationHint => 'What inspires you?';
  String get currentFeelingHint => 'How are you feeling right now?';

  // About You
  String get selfDescription => 'Self Description';
  String get businessType => 'Business Type';
  String get proudMoment => 'Proud Moment';
  String get challenge => 'Challenge';
  String get businessTypeHint => 'Tell us about your business or work';
  String get proudMomentHint => 'Share a moment you\'re proud of';
  String get challengeHint => 'What challenges are you facing?';

  // Preferences
  String get learningStyle => 'Learning Style';
  String get informationDepth => 'Information Depth';
  String get celebrationStyle => 'Celebration Style';

  // Profile
  String get strengths => 'Strengths';
  String get supportAreas => 'Support Areas';
  String get motivationStyle => 'Motivation Style';
  String get neurodivergentUnderstanding => 'Neurodivergent Understanding';
  String get biggestGoal => 'Biggest Goal';
  String get neurodivergentUnderstandingHint =>
      'How would you like us to understand your neurodivergence?';
  String get biggestGoalHint => 'What\'s your biggest goal?';

  // Coaching Buddy
  String get tasks => 'Tasks';
  String get communicationStyle => 'Communication Style';
  String get toolsIntegration => 'Tools Integration';
  String get workingStyle => 'Working Style';
  String get additionalInfo => 'Additional Info';
  String get toolsIntegrationHint => 'What tools would you like to integrate?';
  String get workingStyleHint => 'How do you like to work?';
  String get additionalInfoHint => 'Any additional information?';

  // Closing
  String get safeSpace => 'Safe Space';
  String get tipsOptIn => 'Tips Opt-In';
  String get safeSpaceHint => 'What makes a safe space for you?';
  String get tipsOptInLabel => 'I\'d like to receive tips and suggestions';

  // Follow-On Questions
  String get strengthsQuestions => 'Strengths Questions';
  String get challengesQuestions => 'Challenges Questions';
  String get learningQuestions => 'Learning Questions';
  String get motivationQuestions => 'Motivation Questions';
  String get copingQuestions => 'Coping Questions';
  String get supportQuestions => 'Support Questions';
  String get coachingBuddyQuestions => 'Coaching Buddy Questions';
  String get emotionalQuestions => 'Emotional Questions';
  String get celebratingQuestions => 'Celebrating Questions';
  String get customizationQuestions => 'Customization Questions';

  // Follow-On Question prompts
  String get howDoYouUseStrengths => 'How do you currently use your strengths?';
  String get whatHelpsTapStrengths =>
      'What helps you tap into your strengths when you need them?';
  String get howBuildOnStrengths =>
      'How would you like to build on your strengths?';
  String get whatsHardestToManage => 'What\'s hardest to manage right now?';
  String get whatToolsHaveHelped => 'What tools or strategies have helped you?';
  String get wouldLikeToolSuggestions =>
      'Would you like suggestions for tools or strategies?';
  String get whatHelpsRecharge => 'What helps you recharge?';
  String get shareLearningExample =>
      'Can you share an example of how you learn best?';
  String get preferSpecificFormat =>
      'Would you prefer information in a specific format?';
  String get howBreakDownTasks => 'How do you like to break down tasks?';
  String get whatMotivatesYou => 'What motivates you most?';
  String get howSetGoals => 'How do you prefer to set goals?';
  String get whatRemindersWork => 'What kind of reminders work best for you?';
  String get howCelebrateProgress => 'How do you like to celebrate progress?';
  String get sensoryFriendlyEnvironment =>
      'What makes an environment feel sensory-friendly to you?';
  String get howManageTime => 'How do you manage your time?';
  String get whatHelpsOverwhelmed => 'What helps when you feel overwhelmed?';
  String get exploreCopingStrategies =>
      'Would you like to explore coping strategies?';
  String get whatWouldMakeDifference =>
      'What would make the biggest difference?';
  String get whatDoesSupportLookLike =>
      'What does your support system look like?';
  String get specificSkillsToDevelop =>
      'Are there specific skills you\'d like to develop?';
  String get howBalanceWorkSelfCare => 'How do you balance work and self-care?';
  String get whatTaskTakeOffPlate =>
      'What task would you most like to take off your plate?';
  String get whatWouldLikeHelpWith => 'What would you like help with?';
  String get howAdaptCommunication =>
      'How would you like your coaching buddy to adapt communication?';
  String get specificRemindersPrompts =>
      'Any specific reminders or prompts you\'d find helpful?';
  String get whatHelpsGrounded => 'What helps you feel grounded?';
  String get howProcessChallenges => 'How do you process challenges?';
  String get whatHelpsBuildCalm => 'What helps you build calm?';
  String get whatWouldHelpSupported => 'What would help you feel supported?';
  String get recentWinToCelebrate =>
      'What\'s a recent win you\'d like to celebrate?';
  String get howAcknowledgeProgress => 'How do you acknowledge progress?';
  String get wouldLikeCelebrationIdeas =>
      'Would you like ideas for celebrating wins?';
  String get howRecognizeProgress =>
      'How can we help you recognize your progress?';
  String get specificToolsToIntegrate =>
      'What specific tools would you like to integrate?';
  String get howCustomizeCommunication =>
      'How would you like to customize communication?';
  String get tailoredNeeds => 'What tailored needs should we know about?';

  // Dropdown options
  List<String> get pronounOptions => [
        'he/him',
        'she/her',
        'they/them',
        'he/they',
        'she/they',
        'Other',
      ];

  List<String> get currentFeelingOptions => [
        'excited',
        'overwhelmed',
        'curious',
        'stuck',
        'motivated',
        'uncertain',
        'other',
      ];

  List<String> get selfDescriptionOptions => [
        'creative',
        'problem-solver',
        'big-picture-thinker',
        'detail-oriented',
        'innovative',
        'analytical',
        'strategic',
      ];

  List<String> get challengeOptions {
    if (isUK) {
      return [
        'organisation',
        'energy-management',
        'finding-support',
        'time-management',
        'focus',
        'marketing',
        'networking',
        'self-care',
        'other',
      ];
    }
    return [
      'organization',
      'energy-management',
      'finding-support',
      'time-management',
      'focus',
      'marketing',
      'networking',
      'self-care',
      'other',
    ];
  }

  List<String> get learningStyleOptions => [
        'step-by-step',
        'visuals',
        'videos',
        'hands-on',
        'written',
        'audio',
        'combination',
      ];

  List<String> get informationDepthOptions => [
        'short',
        'detailed',
        'flexible',
      ];

  List<String> get celebrationStyleOptions => [
        'break',
        'sharing',
        'treat',
        'quiet',
        'other',
      ];

  List<String> get strengthsOptions => [
        'creativity',
        'resilience',
        'problem-solving',
        'connecting-people',
        'innovation',
        'adaptability',
        'persistence',
      ];

  List<String> get supportAreasOptions {
    if (isUK) {
      return [
        'time-management',
        'marketing',
        'networking',
        'self-care',
        'organisation',
        'planning',
        'communication',
      ];
    }
    return [
      'time-management',
      'marketing',
      'networking',
      'self-care',
      'organization',
      'planning',
      'communication',
    ];
  }

  List<String> get motivationStyleOptions => [
        'small-goals',
        'reminders',
        'accountability',
        'rewards',
        'visual-progress',
      ];

  List<String> get tasksOptions {
    if (isUK) {
      return [
        'writing-emails',
        'brainstorming',
        'organising-tasks',
        'planning',
        'problem-solving',
        'decision-making',
        'other',
      ];
    }
    return [
      'writing-emails',
      'brainstorming',
      'organizing-tasks',
      'planning',
      'problem-solving',
      'decision-making',
      'other',
    ];
  }

  List<String> get communicationStyleOptions => [
        'direct',
        'supportive',
        'encouraging',
        'analytical',
        'creative',
        'flexible',
      ];

  // Format labels for display (convert kebab-case to Title Case)
  String formatLabel(String value) {
    return value
        .split('-')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }
}
