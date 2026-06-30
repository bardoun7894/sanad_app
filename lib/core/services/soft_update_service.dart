import 'dart:io';

import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../l10n/language_provider.dart';

const _kPlayStoreMarketUrl = 'market://details?id=com.sanadtherapy.app';
const _kPlayStoreFallbackUrl =
    'https://play.google.com/store/apps/details?id=com.sanadtherapy.app';

/// Optional, **dismissible** "a new version is available" prompt.
///
/// Distinct from the hard [ForceUpdateScreen] gate: this fires whenever the
/// Play Store has a newer build than the installed one — regardless of
/// `min_app_version` — and the user can defer it with "Later". Unlike the hard
/// gate it is also shown to admins, so the team actually sees the prompt their
/// users see.
///
/// Android-only (the `in_app_update` plugin is Android-only). Checks at most
/// once per app session.
class SoftUpdateService {
  SoftUpdateService._();

  static bool _checkedThisSession = false;

  /// Reset the once-per-session guard. For tests only.
  @visibleForTesting
  static void resetForTest() => _checkedThisSession = false;

  /// Checks for an available update and, if one exists, shows a dismissible
  /// prompt. Safe to call from a widget's `initState` via a post-frame
  /// callback. Never throws — all failures are swallowed so a flaky Play
  /// lookup can never disrupt the app.
  static Future<void> maybePrompt(
    BuildContext context,
    S strings,
  ) async {
    if (!Platform.isAndroid) return;
    if (_checkedThisSession) return;
    _checkedThisSession = true;

    try {
      final info = await InAppUpdate.checkForUpdate();
      if (info.updateAvailability != UpdateAvailability.updateAvailable) {
        return;
      }
      if (!context.mounted) return;
      await _showPrompt(context, strings, info);
    } catch (_) {
      // No network, not installed from Play, etc. — stay silent.
    }
  }

  /// MANDATORY, blocking update check run automatically on startup.
  ///
  /// Whenever Google Play reports a newer build than the installed one, this
  /// forces the user to update before they can keep using the app:
  ///   1. If Play allows an **immediate** in-app update, it launches Google's
  ///      own full-screen, non-dismissible update flow.
  ///   2. Otherwise it shows our own **non-dismissible** dialog whose only
  ///      action opens the store — the user cannot continue without updating.
  ///
  /// This is independent of the `min_app_version` Firestore gate (which is the
  /// admin-controlled override). Together they guarantee old clients are
  /// blocked both automatically (Play) and on demand (admin).
  ///
  /// Android-only. Never throws — a flaky/absent Play lookup (e.g. sideloaded
  /// build, no network) fails OPEN so the app is never bricked. Checks at most
  /// once per session.
  static Future<void> enforceMandatoryUpdate(
    BuildContext context,
    S strings,
  ) async {
    if (!Platform.isAndroid) return;
    if (_checkedThisSession) return;
    _checkedThisSession = true;

    try {
      final info = await InAppUpdate.checkForUpdate();
      if (info.updateAvailability != UpdateAvailability.updateAvailable) {
        return;
      }

      // Preferred path: Google's blocking immediate update.
      if (info.immediateUpdateAllowed) {
        await InAppUpdate.performImmediateUpdate();
        return;
      }

      // Fallback: our own non-dismissible gate.
      if (!context.mounted) return;
      await _showMandatoryPrompt(context, strings, info);
    } catch (_) {
      // No Play, no network, sideloaded — stay silent, never block.
    }
  }

  static Future<void> _showMandatoryPrompt(
    BuildContext context,
    S strings,
    AppUpdateInfo info,
  ) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        // Block the system back button — the user must update.
        canPop: false,
        child: AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1F2A33) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.system_update_rounded,
                  color: AppColors.primary, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  strings.updateAvailableTitle,
                  style: AppTypography.headingSmall.copyWith(
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            strings.updateAvailableBody,
            style: AppTypography.bodyMedium.copyWith(
              color: isDark ? Colors.white70 : const Color(0xFF64748B),
              height: 1.5,
            ),
          ),
          actions: [
            // Only one action — no "Later". Re-shows itself until updated.
            TextButton(
              onPressed: () async {
                await _startUpdate(info);
                // If the user backs out of the store without updating, the
                // dialog stays (we never popped it). Re-assert on next frame.
              },
              child: Text(
                strings.updateNow,
                style: AppTypography.labelLarge.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// User-initiated "Check for updates" — unlike [maybePrompt] this always
  /// gives feedback: it shows the update prompt when one exists, an
  /// "up to date" message when none does, and a "couldn't check" message
  /// (with a store fallback) on error. Bypasses the once-per-session guard.
  ///
  /// On non-Android platforms (where `in_app_update` is unavailable) it opens
  /// the store directly.
  static Future<void> checkManually(
    BuildContext context,
    S strings,
  ) async {
    if (!Platform.isAndroid) {
      await _launchStore();
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      SnackBar(content: Text(strings.checkingForUpdate)),
    );

    try {
      final info = await InAppUpdate.checkForUpdate();
      if (!context.mounted) return;
      if (info.updateAvailability == UpdateAvailability.updateAvailable) {
        await _showPrompt(context, strings, info);
      } else {
        messenger.showSnackBar(
          SnackBar(content: Text(strings.alreadyUpToDate)),
        );
      }
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(content: Text(strings.updateCheckFailed)),
      );
    }
  }

  static Future<void> _showPrompt(
    BuildContext context,
    S strings,
    AppUpdateInfo info,
  ) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1F2A33) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.system_update_rounded,
                color: AppColors.primary, size: 24),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                strings.updateAvailableTitle,
                style: AppTypography.headingSmall.copyWith(
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ),
          ],
        ),
        content: Text(
          strings.updateAvailableBody,
          style: AppTypography.bodyMedium.copyWith(
            color: isDark ? Colors.white70 : const Color(0xFF64748B),
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              strings.updateLater,
              style: AppTypography.labelLarge.copyWith(
                color: isDark ? Colors.white54 : const Color(0xFF94A3B8),
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await _startUpdate(info);
            },
            child: Text(
              strings.updateNow,
              style: AppTypography.labelLarge.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Future<void> _startUpdate(AppUpdateInfo info) async {
    try {
      if (info.immediateUpdateAllowed) {
        await InAppUpdate.performImmediateUpdate();
        return;
      }
      if (info.flexibleUpdateAllowed) {
        await InAppUpdate.startFlexibleUpdate();
        await InAppUpdate.completeFlexibleUpdate();
        return;
      }
    } catch (_) {
      // Fall through to opening the store.
    }
    await _launchStore();
  }

  static Future<void> _launchStore() async {
    try {
      final launched = await launchUrl(
        Uri.parse(_kPlayStoreMarketUrl),
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        await launchUrl(
          Uri.parse(_kPlayStoreFallbackUrl),
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (_) {
      // Give up silently.
    }
  }
}
