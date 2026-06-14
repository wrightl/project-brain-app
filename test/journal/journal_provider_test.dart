import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:projectbrain/journal/journal_provider.dart';
import 'package:projectbrain/services/journal_service.dart';
import 'package:projectbrain/services/tag_service.dart';
import 'package:projectbrain/services/user_service.dart';
import 'package:projectbrain/models/journal/journal_entry.dart';
import 'package:projectbrain/models/journal/journal_request_dtos.dart';
import 'package:projectbrain/models/journal/journal_streak_summary.dart';
import 'package:projectbrain/models/journal/paged_response.dart';
import 'package:projectbrain/models/journal/timezone_response.dart';

class MockJournalService extends Mock implements JournalService {}

class MockTagService extends Mock implements TagService {}

class MockUserService extends Mock implements UserService {}

void main() {
  late JournalProvider provider;
  late MockJournalService mockJournalService;
  late MockTagService mockTagService;
  late MockUserService mockUserService;

  setUpAll(() {
    // Avoid TestWidgetsFlutterBinding here: it mocks HttpClient globally and
    // breaks tests that use real loopback HTTP (e.g. auth_provider_test).
    registerFallbackValue(JournalCreateRequest(content: ''));
    registerFallbackValue(JournalUpdateRequest(content: ''));
  });

  setUp(() {
    mockJournalService = MockJournalService();
    mockTagService = MockTagService();
    mockUserService = MockUserService();
    provider = JournalProvider(
      journalService: mockJournalService,
      tagService: mockTagService,
      userService: mockUserService,
    );
  });

  group('JournalProvider', () {
    test('initial state is empty', () {
      expect(provider.items, isEmpty);
      expect(provider.isLoading, isFalse);
      expect(provider.hasNextPage, isFalse);
      expect(provider.errorMessage, isNull);
      expect(provider.currentEntry, isNull);
      expect(provider.systemTags, isEmpty);
      expect(provider.userTags, isEmpty);
      expect(provider.streakSummary, isNull);
    });

    test('refresh loads first page and updates items', () async {
      final entry = JournalEntry(
        id: 'e1',
        userId: 'u1',
        content: 'Hello',
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 1, 1),
      );
      final paged = PagedJournalResponse(
        items: [entry],
        page: 1,
        pageSize: 20,
        totalCount: 1,
        totalPages: 1,
        hasPreviousPage: false,
        hasNextPage: false,
      );
      when(() => mockJournalService.listEntries(page: 1, pageSize: 20))
          .thenAnswer((_) async => paged);

      await provider.refresh();

      expect(provider.items.length, 1);
      expect(provider.items.first.content, 'Hello');
      expect(provider.totalCount, 1);
      expect(provider.hasNextPage, isFalse);
      expect(provider.isLoading, isFalse);
    });

    test('refresh on error sets errorMessage and clears items', () async {
      when(() => mockJournalService.listEntries(page: 1, pageSize: 20))
          .thenThrow(Exception('Network error'));
      when(() => mockUserService.getTimezone())
          .thenAnswer((_) async => TimezoneResponse(timezone: 'UTC'));

      await provider.refresh();

      expect(provider.items, isEmpty);
      expect(provider.errorMessage, isNotNull);
      expect(provider.isLoading, isFalse);
    });

    test('createEntry adds request and returns entry', () async {
      final request = JournalCreateRequest(content: 'New entry');
      final created = JournalEntry(
        id: 'e2',
        userId: 'u1',
        content: 'New entry',
        createdAt: DateTime(2025, 1, 2),
        updatedAt: DateTime(2025, 1, 2),
      );
      when(() => mockJournalService.createEntry(any()))
          .thenAnswer((_) async => created);
      when(() => mockUserService.getTimezone())
          .thenAnswer((_) async => TimezoneResponse(timezone: 'UTC'));
      when(() => mockJournalService.getStreakSummary()).thenAnswer((_) async =>
          JournalStreakSummary(currentStreak: 1, longestStreak: 1));

      final result = await provider.createEntry(request);

      expect(result.id, 'e2');
      expect(provider.items.length, 1);
      expect(provider.items.first.content, 'New entry');
    });

    test('loadSystemTags populates systemTags', () async {
      when(() => mockJournalService.getSystemTags())
          .thenAnswer((_) async => []);
      await provider.loadSystemTags();
      expect(provider.systemTags, isEmpty);
    });

    test('loadUserTags populates userTags', () async {
      when(() => mockTagService.listTags()).thenAnswer((_) async => []);
      await provider.loadUserTags();
      expect(provider.userTags, isEmpty);
    });
  });
}
