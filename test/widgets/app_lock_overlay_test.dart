import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:projectbrain/authentication/auth_provider.dart';
import 'package:projectbrain/core/security/app_lock_controller.dart';
import 'package:projectbrain/widgets/app_lock_overlay.dart';
import 'package:provider/provider.dart';

class MockAuthProvider extends Mock implements AuthProvider {}

void main() {
  late AppLockController lock;
  late MockAuthProvider auth;
  late DateTime now;
  var tapped = false;

  setUp(() {
    now = DateTime(2026, 11, 5, 12);
    tapped = false;
    lock = AppLockController(
      isLockEnabled: () => true,
      authenticate: () async => false,
      relockAfter: const Duration(minutes: 1),
      now: () => now,
    );
    auth = MockAuthProvider();
    when(() => auth.isLoggedIn).thenReturn(true);
    when(() => auth.biometricUnlockLabel).thenReturn('Unlock with Face ID');
  });

  Future<void> pump(WidgetTester tester) => tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AppLockController>.value(value: lock),
            ChangeNotifierProvider<AuthProvider>.value(value: auth),
          ],
          child: MaterialApp(
            home: AppLockOverlay(
              child: Scaffold(
                body: TextButton(
                  onPressed: () => tapped = true,
                  child: const Text('Private journal entry'),
                ),
              ),
            ),
          ),
        ),
      );

  void lockApp() {
    lock.handleLifecycleState(AppLifecycleState.paused);
    now = now.add(const Duration(minutes: 5));
    lock.handleLifecycleState(AppLifecycleState.resumed);
  }

  testWidgets('content is readable when unlocked', (tester) async {
    final semantics = tester.ensureSemantics();
    await pump(tester);

    expect(find.semantics.byLabel('Private journal entry'), findsOne);
    semantics.dispose();
  });

  testWidgets('screen readers cannot reach content behind the lock',
      (tester) async {
    final semantics = tester.ensureSemantics();
    await pump(tester);
    lockApp();
    await tester.pump();

    expect(find.text('Project Brain is locked'), findsOneWidget);
    // find.semantics searches the semantics tree, not the widget tree.
    expect(find.semantics.byLabel('Private journal entry'), findsNothing);
    expect(find.semantics.byLabel('Project Brain is locked'), findsOne);

    await tester.tap(find.text('Private journal entry'), warnIfMissed: false);
    expect(tapped, isFalse);
    semantics.dispose();
  });
}
