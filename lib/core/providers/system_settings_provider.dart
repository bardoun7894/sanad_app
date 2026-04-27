import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SystemSettings {
  final bool enableTherapistApplication;
  final bool maintenanceMode;
  final String minAppVersion;
  final String contactEmail;

  const SystemSettings({
    this.enableTherapistApplication = false,
    this.maintenanceMode = false,
    this.minAppVersion = '1.0.0',
    this.contactEmail = 'support@sanad.sa',
  });

  factory SystemSettings.fromFirestore(DocumentSnapshot doc) {
    if (!doc.exists) return const SystemSettings();
    final data = doc.data() as Map<String, dynamic>;
    return SystemSettings(
      enableTherapistApplication:
          data['enable_therapist_application'] as bool? ?? false,
      maintenanceMode: data['maintenance_mode'] as bool? ?? false,
      minAppVersion: data['min_app_version'] as String? ?? '1.0.0',
      contactEmail: data['contact_email'] as String? ?? 'support@sanad.sa',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'enable_therapist_application': enableTherapistApplication,
      'maintenance_mode': maintenanceMode,
      'min_app_version': minAppVersion,
      'contact_email': contactEmail,
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
