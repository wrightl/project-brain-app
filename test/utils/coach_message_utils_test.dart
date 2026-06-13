import 'package:flutter_test/flutter_test.dart';
import 'package:projectbrain/models/coach.dart';
import 'package:projectbrain/services/coach_message_signalr_service.dart';
import 'package:projectbrain/utils/coach_message_utils.dart';

CoachMessage _message({
  required String id,
  required DateTime createdAt,
  String? text,
  bool isFromCoach = false,
}) {
  return CoachMessage(
    id: id,
    coachId: 'coach-1',
    text: text,
    messageType: 'text',
    isFromCoach: isFromCoach,
    createdAt: createdAt,
  );
}

void main() {
  group('mergeCoachMessages', () {
    test('sorts newest-first API payload to ascending order', () {
      final newest = _message(
        id: '2',
        createdAt: DateTime(2026, 1, 2, 12),
        text: 'Newest',
      );
      final oldest = _message(
        id: '1',
        createdAt: DateTime(2026, 1, 1, 12),
        text: 'Oldest',
      );

      final merged = mergeCoachMessages([], [newest, oldest]);

      expect(merged.map((m) => m.id).toList(), ['1', '2']);
      expect(merged.first.text, 'Oldest');
      expect(merged.last.text, 'Newest');
    });

    test('updates duplicate ids in place', () {
      final original = _message(
        id: '1',
        createdAt: DateTime(2026, 1, 1, 12),
        text: 'Original',
      );
      final updated = _message(
        id: '1',
        createdAt: DateTime(2026, 1, 1, 12),
        text: 'Updated',
      );

      final merged = mergeCoachMessages([original], [updated]);

      expect(merged.length, 1);
      expect(merged.single.text, 'Updated');
    });

    test('merges existing and incoming chronologically', () {
      final existing = [
        _message(
          id: '1',
          createdAt: DateTime(2026, 1, 1, 12),
          text: 'First',
        ),
      ];
      final incoming = [
        _message(
          id: '3',
          createdAt: DateTime(2026, 1, 3, 12),
          text: 'Third',
        ),
        _message(
          id: '2',
          createdAt: DateTime(2026, 1, 2, 12),
          text: 'Second',
        ),
      ];

      final merged = mergeCoachMessages(existing, incoming);

      expect(merged.map((m) => m.id).toList(), ['1', '2', '3']);
    });
  });

  group('parseCoachMessageFromSignalR', () {
    test('parses map payload from hub invocation', () {
      final message = parseCoachMessageFromSignalR([
        {
          'id': '1',
          'connectionId': '11111111-1111-1111-1111-111111111111',
          'isFromCurrentUser': false,
          'messageType': 'text',
          'content': 'Coach reply',
          'createdAt': '2026-01-01T00:00:00.000Z',
        },
      ]);

      expect(message, isNotNull);
      expect(message!.text, 'Coach reply');
      expect(message.isFromCoach, isTrue);
    });
  });
}
