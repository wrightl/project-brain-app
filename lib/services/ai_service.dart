import 'dart:async';
import 'dart:convert';
import 'package:projectbrain/core/logging/app_logger.dart';
import 'package:projectbrain/models/citation.dart';
import 'package:projectbrain/services/http_service.dart';

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
}
