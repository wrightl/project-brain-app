import 'package:intl/intl.dart';

/// Locale-aware date and time formatting for display.
///
/// API timestamps are usually UTC; each helper converts to the device's time
/// zone first, so times are not shown hours off. Patterns follow the device
/// locale (set as [Intl.defaultLocale] at startup), e.g. "5 Nov 2026, 14:30"
/// in the UK and "Nov 5, 2026, 2:30 PM" in the US.
class AppDateFormat {
  AppDateFormat._();

  /// "5 Nov 2026"
  static String date(DateTime value) =>
      DateFormat.yMMMd().format(value.toLocal());

  /// "14:30" / "2:30 PM"
  static String time(DateTime value) => DateFormat.jm().format(value.toLocal());

  /// "5 Nov 2026, 14:30"
  static String dateTime(DateTime value) =>
      DateFormat.yMMMd().add_jm().format(value.toLocal());

  /// "Thu, 5 Nov"
  static String shortWeekdayDate(DateTime value) =>
      DateFormat.MMMEd().format(value.toLocal());

  /// "Thursday 5 November"
  static String weekdayDate(DateTime value) =>
      DateFormat.MMMMEEEEd().format(value.toLocal());
}
