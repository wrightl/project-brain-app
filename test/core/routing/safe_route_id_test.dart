import 'package:flutter_test/flutter_test.dart';
import 'package:projectbrain/core/routing/app_router.dart';

void main() {
  group('isSafeRouteId', () {
    test('accepts ids the API hands out', () {
      expect(isSafeRouteId('3f2b8c1e-9a4d-4e7f-8b6a-1c2d3e4f5a6b'), isTrue);
      expect(isSafeRouteId('auth0|abc123'), isTrue);
      expect(isSafeRouteId('general-chat'), isTrue);
      expect(isSafeRouteId('42'), isTrue);
    });

    test('rejects values that could change the API path', () {
      expect(isSafeRouteId(''), isFalse);
      expect(isSafeRouteId('..'), isFalse);
      expect(isSafeRouteId('../admin'), isFalse);
      expect(isSafeRouteId('a/b'), isFalse);
      expect(isSafeRouteId('a%2Fb'), isFalse);
      expect(isSafeRouteId('a?x=1'), isFalse);
      expect(isSafeRouteId('a#b'), isFalse);
    });
  });
}
