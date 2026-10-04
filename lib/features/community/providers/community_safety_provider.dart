import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/l10n/language_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../services/community_safety_service.dart';

final communitySafetyServiceProvider = Provider(
  (ref) => CommunitySafetyService(),
);

/// Live blocked-user ids and rules-acceptance flag for the signed-in user.
final communityUserSafetyProvider = StreamProvider<CommunityUserSafety>((ref) {
  final user = ref.watch(authProvider).user;
  if (user == null || user.isGuest) {
    return Stream.value(const CommunityUserSafety());
  }
  return ref.watch(communitySafetyServiceProvider).watchUserSafety(user.uid);
});

final blockedUserIdsProvider = Provider<Set<String>>((ref) {
  return ref.watch(communityUserSafetyProvider).valueOrNull?.blockedUserIds ??
      const {};
});

/// Post ids and comment ids the user just reported (hidden immediately).
final hiddenPostIdsProvider = StateProvider<Set<String>>((ref) => {});
final hiddenCommentIdsProvider = StateProvider<Set<String>>((ref) => {});

/// Shows the one-time community rules dialog if the user has not agreed yet.
/// Returns true when the user has agreed (now or before), false on cancel.
Future<bool> ensureCommunityTermsAccepted(
  BuildContext context,
  WidgetRef ref,
) async {
  final user = ref.read(authProvider).user;
  if (user == null) return false;
  final service = ref.read(communitySafetyServiceProvider);

  var accepted = ref.read(communityUserSafetyProvider).valueOrNull?.termsAccepted;
  if (accepted == null) {
    try {
      accepted = (await service.watchUserSafety(user.uid).first).termsAccepted;
    } catch (_) {
      accepted = false;
    }
  }
  if (accepted) return true;
  if (!context.mounted) return false;

  final s = ref.read(stringsProvider);
  final agreed = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      title: Text(s.communityRulesTitle),
      content: SingleChildScrollView(child: Text(s.communityRulesBody)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(s.cancel),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(s.communityRulesAgree),
        ),
      ],
    ),
  );
  if (agreed != true) return false;
  try {
    await service.acceptCommunityTerms(user.uid);
  } catch (_) {
    return false;
  }
  return true;
}
