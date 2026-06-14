import 'package:flutter/material.dart';

/// Localization helper for journal feature.
class JournalLocalizations {
  final Locale locale;

  JournalLocalizations(this.locale);

  static JournalLocalizations of(BuildContext context) {
    final locale = Localizations.localeOf(context);
    return JournalLocalizations(locale);
  }

  // Screen titles
  String get journal => 'Journal';
  String get newEntry => 'New entry';
  String get editEntry => 'Edit entry';
  String get viewEntry => 'Entry';

  // Actions
  String get save => 'Save';
  String get edit => 'Edit';
  String get delete => 'Delete';
  String get seeAll => 'See all';
  String get addTag => 'Add tag';

  // Labels
  String get content => 'Content';
  String get suggestedTags => 'Suggested tags';
  String get customTags => 'Custom tags';
  String get journalStreak => 'Journal streak';
  String get bestStreak => 'Best streak';
  String get noStreakYet => 'No streak yet';
  String get youHaveNEntries => 'You have %d journal entries';
  String get recentEntries => 'Recent entries';

  // Validation
  String get contentRequired => 'Content is required';
  String get pleaseEnterContent => 'Please enter your journal content.';

  // Messages
  String get entrySaved => 'Entry saved';
  String get entryDeleted => 'Entry deleted';
  String get couldNotSaveEntry => 'Could not save entry. Please try again.';
  String get couldNotLoadEntries => 'Failed to load entries.';
  String get couldNotLoadEntry => 'Failed to load entry.';
  String get couldNotDeleteEntry => 'Could not delete entry.';
  String get entryNotFound => 'Entry not found.';
  String get deleteEntryConfirm =>
      'Are you sure you want to delete this entry?';

  String formatYouHaveNEntries(int n) {
    return youHaveNEntries.replaceAll('%d', '$n');
  }

  String get streakDaysFormat => '%d days';
  String get bestFormat => 'best: %d';

  String formatStreakDays(int days) {
    return streakDaysFormat.replaceAll('%d', '$days');
  }

  String formatBest(int days) {
    return bestFormat.replaceAll('%d', '$days');
  }
}
