import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

/// Test-only override for [isAppleCoachingBuild].
@visibleForTesting
bool? appleCoachingBuildOverride;

/// Single switch for the Apple App Store build: on iOS the patient app is
/// presented as wellbeing / life coaching rather than therapy.
bool get isAppleCoachingBuild {
  final o = appleCoachingBuildOverride;
  if (o != null) return o;
  return !kIsWeb && Platform.isIOS;
}
