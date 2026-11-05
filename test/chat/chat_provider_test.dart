import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:projectbrain/chat/chat_provider.dart';
import 'package:projectbrain/models/citation.dart';
import 'package:projectbrain/services/ai_service.dart';
import 'package:projectbrain/services/conversation_service.dart';
import 'package:projectbrain/services/feature_flag_service.dart';

class MockAIService extends Mock implements AIService {}

class MockConversationService extends Mock implements ConversationService {}

class MockFeatureFlagService extends Mock implements FeatureFlagService {}

void main() {
  late MockAIService aiService;
  late ChatProvider provider;
  late StreamController<String> tokens;

  setUp(() {
    aiService = MockAIService();
    final featureFlags = MockFeatureFlagService();
    when(() => featureFlags.agentFeatureEnabled).thenReturn(false);
    tokens = StreamController<String>();
    when(() => aiService.streamChatResponse(
          any(),
          conversationId: any(named: 'conversationId'),
        )).thenAnswer(
      (_) async => ChatStreamResponse(
        stream: tokens.stream,
        conversationId: 'conv-1',
        citationsStream: const Stream<List<Citation>>.empty(),
      ),
    );
    provider = ChatProvider(
      aiService: aiService,
      conversationService: MockConversationService(),
      featureFlagService: featureFlags,
    );
  });

  test('streams tokens into the assistant message', () async {
    final send = provider.sendMessage('hi');
    await pumpEventQueue();
    tokens
      ..add('Hel')
      ..add('lo');
    await tokens.close();
    await send;

    expect(provider.messages.map((m) => m.content), ['hi', 'Hello']);
    expect(provider.isSending, isFalse);
  });

  for (final entry in <String, void Function(ChatProvider)>{
    'clearConversation': (p) => p.clearConversation(),
    'resetOnLogout': (p) => p.resetOnLogout(),
  }.entries) {
    test('${entry.key} mid-stream stops the old reply writing', () async {
      final send = provider.sendMessage('hi');
      await pumpEventQueue();
      tokens.add('first');
      await pumpEventQueue();

      entry.value(provider);
      tokens.add(' late');
      await pumpEventQueue();
      await send;

      expect(provider.messages, isEmpty);
      expect(provider.isSending, isFalse);
      expect(provider.activeConversation, isNull);
    });
  }

  test('a new send works after clearing mid-stream', () async {
    final first = provider.sendMessage('one');
    await pumpEventQueue();
    provider.clearConversation();
    tokens.add('ignored');
    await first;

    tokens = StreamController<String>();
    final second = provider.sendMessage('two');
    await pumpEventQueue();
    tokens.add('reply');
    await tokens.close();
    await second;

    expect(provider.messages.map((m) => m.content), ['two', 'reply']);
  });
}
