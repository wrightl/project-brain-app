import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:projectbrain/main.dart' as app;
import 'package:projectbrain/widgets/custom_bottom_nav_bar.dart';

/// Launch smoke test, run on a device or simulator with a real `.env.dev`:
///
///   flutter test integration_test --dart-define-from-file=.env.dev
///
/// Signed out, the app must get past the loading screen to sign-in; with a
/// saved session it may land on Home instead. Either proves bootstrap
/// (config, Firebase, DI, router) completes without throwing.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('app starts and reaches sign-in or home', (tester) async {
    unawaited(app.main());

    // The loading screen animates continuously, so pumpAndSettle would never
    // settle; poll instead.
    final signIn = find.text('Login / Sign Up');
    final home = find.byType(CustomBottomNavBar);
    final deadline = DateTime.now().add(const Duration(seconds: 30));
    while (DateTime.now().isBefore(deadline) &&
        signIn.evaluate().isEmpty &&
        home.evaluate().isEmpty) {
      await tester.pump(const Duration(milliseconds: 250));
    }

    expect(
      signIn.evaluate().isNotEmpty || home.evaluate().isNotEmpty,
      isTrue,
      reason: 'App did not reach the sign-in screen or home within 30s',
    );
  });
}
