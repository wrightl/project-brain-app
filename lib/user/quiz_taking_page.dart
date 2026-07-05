import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:projectbrain/core/di/injection_container.dart';
import 'package:projectbrain/helpers/themes/app_spacing.dart';
import 'package:projectbrain/helpers/themes/app_theme_extension.dart';
import 'package:projectbrain/user/quiz_taking_provider.dart';
import 'package:projectbrain/user/widgets/quiz_question_widget.dart';

/// Page for taking a quiz with swipe navigation
class QuizTakingPage extends StatelessWidget {
  final String quizId;

  const QuizTakingPage({
    super.key,
    required this.quizId,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => QuizTakingProvider(quizService: sl())..loadQuiz(quizId),
      child: _QuizTakingView(quizId: quizId),
    );
  }
}

class _QuizTakingView extends StatefulWidget {
  final String quizId;

  const _QuizTakingView({required this.quizId});

  @override
  State<_QuizTakingView> createState() => _QuizTakingViewState();
}

class _QuizTakingViewState extends State<_QuizTakingView> {
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextQuestion(QuizTakingProvider provider) {
    if (provider.currentQuestionIndex < provider.visibleQuestions.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousQuestion(QuizTakingProvider provider) {
    if (provider.currentQuestionIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _submitQuiz(QuizTakingProvider provider) async {
    final submitted = await provider.submitQuiz(widget.quizId);
    if (!mounted) return;

    if (!submitted) {
      final missingIndex = provider.firstMissingMandatoryIndex();
      if (missingIndex != null && missingIndex >= 0) {
        _pageController.animateToPage(
          missingIndex,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }

      if (provider.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage!),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: AppSpacing.sm),
            Text('Quiz submitted successfully!'),
          ],
        ),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
      ),
    );

    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted) {
      context.pop(true);
    }
  }

  bool _isQuizComplete(QuizTakingProvider provider) {
    return provider.validateMandatoryAnswers() == null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<QuizTakingProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(provider.quiz?.title ?? 'Quiz'),
        actions: [
          if (provider.visibleQuestions.isNotEmpty)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Center(
                child: Text(
                  '${provider.currentQuestionIndex + 1} / ${provider.visibleQuestions.length}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.quiz == null ||
                  (provider.errorMessage != null &&
                      provider.visibleQuestions.isEmpty)
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
                        provider.errorMessage ?? 'Failed to load quiz',
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
              : provider.visibleQuestions.isEmpty
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
                        if (provider.errorMessage != null)
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
                                    provider.errorMessage!,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.onErrorContainer,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (provider.successMessage != null)
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
                                    provider.successMessage!,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color:
                                          theme.colorScheme.onPrimaryContainer,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ClipRRect(
                          borderRadius: AppRadius.circularPill,
                          child: LinearProgressIndicator(
                            value: (provider.currentQuestionIndex + 1) /
                                provider.visibleQuestions.length,
                            minHeight: 8,
                            backgroundColor: context.appTheme.primarySoft,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              theme.colorScheme.primary,
                            ),
                          ),
                        ),
                        Expanded(
                          child: PageView.builder(
                            controller: _pageController,
                            onPageChanged: provider.setCurrentQuestionIndex,
                            physics: const PageScrollPhysics(),
                            itemCount: provider.visibleQuestions.length,
                            itemBuilder: (context, index) {
                              final question = provider.visibleQuestions[index];
                              final answer = provider.answers[question.id];

                              return SingleChildScrollView(
                                padding: AppInsets.page,
                                child: QuizQuestionWidget(
                                  question: question,
                                  value: answer,
                                  onChanged: (value) =>
                                      provider.updateAnswer(question.id, value),
                                ),
                              );
                            },
                          ),
                        ),
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
                              IconButton(
                                onPressed: provider.currentQuestionIndex > 0
                                    ? () => _previousQuestion(provider)
                                    : null,
                                icon: const Icon(Icons.arrow_back),
                                tooltip: 'Previous question',
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(
                                  provider.visibleQuestions.length,
                                  (index) => Container(
                                    width: 8,
                                    height: 8,
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.xs,
                                    ),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color:
                                          index == provider.currentQuestionIndex
                                              ? theme.colorScheme.primary
                                              : theme.colorScheme.onSurface
                                                  .withValues(alpha: 0.3),
                                    ),
                                  ),
                                ),
                              ),
                              if (provider.currentQuestionIndex <
                                  provider.visibleQuestions.length - 1)
                                ElevatedButton.icon(
                                  onPressed: provider.canProceedToNext()
                                      ? () => _nextQuestion(provider)
                                      : null,
                                  icon: const Icon(Icons.arrow_forward),
                                  label: const Text('Next'),
                                )
                              else
                                ElevatedButton.icon(
                                  onPressed: (_isQuizComplete(provider) &&
                                          !provider.isSubmitting)
                                      ? () => _submitQuiz(provider)
                                      : null,
                                  icon: provider.isSubmitting
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Icon(Icons.check),
                                  label: Text(provider.isSubmitting
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
