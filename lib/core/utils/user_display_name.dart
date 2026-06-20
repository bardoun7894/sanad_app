/// Single source of truth for turning a user's stored name fields into a
/// display name. Shared by the admin users list and the admin payments view so
/// the same account always renders the same name.
///
/// Rules (kept identical to the original AdminUser.fullName logic):
/// 1. An explicit `display_name`/`name`/`full_name` wins — unless it is the
///    legacy 'User' placeholder written by old signup code, which is treated as
///    absent so a real first/last name can win.
/// 2. Otherwise `first_name` + `last_name`.
/// 3. Otherwise the placeholder display name if that's all there is.
/// 4. Otherwise null.
String? resolveDisplayName({
  String? displayName,
  String? firstName,
  String? lastName,
}) {
  final dn = displayName?.trim();
  if (dn != null && dn.isNotEmpty && dn.toLowerCase() != 'user') {
    return dn;
  }
  final combined = [firstName, lastName]
      .where((p) => p != null && p.trim().isNotEmpty)
      .join(' ')
      .trim();
  if (combined.isNotEmpty) return combined;
  // Never surface the legacy 'User' placeholder. An abandoned signup with no
  // real name resolves to null so the UI can show an "incomplete signup"
  // fallback instead of a fake user literally named "User".
  return null;
}

/// Convenience over a raw `users/{uid}` Firestore data map.
String? resolveDisplayNameFromUserDoc(Map<String, dynamic> data) =>
    resolveDisplayName(
      displayName:
          (data['display_name'] ?? data['name'] ?? data['full_name']) as String?,
      firstName: data['first_name'] as String?,
      lastName: data['last_name'] as String?,
    );
