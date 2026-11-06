import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:projectbrain/helpers/themes/app_theme_extension.dart';
import 'package:projectbrain/widgets/ds/goal_row.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(
        theme: ThemeData(extensions: [AppThemeExtension.light()]),
        home: Scaffold(body: Center(child: child)),
      );

  testWidgets('goal checkbox is a labelled, checkable 48dp target',
      (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      wrap(GoalRow(title: 'Drink water', completed: true, onToggle: () {})),
    );

    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    expect(
      tester.getSemantics(find.bySemanticsLabel('Drink water').first),
      matchesSemantics(
        label: 'Drink water',
        hasCheckedState: true,
        isChecked: true,
        hasEnabledState: true,
        isEnabled: true,
        hasTapAction: true,
      ),
    );
    handle.dispose();
  });
}
