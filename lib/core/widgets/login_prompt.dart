import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../l10n/language_provider.dart';
import '../theme/app_colors.dart';
import '../../routes/app_router.dart';
import '../../features/auth/providers/auth_provider.dart';

/// Shows a login prompt dialog for guest users trying to access protected features
Future<bool?> showLoginPrompt(
  BuildContext context, {
  required String feature,
  String? description,
}) async {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => LoginPromptSheet(
      feature: feature,
      description: description,
    ),
  );
}

/// Login prompt bottom sheet widget
class LoginPromptSheet extends ConsumerWidget {
  final String feature;
  final String? description;

  const LoginPromptSheet({
    super.key,
    required this.feature,
    this.description,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[700] : Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),

              // Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_outline_rounded,
                  size: 40,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 20),

              // Title
              Text(
                s.loginRequired,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppColors.textLight,
                ),
              ),
              const SizedBox(height: 12),

              // Description
              Text(
                description ?? s.loginToAccessFeature(feature),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: isDark ? AppColors.textDark : AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),

              // Login button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context, true);
                    context.push(AppRoutes.login);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    s.login,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Sign up button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context, true);
                    context.push(AppRoutes.signup);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: BorderSide(
                      color: isDark ? AppColors.primary : AppColors.primary.withValues(alpha: 0.5),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    s.createAccount,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Continue as guest
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  s.continueAsGuest,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? AppColors.textDark : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A widget that wraps content and shows login prompt when tapped by guest users
class GuestGuard extends ConsumerWidget {
  final Widget child;
  final String feature;
  final String? description;
  final VoidCallback? onAuthenticated;

  const GuestGuard({
    super.key,
    required this.child,
    required this.feature,
    this.description,
    this.onAuthenticated,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return child;
  }

  /// Check if user is authenticated and show login prompt if not
  static Future<bool> checkAuth(
    BuildContext context,
    WidgetRef ref, {
    required String feature,
    String? description,
  }) async {
    final authState = ref.read(authProvider);

    if (authState.status == AuthStatus.authenticated) {
      return true;
    }

    final result = await showLoginPrompt(
      context,
      feature: feature,
      description: description,
    );

    return result == true;
  }
}
