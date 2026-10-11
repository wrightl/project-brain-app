import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mocktail/mocktail.dart';
import 'package:projectbrain/core/network/rate_limited_exception.dart';
import 'package:projectbrain/services/auth/auth_service.dart';
import 'package:projectbrain/services/http_service.dart';
import '../helpers/test_helpers.dart';

class MockAuthService extends Mock implements AuthService {}

void main() {
  late HttpService httpService;

  setUpAll(() async {
    await initializeTestEnvironment();
  });

  tearDownAll(() {
    resetTestEnvironment();
  });

  setUp(() {
    final authService = MockAuthService();
    when(() => authService.getAccessToken())
        .thenAnswer((_) async => 'test_token');
    httpService = HttpService(authService: authService);
  });

  /// Runs [body] with every top-level `http` call answered by [handler],
  /// returning how many requests reached the "server".
  Future<int> withServer(
    FutureOr<http.Response> Function(http.Request request) handler,
    Future<void> Function() body,
  ) async {
    var calls = 0;
    final client = MockClient((request) async {
      calls++;
      return handler(request);
    });
    await http.runWithClient(body, () => client);
    return calls;
  }

  group('HttpService retries', () {
    test('POST is not retried after a 500', () async {
      late http.Response response;
      final calls = await withServer(
        (_) => http.Response('boom', 500),
        () async => response = await httpService.post('/journal', body: '{}'),
      );

      expect(calls, 1);
      expect(response.statusCode, 500);
    });

    test('POST is not retried after a dropped connection', () async {
      final calls = await withServer(
        (_) => throw http.ClientException('connection reset'),
        () async {
          await expectLater(
            httpService.post('/journal', body: '{}'),
            throwsA(isA<http.ClientException>()),
          );
        },
      );

      expect(calls, 1);
    });

    test('POST is retried after a 503 startup gate', () async {
      var attempt = 0;
      late http.Response response;
      final calls = await withServer(
        (_) => ++attempt == 1
            ? http.Response('', 503, headers: {'retry-after': '0'})
            : http.Response('{}', 200),
        () async => response = await httpService.post('/journal', body: '{}'),
      );

      expect(calls, 2);
      expect(response.statusCode, 200);
    });

    test('GET is retried after a 500', () async {
      var attempt = 0;
      late http.Response response;
      final calls = await withServer(
        (_) => ++attempt == 1
            ? http.Response('boom', 500, headers: {'retry-after': '0'})
            : http.Response('{}', 200),
        () async => response = await httpService.get('/goals', useCache: false),
      );

      expect(calls, 2);
      expect(response.statusCode, 200);
    });
  });

  group('HttpService rate limiting', () {
    test('429 with a short Retry-After is retried, even for POST', () async {
      var attempt = 0;
      late http.Response response;
      final calls = await withServer(
        (_) => ++attempt == 1
            ? http.Response('', 429, headers: {'retry-after': '0'})
            : http.Response('{}', 200),
        () async => response = await httpService.post('/journal', body: '{}'),
      );

      expect(calls, 2);
      expect(response.statusCode, 200);
    });

    test('429 without Retry-After throws with the default message', () async {
      final calls = await withServer(
        (_) => http.Response('', 429),
        () async {
          await expectLater(
            httpService.get('/goals', useCache: false),
            throwsA(isA<RateLimitedException>().having(
              (e) => e.message,
              'message',
              RateLimitedException.defaultMessage,
            )),
          );
        },
      );

      expect(calls, 1);
    });

    test('429 with a long Retry-After throws instead of waiting', () async {
      final calls = await withServer(
        (_) => http.Response('', 429, headers: {'retry-after': '60'}),
        () async {
          await expectLater(
            httpService.post('/journal', body: '{}'),
            throwsA(isA<RateLimitedException>().having(
              (e) => e.retryAfter,
              'retryAfter',
              const Duration(seconds: 60),
            )),
          );
        },
      );

      expect(calls, 1);
    });

    test('streaming 429 surfaces the quota message from the body', () async {
      const quota =
          'You have reached your daily limit of 50 AI queries. Please upgrade or try again tomorrow.';
      await withServer(
        (_) => http.Response('{"error":"$quota"}', 429),
        () async {
          await expectLater(
            httpService.send('/chat/stream', '{}'),
            throwsA(isA<RateLimitedException>()
                .having((e) => e.message, 'message', quota)),
          );
        },
      );
    });

    test('streaming 200 is returned unchanged', () async {
      late http.StreamedResponse response;
      await withServer(
        (_) => http.Response('data: hi\n\n', 200),
        () async => response = await httpService.send('/chat/stream', '{}'),
      );

      expect(response.statusCode, 200);
      expect(await response.stream.bytesToString(), 'data: hi\n\n');
    });
  });
}
