import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:projectbrain/widgets/unsaved_changes_scope.dart';

void main() {
  Future<void> openGuardedPage(
    WidgetTester tester, {
    required bool hasUnsavedChanges,
    bool Function()? isDirty,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => UnsavedChangesScope(
                    hasUnsavedChanges: hasUnsavedChanges,
                    isDirty: isDirty,
                    child: const Scaffold(body: Text('Form')),
                  ),
                ),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  Future<void> pressBack(WidgetTester tester) async {
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    await navigator.maybePop();
    await tester.pumpAndSettle();
  }

  testWidgets('leaves straight away without changes', (tester) async {
    await openGuardedPage(tester, hasUnsavedChanges: false);

    await pressBack(tester);

    expect(find.text('Form'), findsNothing);
    expect(find.text('Discard changes?'), findsNothing);
  });

  testWidgets('asks first, and stays on "Keep editing"', (tester) async {
    await openGuardedPage(tester, hasUnsavedChanges: true);

    await pressBack(tester);
    expect(find.text('Discard changes?'), findsOneWidget);

    await tester.tap(find.text('Keep editing'));
    await tester.pumpAndSettle();
    expect(find.text('Form'), findsOneWidget);
  });

  testWidgets('leaves after "Discard"', (tester) async {
    await openGuardedPage(tester, hasUnsavedChanges: true);

    await pressBack(tester);
    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();

    expect(find.text('Form'), findsNothing);
  });

  testWidgets('skips the dialog when isDirty says nothing changed',
      (tester) async {
    await openGuardedPage(
      tester,
      hasUnsavedChanges: true,
      isDirty: () => false,
    );

    await pressBack(tester);

    expect(find.text('Discard changes?'), findsNothing);
    expect(find.text('Form'), findsNothing);
  });
}
