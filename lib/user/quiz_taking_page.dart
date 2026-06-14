import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:projectbrain/core/di/injection_container.dart';
import 'package:projectbrain/models/quiz.dart';
import 'package:projectbrain/services/quiz_service.dart';
import 'package:projectbrain/user/widgets/quiz_question_widget.dart';
import 'package:projectbrain/helpers/themes/app_spacing.dart';

/// Page for taking a quiz with swipe navigation
class QuizTakingPage extends StatefulWidget {
  final String quizId;

  const QuizTakingPage({
    super.key,
    required this.quizId,
  });

  @override
  State<QuizTakingPage> createState() => _QuizTakingPageState();
}

class _QuizTakingPageState extends State<QuizTakingPage> {
  final QuizService _quizService = sl<QuizService>();
  final PageController _pageController = PageController();
  final Map<String, dynamic> _answers = {};

  Quiz? _quiz;
  List<QuizQuestion> _visibleQuestions = [];
  int _currentQuestionIndex = 0;
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    _loadQuiz();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadQuiz() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final quiz = await _quizService.getQuizById(widget.quizId);

      // Filter to only visible questions
      final visibleQuestions =
          quiz.questions?.where((q) => q.visible).toList() ?? [];

      setState(() {
        _quiz = quiz;
        _visibleQuestions = visibleQuestions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load quiz: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _updateAnswer(String questionId, dynamic value) {
    setState(() {
      _answers[questionId] = value;
    });
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _visibleQuestions.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentQuestionIndex = index;
    });
  }

  bool _canProceedToNext() {
    if (_currentQuestionIndex >= _visibleQuestions.length - 1) {
      return false; // Already on last question
    }

    final currentQuestion = _visibleQuestions[_currentQuestionIndex];

    // If question is mandatory, check if it's answered
    if (currentQuestion.mandatory) {
      final answer = _answers[currentQuestion.id];
      if (answer == null ||
          answer == '' ||
          (answer is List && answer.isEmpty)) {
        return false;
      }
    }

    return true;
  }

  Future<void> _submitQuiz() async {
    // Validate all mandatory questions are answered
    final missingMandatory = <String>[];
    for (final question in _visibleQuestions) {
      if (question.mandatory) {
        final answer = _answers[question.id];
        if (answer == null ||
            answer == '' ||
            (answer is List && answer.isEmpty)) {
          missingMandatory.add(question.label);
        }
      }
    }

    if (missingMandatory.isNotEmpty) {
      setState(() {
        _errorMessage =
            'Please answer all required questions before submitting:\n${missingMandatory.map((q) => '• $q').join('\n')}';
      });
      // Scroll to first unanswered mandatory question
      final firstMissingIndex = _visibleQuestions.indexWhere((q) =>
          q.mandatory &&
          (_answers[q.id] == null ||
              _answers[q.id] == '' ||
              (_answers[q.id] is List && (_answers[q.id] as List).isEmpty)));
      if (firstMissingIndex >= 0) {
        _pageController.animateToPage(
          firstMissingIndex,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      await _quizService.submitQuizResponse(
        widget.quizId,
        _answers,
      );

      setState(() {
        _isSubmitting = false;
        _successMessage = 'Quiz submitted successfully!';
      });

      // Show success message and navigate back
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: AppSpacing.sm),
                Text('Quiz submitted successfully!'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );

        // Wait a moment then navigate back with success result
        await Future.delayed(const Duration(milliseconds: 1500));
        if (mounted) {
          context.pop(true); // Return true to indicate successful submission
        }
      }
    } catch (e) {
      setState(() {
        _isSubmitting = false;
        _errorMessage = 'Failed to submit quiz: ${e.toString()}';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  bool _isQuizComplete() {
    // Check if all mandatory questions are answered
    for (final question in _visibleQuestions) {
      if (question.mandatory) {
        final answer = _answers[question.id];
        if (answer == null ||
            answer == '' ||
            (answer is List && answer.isEmpty)) {
          return false;
        }
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_quiz?.title ?? 'Quiz'),
        actions: [
          if (_visibleQuestions.isNotEmpty)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Center(
                child: Text(
                  '${_currentQuestionIndex + 1} / ${_visibleQuestions.length}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _quiz == null || _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: theme.colorScheme.error,
                      ),
                      SizedBox(height: AppSpacing.lg),
                      Text(
                        _errorMessage ?? 'Failed to load quiz',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: AppSpacing.lg),
                      ElevatedButton(
                        onPressed: () => context.pop(),
                        child: const Text('Go Back'),
                      ),
                    ],
                  ),
                )
              : _visibleQuestions.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.quiz_outlined,
                            size: 64,
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.3,
                            ),
                          ),
                          SizedBox(height: AppSpacing.lg),
                          Text(
                            'No questions available',
                            style: theme.textTheme.titleMedium,
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        // Error/Success messages
                        if (_errorMessage != null)
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(AppSpacing.md),
                            color: theme.colorScheme.errorContainer,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  color: theme.colorScheme.onErrorContainer,
                                  size: 20,
                                ),
                                SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.onErrorContainer,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.close,
                                    size: 18,
                                    color: theme.colorScheme.onErrorContainer,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _errorMessage = null;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        if (_successMessage != null)
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(AppSpacing.md),
                            color: theme.colorScheme.primaryContainer,
                            child: Row(
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  color: theme.colorScheme.onPrimaryContainer,
                                  size: 20,
                                ),
                                SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Text(
                                    _successMessage!,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color:
                                          theme.colorScheme.onPrimaryContainer,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Progress indicator
                        LinearProgressIndicator(
                          value: (_currentQuestionIndex + 1) /
                              _visibleQuestions.length,
                          backgroundColor:
                              theme.colorScheme.surfaceContainerHighest,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            theme.colorScheme.primary,
                          ),
                        ),

                        // Questions
                        Expanded(
                          child: PageView.builder(
                            controller: _pageController,
                            onPageChanged: _onPageChanged,
                            physics: const PageScrollPhysics(),
                            itemCount: _visibleQuestions.length,
                            itemBuilder: (context, index) {
                              final question = _visibleQuestions[index];
                              final answer = _answers[question.id];

                              return SingleChildScrollView(
                                padding: AppInsets.page,
                                child: QuizQuestionWidget(
                                  question: question,
                                  value: answer,
                                  onChanged: (value) =>
                                      _updateAnswer(question.id, value),
                                ),
                              );
                            },
                          ),
                        ),

                        // Navigation buttons
                        Container(
                          padding: AppInsets.screen,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            border: Border(
                              top: BorderSide(color: theme.dividerColor),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Back button
                              IconButton(
                                onPressed: _currentQuestionIndex > 0
                                    ? _previousQuestion
                                    : null,
                                icon: const Icon(Icons.arrow_back),
                                tooltip: 'Previous question',
                              ),

                              // Page indicators (dots)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(
                                  _visibleQuestions.length,
                                  (index) => Container(
                                    width: 8,
                                    height: 8,
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.xs,
                                    ),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: index == _currentQuestionIndex
                                          ? theme.colorScheme.primary
                                          : theme.colorScheme.onSurface
                                              .withValues(alpha: 0.3),
                                    ),
                                  ),
                                ),
                              ),

                              // Next/Submit button
                              if (_currentQuestionIndex <
                                  _visibleQuestions.length - 1)
                                ElevatedButton.icon(
                                  onPressed: _canProceedToNext()
                                      ? _nextQuestion
                                      : null,
                                  icon: const Icon(Icons.arrow_forward),
                                  label: const Text('Next'),
                                )
                              else
                                ElevatedButton.icon(
                                  onPressed:
                                      (_isQuizComplete() && !_isSubmitting)
                                          ? _submitQuiz
                                          : null,
                                  icon: _isSubmitting
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Icon(Icons.check),
                                  label: Text(_isSubmitting
                                      ? 'Submitting...'
                                      : 'Submit'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        theme.colorScheme.primaryContainer,
                                    foregroundColor:
                                        theme.colorScheme.onPrimaryContainer,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
    );
  }
}
