import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:projectbrain/widgets/chat/conversation_list_item.dart';
import 'package:projectbrain/models/conversation.dart';

void main() {
  group('ConversationListItem Widget Tests', () {
    testWidgets('displays conversation title', (WidgetTester tester) async {
      final conversation = Conversation(
        id: '123',
        userId: 'user1',
        title: 'Test Conversation',
        messages: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConversationListItem(
              conversation: conversation,
              isActive: false,
              onTap: () {},
            ),
          ),
        ),
      );

      // Should display conversation title
      expect(find.text('Test Conversation'), findsOneWidget);
    });

    testWidgets('highlights active conversation', (WidgetTester tester) async {
      final conversation = Conversation(
        id: '123',
        userId: 'user1',
        title: 'Active Conversation',
        messages: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConversationListItem(
              conversation: conversation,
              isActive: true,
              onTap: () {},
            ),
          ),
        ),
      );

      // Find the ListTile
      final listTile = tester.widget<ListTile>(find.byType(ListTile));

      // Active items should have tileColor set
      expect(listTile.tileColor, isNotNull);
    });

    testWidgets('does not highlight inactive conversation', (WidgetTester tester) async {
      final conversation = Conversation(
        id: '123',
        userId: 'user1',
        title: 'Inactive Conversation',
        messages: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConversationListItem(
              conversation: conversation,
              isActive: false,
              onTap: () {},
            ),
          ),
        ),
      );

      // Find the ListTile
      final listTile = tester.widget<ListTile>(find.byType(ListTile));

      // Inactive items should not have tileColor
      expect(listTile.tileColor, isNull);
    });

    testWidgets('calls onTap when tapped', (WidgetTester tester) async {
      final conversation = Conversation(
        id: '123',
        userId: 'user1',
        title: 'Tappable Conversation',
        messages: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      bool wasTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConversationListItem(
              conversation: conversation,
              isActive: false,
              onTap: () {
                wasTapped = true;
              },
            ),
          ),
        ),
      );

      // Tap the item
      await tester.tap(find.byType(ListTile));
      await tester.pumpAndSettle();

      // Verify onTap was called
      expect(wasTapped, isTrue);
    });

    testWidgets('handles long titles', (WidgetTester tester) async {
      final longTitle = 'Very Long Conversation Title ' * 10;
      final conversation = Conversation(
        id: '123',
        userId: 'user1',
        title: longTitle,
        messages: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConversationListItem(
              conversation: conversation,
              isActive: false,
              onTap: () {},
            ),
          ),
        ),
      );

      // Should render without overflow
      expect(tester.takeException(), isNull);

      // Title should be displayed
      expect(find.text(longTitle), findsOneWidget);
    });

    testWidgets('uses theme colors', (WidgetTester tester) async {
      final conversation = Conversation(
        id: '123',
        userId: 'user1',
        title: 'Themed Conversation',
        messages: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final customTheme = ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          brightness: Brightness.light,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: customTheme,
          home: Scaffold(
            body: ConversationListItem(
              conversation: conversation,
              isActive: true,
              onTap: () {},
            ),
          ),
        ),
      );

      // Should render with theme (no errors)
      expect(find.text('Themed Conversation'), findsOneWidget);
    });
  });
}
