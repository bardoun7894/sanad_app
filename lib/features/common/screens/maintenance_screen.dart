import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/l10n/language_provider.dart';
import '../../../core/providers/system_settings_provider.dart';
import '../../../routes/app_routes.dart';
import '../../auth/providers/auth_provider.dart';

class MaintenanceScreen extends ConsumerWidget {
  const MaintenanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final strings = ref.watch(stringsProvider);
    final userId = ref.watch(authProvider).user?.uid;
    final settingsAsync = ref.watch(systemSettingsProvider);

    return Scaffold(
      // TOKEN GAP: 0xFF0F172A has no exact AppColors token (backgroundDark=0xFF0B0F19, textDark=0xFF1E293B — both differ).
      // Keeping literal until a design-token pass adds AppColors.backgroundDeepSlate or similar.
      backgroundColor: isDark ? const Color(0xFF0F172A) : AppColors.surface,
      body: SafeArea(
        child: settingsAsync.when(
          data: (settings) {
            // Poll: if maintenance is off, redirect to home via GoRouter
            // (Navigator.pushReplacementNamed silently fails inside a GoRouter tree)
            if (!settings.maintenanceMode) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (context.mounted) context.go(AppRoutes.home);
              });
              return const SizedBox.shrink();
            }

            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.construction_rounded,
                      size: 80,
                      // TOKEN GAP: Colors.orange has no exact AppColors token.
                      // AppColors.warning=0xFFF59E0B (amber) is visually different from orange.
                      // Keeping literal until design tokens add AppColors.statusOrange or similar.
                      color: Colors.orange.withValues(alpha: 0.8),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      strings.maintenanceTitle,
                      style: AppTypography.headingLarge.copyWith(
                        // TOKEN GAP: 0xFF0F172A (dark text) has no exact token — see scaffold bg note above.
                        color: isDark ? AppColors.textLight : const Color(0xFF0F172A),
                        fontWeight: FontWeight.w800,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      strings.maintenanceBody,
                      style: AppTypography.bodyLarge.copyWith(
                        color: isDark ? AppColors.textMuted : AppColors.textSecondary,
                        height: 1.6,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (userId != null) ...[
                      const SizedBox(height: 40),
                      _NotifyButton(userId: userId),
                    ],
                    const SizedBox(height: 24),
                    Text(
                      strings.supportEmailSetting,
                      style: AppTypography.bodySmall.copyWith(
                        color: isDark ? AppColors.textSecondary : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) {
            // Fail-open: transient Firestore error should not strand the user.
            // Mirror the maintenance-off redirect pattern (line 31-34 above).
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) context.go(AppRoutes.home);
            });
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

class _NotifyButton extends ConsumerStatefulWidget {
  final String userId;

  const _NotifyButton({required this.userId});

  @override
  ConsumerState<_NotifyButton> createState() => _NotifyButtonState();
}

class _NotifyButtonState extends ConsumerState<_NotifyButton> {
  bool _subscribed = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _checkSubscription();
  }

  Future<void> _checkSubscription() async {
    final doc = await FirebaseFirestore.instance
        .collection('maintenance_subscribers')
        .doc(widget.userId)
        .get();
    if (mounted && doc.exists) {
      setState(() => _subscribed = true);
    }
  }

  Future<void> _subscribe() async {
    setState(() => _loading = true);
    try {
      final token = await FirebaseMessaging.instance.getToken();
      await FirebaseFirestore.instance
          .collection('maintenance_subscribers')
          .doc(widget.userId)
          .set({
        'fcm_token': token,
        'subscribed_at': FieldValue.serverTimestamp(),
      });
      if (mounted) setState(() => _subscribed = true);
    } catch (_) {
      // Non-critical
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(stringsProvider);

    if (_subscribed) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              strings.notifySubscribed,
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return ElevatedButton.icon(
      onPressed: _loading ? null : _subscribe,
      icon: _loading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.notifications_outlined),
      label: Text(strings.notifyWhenBack),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
