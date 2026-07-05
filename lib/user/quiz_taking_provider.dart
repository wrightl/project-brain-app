import 'package:flutter/foundation.dart';
import 'package:projectbrain/models/quiz.dart';
import 'package:projectbrain/services/quiz_service.dart';

class QuizTakingProvider extends ChangeNotifier {
  QuizTakingProvider({required QuizService quizService})
      : _quizService = quizService;

  final QuizService _quizService;
  final Map<String, dynamic> _answers = {};

  Quiz? quiz;
  List<QuizQuestion> visibleQuestions = [];
  int currentQuestionIndex = 0;
  bool isLoading = false;
  bool isSubmitting = false;
  String? errorMessage;
  String? successMessage;

  Map<String, dynamic> get answers => Map.unmodifiable(_answers);

  Future<void> loadQuiz(String quizId) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final loadedQuiz = await _quizService.getQuizById(quizId);
      quiz = loadedQuiz;
      visibleQuestions =
          loadedQuiz.questions?.where((q) => q.visible).toList() ?? [];
      isLoading = false;
      notifyListeners();
    } catch (e) {
      errorMessage = 'Failed to load quiz: ${e.toString()}';
      isLoading = false;
      notifyListeners();
    }
  }

  void updateAnswer(String questionId, dynamic value) {
    _answers[questionId] = value;
    notifyListeners();
  }

  void setCurrentQuestionIndex(int index) {
    currentQuestionIndex = index;
    notifyListeners();
  }

  bool canProceedToNext() {
    if (currentQuestionIndex >= visibleQuestions.length - 1) {
      return false;
    }

    final currentQuestion = visibleQuestions[currentQuestionIndex];
    if (!currentQuestion.mandatory) {
      return true;
    }

    final answer = _answers[currentQuestion.id];
    if (answer == null || answer == '' || (answer is List && answer.isEmpty)) {
      return false;
    }

    return true;
  }

  int? firstMissingMandatoryIndex() {
    return visibleQuestions.indexWhere((q) =>
        q.mandatory &&
        (_answers[q.id] == null ||
            _answers[q.id] == '' ||
            (_answers[q.id] is List && (_answers[q.id] as List).isEmpty)));
  }

  String? validateMandatoryAnswers() {
    final missingMandatory = <String>[];
    for (final question in visibleQuestions) {
      if (!question.mandatory) continue;
      final answer = _answers[question.id];
      if (answer == null ||
          answer == '' ||
          (answer is List && answer.isEmpty)) {
        missingMandatory.add(question.label);
      }
    }

    if (missingMandatory.isEmpty) {
      return null;
    }

    return 'Please answer all required questions before submitting:\n'
        '${missingMandatory.map((q) => '• $q').join('\n')}';
  }

  Future<bool> submitQuiz(String quizId) async {
    final validationError = validateMandatoryAnswers();
    if (validationError != null) {
      errorMessage = validationError;
      successMessage = null;
      notifyListeners();
      return false;
    }

    isSubmitting = true;
    errorMessage = null;
    successMessage = null;
    notifyListeners();

    try {
      await _quizService.submitQuizResponse(quizId, _answers);
      isSubmitting = false;
      successMessage = 'Quiz submitted successfully!';
      notifyListeners();
      return true;
    } catch (e) {
      isSubmitting = false;
      errorMessage = 'Failed to submit quiz: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }
}
