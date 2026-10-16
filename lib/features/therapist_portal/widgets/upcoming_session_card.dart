import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/l10n/language_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../models/therapist_booking.dart';
import '../utils/session_display.dart';

/// Prominent home card: "You have a session <when> Sudan time with <client>".
/// The client name opens the patient chat via [onOpenChat]. Tentative
/// (bank-transfer) sessions carry the awaiting-payment badge.
class UpcomingSessionCard extends ConsumerWidget {
  final TherapistBooking booking;
  final VoidCallback? onOpenChat;
  final VoidCallback? onTap;
  final DateTime? now;

  const UpcomingSessionCard({
    super.key,
    required this.booking,
    this.onOpenChat,
    this.onTap,
    this.now,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tentative = isTentativeBooking(booking);
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
                      onTap: onOpenChat,
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
          ],
        ),
      ),
    );
  }
}
