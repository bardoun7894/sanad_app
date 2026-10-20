import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/l10n/language_provider.dart';
import '../../../core/services/zego_call_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../../therapists/models/therapist.dart';
import '../models/therapist_booking.dart';
import '../utils/session_display.dart';

/// Prominent home card: "You have a session <when> Sudan time with <client>".
/// Tapping the card opens the booking detail via [onTap].
/// Tentative (bank-transfer) sessions carry the awaiting-payment badge.
/// Includes a prominent call button enabled only for confirmed sessions.
class UpcomingSessionCard extends ConsumerWidget {
  final TherapistBooking booking;
  @Deprecated('Tapping opens booking detail instead of chat')
  final VoidCallback? onOpenChat;
  final VoidCallback? onTap;
  final VoidCallback? onCall;
  final DateTime? now;

  const UpcomingSessionCard({
    super.key,
    required this.booking,
    this.onOpenChat,
    this.onTap,
    this.onCall,
    this.now,
  });

  Future<void> _callClient(
    BuildContext context,
    WidgetRef ref,
    TherapistBooking booking,
  ) async {
    if (booking.sessionType == SessionType.chat) {
      return;
    }

    final userId = ref.read(authProvider).user?.uid ?? 'therapist';
    final userName = ref.read(authProvider).user?.displayName ?? 'Therapist';

    try {
      final result = await ZegoCallService.instance.sendCallInvitation(
        targetUserId: booking.clientId,
        targetUserName: booking.clientName,
        callID: booking.id,
        callerUserId: userId,
        callerName: userName,
        chatId: booking.id,
        timeoutSeconds: 60,
      );

      if (!context.mounted) return;
      final strings = ref.read(stringsProvider);
      if (!result.ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${strings.errorOccurred}${result.error != null ? '\n${result.error}' : ''}',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 6),
          ),
        );
      } else if (result.warning != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.warning!),
            backgroundColor: Colors.orange.shade800,
            duration: const Duration(seconds: 6),
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      final strings = ref.read(stringsProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(strings.errorOccurred),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tentative = isTentativeBooking(booking);
    final isConfirmed = booking.status == BookingStatus.confirmed;
    final canCall = isConfirmed;
    final textColor = isDark ? Colors.white : AppColors.textPrimary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: tentative ? Colors.amber.shade600 : AppColors.primary,
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text.rich(
              TextSpan(
                style: TextStyle(
                  color: textColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  height: 1.5,
                ),
                children: [
                  TextSpan(text: '${sessionCardPrefix(booking, s, now: now)} '),
                  WidgetSpan(
                    alignment: PlaceholderAlignment.baseline,
                    baseline: TextBaseline.alphabetic,
                    child: GestureDetector(
                      key: const Key('session_client_link'),
                      onTap: onTap,
                      child: Text(
                        sessionClientName(booking, s),
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (tentative) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  bookingStatusLabel(booking, s),
                  style: TextStyle(
                    color: Colors.amber.shade900,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                key: const Key('upcoming_session_call_button'),
                onPressed: canCall
                    ? () => onCall != null
                        ? onCall!()
                        : _callClient(context, ref, booking)
                    : null,
                icon: const Icon(Icons.call, size: 20),
                label: Text(s.callLabel),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      isDark ? Colors.white12 : Colors.grey.shade200,
                  disabledForegroundColor:
                      isDark ? Colors.white38 : Colors.grey.shade500,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
