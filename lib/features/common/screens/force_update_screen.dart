import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/l10n/language_provider.dart';

// ---------------------------------------------------------------------------
// Store URLs
// ---------------------------------------------------------------------------
const _kPlayStoreMarketUrl =
    'market://details?id=com.sanadtherapy.app';
const _kPlayStoreFallbackUrl =
    'https://play.google.com/store/apps/details?id=com.sanadtherapy.app';

// TODO(release): Replace id0 with the actual Apple App Store numeric ID for
// com.sanad.sanadApp once the app is live on the App Store.
const _kAppStoreUrl = 'https://apps.apple.com/app/id0';

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

/// Blocking gate shown when the running app version is below
/// [SystemSettings.minAppVersion] stored in Firestore.
///
/// Cannot be dismissed — [PopScope.canPop] is `false`.
/// On Android, attempts an in-app immediate update via Google Play;
/// falls back to launching the store URL on any error or on other platforms.
class ForceUpdateScreen extends ConsumerStatefulWidget {
  const ForceUpdateScreen({super.key});

  @override
  ConsumerState<ForceUpdateScreen> createState() => _ForceUpdateScreenState();
}

class _ForceUpdateScreenState extends ConsumerState<ForceUpdateScreen> {
  bool _isLoading = false;

  Future<void> _handleUpdate() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      if (Platform.isAndroid) {
        await _tryInAppUpdate();
        return;
      }
    } catch (_) {
      // Fall through to store URL
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }

    await _launchStore();
  }

  Future<void> _tryInAppUpdate() async {
    final info = await InAppUpdate.checkForUpdate();
    if (info.updateAvailability == UpdateAvailability.updateAvailable) {
      await InAppUpdate.performImmediateUpdate();
      // If we reach here, the update dialog was dismissed without installing.
      // Fall back to the store URL.
    }
    // updateAvailability is not `updateAvailable` (e.g. already latest
    // according to Play, or no network) — open store as fallback.
    await _launchStore();
  }

  Future<void> _launchStore() async {
    final storeUrl = Platform.isAndroid
        ? _kPlayStoreMarketUrl
        : _kAppStoreUrl;

    final uri = Uri.parse(storeUrl);
    final launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!launched && mounted) {
      // market:// URI failed on Android — try the web fallback
      if (Platform.isAndroid) {
        final fallback = Uri.parse(_kPlayStoreFallbackUrl);
        final webLaunched = await launchUrl(
          fallback,
          mode: LaunchMode.externalApplication,
        );
        if (!webLaunched && mounted) {
          _showManualUrlSnack(_kPlayStoreFallbackUrl);
        }
      } else {
        _showManualUrlSnack(_kAppStoreUrl);
      }
    }
  }

  void _showManualUrlSnack(String url) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(url),
        duration: const Duration(seconds: 6),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final strings = ref.watch(stringsProvider);

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor:
            isDark ? const Color(0xFF0F172A) : Colors.white,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon
                  Icon(
                    Icons.system_update_rounded,
                    size: 88,
                    color: AppColors.primary.withValues(alpha: 0.9),
                  ),
                  const SizedBox(height: 32),

                  // Headline
                  Text(
                    strings.forceUpdateTitle,
                    style: AppTypography.headingLarge.copyWith(
                      color:
                          isDark ? Colors.white : const Color(0xFF0F172A),
                      fontWeight: FontWeight.w800,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),

                  // Body
                  Text(
                    strings.forceUpdateBody,
                    style: AppTypography.bodyLarge.copyWith(
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                      height: 1.6,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),

                  // CTA button — no skip, no dismiss
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleUpdate,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            AppColors.primary.withValues(alpha: 0.5),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              strings.forceUpdateButton,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
