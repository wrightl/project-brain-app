import 'package:flutter/material.dart';
import 'package:projectbrain/chat/chat_provider.dart';
import 'package:projectbrain/subscription/subscription_provider.dart';
import 'package:projectbrain/subscription/widgets/upgrade_prompt.dart';
import 'package:projectbrain/models/subscription.dart';
import 'package:provider/provider.dart';
import 'package:projectbrain/helpers/themes/app_spacing.dart';
import 'package:projectbrain/helpers/themes/app_theme_extension.dart';

/// Reusable chat input field with send button.
class ChatInputField extends StatelessWidget {
  const ChatInputField({
    super.key,
    required this.controller,
    this.scrollController,
    this.hintText = 'Type a message...',
    this.onMessageSent,
  });

  final TextEditingController controller;
  final ScrollController? scrollController;
  final String hintText;
  final VoidCallback? onMessageSent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appTheme = context.appTheme;

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(top: BorderSide(color: appTheme.borderColor)),
        ),
        child: Row(
          children: [
            _RoundIconButton(
              icon: Icons.add,
              onPressed: () {},
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: hintText,
                  filled: true,
                  fillColor: theme.scaffoldBackgroundColor,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.s14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: AppRadius.circularPill,
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: AppRadius.circularPill,
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: AppRadius.circularPill,
                    borderSide: BorderSide(
                      color: theme.colorScheme.primary,
                      width: 1.5,
                    ),
                  ),
                ),
                onSubmitted: (text) => _sendMessage(context, text),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Consumer<SubscriptionProvider>(
              builder: (context, subscriptionProvider, _) {
                final canUseSpeech = subscriptionProvider.canUseSpeechInput();
                return _RoundIconButton(
                  icon: Icons.mic,
                  onPressed: canUseSpeech
                      ? () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Speech input coming soon'),
                            ),
                          );
                        }
                      : () {
                          showDialog(
                            context: context,
                            builder: (context) => UpgradePromptDialog(
                              requiredTier: SubscriptionTier.pro,
                              featureName: 'Speech input',
                            ),
                          );
                        },
                );
              },
            ),
            const SizedBox(width: AppSpacing.sm),
            _RoundIconButton(
              icon: Icons.arrow_upward,
              backgroundColor: theme.colorScheme.primary,
              iconColor: theme.colorScheme.onPrimary,
              onPressed: () => _sendMessage(context, controller.text),
            ),
          ],
        ),
      ),
    );
  }

  void _sendMessage(BuildContext context, String text) {
    final trimmed = text.trim();
    if (trimmed.isNotEmpty) {
      context.read<ChatProvider>().sendMessage(trimmed);
      controller.clear();
      onMessageSent?.call();
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

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.onPressed,
    this.backgroundColor,
    this.iconColor,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appTheme = context.appTheme;

    return Material(
      color: backgroundColor ?? theme.colorScheme.surface,
      shape: CircleBorder(
        side: backgroundColor == null
            ? BorderSide(color: appTheme.borderColor)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(
            icon,
            size: 20,
            color: iconColor ?? theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}
