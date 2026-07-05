import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:projectbrain/core/di/injection_container.dart';
import 'package:projectbrain/core/logging/app_logger.dart';
import 'package:projectbrain/models/quiz.dart';
import 'package:projectbrain/services/quiz_service.dart';
import 'package:intl/intl.dart';
import 'package:projectbrain/helpers/themes/app_spacing.dart';
import 'package:projectbrain/helpers/themes/app_theme_extension.dart';
import 'package:projectbrain/widgets/ds/ds_widgets.dart';

/// Quizzes page for managing neurodiversity quizzes
class QuizzesPage extends StatefulWidget {
  const QuizzesPage({super.key});

  @override
  State<QuizzesPage> createState() => _QuizzesPageState();
}

class _QuizzesPageState extends State<QuizzesPage> {
  final QuizService _quizService = sl<QuizService>();

  List<Quiz> _quizzes = [];
  List<QuizResponse> _completedQuizzes = [];
  QuizInsights? _insights;
  bool _isLoading = true;
  bool _isLoadingInsights = true;
  bool _isLoadingCompleted = true;
  String? _errorMessage;
  String? _insightsErrorMessage;
  String? _completedErrorMessage;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  /// Refresh insights and completed quizzes
  /// Called after quiz submission to update the page
  Future<void> _refreshAfterSubmission() async {
    await Future.wait([
      _loadInsights(),
      _loadCompletedQuizzes(),
    ]);
  }

  Future<void> _loadAllData() async {
    await Future.wait([
      _loadQuizzes(),
      _loadInsights(),
      _loadCompletedQuizzes(),
    ]);
  }

  Future<void> _loadQuizzes() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final quizzes = await _quizService.getQuizzes();
      setState(() {
        _quizzes = quizzes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load quizzes: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadInsights() async {
    setState(() {
      _isLoadingInsights = true;
      _insightsErrorMessage = null;
    });

    try {
      final insights = await _quizService.getInsights();
      setState(() {
        _insights = insights;
        _isLoadingInsights = false;
      });
    } catch (e) {
      setState(() {
        _insightsErrorMessage = 'Failed to load insights: ${e.toString()}';
        _isLoadingInsights = false;
      });
      logError('[QuizzesPage] Error loading insights: $e');
    }
  }

  Future<void> _loadCompletedQuizzes() async {
    setState(() {
      _isLoadingCompleted = true;
      _completedErrorMessage = null;
    });

    try {
      final responses = await _quizService.getQuizResponses();
      setState(() {
        _completedQuizzes = responses;
        _isLoadingCompleted = false;
      });
    } catch (e) {
      setState(() {
        _completedErrorMessage =
            'Failed to load completed quizzes: ${e.toString()}';
        _isLoadingCompleted = false;
      });
      logError('[QuizzesPage] Error loading completed quizzes: $e');
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown date';
    return DateFormat('MMM d, y').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appTheme = context.appTheme;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadAllData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: AppInsets.page,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Quizzes', style: theme.textTheme.headlineSmall),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Identify neurodiverse traits and track your insights.',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: AppSpacing.xl),
                if (_insights != null ||
                    _isLoadingInsights ||
                    _insightsErrorMessage != null)
                  DsSurfaceCard(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              IconBubble(
                                icon: Icons.insights,
                                color: appTheme.sky,
                                backgroundColor: appTheme.skySoft,
                                size: 40,
                                iconSize: 20,
                                borderRadius: 12,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Text(
                                'Quiz Insights',
                                style: theme.textTheme.titleMedium,
                              ),
                            ],
                          ),
                          SizedBox(height: AppSpacing.lg),
                          if (_isLoadingInsights)
                            const Center(child: CircularProgressIndicator())
                          else if (_insightsErrorMessage != null)
                            Text(
                              _insightsErrorMessage!,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.error,
                              ),
                            )
                          else if (_insights != null) ...[
                            if (_insights!.summary.isNotEmpty)
                              Text(
                                _insights!.summary,
                                style: theme.textTheme.bodyLarge,
                              ),
                            if (_insights!.keyInsights.isNotEmpty) ...[
                              SizedBox(height: AppSpacing.lg),
                              Text(
                                'Key Insights:',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: AppSpacing.sm),
                              ..._insights!.keyInsights.map((insight) =>
                                  Padding(
                                    padding:
                                        EdgeInsets.only(bottom: AppSpacing.sm),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Icon(
                                          Icons.check_circle,
                                          size: 20,
                                          color: theme.colorScheme.primary,
                                        ),
                                        SizedBox(width: AppSpacing.sm),
                                        Expanded(
                                          child: Text(
                                            insight,
                                            style: theme.textTheme.bodyMedium,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )),
                            ],
                            if (_insights!.lastUpdated != null) ...[
                              SizedBox(height: AppSpacing.lg),
                              Text(
                                'Last updated: ${_formatDate(_insights!.lastUpdated)}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ],
                        ],
                      ),
                    ),

                const SizedBox(height: AppSpacing.xl),
                SectionHeader(title: 'Available Quizzes'),
                const SizedBox(height: AppSpacing.lg),
                if (_errorMessage != null)
                  Container(
                    width: double.infinity,
                    padding: AppInsets.screen,
                    margin: EdgeInsets.only(bottom: AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer,
                      borderRadius: AppRadius.circularSm,
                    ),
                    child: Text(
                      _errorMessage!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onErrorContainer,
                      ),
                    ),
                  ),

                // Loading state
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                // Empty state
                else if (_quizzes.isEmpty)
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.quiz,
                          size: 64,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.3),
                        ),
                        SizedBox(height: AppSpacing.lg),
                        Text(
                          'No quizzes available',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.6),
                          ),
                        ),
                        SizedBox(height: AppSpacing.sm),
                        Text(
                          'Check back later for new quizzes',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.5),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                // Quizzes list
                else
                  ..._quizzes.map(
                    (quiz) => Padding(
                      padding: AppInsets.listItemBottom,
                      child: DsSurfaceCard(
                        onTap: () async {
                          await context.push('/quizzes/${quiz.id}');
                          if (mounted) _refreshAfterSubmission();
                        },
                        child: Row(
                          children: [
                            IconBubble(
                              icon: Icons.quiz_outlined,
                              color: appTheme.sky,
                              backgroundColor: appTheme.skySoft,
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    quiz.title,
                                    style: theme.textTheme.titleSmall,
                                  ),
                                  if (quiz.description.isNotEmpty) ...[
                                    const SizedBox(height: AppSpacing.micro),
                                    Text(
                                      quiz.description,
                                      style: theme.textTheme.bodySmall,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                  const SizedBox(height: AppSpacing.micro),
                                  Text(
                                    _formatDate(quiz.createdAt),
                                    style: theme.textTheme.labelSmall,
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.chevron_right,
                              color: appTheme.textMuted,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: AppSpacing.xl),
                SectionHeader(title: 'Completed Quizzes'),
                const SizedBox(height: AppSpacing.lg),
                if (_completedErrorMessage != null)
                  Container(
                    width: double.infinity,
                    padding: AppInsets.screen,
                    margin: EdgeInsets.only(bottom: AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer,
                      borderRadius: AppRadius.circularSm,
                    ),
                    child: Text(
                      _completedErrorMessage!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onErrorContainer,
                      ),
                    ),
                  ),

                // Loading state for completed quizzes
                if (_isLoadingCompleted)
                  const Center(child: CircularProgressIndicator())
                // Empty state for completed quizzes
                else if (_completedQuizzes.isEmpty)
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 64,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.3),
                        ),
                        SizedBox(height: AppSpacing.lg),
                        Text(
                          'No completed quizzes',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.6),
                          ),
                        ),
                        SizedBox(height: AppSpacing.sm),
                        Text(
                          'Complete a quiz to see it here',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.5),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                // Completed quizzes list
                else
                  ..._completedQuizzes.map(
                    (response) => Padding(
                      padding: AppInsets.listItemBottom,
                      child: DsSurfaceCard(
                        onTap: () async {
                          await context.push('/quizzes/${response.quizId}');
                          if (mounted) _refreshAfterSubmission();
                        },
                        child: Row(
                          children: [
                            IconBubble(
                              icon: Icons.check_circle_outline,
                              color: appTheme.green,
                              backgroundColor: appTheme.greenSoft,
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    response.quizTitle ??
                                        'Quiz ${response.quizId}',
                                    style: theme.textTheme.titleSmall,
                                  ),
                                  if (response.score != null) ...[
                                    const SizedBox(height: AppSpacing.micro),
                                    Text(
                                      'Score: ${response.score}',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: appTheme.green,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: AppSpacing.micro),
                                  Text(
                                    'Completed: ${_formatDate(response.completedAt)}',
                                    style: theme.textTheme.labelSmall,
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.chevron_right,
                              color: appTheme.textMuted,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
