import 'package:projectbrain/models/agent/action_card.dart';
import 'package:projectbrain/models/agent/tool_execution.dart';
import 'package:projectbrain/models/agent/user_choice_prompt.dart';
import 'package:projectbrain/models/citation.dart';
import 'package:projectbrain/models/strategies/suggested_strategy.dart';

class AgentStreamEvent {
  final String type;
  final dynamic value;

  const AgentStreamEvent({required this.type, this.value});
}

class AgentStreamResult {
  final String? conversationId;
  final Stream<AgentStreamEvent> stream;

  const AgentStreamResult({
    this.conversationId,
    required this.stream,
  });
}

class AgentMessageExtras {
  final List<ToolExecution> toolExecutions;
  final List<ActionCard> actionCards;
  final List<SuggestedStrategy> suggestedStrategies;
  final UserChoicePrompt? userChoices;

  const AgentMessageExtras({
    this.toolExecutions = const [],
    this.actionCards = const [],
    this.suggestedStrategies = const [],
    this.userChoices,
  });

  AgentMessageExtras copyWith({
    List<ToolExecution>? toolExecutions,
    List<ActionCard>? actionCards,
    List<SuggestedStrategy>? suggestedStrategies,
    UserChoicePrompt? userChoices,
  }) {
    return AgentMessageExtras(
      toolExecutions: toolExecutions ?? this.toolExecutions,
      actionCards: actionCards ?? this.actionCards,
      suggestedStrategies: suggestedStrategies ?? this.suggestedStrategies,
      userChoices: userChoices ?? this.userChoices,
    );
  }
}

class AgentStreamAccumulator {
  final List<Citation> citations = [];
  final List<ToolExecution> toolExecutions = [];
  final List<ActionCard> actionCards = [];
  final List<SuggestedStrategy> strategies = [];
  UserChoicePrompt? userChoices;
  final StringBuffer textBuffer = StringBuffer();
}
