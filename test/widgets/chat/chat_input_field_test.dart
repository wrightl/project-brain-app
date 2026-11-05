import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:projectbrain/widgets/chat/chat_input_field.dart';
import 'package:projectbrain/chat/chat_provider.dart';
import 'package:projectbrain/subscription/subscription_provider.dart';
import 'package:projectbrain/services/subscription_service.dart';

class MockChatProvider extends Mock implements ChatProvider {}

class MockSubscriptionService extends Mock implements SubscriptionService {}

void main() {
  late MockChatProvider mockChatProvider;
  late MockSubscriptionService mockSubscriptionService;
  late SubscriptionProvider subscriptionProvider;
  late TextEditingController controller;
  late ScrollController scrollController;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    mockChatProvider = MockChatProvider();
    when(() => mockChatProvider.isSending).thenReturn(false);
    mockSubscriptionService = MockSubscriptionService();
    subscriptionProvider = SubscriptionProvider(
      subscriptionService: mockSubscriptionService,
      sharedPreferences: prefs,
    );
    controller = TextEditingController();
    scrollController = ScrollController();
  });

  tearDown(() {
    controller.dispose();
    scrollController.dispose();
  });

  Widget wrap(Widget child) {
    return MaterialApp(
      home: Scaffold(
        body: MultiProvider(
          providers: [
            ChangeNotifierProvider<ChatProvider>.value(value: mockChatProvider),
            ChangeNotifierProvider<SubscriptionProvider>.value(
              value: subscriptionProvider,
            ),
          ],
          child: child,
        ),
      ),
    );
  }

  group('ChatInputField Widget Tests', () {
    testWidgets('renders text field and send button',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        wrap(
          ChatInputField(
            controller: controller,
            scrollController: scrollController,
          ),
        ),
      );

      expect(find.byType(TextField), findsOneWidget);
      expect(find.byIcon(Icons.arrow_upward), findsOneWidget);
    });

    testWidgets('accepts text input', (WidgetTester tester) async {
      await tester.pumpWidget(
        wrap(
          ChatInputField(
            controller: controller,
            scrollController: scrollController,
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'Hello World');
      expect(controller.text, equals('Hello World'));
    });

    testWidgets('displays custom hint text', (WidgetTester tester) async {
      await tester.pumpWidget(
        wrap(
          ChatInputField(
            controller: controller,
            scrollController: scrollController,
            hintText: 'Custom hint text',
          ),
        ),
      );

      expect(find.text('Custom hint text'), findsOneWidget);
    });

    testWidgets('uses default hint text when not provided',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        wrap(
          ChatInputField(
            controller: controller,
            scrollController: scrollController,
          ),
        ),
      );

      expect(find.text('Type a message...'), findsOneWidget);
    });

    testWidgets('send button is always visible', (WidgetTester tester) async {
      await tester.pumpWidget(
        wrap(
          ChatInputField(
            controller: controller,
            scrollController: scrollController,
          ),
        ),
      );

      expect(find.byIcon(Icons.arrow_upward), findsOneWidget);
    });

    testWidgets('text field is configured correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        wrap(
          ChatInputField(
            controller: controller,
            scrollController: scrollController,
          ),
        ),
      );

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.decoration, isNotNull);
      expect(textField.onSubmitted, isNotNull);
    });

    testWidgets('keeps typed text when sending while a reply streams',
        (WidgetTester tester) async {
      when(() => mockChatProvider.isSending).thenReturn(true);
      await tester.pumpWidget(
        wrap(
          ChatInputField(
            controller: controller,
            scrollController: scrollController,
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'Follow-up');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.tap(find.byIcon(Icons.arrow_upward));
      await tester.pump();

      expect(controller.text, 'Follow-up');
      verifyNever(() => mockChatProvider.sendMessage(any()));
    });

    testWidgets('sends and clears the field when idle',
        (WidgetTester tester) async {
      when(() => mockChatProvider.sendMessage(any())).thenAnswer((_) async {});
      await tester.pumpWidget(
        wrap(
          ChatInputField(
            controller: controller,
            scrollController: scrollController,
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'Hello');
      await tester.tap(find.byIcon(Icons.arrow_upward));
      await tester.pump();

      expect(controller.text, isEmpty);
      verify(() => mockChatProvider.sendMessage('Hello')).called(1);
    });
  });
}
