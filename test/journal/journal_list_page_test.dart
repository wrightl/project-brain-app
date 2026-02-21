import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:projectbrain/journal/journal_list_page.dart';
import 'package:projectbrain/journal/journal_provider.dart';
import 'package:projectbrain/models/journal/journal_request_dtos.dart';
import 'package:projectbrain/services/auth/auth_service.dart';
import 'package:projectbrain/services/journal_service.dart';
import 'package:projectbrain/services/tag_service.dart';
import 'package:projectbrain/services/user_service.dart';

class MockAuthService extends Mock implements AuthService {}

class MockJournalService extends Mock implements JournalService {}

class MockTagService extends Mock implements TagService {}

class MockUserService extends Mock implements UserService {}

void main() {
  late JournalProvider provider;

  setUpAll(() {
    registerFallbackValue(JournalCreateRequest(content: ''));
  });

  setUp(() {
    provider = JournalProvider(
      journalService: MockJournalService(),
      tagService: MockTagService(),
      userService: MockUserService(),
    );
  });

  testWidgets('JournalListPage has AppBar with Journal title', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<JournalProvider>.value(
          value: provider,
          child: const JournalListPage(),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Journal'), findsOneWidget);
  });

  testWidgets('JournalListPage has FAB for new entry', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<JournalProvider>.value(
          value: provider,
          child: const JournalListPage(),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(find.text('New entry'), findsOneWidget);
  });
}
