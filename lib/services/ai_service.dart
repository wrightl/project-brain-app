import 'dart:async';
import 'dart:convert';
import 'package:projectbrain/core/logging/app_logger.dart';
import 'package:projectbrain/models/agent/action_card.dart';
import 'package:projectbrain/models/agent/agent_stream_event.dart';
import 'package:projectbrain/models/agent/user_choice_prompt.dart';
import 'package:projectbrain/models/agent/tool_execution.dart';
import 'package:projectbrain/models/citation.dart';
import 'package:projectbrain/models/strategies/suggested_strategy.dart';
import 'package:projectbrain/services/http_service.dart';

/// One event from the strategies-mode chat stream (text or strategies list).
class StrategiesStreamEvent {
  final String? text;
  final List<SuggestedStrategy>? strategies;

  StrategiesStreamEvent({this.text, this.strategies});
}

/// Result of streaming a strategies-mode chat message.
class StrategiesStreamResult {
  final String? conversationId;
  final Stream<StrategiesStreamEvent> stream;

  StrategiesStreamResult({
    this.conversationId,
    required this.stream,
  });
}

/// Response object for chat streaming
class ChatStreamResponse {
  final Stream<String> stream;
  final String? conversationId;
  final Stream<List<Citation>> citationsStream;

  ChatStreamResponse({
    required this.stream,
    this.conversationId,
    required this.citationsStream,
  });
}

/// Service for AI chat interactions
class AIService extends HttpService {
  AIService({required super.authService});

  /// Parse citations from message content in format [ 1 ], [ 2 ], etc.
  /// Returns a map of citation index to citation number
  static Map<int, int> parseCitationReferences(String content) {
    final Map<int, int> citations = {};
    final regex = RegExp(r'\[\s*(\d+)\s*\]');
    final matches = regex.allMatches(content);

    for (final match in matches) {
      final citationNumber = int.tryParse(match.group(1) ?? '');
      if (citationNumber != null) {
        // Store the position and citation number
        citations[match.start] = citationNumber;
      }
    }

    return citations;
  }

  /// Stream chat response from the AI
  Future<ChatStreamResponse> streamChatResponse(
    String text, {
    String? conversationId,
  }) async {
    logDebug(
        '[AIService] Sending chat message (conversation: $conversationId)');

    final response = await send(
      '/chat/stream',
      jsonEncode({'content': text, 'conversationId': conversationId}),
    );

    logDebug(
        '[AIService] Received response with status: ${response.statusCode}');

    if (response.statusCode == 200) {
      final convId = response.headers['x-conversation-id'];

      // Create a broadcast stream controller for citations
      final citationsController = StreamController<List<Citation>>.broadcast();
      final List<Citation> collectedCitations = [];

      final stream = response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .map((line) {
            if (line.startsWith('data:')) {
              final jsonStr = line.substring(5).trim();
              logDebug('[AIService] Received chunk: $jsonStr');
              try {
                final data = jsonDecode(jsonStr);
                logDebug('[AIService] Parsed data: $data');

                if (data['type'] == 'text') {
                  return data['value'] ?? '';
                } else if (data['type'] == 'citation') {
                  // Handle citation from stream
                  final citationData = data['value'];
                  if (citationData is Map<String, dynamic>) {
                    try {
                      final citation = Citation.fromJson(citationData);
                      collectedCitations.add(citation);
                      citationsController.add(List.from(collectedCitations));
                      logDebug('[AIService] Added citation: ${citation.url}');
                    } catch (e) {
                      logDebug('[AIService] Error parsing citation: $e');
                    }
                  } else if (citationData is List) {
                    // Handle list of citations
                    for (var item in citationData) {
                      if (item is Map<String, dynamic>) {
                        try {
                          final citation = Citation.fromJson(item);
                          if (!collectedCitations
                              .any((c) => c.url == citation.url)) {
                            collectedCitations.add(citation);
                          }
                        } catch (e) {
                          logDebug(
                              '[AIService] Error parsing citation from list: $e');
                        }
                      }
                    }
                    citationsController.add(List.from(collectedCitations));
                  }
                  return '';
                } else {
                  return '';
                }
              } catch (e) {
                logDebug('[AIService] Error parsing stream chunk: $e');
                return '';
              }
            }
            return '';
          })
          .where((value) => value.isNotEmpty)
          .cast<String>();

      return ChatStreamResponse(
        stream: stream,
        conversationId: convId,
        citationsStream: citationsController.stream,
      );
    } else {
      logError(
          '[AIService] Error streaming chat response: ${response.statusCode} ${response.reasonPhrase}');
      throw Exception(
        'Failed to stream chat response: ${response.statusCode} ${response.reasonPhrase}',
      );
    }
  }

  /// Stream agent response with tool execution and action card events.
  Future<AgentStreamResult> streamAgentResponse(
    String content, {
    String? conversationId,
    String? workflowId,
  }) async {
    logDebug(
        '[AIService] Sending agent message (conversation: $conversationId)');

    final body = <String, dynamic>{'content': content};
    if (conversationId != null) body['conversationId'] = conversationId;
    if (workflowId != null) body['workflowId'] = workflowId;

    final response = await send(
      '/agent/stream',
      jsonEncode(body),
      extraHeaders: {'Accept': 'text/event-stream'},
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to stream agent response: ${response.statusCode} ${response.reasonPhrase}',
      );
    }

    final convId = response.headers['x-conversation-id'];
    final controller = StreamController<AgentStreamEvent>();
    var buffer = '';

    void onData(String chunk) {
      buffer += chunk;
      while (buffer.contains('\n\n')) {
        final idx = buffer.indexOf('\n\n');
        final eventBlock = buffer.substring(0, idx);
        buffer = buffer.substring(idx + 2);
        _parseAgentEvent(eventBlock, controller);
      }
    }

    void onDone() {
      if (buffer.trim().isNotEmpty) {
        _parseAgentEvent(buffer, controller);
      }
      controller.close();
    }

    void onError(Object e, StackTrace st) {
      logError('[AIService] Agent stream error', e, st);
      controller.addError(e is Exception ? e : Exception(e.toString()));
      controller.close();
    }

    response.stream
        .transform(utf8.decoder)
        .listen(onData, onDone: onDone, onError: onError);

    return AgentStreamResult(
      conversationId: convId,
      stream: controller.stream,
    );
  }

  static void _parseAgentEvent(
      String eventBlock, StreamController<AgentStreamEvent> controller) {
    final dataLines = <String>[];
    for (final line in eventBlock.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.startsWith('data:')) {
        dataLines.add(trimmed.substring(5).trim());
      }
    }
    if (dataLines.isEmpty) return;
    final jsonStr = dataLines.join('\n');
    if (jsonStr.isEmpty) return;
    try {
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      final type = data['type'] as String? ?? '';
      final value = data['value'];
      controller.add(AgentStreamEvent(type: type, value: value));
    } catch (e) {
      logDebug('[AIService] Failed to parse agent SSE event: $e');
    }
  }

  static List<Citation> parseAgentCitations(dynamic value) {
    if (value is! List) return [];
    return value
        .whereType<Map>()
        .map((item) {
          final map = Map<String, dynamic>.from(item);
          return Citation(
            url: map['storageUrl'] as String? ?? '',
            title: map['sourceFile'] as String? ?? 'Source',
            description: map['sourcePage'] as String?,
          );
        })
        .toList();
  }

  static List<ToolExecution> parseToolExecutions(dynamic value) {
    if (value is! List) return [];
    return value
        .whereType<Map>()
        .map((e) => ToolExecution.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  static List<ActionCard> parseActionCards(dynamic value) {
    if (value is! Map) return [];
    return [ActionCard.fromJson(Map<String, dynamic>.from(value))];
  }

  static UserChoicePrompt? parseUserChoices(dynamic value) {
    if (value is! Map) return null;
    final prompt = UserChoicePrompt.fromJson(Map<String, dynamic>.from(value));
    return prompt.options.isEmpty ? null : prompt;
  }

  Future<Map<String, dynamic>> confirmPendingAgentAction({
    required String workflowId,
    required String actionId,
  }) async {
    final response = await post(
      '/agent/workflows/$workflowId/actions/$actionId/confirm',
      body: '{}',
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to confirm action: ${response.statusCode} ${response.reasonPhrase}',
      );
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> cancelPendingAgentAction({
    required String workflowId,
    required String actionId,
  }) async {
    final response = await post(
      '/agent/workflows/$workflowId/actions/$actionId/cancel',
      body: '{}',
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to cancel action: ${response.statusCode} ${response.reasonPhrase}',
      );
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// Stream strategies-mode chat: POST /chat/stream with mode "strategies".
  /// Parses SSE by buffering and splitting on \n\n; each event is JSON from "data:" line(s).
  Future<StrategiesStreamResult> streamStrategiesResponse(
    String content, {
    String? conversationId,
  }) async {
    logDebug(
        '[AIService] Sending strategies message (conversation: $conversationId)');

    final body = jsonEncode({
      'content': content,
      'conversationId': conversationId,
      'mode': 'strategies',
    });
    final response = await send(
      '/chat/stream',
      body,
      extraHeaders: {'Accept': 'text/event-stream'},
    );

    logDebug('[AIService] Strategies response status: ${response.statusCode}');

    if (response.statusCode != 200) {
      logError(
          '[AIService] Strategies stream failed: ${response.statusCode} ${response.reasonPhrase}');
      throw Exception(
        'Failed to stream strategies: ${response.statusCode} ${response.reasonPhrase}',
      );
    }

    final convId = response.headers['x-conversation-id'];
    final controller = StreamController<StrategiesStreamEvent>();
    String buffer = '';

    void onData(String chunk) {
      buffer += chunk;
      while (buffer.contains('\n\n')) {
        final idx = buffer.indexOf('\n\n');
        final eventBlock = buffer.substring(0, idx);
        buffer = buffer.substring(idx + 2);
        _parseAndEmitEvent(eventBlock, controller);
      }
    }

    void onDone() {
      if (buffer.trim().isNotEmpty) {
        _parseAndEmitEvent(buffer, controller);
      }
      controller.close();
    }

    void onError(e, st) {
      logError('[AIService] Strategies stream error', e, st);
      controller.addError(e is Exception ? e : Exception(e.toString()));
      controller.close();
    }

    response.stream
        .transform(utf8.decoder)
        .listen(onData, onDone: onDone, onError: onError);

    return StrategiesStreamResult(
      conversationId: convId,
      stream: controller.stream,
    );
  }

  static void _parseAndEmitEvent(
      String eventBlock, StreamController<StrategiesStreamEvent> controller) {
    final dataLines = <String>[];
    for (final line in eventBlock.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.startsWith('data:')) {
        dataLines.add(trimmed.substring(5).trim());
      }
    }
    if (dataLines.isEmpty) return;
    final jsonStr = dataLines.join('\n');
    if (jsonStr.isEmpty) return;
    try {
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      final type = data['type'] as String?;
      final value = data['value'];
      if (type == 'text' && value != null) {
        controller.add(StrategiesStreamEvent(
            text: value is String ? value : value.toString()));
      } else if (type == 'strategies' && value is List) {
        final list = value
            .map((e) => SuggestedStrategy.fromJson(e as Map<String, dynamic>))
            .toList();
        controller.add(StrategiesStreamEvent(strategies: list));
      }
    } catch (e) {
      logDebug('[AIService] Failed to parse SSE event: $e');
    }
  }
}
