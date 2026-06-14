/// Defensive JSON field parsing helpers.
///
/// Backend payloads are not guaranteed to match the expected shape (nulls,
/// numbers-as-strings, malformed dates). Hard casts like `json['x'] as String`
/// throw and surface as opaque crashes; these helpers degrade gracefully.
class JsonParse {
  JsonParse._();

  /// Read a String, coercing non-strings via `toString()` and falling back when
  /// the value is null.
  static String asString(dynamic value, {String fallback = ''}) {
    if (value == null) return fallback;
    if (value is String) return value;
    return value.toString();
  }

  /// Read a nullable String (null stays null; non-strings are stringified).
  static String? asStringOrNull(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    return value.toString();
  }

  /// Parse an ISO-8601 date, returning [fallback] (defaults to epoch) when the
  /// value is missing or unparseable instead of throwing.
  static DateTime asDateTime(dynamic value, {DateTime? fallback}) {
    final fb = fallback ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    if (value == null) return fb;
    if (value is DateTime) return value;
    final parsed = DateTime.tryParse(value.toString());
    return parsed ?? fb;
  }

  /// Parse a nullable ISO-8601 date; returns null on missing/invalid input.
  static DateTime? asDateTimeOrNull(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}
