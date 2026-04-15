import 'package:flutter/material.dart';

/// Global navigation service for handling deep links and notifications
/// Allows navigation from background contexts where BuildContext is not available
class NavigationService {
  /// Global navigator key for accessing navigator state from anywhere
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  /// Navigate to a named route
  ///
  /// [route]: The route path (e.g., '/therapist-chat/123')
  /// [extra]: Optional data to pass to the route
  static Future<void> navigateTo(String route, {Object? extra}) async {
    final navigator = navigatorKey.currentState;
    if (navigator == null) {
      debugPrint('NavigationService: Navigator not ready, cannot navigate to $route');
      return;
    }

    try {
      if (extra != null) {
        await navigator.pushNamed(route, arguments: extra);
      } else {
        await navigator.pushNamed(route);
      }
    } catch (e) {
      debugPrint('NavigationService: Error navigating to $route: $e');
    }
  }

  /// Navigate and replace current route
  static Future<void> navigateAndReplace(String route, {Object? extra}) async {
    final navigator = navigatorKey.currentState;
    if (navigator == null) return;

    try {
      if (extra != null) {
        await navigator.pushReplacementNamed(route, arguments: extra);
      } else {
        await navigator.pushReplacementNamed(route);
      }
    } catch (e) {
      debugPrint('NavigationService: Error replacing route with $route: $e');
    }
  }

  /// Pop current route
  static void pop([Object? result]) {
    final navigator = navigatorKey.currentState;
    if (navigator == null || !navigator.canPop()) return;

    navigator.pop(result);
  }

  /// Check if we can pop
  static bool canPop() {
    final navigator = navigatorKey.currentState;
    return navigator?.canPop() ?? false;
  }
}
