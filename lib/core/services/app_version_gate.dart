import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../providers/system_settings_provider.dart';
import '../utils/version_compare.dart';

/// Provides the current installed app version (e.g., "1.0.0").
/// Uses [PackageInfo.version], which excludes the build number.
final appVersionProvider = FutureProvider<String>((ref) async {
  final info = await PackageInfo.fromPlatform();
  return info.version;
});

/// Returns `true` ONLY when BOTH providers have loaded data AND
/// the current version is strictly below [SystemSettings.minAppVersion].
///
/// Fails OPEN: returns `false` while either provider is still loading or
/// has errored — we never block the app due to a lookup failure.
final requiresUpdateProvider = Provider<bool>((ref) {
  final versionAsync = ref.watch(appVersionProvider);
  final settingsAsync = ref.watch(systemSettingsProvider);

  return versionAsync.when(
    data: (currentVersion) {
      return settingsAsync.when(
        data: (settings) {
          final minVersion = settings.minAppVersion;
          if (minVersion.isEmpty) return false;
          return isVersionBelow(currentVersion, minVersion);
        },
        loading: () => false,
        error: (_, __) => false,
      );
    },
    loading: () => false,
    error: (_, __) => false,
  );
});
