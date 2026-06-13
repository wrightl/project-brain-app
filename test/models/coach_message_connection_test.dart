import 'package:flutter_test/flutter_test.dart';
import 'package:projectbrain/models/coach.dart';
import 'package:projectbrain/models/connection.dart';
import 'package:projectbrain/services/coach_service.dart';

void main() {
  group('Connection.fromJson', () {
    test('parses connection fields from camelCase json', () {
      final connection = Connection.fromJson({
        'id': '11111111-1111-1111-1111-111111111111',
        'userId': 'user-1',
        'coachId': 'coach-1',
        'status': 'accepted',
        'coachName': 'Jane Coach',
        'coachProfileId': '42',
        'requestedAt': '2026-01-01T00:00:00.000Z',
      });

      expect(connection.id, '11111111-1111-1111-1111-111111111111');
      expect(connection.coachId, 'coach-1');
      expect(connection.coachName, 'Jane Coach');
      expect(connection.isAccepted, isTrue);
    });
  });

  group('isConnectionGuid', () {
    test('returns true for valid guids', () {
      expect(
        isConnectionGuid('11111111-1111-1111-1111-111111111111'),
        isTrue,
      );
    });

    test('returns false for auth0 user ids', () {
      expect(isConnectionGuid('auth0|abc123'), isFalse);
    });
  });

  group('Connection status helpers', () {
    test('isAccepted and isPending reflect status', () {
      final accepted = Connection.fromJson({
        'id': '1',
        'userId': 'u',
        'coachId': 'c',
        'status': 'accepted',
      });
      final pending = Connection.fromJson({
        'id': '2',
        'userId': 'u',
        'coachId': 'c',
        'status': 'pending',
      });

      expect(accepted.isAccepted, isTrue);
      expect(accepted.isPending, isFalse);
      expect(pending.isPending, isTrue);
      expect(pending.isAccepted, isFalse);
    });
  });

  group('CoachMessage.fromJson', () {
    test('maps isFromCurrentUser to isFromCoach', () {
      final fromUser = CoachMessage.fromJson({
        'id': '1',
        'connectionId': '11111111-1111-1111-1111-111111111111',
        'isFromCurrentUser': true,
        'messageType': 'text',
        'content': 'Hello',
        'createdAt': '2026-01-01T00:00:00.000Z',
      });

      final fromCoach = CoachMessage.fromJson({
        'id': '2',
        'connectionId': '11111111-1111-1111-1111-111111111111',
        'isFromCurrentUser': false,
        'messageType': 'text',
        'content': 'Hi there',
        'createdAt': '2026-01-01T00:00:00.000Z',
      });

      expect(fromUser.isFromCoach, isFalse);
      expect(fromCoach.isFromCoach, isTrue);
      expect(fromUser.text, 'Hello');
      expect(fromUser.connectionId, '11111111-1111-1111-1111-111111111111');
    });
  });

  group('CoachService.buildConversationMessagesPath', () {
    test('uses coach-messages conversation endpoint', () {
      final path = CoachService.buildConversationMessagesPath(
        '11111111-1111-1111-1111-111111111111',
      );

      expect(
        path,
        '/coach-messages/conversation/11111111-1111-1111-1111-111111111111?pageSize=20',
      );
    });
  });
}
