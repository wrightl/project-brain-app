import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:projectbrain/widgets/chat/chat_input_field.dart';
import 'package:projectbrain/chat/chat_provider.dart';

// Mock classes
class MockChatProvider extends Mock implements ChatProvider {}

void main() {
  late MockChatProvider mockChatProvider;
  late TextEditingController controller;
  late ScrollController scrollController;

  setUp(() {
    mockChatProvider = MockChatProvider();
    controller = TextEditingController();
    scrollController = ScrollController();
  });

  tearDown(() {
    controller.dispose();
    scrollController.dispose();
  });

  group('ChatInputField Widget Tests', () {
    testWidgets('renders text field and send button', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider<ChatProvider>.value(
              value: mockChatProvider,
              child: ChatInputField(
                controller: controller,
                scrollController: scrollController,
              ),
            ),
          ),
        ),
      );

      // Should find text field
      expect(find.byType(TextField), findsOneWidget);

      // Should find send button
      expect(find.byIcon(Icons.send), findsOneWidget);
    });

    testWidgets('accepts text input', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider<ChatProvider>.value(
              value: mockChatProvider,
              child: ChatInputField(
                controller: controller,
                scrollController: scrollController,
              ),
            ),
          ),
        ),
      );

      // Enter text
      await tester.enterText(find.byType(TextField), 'Hello World');

      // Verify text is in controller
      expect(controller.text, equals('Hello World'));
    });

    testWidgets('displays custom hint text', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider<ChatProvider>.value(
              value: mockChatProvider,
              child: ChatInputField(
                controller: controller,
                scrollController: scrollController,
                hintText: 'Custom hint text',
              ),
            ),
          ),
        ),
      );

      // Should find custom hint
      expect(find.text('Custom hint text'), findsOneWidget);
    });

    testWidgets('uses default hint text when not provided', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider<ChatProvider>.value(
              value: mockChatProvider,
              child: ChatInputField(
                controller: controller,
                scrollController: scrollController,
              ),
            ),
          ),
        ),
      );

      // Should find default hint
      expect(find.text('Type a message...'), findsOneWidget);
    });

    testWidgets('send button is always visible', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider<ChatProvider>.value(
              value: mockChatProvider,
              child: ChatInputField(
                controller: controller,
                scrollController: scrollController,
              ),
            ),
          ),
        ),
      );

      // Send button should be visible
      expect(find.byIcon(Icons.send), findsOneWidget);
    });

    testWidgets('text field is configured correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider<ChatProvider>.value(
              value: mockChatProvider,
              child: ChatInputField(
                controller: controller,
                scrollController: scrollController,
              ),
            ),
          ),
        ),
      );

      final textField = tester.widget<TextField>(find.byType(TextField));

      // Text field should have standard configuration
      expect(textField.decoration, isNotNull);
      expect(textField.onSubmitted, isNotNull);
    });
  });
}
