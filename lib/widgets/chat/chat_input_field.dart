import 'dart:async';

import 'package:flutter/material.dart';
import 'package:projectbrain/chat/chat_provider.dart';
import 'package:projectbrain/widgets/chat/chat_composer.dart';
import 'package:provider/provider.dart';

/// AI chat input: a [ChatComposer] wired to [ChatProvider].
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
    // While a reply streams the user can keep typing, but sending waits.
    final isSending = context.select<ChatProvider, bool>((p) => p.isSending);

    return ChatComposer(
      controller: controller,
      hintText: hintText,
      isBusy: isSending,
      onSend: (text) => _sendMessage(context, text),
    );
  }

  void _sendMessage(BuildContext context, String text) {
    final chatProvider = context.read<ChatProvider>();
    // The provider drops a send while a reply is streaming; keep the text so
    // it is not lost.
    if (chatProvider.isSending) return;
    unawaited(chatProvider.sendMessage(text));
    controller.clear();
    onMessageSent?.call();

    final scroll = scrollController;
    if (scroll == null) return;
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!scroll.hasClients) return;
      final end = scroll.position.maxScrollExtent;
      if (reduceMotion) {
        scroll.jumpTo(end);
      } else {
        unawaited(scroll.animateTo(
          end,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        ));
      }
    });
  }
}
