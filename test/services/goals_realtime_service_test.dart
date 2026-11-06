import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mocktail/mocktail.dart';
import 'package:projectbrain/services/auth/auth_service.dart';
import 'package:projectbrain/services/goals_realtime_service.dart';

import '../helpers/test_helpers.dart';

class MockAuthService extends Mock implements AuthService {}

void main() {
  late MockAuthService authService;
  late int requests;
  late StreamController<List<int>> body;

  setUpAll(() async {
    await initializeTestEnvironment();
  });

  setUp(() {
    authService = MockAuthService();
    requests = 0;
    body = StreamController<List<int>>();
  });

  // Not awaited: close() on a controller nobody listened to never completes.
  tearDown(() => unawaited(body.close()));

  GoalsRealtimeService service() => GoalsRealtimeService(
        authService: authService,
        createClient: () => MockClient.streaming((request, _) async {
          requests++;
          return http.StreamedResponse(body.stream, 200);
        }),
      );

  test('stop while waiting for a token leaves no connection open', () async {
    final token = Completer<String>();
    when(() => authService.getAccessToken()).thenAnswer((_) => token.future);
    final realtime = service();

    final starting = realtime.start(() {});
    await realtime.stop();
    token.complete('t');
    await starting;

    expect(requests, 0);
    expect(realtime.isRunning, isFalse);
  });

  test('handles a character split across chunks', () async {
    when(() => authService.getAccessToken()).thenAnswer((_) async => 't');
    var updates = 0;
    final realtime = service();

    await realtime.start(() => updates++);
    final bytes = utf8.encode('event: goals-updated\ndata: "café"\n\n');
    final split = bytes.indexOf(0xC3) + 1; // inside the two-byte 'é'
    body
      ..add(bytes.sublist(0, split))
      ..add(bytes.sublist(split));
    await pumpEventQueue();

    expect(updates, 1);
    expect(realtime.isRunning, isTrue);
    await realtime.stop();
  });
}
