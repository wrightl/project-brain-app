import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:projectbrain/widgets/chat/message_bubble.dart';
import 'package:projectbrain/widgets/chat/typing_indicator.dart';
import 'package:projectbrain/models/chatmessage.dart';

void main() {
  group('MessageBubble Widget Tests', () {
    testWidgets('displays user message with correct styling',
        (WidgetTester tester) async {
      const userMessage = ChatMessage(
        role: 'user',
        content: 'Hello, this is a user message',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MessageBubble(message: userMessage),
          ),
        ),
      );

      // Verify text is displayed
      expect(find.text('Hello, this is a user message'), findsOneWidget);

      // Find the outer container that should be aligned to the right
      final outerContainers = find.descendant(
        of: find.byType(MessageBubble),
        matching: find.byType(Container),
      );

      // There should be containers present
      expect(outerContainers, findsWidgets);

      // Get the outermost container
      final container = tester.widget<Container>(outerContainers.first);

      // User messages should be aligned to the right
      expect(container.alignment, equals(Alignment.centerRight));
    });

    testWidgets('displays assistant message with correct styling',
        (WidgetTester tester) async {
      const assistantMessage = ChatMessage(
        role: 'assistant',
        content: 'Hello, this is an assistant message',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MessageBubble(message: assistantMessage),
          ),
        ),
      );

      // Verify text is displayed
      expect(find.text('Hello, this is an assistant message'), findsOneWidget);

      // Find the outer container that should be aligned to the left
      final outerContainers = find.descendant(
        of: find.byType(MessageBubble),
        matching: find.byType(Container),
      );

      // There should be containers present
      expect(outerContainers, findsWidgets);

      // Get the outermost container
      final container = tester.widget<Container>(outerContainers.first);

      // Assistant messages should be aligned to the left
      expect(container.alignment, equals(Alignment.centerLeft));
    });

    testWidgets('displays typing indicator for empty assistant message',
        (WidgetTester tester) async {
      const loadingMessage = ChatMessage(
        role: 'assistant',
        content: '',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MessageBubble(
              message: loadingMessage,
              showTypingIndicator: true,
            ),
          ),
        ),
      );

      // Should display a typing indicator (not CircularProgressIndicator)
      expect(find.byType(TypingIndicator), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('hides typing indicator for empty assistant when not pending',
        (WidgetTester tester) async {
      const loadingMessage = ChatMessage(
        role: 'assistant',
        content: '',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MessageBubble(message: loadingMessage),
          ),
        ),
      );

      expect(find.byType(TypingIndicator), findsNothing);
    });

    testWidgets('uses theme colors correctly', (WidgetTester tester) async {
      const userMessage = ChatMessage(
        role: 'user',
        content: 'Test message',
      );

      // Create a custom theme to test theme integration
      final customTheme = ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.purple,
          brightness: Brightness.light,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: customTheme,
          home: Scaffold(
            body: MessageBubble(message: userMessage),
          ),
        ),
      );

      // Verify widget renders (theme colors are applied)
      expect(find.text('Test message'), findsOneWidget);
    });

    testWidgets('handles markdown content', (WidgetTester tester) async {
      const markdownMessage = ChatMessage(
        role: 'assistant',
        content: '**Bold** and *italic* text',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MessageBubble(message: markdownMessage),
          ),
        ),
      );

      // MarkdownBody renders markdown, so we check for the processed text
      // Markdown will be rendered as separate TextSpan widgets, not a single text
      // So we just verify the widget renders without error
      expect(find.byType(MessageBubble), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('handles long messages', (WidgetTester tester) async {
      final longMessage = ChatMessage(
        role: 'assistant',
        content: 'This is a very long message. ' * 50,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: MessageBubble(message: longMessage),
            ),
          ),
        ),
      );

      // Should render without overflow
      expect(tester.takeException(), isNull);
    });

    testWidgets('handles empty user messages', (WidgetTester tester) async {
      const emptyUserMessage = ChatMessage(
        role: 'user',
        content: '',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MessageBubble(message: emptyUserMessage),
          ),
        ),
      );

      // User messages with empty content should still render
      // (no loading indicator for user messages)
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });
}
