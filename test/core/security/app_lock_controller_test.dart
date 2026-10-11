import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:projectbrain/core/security/app_lock_controller.dart';

void main() {
  late DateTime now;
  late bool lockEnabled;
  late bool authenticateResult;
  late int authenticateCalls;
  late AppLockController controller;

  setUp(() {
    now = DateTime(2026, 10, 11, 12);
    lockEnabled = true;
    authenticateResult = true;
    authenticateCalls = 0;
    controller = AppLockController(
      isLockEnabled: () => lockEnabled,
      authenticate: () async {
        authenticateCalls++;
        return authenticateResult;
      },
      relockAfter: const Duration(minutes: 1),
      now: () => now,
    );
  });

  void background(Duration duration) {
    controller.handleLifecycleState(AppLifecycleState.inactive);
    controller.handleLifecycleState(AppLifecycleState.hidden);
    controller.handleLifecycleState(AppLifecycleState.paused);
    now = now.add(duration);
    controller.handleLifecycleState(AppLifecycleState.hidden);
    controller.handleLifecycleState(AppLifecycleState.inactive);
    controller.handleLifecycleState(AppLifecycleState.resumed);
  }

  group('AppLockController privacy overlay', () {
    test('obscures content while inactive and clears it on resume', () {
      controller.handleLifecycleState(AppLifecycleState.inactive);
      expect(controller.isObscured, isTrue);

      controller.handleLifecycleState(AppLifecycleState.resumed);
      expect(controller.isObscured, isFalse);
    });

    test('obscures content even when biometric lock is off', () {
      lockEnabled = false;
      controller.handleLifecycleState(AppLifecycleState.paused);

      expect(controller.isObscured, isTrue);
    });
  });

  group('AppLockController re-lock', () {
    test('locks after a background longer than relockAfter', () {
      background(const Duration(minutes: 2));

      expect(controller.isLocked, isTrue);
    });

    test('does not lock after a short background', () {
      background(const Duration(seconds: 30));

      expect(controller.isLocked, isFalse);
    });

    test('does not lock when biometric unlock is disabled', () {
      lockEnabled = false;
      background(const Duration(minutes: 5));

      expect(controller.isLocked, isFalse);
    });

    test('an inactive-only interruption (Face ID sheet) never locks', () {
      controller.handleLifecycleState(AppLifecycleState.inactive);
      now = now.add(const Duration(minutes: 5));
      controller.handleLifecycleState(AppLifecycleState.resumed);

      expect(controller.isLocked, isFalse);
    });

    test('timer restarts after each foreground visit', () {
      background(const Duration(seconds: 50));
      background(const Duration(seconds: 50));

      expect(controller.isLocked, isFalse);
    });
  });

  group('AppLockController unlock', () {
    test('successful authentication unlocks', () async {
      background(const Duration(minutes: 2));

      await controller.unlock();

      expect(controller.isLocked, isFalse);
      expect(authenticateCalls, 1);
    });

    test('failed authentication stays locked', () async {
      authenticateResult = false;
      background(const Duration(minutes: 2));

      await controller.unlock();

      expect(controller.isLocked, isTrue);
      expect(controller.isUnlocking, isFalse);
    });

    test('unlock does nothing when not locked', () async {
      await controller.unlock();

      expect(authenticateCalls, 0);
    });

    test('concurrent unlock taps prompt only once', () async {
      background(const Duration(minutes: 2));

      await Future.wait([controller.unlock(), controller.unlock()]);

      expect(authenticateCalls, 1);
    });
  });
}
