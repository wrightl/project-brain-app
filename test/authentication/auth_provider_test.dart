import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:projectbrain/authentication/auth_provider.dart';
import 'package:projectbrain/services/auth/auth_service.dart';
import 'package:projectbrain/models/auth0_user.dart';
import 'package:projectbrain/services/auth/auth_exception.dart';
import '../helpers/test_helpers.dart';

// Mock classes
class MockAuthService extends Mock implements AuthService {}

class MockAuth0User extends Mock implements Auth0User {}

void main() {
  late AuthProvider authProvider;
  late MockAuthService mockAuthService;

  setUpAll(() async {
    // Initialize test environment once for all tests
    await initializeTestEnvironment();
  });

  setUp(() {
    mockAuthService = MockAuthService();
    authProvider = AuthProvider(authService: mockAuthService);
  });

  tearDownAll(() {
    resetTestEnvironment();
  });

  group('AuthProvider - Initialization', () {
    test('starts with unauthenticated state', () {
      expect(authProvider.isLoggedIn, isFalse);
      expect(authProvider.profile, isNull);
      expect(authProvider.hasError, isFalse);
    });

    test('initializes auth state from service', () async {
      final mockUser = MockAuth0User();
      when(() => mockAuthService.init()).thenAnswer((_) async => true);
      when(() => mockAuthService.isLoggedIn).thenReturn(true);
      when(() => mockAuthService.profile).thenReturn(mockUser);

      await authProvider.init();

      expect(authProvider.isLoggedIn, isTrue);
      expect(authProvider.profile, equals(mockUser));
    });

    test('handles initialization with no user', () async {
      when(() => mockAuthService.init()).thenAnswer((_) async => false);
      when(() => mockAuthService.isLoggedIn).thenReturn(false);
      when(() => mockAuthService.profile).thenReturn(null);

      await authProvider.init();

      expect(authProvider.isLoggedIn, isFalse);
      expect(authProvider.profile, isNull);
    });

    test('handles initialization errors', () async {
      when(() => mockAuthService.init())
          .thenThrow(AuthException('Init failed'));

      await authProvider.init();

      expect(authProvider.hasError, isTrue);
      expect(authProvider.errorMessage, contains('initialize'));
    });
  });

  group('AuthProvider - Login', () {
    test('successful login updates state', () async {
      final mockUser = MockAuth0User();
      when(() => mockAuthService.login()).thenAnswer((_) async {});
      when(() => mockAuthService.isLoggedIn).thenReturn(true);
      when(() => mockAuthService.profile).thenReturn(mockUser);

      await authProvider.login();

      expect(authProvider.isLoggedIn, isTrue);
      expect(authProvider.profile, equals(mockUser));
      verify(() => mockAuthService.login()).called(1);
    });

    test('failed login sets error state', () async {
      when(() => mockAuthService.login())
          .thenThrow(AuthException('Login failed'));

      await authProvider.login();

      expect(authProvider.isLoggedIn, isFalse);
      expect(authProvider.hasError, isTrue);
      expect(authProvider.errorMessage, contains('Login failed'));
    });

    test('login clears previous errors', () async {
      final mockUser = MockAuth0User();
      // First, set an error state
      when(() => mockAuthService.login())
          .thenThrow(AuthException('First error'));
      await authProvider.login();
      expect(authProvider.hasError, isTrue);

      // Then, successful login should clear error
      when(() => mockAuthService.login()).thenAnswer((_) async {});
      when(() => mockAuthService.isLoggedIn).thenReturn(true);
      when(() => mockAuthService.profile).thenReturn(mockUser);

      await authProvider.login();

      expect(authProvider.hasError, isFalse);
      expect(authProvider.errorMessage, isNull);
    });
  });

  group('AuthProvider - Logout', () {
    test('successful logout clears state', () async {
      // First login
      final mockUser = MockAuth0User();
      when(() => mockAuthService.login()).thenAnswer((_) async {});
      when(() => mockAuthService.isLoggedIn).thenReturn(true);
      when(() => mockAuthService.profile).thenReturn(mockUser);
      await authProvider.login();

      // Then logout
      when(() => mockAuthService.logout()).thenAnswer((_) async {});
      when(() => mockAuthService.isLoggedIn).thenReturn(false);
      when(() => mockAuthService.profile).thenReturn(null);

      await authProvider.logout();

      expect(authProvider.isLoggedIn, isFalse);
      expect(authProvider.profile, isNull);
      expect(authProvider.hasError, isFalse);
      verify(() => mockAuthService.logout()).called(1);
    });

    test('failed logout sets error state', () async {
      when(() => mockAuthService.logout())
          .thenThrow(AuthException('Logout failed'));

      await authProvider.logout();

      expect(authProvider.hasError, isTrue);
      expect(authProvider.errorMessage, contains('logout'));
    });
  });

  group('AuthProvider - Error Handling', () {
    test('clearError removes error state', () async {
      when(() => mockAuthService.login())
          .thenThrow(AuthException('Test error'));
      await authProvider.login();

      expect(authProvider.hasError, isTrue);

      authProvider.clearError();

      expect(authProvider.hasError, isFalse);
      expect(authProvider.errorMessage, isNull);
    });

    test('error messages are cleaned up', () async {
      when(() => mockAuthService.login())
          .thenThrow(AuthException('AuthException: Test error'));
      await authProvider.login();

      // Should remove "AuthException: " prefix
      expect(authProvider.errorMessage, equals('Test error'));
    });

    test('handles non-AuthException errors', () async {
      when(() => mockAuthService.login()).thenThrow(Exception('Generic error'));
      await authProvider.login();

      expect(authProvider.hasError, isTrue);
      expect(authProvider.errorMessage, isNotNull);
    });
  });

  group('AuthProvider - State Management', () {
    test('notifies listeners on state changes', () async {
      int notifyCount = 0;
      authProvider.addListener(() => notifyCount++);

      final mockUser = MockAuth0User();
      when(() => mockAuthService.login()).thenAnswer((_) async => {});
      when(() => mockAuthService.isLoggedIn).thenReturn(true);
      when(() => mockAuthService.profile).thenReturn(mockUser);

      await authProvider.login();

      expect(notifyCount, greaterThan(0));
    });

    test('hasError returns correct value', () {
      expect(authProvider.hasError, isFalse);

      // Manually set error for testing
      when(() => mockAuthService.login())
          .thenThrow(AuthException('Error'));

      authProvider.login();

      // After async error
      Future.delayed(Duration.zero, () {
        expect(authProvider.hasError, isTrue);
      });
    });
  });
}
