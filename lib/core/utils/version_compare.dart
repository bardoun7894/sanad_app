/// Semver comparison utilities.
///
/// Both functions are tolerant of:
/// - Build metadata suffixes: "1.0.0+17" → "1.0.0"
/// - Pre-release labels: "1.2.3-beta" → "1.2.3"
/// - Short forms: "1.2" treated as "1.2.0"

/// Strips any build (+) or pre-release (-) suffix, then splits into
/// integer segments.
List<int> _parseVersion(String version) {
  // Strip build metadata: everything from '+' onward
  final plusIdx = version.indexOf('+');
  if (plusIdx != -1) version = version.substring(0, plusIdx);

  // Strip pre-release label: everything from '-' onward
  final dashIdx = version.indexOf('-');
  if (dashIdx != -1) version = version.substring(0, dashIdx);

  return version
      .split('.')
      .map((s) => int.tryParse(s.trim()) ?? 0)
      .toList();
}

/// Compares two version strings using semver rules.
///
/// Returns:
///  1 if [a] > [b]
/// -1 if [a] < [b]
///  0 if [a] == [b]
int compareSemver(String a, String b) {
  final partsA = _parseVersion(a);
  final partsB = _parseVersion(b);

  final maxLen =
      partsA.length > partsB.length ? partsA.length : partsB.length;

  for (var i = 0; i < maxLen; i++) {
    final segA = i < partsA.length ? partsA[i] : 0;
    final segB = i < partsB.length ? partsB[i] : 0;
    if (segA > segB) return 1;
    if (segA < segB) return -1;
  }
  return 0;
}

/// Returns true only when [current] is strictly below [minimum].
bool isVersionBelow(String current, String minimum) {
  return compareSemver(current, minimum) < 0;
}
