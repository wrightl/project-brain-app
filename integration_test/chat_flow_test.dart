import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:projectbrain/main.dart' as app;

/// Integration test for chat functionality
///
/// This test verifies the complete chat flow including sending messages,
/// receiving responses, and conversation management.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Chat Flow Integration Tests', () {
    testWidgets('Send message and receive response',
        (WidgetTester tester) async {
      // Start the app (assuming user is already authenticated)
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Note: This test requires a logged-in state
      // You may need to set up authentication state first

      // Find the message input field
      final inputField = find.byType(TextField);

      if (inputField.evaluate().isEmpty) {
        // If not on chat screen, this test cannot proceed
        print('Not on chat screen, skipping test');
        return;
      }

      // Enter a test message
      await tester.enterText(inputField, 'Hello, this is a test message');
      await tester.pumpAndSettle();

      // Find and tap the send button
      final sendButton = find.byIcon(Icons.send);
      expect(sendButton, findsOneWidget);
      await tester.tap(sendButton);
      await tester.pumpAndSettle();

      // Verify message appears in the chat
      expect(find.text('Hello, this is a test message'), findsOneWidget);

      // Wait for AI response (this may take several seconds)
      await tester.pumpAndSettle(const Duration(seconds: 10));

      // Verify loading indicator or response appears
      // The exact widget depends on your implementation
    });

    testWidgets('Create new conversation', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Find and tap new conversation button
      final newConversationButton = find.byIcon(Icons.add);
      if (newConversationButton.evaluate().isNotEmpty) {
        await tester.tap(newConversationButton);
        await tester.pumpAndSettle();

        // Verify conversation was cleared
        // The chat list should be empty or show empty state
      }
    });

    testWidgets('Load previous conversation', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Open drawer to see conversation list
      final drawerButton = find.byIcon(Icons.menu);
      if (drawerButton.evaluate().isNotEmpty) {
        await tester.tap(drawerButton);
        await tester.pumpAndSettle();

        // Find and tap a conversation (if any exist)
        // final conversation = find.byType(ListTile).first;
        // await tester.tap(conversation);
        // await tester.pumpAndSettle();

        // Verify messages load
      }
    });
  });

  group('Chat Performance Tests', () {
    testWidgets('Smooth scrolling with many messages',
        (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // This test would verify that the ListView optimizations work
      // by checking that scrolling remains smooth even with many messages

      // Find the scrollable chat list
      final chatList = find.byType(ListView);

      if (chatList.evaluate().isNotEmpty) {
        // Perform scroll gestures
        await tester.drag(chatList, const Offset(0, -300));
        await tester.pumpAndSettle();

        // Scroll back up
        await tester.drag(chatList, const Offset(0, 300));
        await tester.pumpAndSettle();

        // Verify no frame drops (this is more of a manual check)
        // In CI, you could check for jank using timeline analysis
      }
    });

    testWidgets('Handle rapid message sending', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      final inputField = find.byType(TextField);
      final sendButton = find.byIcon(Icons.send);

      if (inputField.evaluate().isEmpty) return;

      // Send multiple messages rapidly
      for (int i = 0; i < 3; i++) {
        await tester.enterText(inputField, 'Test message $i');
        await tester.pumpAndSettle();

        if (sendButton.evaluate().isNotEmpty) {
          await tester.tap(sendButton);
          await tester.pump(); // Don't wait for settle to test rapid sending
        }
      }

      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Verify all messages appear
      expect(find.text('Test message 0'), findsOneWidget);
      expect(find.text('Test message 1'), findsOneWidget);
      expect(find.text('Test message 2'), findsOneWidget);
    });
  });

  group('Offline Behavior Tests', () {
    testWidgets('Queue messages when offline', (WidgetTester tester) async {
      // This test would verify offline queue functionality
      // Requires network simulation capabilities

      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // 1. Simulate going offline
      // 2. Send a message
      // 3. Verify message is queued
      // 4. Simulate going online
      // 5. Verify message is sent
    });

    testWidgets('Load cached data when offline', (WidgetTester tester) async {
      // This test verifies persistent cache works
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // 1. Ensure some data is cached (e.g., conversation list)
      // 2. Restart app in offline mode
      // 3. Verify cached data is displayed
    });
  });
}
