import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:projectbrain/models/agent/user_choice_prompt.dart';

class CoachAgentActions {
  static const messageNotConnectedError =
      'You need to be connected with this coach before you can message them.';

  static UserChoiceAction? resolveCoachAction(UserChoiceOption option) {
    if (option.action != null &&
        option.action!.type.isNotEmpty &&
        option.action!.coachProfileId.isNotEmpty) {
      return option.action;
    }

    final viewMatch = RegExp(r'^view_profile:(.+)$').firstMatch(option.id);
    if (viewMatch != null) {
      return UserChoiceAction(
        type: 'view_coach_profile',
        coachProfileId: viewMatch.group(1)!,
      );
    }

    final messageMatch = RegExp(r'^message_coach:(.+)$').firstMatch(option.id);
    if (messageMatch != null) {
      return UserChoiceAction(
        type: 'message_coach',
        coachProfileId: messageMatch.group(1)!,
      );
    }

    return null;
  }

  static bool tryExecute(BuildContext context, UserChoiceOption option) {
    final action = resolveCoachAction(option);
    if (action == null) {
      return false;
    }

    return execute(context, action);
  }

  static bool execute(BuildContext context, UserChoiceAction action) {
    switch (action.type) {
      case 'view_coach_profile':
        if (action.coachProfileId.isEmpty) {
          return false;
        }
        context.push('/network/coaches/${action.coachProfileId}');
        return true;
      case 'message_coach':
        if (action.connectionId != null && action.connectionId!.isNotEmpty) {
          context.go('/network/chat/${action.connectionId}');
          return true;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(messageNotConnectedError)),
        );
        return true;
      default:
        return false;
    }
  }

  static void viewCoachProfile(BuildContext context, String coachProfileId) {
    execute(
      context,
      UserChoiceAction(
        type: 'view_coach_profile',
        coachProfileId: coachProfileId,
      ),
    );
  }

  static void messageCoach(
    BuildContext context, {
    required String coachProfileId,
    String? connectionId,
    String? connectionStatus,
  }) {
    if (connectionStatus == 'connected' &&
        connectionId != null &&
        connectionId.isNotEmpty) {
      execute(
        context,
        UserChoiceAction(
          type: 'message_coach',
          coachProfileId: coachProfileId,
          connectionId: connectionId,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(messageNotConnectedError)),
    );
  }
}
