import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Asks before leaving a screen that has unsaved changes.
///
/// Covers the system back gesture and button. On-screen close/back buttons
/// should call `Navigator.maybePop(context)` so they are covered too
/// (`Navigator.pop` and `context.pop()` skip the check).
class UnsavedChangesScope extends StatelessWidget {
  const UnsavedChangesScope({
    super.key,
    required this.hasUnsavedChanges,
    required this.child,
    this.message = 'You have changes that have not been saved.',
    this.isDirty,
  });

  /// Whether leaving needs a check. When [isDirty] is given, this only needs
  /// to say a form is open; [isDirty] then decides at pop time whether to ask.
  final bool hasUnsavedChanges;

  /// Optional precise check, run when the user tries to leave.
  final bool Function()? isDirty;

  final String message;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return PopScope<Object?>(
      canPop: !hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final dirty = isDirty?.call() ?? true;
        final discard =
            !dirty || await confirmDiscardChanges(context, message: message);
        if (!discard || !context.mounted) return;
        final navigator = Navigator.of(context);
        if (navigator.canPop()) {
          navigator.pop(result);
        } else {
          // Nothing to go back to: the back press would have left the app.
          await SystemNavigator.pop();
        }
      },
      child: child,
    );
  }
}

/// Shows a "Discard changes?" dialog. Returns true when the user chooses to
/// discard.
Future<bool> confirmDiscardChanges(
  BuildContext context, {
  String message = 'You have changes that have not been saved.',
}) async {
  final discard = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Discard changes?'),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Keep editing'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text('Discard'),
        ),
      ],
    ),
  );
  return discard == true;
}
