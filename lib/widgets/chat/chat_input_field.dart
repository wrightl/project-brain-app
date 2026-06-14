import 'package:flutter/material.dart';
import 'package:projectbrain/chat/chat_provider.dart';
import 'package:projectbrain/subscription/subscription_provider.dart';
import 'package:projectbrain/subscription/widgets/upgrade_prompt.dart';
import 'package:projectbrain/models/subscription.dart';
import 'package:provider/provider.dart';
import 'package:projectbrain/helpers/themes/app_spacing.dart';

/// Reusable chat input field with send button
class ChatInputField extends StatelessWidget {
  final TextEditingController controller;
  final ScrollController? scrollController;
  final String hintText;
  final VoidCallback? onMessageSent;

  const ChatInputField({
    super.key,
    required this.controller,
    this.scrollController,
    this.hintText = "Type a message...",
    this.onMessageSent,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Row(
        children: [
          // Microphone button (gated by subscription)
          Consumer<SubscriptionProvider>(
            builder: (context, subscriptionProvider, _) {
              final canUseSpeech = subscriptionProvider.canUseSpeechInput();

              return IconButton(
                icon: Icon(
                  Icons.mic,
                  color: canUseSpeech
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                onPressed: canUseSpeech
                    ? () {
                        // TODO: Implement speech input functionality
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Speech input coming soon'),
                          ),
                        );
                      }
                    : () {
                        // Show upgrade prompt
                        showDialog(
                          context: context,
                          builder: (context) => UpgradePromptDialog(
                            requiredTier: SubscriptionTier.pro,
                            featureName: 'Speech input',
                          ),
                        );
                      },
                tooltip: canUseSpeech
                    ? 'Speech input'
                    : 'Speech input requires Pro tier',
              );
            },
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: hintText,
                  border: const OutlineInputBorder(),
                ),
                onSubmitted: (text) {
                  _sendMessage(context, text);
                },
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: () {
              _sendMessage(context, controller.text);
            },
          )
        ],
      ),
    );
  }

  void _sendMessage(BuildContext context, String text) {
    final trimmed = text.trim();
    if (trimmed.isNotEmpty) {
      final chatProvider = context.read<ChatProvider>();
      chatProvider.sendMessage(trimmed);
      controller.clear();

      // Callback for additional actions
      onMessageSent?.call();

      // Auto-scroll to bottom after sending
      if (scrollController != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (scrollController!.hasClients) {
            scrollController!.animateTo(
              scrollController!.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    }
  }
}
