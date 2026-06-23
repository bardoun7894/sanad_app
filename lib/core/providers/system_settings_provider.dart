import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SystemSettings {
  final bool enableTherapistApplication;
  final bool maintenanceMode;
  final String minAppVersion;
  final String contactEmail;

  /// When true, card payments (Freemius) run against the SANDBOX environment
  /// instead of live — no real money is charged. Admin-controlled from the
  /// dashboard so the live gateway can be verified without a code release.
  final bool paymentTestMode;

  /// Whether the PayPal option is shown on the payment-method screen.
  /// Admin-controlled — lets the dashboard hide PayPal (e.g. while it's still
  /// in sandbox) without an app release. Defaults to visible.
  final bool paypalEnabled;

  /// Whether the Google Pay / Apple Pay (native wallet) option is shown on the
  /// payment-method screen. Admin-controlled. Defaults to HIDDEN — the wallet
  /// tile stays off until an admin explicitly enables it from the dashboard.
  final bool googlePayEnabled;

  /// Percentage of each booking amount that goes to the therapist (0-100).
  final double revenueTherapistPct;

  /// Percentage of each booking amount retained by the app (0-100).
  final double revenueAppPct;

  /// Percentage of each booking amount allocated to maintenance (0-100).
  final double revenueMaintenancePct;

  /// Direct URL of the marketing landing-page hero background video.
  /// Admin-controlled (uploaded from the dashboard) so the public site at
  /// sanadtherapy.com can swap the hero video without a code release. Empty
  /// means the landing page shows its branded gradient fallback.
  final String landingHeroVideoUrl;

  /// Optional poster image shown while the hero video loads (and as the
  /// fallback frame). Empty means the gradient fallback is used.
  final String landingHeroPosterUrl;

  /// When true, the "دعم سند" support chat tile is shown to ALL users
  /// (including guests / anonymous and free-tier users) regardless of their
  /// subscription tier. Admin-controlled — flip
  /// `system_settings/config.support_open_to_all = true` in the Firebase
  /// console to open the channel; set it back to `false` to revert.
  /// No app release needed. Defaults to false so existing behaviour is
  /// unchanged until an admin explicitly enables it.
  final bool supportOpenToAll;

  /// Number of days after signup during which free users can send messages
  /// in the support chat without a subscription. After this window,
  /// the input bar is replaced with a "subscribe to continue" paywall.
  /// Admin-controlled via `system_settings/config.support_trial_days`.
  /// Defaults to 3.
  final int supportTrialDays;

  /// Only accounts created ON OR AFTER this date are subject to the support
  /// trial paywall — existing users (created before) are grandfathered and
  /// never gated. Null means the trial gate is OFF for everyone (safe default).
  /// Admin-controlled via `system_settings/config.support_trial_start_date`.
  final DateTime? supportTrialStartDate;

  const SystemSettings({
    this.enableTherapistApplication = false,
    this.maintenanceMode = false,
    this.minAppVersion = '1.0.0',
    this.contactEmail = 'support@sanad.sa',
    this.paymentTestMode = false,
    this.paypalEnabled = true,
    this.googlePayEnabled = false,
    this.revenueTherapistPct = 70,
    this.revenueAppPct = 20,
    this.revenueMaintenancePct = 10,
    this.landingHeroVideoUrl = '',
    this.landingHeroPosterUrl = '',
    this.supportOpenToAll = false,
    this.supportTrialDays = 3,
    this.supportTrialStartDate,
  });

  /// Parse a raw Firestore [data] map into a [SystemSettings] instance.
  /// Used by [fromFirestore] and directly in unit tests.
  factory SystemSettings.fromMap(Map<String, dynamic> data) {
    return SystemSettings(
      enableTherapistApplication:
          data['enable_therapist_application'] as bool? ?? false,
      maintenanceMode: data['maintenance_mode'] as bool? ?? false,
      minAppVersion: data['min_app_version'] as String? ?? '1.0.0',
      contactEmail: data['contact_email'] as String? ?? 'support@sanad.sa',
      paymentTestMode: data['payment_test_mode'] as bool? ?? false,
      paypalEnabled: data['payment_paypal_enabled'] as bool? ?? true,
      googlePayEnabled: data['payment_google_pay_enabled'] as bool? ?? false,
      revenueTherapistPct:
          (data['revenue_therapist_pct'] as num?)?.toDouble() ?? 70,
      revenueAppPct: (data['revenue_app_pct'] as num?)?.toDouble() ?? 20,
      revenueMaintenancePct:
          (data['revenue_maintenance_pct'] as num?)?.toDouble() ?? 10,
      landingHeroVideoUrl: data['landing_hero_video_url'] as String? ?? '',
      landingHeroPosterUrl: data['landing_hero_poster_url'] as String? ?? '',
      supportOpenToAll: data['support_open_to_all'] as bool? ?? false,
      supportTrialDays: (data['support_trial_days'] as num?)?.toInt() ?? 3,
      supportTrialStartDate:
          (data['support_trial_start_date'] as Timestamp?)?.toDate(),
    );
  }

  factory SystemSettings.fromFirestore(DocumentSnapshot doc) {
    if (!doc.exists) return const SystemSettings();
    final data = doc.data() as Map<String, dynamic>;
    return SystemSettings.fromMap(data);
  }

  Map<String, dynamic> toMap() {
    return {
      'enable_therapist_application': enableTherapistApplication,
      'maintenance_mode': maintenanceMode,
      'min_app_version': minAppVersion,
      'contact_email': contactEmail,
      'payment_test_mode': paymentTestMode,
      'payment_paypal_enabled': paypalEnabled,
      'payment_google_pay_enabled': googlePayEnabled,
      'revenue_therapist_pct': revenueTherapistPct,
      'revenue_app_pct': revenueAppPct,
      'revenue_maintenance_pct': revenueMaintenancePct,
      'landing_hero_video_url': landingHeroVideoUrl,
      'landing_hero_poster_url': landingHeroPosterUrl,
      'support_open_to_all': supportOpenToAll,
      'support_trial_days': supportTrialDays,
      if (supportTrialStartDate != null)
        'support_trial_start_date': Timestamp.fromDate(supportTrialStartDate!),
    };
  }
}

class SystemSettingsNotifier extends StateNotifier<AsyncValue<SystemSettings>> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  SystemSettingsNotifier() : super(const AsyncValue.loading()) {
    _init();
  }

  void _init() {
    _firestore
        .collection('system_settings')
        .doc('config')
        .snapshots()
        .listen(
          (doc) {
            if (!mounted) return;
            debugPrint(
              '⚙️ System Settings updated: enableTherapistApplication=${doc.data()?['enable_therapist_application']}',
            );
            state = AsyncValue.data(SystemSettings.fromFirestore(doc));
          },
          onError: (Object e, StackTrace st) {
            if (!mounted) return;
            debugPrint('❌ Error loading System Settings: $e');
            debugPrintStack(stackTrace: st);
            state = AsyncValue.error(e, st);
          },
        );
  }

  Future<void> updateSetting(String key, dynamic value) async {
    await _firestore.collection('system_settings').doc('config').set({
      key: value,
    }, SetOptions(merge: true));
  }
}

final systemSettingsProvider =
    StateNotifierProvider<SystemSettingsNotifier, AsyncValue<SystemSettings>>(
      (ref) => SystemSettingsNotifier(),
    );
