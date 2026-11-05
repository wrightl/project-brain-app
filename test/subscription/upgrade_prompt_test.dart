import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:projectbrain/models/subscription.dart';
import 'package:projectbrain/subscription/widgets/upgrade_prompt.dart';

void main() {
  testWidgets('names the required tier', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: UpgradePromptDialog(
            requiredTier: SubscriptionTier.pro,
            featureName: 'Coach connections',
          ),
        ),
      ),
    );

    expect(find.text('Coach connections requires Pro tier'), findsOneWidget);
    expect(find.textContaining('Closure'), findsNothing);
  });
}
