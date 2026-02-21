/// Main onboarding data structure
class UserOnboardingData {
  final String email;
  final String fullName;
  final String doB; // DateOnly format: "YYYY-MM-DD"
  final String preferredPronoun;
  final List<String>? neurodiverseTraits;
  final String? preferences; // JSON string containing user preferences
  final OnboardingData? onboarding; // Structured onboarding data

  UserOnboardingData({
    required this.email,
    required this.fullName,
    required this.doB,
    required this.preferredPronoun,
    this.neurodiverseTraits,
    this.preferences,
    this.onboarding,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'email': email,
      'fullName': fullName,
      'doB': doB,
      'preferredPronoun': preferredPronoun,
    };

    if (neurodiverseTraits != null && neurodiverseTraits!.isNotEmpty) {
      map['neurodiverseTraits'] = neurodiverseTraits;
    }

    if (preferences != null && preferences!.isNotEmpty) {
      map['preferences'] = preferences;
    }

    if (onboarding != null) {
      map['onboarding'] = onboarding!.toJson();
    }

    return map;
  }
}

/// Structured onboarding data
class OnboardingData {
  final String? locale; // "en-US" or "en-GB"
  final WelcomeSection? welcome;
  final AboutYouSection? aboutYou;
  final PreferencesSection? preferences;
  final ProfileSection? profile;
  final CoachingBuddySection? coachingBuddy;
  final ClosingSection? closing;
  final Map<String, dynamic>?
      followOnQuestions; // Dynamic structure based on categories shown

  OnboardingData({
    this.locale,
    this.welcome,
    this.aboutYou,
    this.preferences,
    this.profile,
    this.coachingBuddy,
    this.closing,
    this.followOnQuestions,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};

    if (locale != null) {
      map['locale'] = locale;
    }

    if (welcome != null) {
      map['welcome'] = welcome!.toJson();
    }

    if (aboutYou != null) {
      map['aboutYou'] = aboutYou!.toJson();
    }

    if (preferences != null) {
      map['preferences'] = preferences!.toJson();
    }

    if (profile != null) {
      map['profile'] = profile!.toJson();
    }

    if (coachingBuddy != null) {
      map['coachingBuddy'] = coachingBuddy!.toJson();
    }

    if (closing != null) {
      map['closing'] = closing!.toJson();
    }

    if (followOnQuestions != null && followOnQuestions!.isNotEmpty) {
      map['followOnQuestions'] = followOnQuestions;
    }

    return map;
  }
}

/// Welcome section data
class WelcomeSection {
  final String? preferredName;
  final String? inspiration;
  final String? currentFeeling;

  WelcomeSection({
    this.preferredName,
    this.inspiration,
    this.currentFeeling,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};

    if (preferredName != null && preferredName!.isNotEmpty) {
      map['preferredName'] = preferredName;
    }

    if (inspiration != null && inspiration!.isNotEmpty) {
      map['inspiration'] = inspiration;
    }

    if (currentFeeling != null && currentFeeling!.isNotEmpty) {
      map['currentFeeling'] = currentFeeling;
    }

    return map;
  }
}

/// About You section data
class AboutYouSection {
  final List<String>? selfDescription;
  final String? businessType;
  final String? proudMoment;
  final List<String>? challenge;

  AboutYouSection({
    this.selfDescription,
    this.businessType,
    this.proudMoment,
    this.challenge,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};

    if (selfDescription != null && selfDescription!.isNotEmpty) {
      map['selfDescription'] = selfDescription;
    }

    if (businessType != null && businessType!.isNotEmpty) {
      map['businessType'] = businessType;
    }

    if (proudMoment != null && proudMoment!.isNotEmpty) {
      map['proudMoment'] = proudMoment;
    }

    if (challenge != null && challenge!.isNotEmpty) {
      map['challenge'] = challenge;
    }

    return map;
  }
}

/// Preferences section data
class PreferencesSection {
  final String? learningStyle;
  final String? informationDepth;
  final String? celebrationStyle;

  PreferencesSection({
    this.learningStyle,
    this.informationDepth,
    this.celebrationStyle,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};

    if (learningStyle != null && learningStyle!.isNotEmpty) {
      map['learningStyle'] = learningStyle;
    }

    if (informationDepth != null && informationDepth!.isNotEmpty) {
      map['informationDepth'] = informationDepth;
    }

    if (celebrationStyle != null && celebrationStyle!.isNotEmpty) {
      map['celebrationStyle'] = celebrationStyle;
    }

    return map;
  }
}

/// Profile section data
class ProfileSection {
  final List<String>? strengths;
  final List<String>? supportAreas;
  final String? motivationStyle;
  final String? neurodivergentUnderstanding;
  final String? biggestGoal;

  ProfileSection({
    this.strengths,
    this.supportAreas,
    this.motivationStyle,
    this.neurodivergentUnderstanding,
    this.biggestGoal,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};

    if (strengths != null && strengths!.isNotEmpty) {
      map['strengths'] = strengths;
    }

    if (supportAreas != null && supportAreas!.isNotEmpty) {
      map['supportAreas'] = supportAreas;
    }

    if (motivationStyle != null && motivationStyle!.isNotEmpty) {
      map['motivationStyle'] = motivationStyle;
    }

    if (neurodivergentUnderstanding != null &&
        neurodivergentUnderstanding!.isNotEmpty) {
      map['neurodivergentUnderstanding'] = neurodivergentUnderstanding;
    }

    if (biggestGoal != null && biggestGoal!.isNotEmpty) {
      map['biggestGoal'] = biggestGoal;
    }

    return map;
  }
}

/// Coaching Buddy section data
class CoachingBuddySection {
  final List<String>? tasks;
  final String? communicationStyle;
  final String? toolsIntegration;
  final String? workingStyle;
  final String? additionalInfo;

  CoachingBuddySection({
    this.tasks,
    this.communicationStyle,
    this.toolsIntegration,
    this.workingStyle,
    this.additionalInfo,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};

    if (tasks != null && tasks!.isNotEmpty) {
      map['tasks'] = tasks;
    }

    if (communicationStyle != null && communicationStyle!.isNotEmpty) {
      map['communicationStyle'] = communicationStyle;
    }

    if (toolsIntegration != null && toolsIntegration!.isNotEmpty) {
      map['toolsIntegration'] = toolsIntegration;
    }

    if (workingStyle != null && workingStyle!.isNotEmpty) {
      map['workingStyle'] = workingStyle;
    }

    if (additionalInfo != null && additionalInfo!.isNotEmpty) {
      map['additionalInfo'] = additionalInfo;
    }

    return map;
  }
}

/// Closing section data
class ClosingSection {
  final String? safeSpace;
  final bool? tipsOptIn;

  ClosingSection({
    this.safeSpace,
    this.tipsOptIn,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};

    if (safeSpace != null && safeSpace!.isNotEmpty) {
      map['safeSpace'] = safeSpace;
    }

    if (tipsOptIn != null) {
      map['tipsOptIn'] = tipsOptIn;
    }

    return map;
  }
}
