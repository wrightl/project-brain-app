import 'package:flutter/material.dart';
import 'package:projectbrain/chat/chat_provider.dart';
import 'package:provider/provider.dart';

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
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 4.0,
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
