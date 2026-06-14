import 'package:flutter/material.dart';

/// Localization helper for coping strategies feature.
class StrategiesLocalizations {
  final Locale locale;

  StrategiesLocalizations(this.locale);

  static StrategiesLocalizations of(BuildContext context) {
    final locale = Localizations.localeOf(context);
    return StrategiesLocalizations(locale);
  }

  // Section and screen titles
  String get copingStrategies => 'Coping strategies';
  String get strategiesLibrary => 'My strategies';
  String get getNewStrategies => 'Get new strategies';
  String get viewLibrary => 'View library';
  String get backToLibrary => 'Back to library';

  // Actions
  String get save => 'Save';
  String get saveCount => 'Save (%d)';
  String get delete => 'Delete';
  String get learnMore => 'Learn more';
  String get newConversation => 'New conversation';
  String get retry => 'Retry';

  // Dashboard
  String get youHaveNSavedStrategies => 'You have %d saved strategies';

  // Chat
  String get greeting =>
      'Hi there %s! I\'m here to help you find coping strategies that work for you. Just tell me what you\'re dealing with, and I\'ll suggest some techniques you might find helpful.';
  String get examplePrompt1 =>
      'I\'m feeling overwhelmed after work — what can I do right now?';
  String get examplePrompt2 => 'I\'m anxious about an upcoming meeting.';
  String get examplePrompt3 => 'I\'m having trouble sleeping.';

  // Library
  String get emptyLibraryTitle => 'No saved strategies yet';
  String get emptyLibraryMessage =>
      'Get AI-suggested coping strategies and save the ones that work for you.';
  String get deleteStrategyConfirm =>
      'Are you sure you want to delete this strategy?';

  // Messages
  String get strategiesSaved => 'Strategies saved';
  String get strategyDeleted => 'Strategy deleted';
  String get couldNotSaveStrategies =>
      'Could not save strategies. Please try again.';
  String get couldNotDeleteStrategy => 'Could not delete strategy.';
  String get couldNotUpdateRating => 'Could not update rating.';
  String get failedToLoadLibrary => 'Failed to load strategies.';
  String get failedToGetResponse => 'Failed to get response. Please try again.';

  String formatGreeting(String name) {
    return greeting.replaceAll('%s', name);
  }

  String formatSaveCount(int n) {
    return saveCount.replaceAll('%d', '$n');
  }

  String formatYouHaveNSavedStrategies(int n) {
    return youHaveNSavedStrategies.replaceAll('%d', '$n');
  }
}
