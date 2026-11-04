import 'dart:convert';

import 'package:auth0_flutter/auth0_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:projectbrain/core/config/app_config.dart';
import 'package:projectbrain/services/auth/oauth_service.dart';

import '../../helpers/test_helpers.dart';

void main() {
  setUpAll(() async {
    await initializeTestEnvironment();
  });

  OAuthService serviceWith(http.Client client) => OAuthService(
        auth0: Auth0(AppConfig.authDomain, AppConfig.authClientId),
        httpClient: client,
      );

  group('OAuthService.revokeRefreshToken', () {
    test('posts the refresh token to the Auth0 revoke endpoint', () async {
      late http.Request sent;
      final client = MockClient((request) async {
        sent = request;
        return http.Response('', 200);
      });

      await serviceWith(client).revokeRefreshToken('rt-123');

      expect(sent.method, 'POST');
      expect(sent.url, Uri.https(AppConfig.authDomain, '/oauth/revoke'));
      expect(jsonDecode(sent.body), {
        'client_id': AppConfig.authClientId,
        'token': 'rt-123',
      });
    });

    test('does not throw when the request fails', () async {
      final client = MockClient((_) async => throw http.ClientException('x'));

      await serviceWith(client).revokeRefreshToken('rt-123');
    });

    test('does not throw on a non-200 response', () async {
      final client = MockClient((_) async => http.Response('nope', 400));

      await serviceWith(client).revokeRefreshToken('rt-123');
    });
  });
}
