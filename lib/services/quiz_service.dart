import 'dart:convert';
import 'package:projectbrain/core/logging/app_logger.dart';
import 'package:projectbrain/models/quiz.dart';
import 'package:projectbrain/services/http_service.dart';

/// Service for managing quizzes
class QuizService extends HttpService {
  QuizService({required super.authService});

  /// Get all quizzes available to the current user
  Future<List<Quiz>> getQuizzes() async {
    logDebug('[QuizService] Fetching quizzes');

    final response = await get(
      '/quizes',
      useCache: false, // Don't cache quizzes list as it changes frequently
    );

    if (response.statusCode == 200) {
      final body = response.body;
      final data = jsonDecode(body);
      final List<dynamic> items = data is Map && data.containsKey('items')
          ? (data['items'] as List<dynamic>)
          : (data is List ? data : <dynamic>[]);
      final quizzes = items
          .map((json) => Quiz.fromJson(json as Map<String, dynamic>))
          .toList();
      logDebug('[QuizService] Fetched ${quizzes.length} quizzes');
      return quizzes;
    } else {
      logError(
          '[QuizService] Failed to fetch quizzes: ${response.statusCode} ${response.reasonPhrase}');
      throw Exception(
        'Failed to fetch quizzes: ${response.statusCode} ${response.reasonPhrase}',
      );
    }
  }

  /// Create a new quiz
  Future<Quiz> createQuiz(Map<String, dynamic> quizData) async {
    logDebug('[QuizService] Creating quiz');

    final response = await post(
      '/quizes',
      body: jsonEncode(quizData),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final body = response.body;
      final data = jsonDecode(body);
      final quiz = Quiz.fromJson(data);
      logDebug('[QuizService] Successfully created quiz: ${quiz.id}');
      // Clear cache for quizzes list
      clearCacheForPath('/quizes');
      return quiz;
    } else {
      logError(
          '[QuizService] Failed to create quiz: ${response.statusCode} ${response.reasonPhrase}');
      throw Exception(
        'Failed to create quiz: ${response.statusCode} ${response.reasonPhrase}',
      );
    }
  }

  /// Delete a quiz by ID
  Future<void> deleteQuiz(String quizId) async {
    logDebug('[QuizService] Deleting quiz: $quizId');

    final response = await delete('/quizes/$quizId');

    if (response.statusCode == 200 || response.statusCode == 204) {
      logDebug('[QuizService] Successfully deleted quiz: $quizId');
      // Clear cache for quizzes list
      clearCacheForPath('/quizes');
    } else {
      logError(
          '[QuizService] Failed to delete quiz: ${response.statusCode} ${response.reasonPhrase}');
      throw Exception(
        'Failed to delete quiz: ${response.statusCode} ${response.reasonPhrase}',
      );
    }
  }

  /// Get insights from previous quiz results
  Future<QuizInsights> getInsights() async {
    logDebug('[QuizService] Fetching quiz insights');

    final response = await get(
      '/quizes/insights',
      useCache: true, // Cache insights as they don't change as frequently
    );

    if (response.statusCode == 200) {
      final body = response.body;
      final data = jsonDecode(body);
      final insights = QuizInsights.fromJson(data);
      logDebug('[QuizService] Fetched quiz insights');
      return insights;
    } else {
      logError(
          '[QuizService] Failed to fetch insights: ${response.statusCode} ${response.reasonPhrase}');
      throw Exception(
        'Failed to fetch insights: ${response.statusCode} ${response.reasonPhrase}',
      );
    }
  }

  /// Get a quiz by ID with all questions
  Future<Quiz> getQuizById(String quizId) async {
    logDebug('[QuizService] Fetching quiz: $quizId');

    final response = await get(
      '/quizes/$quizId',
      useCache: false,
    );

    if (response.statusCode == 200) {
      final body = response.body;
      final data = jsonDecode(body);
      final quiz = Quiz.fromJson(data);
      logDebug('[QuizService] Fetched quiz: ${quiz.title}');
      return quiz;
    } else {
      logError(
          '[QuizService] Failed to fetch quiz: ${response.statusCode} ${response.reasonPhrase}');
      throw Exception(
        'Failed to fetch quiz: ${response.statusCode} ${response.reasonPhrase}',
      );
    }
  }

  /// Submit quiz response with answers
  Future<QuizResponse> submitQuizResponse(
    String quizId,
    Map<String, dynamic> answers,
  ) async {
    logDebug('[QuizService] Submitting quiz response for quiz: $quizId');

    final response = await post(
      '/quizes/$quizId/responses',
      body: jsonEncode({
        'answers': answers,
        'completedAt': DateTime.now().toIso8601String(),
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final body = response.body;
      final data = jsonDecode(body);
      final quizResponse = QuizResponse.fromJson(data);
      logDebug(
          '[QuizService] Successfully submitted quiz response: ${quizResponse.id}');
      // Clear cache for insights since they may have changed
      clearCacheForPath('/quizes/insights');
      return quizResponse;
    } else {
      // Try to parse error message from response
      String errorMessage = 'Failed to submit quiz response';
      try {
        final body = response.body;
        final data = jsonDecode(body);
        if (data['error'] != null) {
          errorMessage = data['error']['message'] ?? errorMessage;
        }
      } catch (e) {
        logDebug('[QuizService] Could not parse error response: $e');
      }

      logError(
          '[QuizService] Failed to submit quiz response: ${response.statusCode} ${response.reasonPhrase}');
      throw Exception(errorMessage);
    }
  }

  /// Get user's completed quiz responses
  Future<List<QuizResponse>> getQuizResponses() async {
    logDebug('[QuizService] Fetching quiz responses');

    final response = await get(
      '/quizes/responses',
      useCache: false,
    );

    if (response.statusCode == 200) {
      final body = response.body;
      final data = jsonDecode(body);
      final List<dynamic> items = data is Map && data.containsKey('items')
          ? (data['items'] as List<dynamic>)
          : (data is List ? data : <dynamic>[]);
      final responses = items
          .map((json) => QuizResponse.fromJson(json as Map<String, dynamic>))
          .toList();
      logDebug('[QuizService] Fetched ${responses.length} quiz responses');
      return responses;
    } else {
      logError(
          '[QuizService] Failed to fetch quiz responses: ${response.statusCode} ${response.reasonPhrase}');
      throw Exception(
        'Failed to fetch quiz responses: ${response.statusCode} ${response.reasonPhrase}',
      );
    }
  }
}
