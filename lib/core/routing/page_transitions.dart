import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:projectbrain/core/logging/app_logger.dart';

/// Reusable page transition utilities for go_router
class PageTransitions {
  /// Creates a slide-left transition (page slides in from right)
  ///
  /// This is commonly used for "back" navigation where the new page
  /// appears to slide in from the right, creating a slide-left effect.
  ///
  /// [duration] - Duration of the transition (default: 300ms)
  /// [curve] - Animation curve (default: Curves.easeInOut)
  static Page<T> slideLeft<T extends Object?>({
    required LocalKey key,
    required Widget child,
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeInOut,
  }) {
    return CustomTransitionPage<T>(
      key: key,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0), // Start from right
            end: Offset.zero, // End at center
          ).animate(CurvedAnimation(
            parent: animation,
            curve: curve,
          )),
          child: child,
        );
      },
      transitionDuration: duration,
      reverseTransitionDuration: duration,
    );
  }

  /// Creates a slide-right transition (page slides in from left)
  ///
  /// This is commonly used for "forward" navigation where the new page
  /// appears to slide in from the left, creating a slide-right effect.
  ///
  /// [duration] - Duration of the transition (default: 300ms)
  /// [curve] - Animation curve (default: Curves.easeInOut)
  static Page<T> slideRight<T extends Object?>({
    required LocalKey key,
    required Widget child,
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeInOut,
  }) {
    return CustomTransitionPage<T>(
      key: key,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(-1.0, 0.0), // Start from left
            end: Offset.zero, // End at center
          ).animate(CurvedAnimation(
            parent: animation,
            curve: curve,
          )),
          child: child,
        );
      },
      transitionDuration: duration,
      reverseTransitionDuration: duration,
    );
  }

  /// Creates a fade transition
  ///
  /// [duration] - Duration of the transition (default: 300ms)
  /// [curve] - Animation curve (default: Curves.easeInOut)
  static Page<T> fade<T extends Object?>({
    required LocalKey key,
    required Widget child,
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeInOut,
  }) {
    return CustomTransitionPage<T>(
      key: key,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: curve,
          ),
          child: child,
        );
      },
      transitionDuration: duration,
      reverseTransitionDuration: duration,
    );
  }

  /// Creates a scale transition (page scales in)
  ///
  /// [duration] - Duration of the transition (default: 300ms)
  /// [curve] - Animation curve (default: Curves.easeInOut)
  static Page<T> scale<T extends Object?>({
    required LocalKey key,
    required Widget child,
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeInOut,
  }) {
    return CustomTransitionPage<T>(
      key: key,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: CurvedAnimation(
            parent: animation,
            curve: curve,
          ),
          child: child,
        );
      },
      transitionDuration: duration,
      reverseTransitionDuration: duration,
    );
  }

  /// Helper to create a page builder that conditionally applies a transition
  ///
  /// [condition] - Function that determines if transition should be applied
  /// [transition] - The transition to apply if condition is true
  /// [defaultPage] - The default page to use if condition is false
  static Page<T> Function(BuildContext, GoRouterState)
      conditional<T extends Object?>(
    bool Function(GoRouterState) condition,
    Page<T> Function(GoRouterState) transition,
    Page<T> Function(GoRouterState) defaultPage,
  ) {
    return (context, state) {
      final shouldApplyTransition = condition(state);
      logDebug(
          '[PageTransitions] Conditional check: $shouldApplyTransition, URI: ${state.uri}, QueryParams: ${state.uri.queryParameters}, Extra: ${state.extra}');
      if (shouldApplyTransition) {
        logDebug('[PageTransitions] Applying custom transition');
        return transition(state);
      }
      logDebug('[PageTransitions] Using default transition');
      return defaultPage(state);
    };
  }
}
