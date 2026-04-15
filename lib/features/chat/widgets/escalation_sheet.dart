import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';

import '../../../core/widgets/glass_card.dart';
import '../../../core/l10n/language_provider.dart';
import '../../therapist_portal/models/therapist_booking.dart';
import '../../therapist_portal/services/therapist_booking_service.dart';
import '../../auth/providers/auth_provider.dart';

/// Bottom sheet for escalating chat to Admin or Therapist
class EscalationSheet extends ConsumerStatefulWidget {
  final Function(String escalateTo, String? therapistId, String? context)?
  onEscalate;

  const EscalationSheet({super.key, this.onEscalate});

  @override
  ConsumerState<EscalationSheet> createState() => _EscalationSheetState();
}

class _EscalationSheetState extends ConsumerState<EscalationSheet> {
  bool _transferContext = true;
  bool _isLoading = false;
  List<TherapistBooking> _userBookings = [];

  @override
  void initState() {
    super.initState();
    _loadUserBookings();
  }

  Future<void> _loadUserBookings() async {
    final authState = ref.read(authProvider);
    if (authState.user == null) return;

    setState(() => _isLoading = true);

    try {
      final bookingService = TherapistBookingService();
      // Get all user's bookings (pending, confirmed, or completed)
      final bookings = await bookingService.getBookingsForClient(
        authState.user!.uid,
      );
      setState(() {
        _userBookings = bookings;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = ref.watch(stringsProvider);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusXl),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.black12,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text(
                  s.talkToHuman,
                  style: AppTypography.headingMedium.copyWith(
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  s.chooseConnection,
                  style: AppTypography.bodyMedium.copyWith(
                    color: isDark
                        ? Colors.white70
                        : AppColors.textLightSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          // Options
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                // Admin Support Option
                _EscalationOption(
                  icon: Icons.support_agent_rounded,
                  iconColor: AppColors.primary,
                  title: s.supportTeam,
                  subtitle: s.generalInquiries,
                  onTap: () => _handleEscalation('admin', null),
                ),

                const SizedBox(height: 12),

                // Therapist Option
                _EscalationOption(
                  icon: Icons.psychology_rounded,
                  iconColor: AppColors.success,
                  title: s.yourTherapist,
                  subtitle: _userBookings.isEmpty
                      ? s.requiresActiveBooking
                      : '${_userBookings.length} booking(s) available',
                  enabled: _userBookings.isNotEmpty,
                  isLoading: _isLoading,
                  onTap: _userBookings.isEmpty
                      ? null
                      : () => _showTherapistSelector(s),
                ),
              ],
            ),
          ),

          // Transfer context toggle
          Padding(
            padding: const EdgeInsets.all(20),
            child: GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    Icons.history_rounded,
                    size: 20,
                    color: isDark
                        ? Colors.white70
                        : AppColors.textLightSecondary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.shareConversationContext,
                          style: AppTypography.labelMedium.copyWith(
                            color: isDark
                                ? Colors.white
                                : AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          s.helpUnderstandSituation,
                          style: AppTypography.caption.copyWith(
                            color: isDark
                                ? Colors.white54
                                : AppColors.textLightSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: _transferContext,
                    onChanged: (value) {
                      setState(() => _transferContext = value);
                    },
                    activeTrackColor: AppColors.primary,
                  ),
                ],
              ),
            ),
          ),

          // Book therapist CTA if no bookings
          if (_userBookings.isEmpty && !_isLoading)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.push('/therapists');
                },
                child: Text(
                  s.bookTherapistSession,
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),

          SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
        ],
      ),
    );
  }

  void _showTherapistSelector(S s) {
    if (_userBookings.length == 1) {
      // Only one booking, directly escalate
      _handleEscalation('therapist', _userBookings.first.therapistId);
      return;
    }

    // Multiple bookings, show selector
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _TherapistSelectorSheet(
        bookings: _userBookings,
        strings: s,
        onSelect: (booking) {
          Navigator.pop(context); // Close selector
          _handleEscalation('therapist', booking.therapistId);
        },
      ),
    );
  }

  void _handleEscalation(String escalateTo, String? therapistId) {
    Navigator.pop(context);
    widget.onEscalate?.call(
      escalateTo,
      therapistId,
      _transferContext ? 'transfer' : null,
    );
  }
}

class _EscalationOption extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool enabled;
  final bool isLoading;
  final VoidCallback? onTap;

  const _EscalationOption({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.enabled = true,
    this.isLoading = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedOpacity(
        opacity: enabled ? 1.0 : 0.5,
        duration: const Duration(milliseconds: 200),
        child: GlassCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.labelLarge.copyWith(
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTypography.caption.copyWith(
                        color: isDark
                            ? Colors.white54
                            : AppColors.textLightSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (isLoading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else if (enabled)
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: isDark ? Colors.white38 : Colors.black26,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TherapistSelectorSheet extends StatelessWidget {
  final List<TherapistBooking> bookings;
  final Function(TherapistBooking) onSelect;
  final S strings;

  const _TherapistSelectorSheet({
    required this.bookings,
    required this.onSelect,
    required this.strings,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusXl),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.black12,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              strings.selectATherapist,
              style: AppTypography.headingSmall.copyWith(
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ),

          ListView.builder(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final booking = bookings[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _TherapistTile(
                  booking: booking,
                  strings: strings,
                  onTap: () => onSelect(booking),
                ),
              );
            },
          ),

          SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
        ],
      ),
    );
  }
}

class _TherapistTile extends StatelessWidget {
  final TherapistBooking booking;
  final VoidCallback onTap;
  final S strings;

  const _TherapistTile({
    required this.booking,
    required this.onTap,
    required this.strings,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              child: Text(
                booking.clientName.isNotEmpty
                    ? booking.clientName[0].toUpperCase()
                    : 'T',
                style: AppTypography.headingSmall.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    strings.therapist, // Would need therapist name from booking
                    style: AppTypography.labelLarge.copyWith(
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    _getStatusText(booking.status),
                    style: AppTypography.caption.copyWith(
                      color: _getStatusColor(booking.status),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chat_bubble_outline_rounded, color: AppColors.primary),
          ],
        ),
      ),
    );
  }

  String _getStatusText(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return strings.bookingPending;
      case BookingStatus.confirmed:
        return strings.sessionConfirmed;
      case BookingStatus.completed:
        return strings.previousSession;
      default:
        return strings.availableStatus;
    }
  }

  Color _getStatusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return AppColors.warning;
      case BookingStatus.confirmed:
        return AppColors.success;
      case BookingStatus.completed:
        return AppColors.textLightSecondary;
      default:
        return AppColors.textLightSecondary;
    }
  }
}

/// Helper method to show escalation sheet
void showEscalationSheet(
  BuildContext context, {
  Function(String escalateTo, String? therapistId, String? context)? onEscalate,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => EscalationSheet(onEscalate: onEscalate),
  );
}
