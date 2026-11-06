import 'package:flutter/material.dart';
import 'package:projectbrain/helpers/themes/app_spacing.dart';
import 'package:projectbrain/helpers/themes/app_theme_extension.dart';

/// Message input bar shared by the AI, coping-strategies and coach chats.
///
/// The field stays editable while [isBusy] (so people can type their next
/// message); only sending waits. [onSend] gets the trimmed text and decides
/// whether to clear [controller], so text is never lost when a send is
/// refused.
class ChatComposer extends StatelessWidget {
  const ChatComposer({
    super.key,
    required this.controller,
    required this.onSend,
    this.hintText = 'Type a message...',
    this.semanticsLabel = 'Message',
    this.isBusy = false,
    this.showBusySpinner = false,
    this.leading,
  });

  final TextEditingController controller;
  final ValueChanged<String> onSend;
  final String hintText;

  /// Kept as the field's label once the hint disappears while typing.
  final String semanticsLabel;

  /// Disables sending, e.g. while a reply streams or a message uploads.
  final bool isBusy;

  /// Shows a spinner in the send button while [isBusy].
  final bool showBusySpinner;

  /// Optional control before the field (e.g. a record button).
  final Widget? leading;

  void _submit() {
    if (isBusy) return;
    final text = controller.text.trim();
    if (text.isEmpty) return;
    onSend(text);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appTheme = context.appTheme;
    final pillBorder = OutlineInputBorder(
      borderRadius: AppRadius.circularPill,
      borderSide: BorderSide.none,
    );

    return SafeArea(
      top: false,
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
            if (leading != null) leading!,
            Expanded(
              child: Semantics(
                label: semanticsLabel,
                child: TextField(
                  controller: controller,
                  minLines: 1,
                  maxLines: 5,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _submit(),
                  decoration: InputDecoration(
                    hintText: hintText,
                    filled: true,
                    fillColor: theme.scaffoldBackgroundColor,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.s14,
                    ),
                    border: pillBorder,
                    enabledBorder: pillBorder,
                    focusedBorder: OutlineInputBorder(
                      borderRadius: AppRadius.circularPill,
                      borderSide: BorderSide(
                        color: theme.colorScheme.primary,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            _SendButton(
              onPressed: isBusy ? null : _submit,
              showSpinner: isBusy && showBusySpinner,
            ),
          ],
        ),
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  const _SendButton({required this.onPressed, required this.showSpinner});

  final VoidCallback? onPressed;
  final bool showSpinner;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enabled = onPressed != null;

    return Tooltip(
      message: 'Send',
      child: Material(
        color: enabled
            ? theme.colorScheme.primary
            : theme.colorScheme.primary.withValues(alpha: 0.4),
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 48,
            height: 48,
            child: Center(
              child: showSpinner
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        semanticsLabel: 'Sending',
                        strokeWidth: 2,
                        color: theme.colorScheme.onPrimary,
                      ),
                    )
                  : Icon(
                      Icons.arrow_upward,
                      size: 20,
                      color: theme.colorScheme.onPrimary,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
