import 'package:projectbrain/models/coach.dart';

/// Merges message lists, deduplicating by id and sorting oldest-first.
List<CoachMessage> mergeCoachMessages(
  List<CoachMessage> existing,
  List<CoachMessage> incoming,
) {
  final byId = {for (final message in existing) message.id: message};
  for (final message in incoming) {
    byId[message.id] = message;
  }
  final merged = byId.values.toList()
    ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  return merged;
}
