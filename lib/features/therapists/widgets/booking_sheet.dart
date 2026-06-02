import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/config/booking_pricing.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/sanad_button.dart';
import '../../../core/l10n/language_provider.dart';
import '../models/therapist.dart';
import '../../../core/widgets/whatsapp_support_button.dart';
import '../services/booking_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../../booking/screens/booking_payment_screen.dart';

class BookingSheet extends ConsumerStatefulWidget {
  final Therapist therapist;

  const BookingSheet({super.key, required this.therapist});

  @override
  ConsumerState<BookingSheet> createState() => _BookingSheetState();
}

class _BookingSheetState extends ConsumerState<BookingSheet> {
  DateTime _selectedDate = DateTime.now();
  AvailableSlot? _selectedSlot;
  // Bookings are always voice-call sessions; the type selector has been
  // removed from the UI.
  final SessionType _selectedSessionType = SessionType.audio;
  bool _showSuccess = false;
  bool _isBooking = false;

  List<DateTime> _getWeekDates() {
    final now = DateTime.now();
    return List.generate(14, (index) => now.add(Duration(days: index)));
  }

  // Localized short day-of-week (e.g. "أحد", "Dim", "Sun") without relying on
  // `intl`'s locale data, which isn't initialized in this app.
  static const _arDays = ['أحد', 'إثن', 'ثلا', 'أرب', 'خمي', 'جمع', 'سبت'];
  static const _frDays = ['Dim', 'Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam'];
  static const _enDays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  String _shortDayLabel(DateTime date, String locale) {
    // DateTime.weekday: Mon=1..Sun=7 → map Sun→0, Mon→1..Sat→6 for our arrays.
    final idx = date.weekday == DateTime.sunday ? 0 : date.weekday;
    return switch (locale) {
      'ar' => _arDays[idx],
      'fr' => _frDays[idx],
      _ => _enDays[idx],
    };
  }

  static const _arMonths = [
    'ينا', 'فبر', 'مار', 'أبر', 'ماي', 'يون',
    'يول', 'أغس', 'سبت', 'أكت', 'نوف', 'ديس',
  ];
  static const _frMonths = [
    'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jui',
    'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc',
  ];
  static const _enMonths = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  String _shortMonthLabel(DateTime date, String locale) {
    final i = date.month - 1;
    return switch (locale) {
      'ar' => _arMonths[i],
      'fr' => _frMonths[i],
      _ => _enMonths[i],
    };
  }

  Future<void> _confirmBooking() async {
    if (_selectedSlot == null) return;

    final user = ref.read(currentUserProvider);
    final s = ref.read(stringsProvider);
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(s.loginToBook)));
      return;
    }

    HapticFeedback.mediumImpact();

    setState(() {
      _isBooking = true;
    });

    try {
      final bookingService = ref.read(bookingServiceProvider);
      // Every booking charges the same flat price, regardless of the
      // therapist's listed hourly rate. See [[kBookingFlatPriceUsd]].
      final bookingId = await bookingService.createBooking(
        therapistId: widget.therapist.id,
        therapistName: widget.therapist.name,
        clientId: user.uid,
        clientName: user.displayName ?? user.email.split('@').first,
        clientEmail: user.email,
        scheduledTime: _selectedSlot!.startTime,
        durationMinutes: 60,
        sessionType: _selectedSessionType.name,
        amount: kBookingFlatPriceUsd,
        currency: kBookingFlatCurrency,
      );

      if (mounted) {
        setState(() => _isBooking = false);

        // Close booking sheet and navigate to payment screen
        Navigator.of(context).pop();
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => BookingPaymentScreen(
              bookingId: bookingId,
              amount: kBookingFlatPriceUsd,
              currency: kBookingFlatCurrency,
              therapistName: widget.therapist.name,
              paymentDeadline: DateTime.now().add(const Duration(hours: 24)),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isBooking = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${s.errorOccurred}: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = ref.watch(stringsProvider);
    final localeCode = ref.watch(languageProvider).locale.languageCode;

    if (_showSuccess) {
      return _SuccessView(
        therapist: widget.therapist,
        date: _selectedDate,
        time: _selectedSlot!.formattedTime,
        sessionType: _selectedSessionType,
        isDark: isDark,
        strings: s,
      );
    }

    // Watch available slots for the selected date
    final slotsAsync = ref.watch(
      availableSlotsProvider((
        therapistId: widget.therapist.id,
        date: _selectedDate,
      )),
    );

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle bar
              Padding(
                padding: const EdgeInsets.all(12),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textMuted.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  children: [
                    // Header
                    Row(
                      children: [
                        Text(
                          s.bookASession,
                          style: AppTypography.headingMedium.copyWith(
                            color: isDark
                                ? Colors.white
                                : AppColors.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(
                            Icons.close_rounded,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${s.withTherapist} ${widget.therapist.name}',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Date selection
                    Text(
                      s.selectDate,
                      style: AppTypography.labelLarge.copyWith(
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 90,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _getWeekDates().length,
                        itemBuilder: (context, index) {
                          final date = _getWeekDates()[index];
                          final isSelected =
                              _selectedDate.day == date.day &&
                              _selectedDate.month == date.month;
                          final isToday =
                              date.day == DateTime.now().day &&
                              date.month == DateTime.now().month;

                          return GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              setState(() {
                                _selectedDate = date;
                                _selectedSlot = null;
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 60,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primary
                                    : (isDark
                                          ? AppColors.backgroundDark
                                          : AppColors.backgroundLight),
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radiusMd,
                                ),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primary
                                      : isToday
                                      ? AppColors.primary.withValues(alpha: 0.5)
                                      : (isDark
                                            ? AppColors.borderDark
                                            : AppColors.borderLight),
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _shortDayLabel(date, localeCode),
                                    style: AppTypography.caption.copyWith(
                                      color: isSelected
                                          ? Colors.white.withValues(alpha: 0.8)
                                          : AppColors.textMuted,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    date.day.toString(),
                                    style: AppTypography.headingSmall.copyWith(
                                      color: isSelected
                                          ? Colors.white
                                          : (isDark
                                                ? Colors.white
                                                : AppColors.textPrimary),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _shortMonthLabel(date, localeCode),
                                    style: AppTypography.caption.copyWith(
                                      color: isSelected
                                          ? Colors.white.withValues(alpha: 0.8)
                                          : AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Time selection
                    Text(
                      s.selectTime,
                      style: AppTypography.labelLarge.copyWith(
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    slotsAsync.when(
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      error: (error, stack) => Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            s.failedToLoadAvailableTimes,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.error,
                            ),
                          ),
                        ),
                      ),
                      data: (slots) {
                        // Hide unavailable / booked slots entirely instead of
                        // greying them out — if the day has no free time, the
                        // grid disappears and only the empty state shows.
                        final availableSlots =
                            slots.where((slot) => !slot.isBooked).toList();
                        if (availableSlots.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Text(
                                s.noAvailableSlots,
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ),
                          );
                        }
                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 4,
                                mainAxisSpacing: 8,
                                crossAxisSpacing: 8,
                                childAspectRatio: 2,
                              ),
                          itemCount: availableSlots.length,
                          itemBuilder: (context, index) {
                            final slot = availableSlots[index];
                            final isSelected = _selectedSlot?.id == slot.id;

                            return GestureDetector(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                setState(() {
                                  _selectedSlot = slot;
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.primary
                                      : (isDark
                                            ? AppColors.backgroundDark
                                            : AppColors.backgroundLight),
                                  borderRadius: BorderRadius.circular(
                                    AppTheme.radiusSm,
                                  ),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.primary
                                        : (isDark
                                              ? AppColors.borderDark
                                              : AppColors.borderLight),
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    slot.formattedTime,
                                    style: AppTypography.labelSmall.copyWith(
                                      color: isSelected
                                          ? Colors.white
                                          : (isDark
                                                ? AppColors.textDark
                                                : AppColors.textPrimary),
                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 24),

                    // Summary
                    if (_selectedSlot != null)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.primary.withValues(alpha: 0.1)
                              : AppColors.softBlue,
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusMd,
                          ),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.bookingSummary,
                              style: AppTypography.labelLarge.copyWith(
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _SummaryRow(
                              icon: Icons.calendar_today_outlined,
                              label: s.date,
                              value: DateFormat(
                                'EEEE, MMMM d, y',
                                localeCode,
                              ).format(_selectedDate),
                              isDark: isDark,
                            ),
                            const SizedBox(height: 8),
                            _SummaryRow(
                              icon: Icons.access_time_rounded,
                              label: s.time,
                              value: _selectedSlot!.formattedTime,
                              isDark: isDark,
                            ),
                            const SizedBox(height: 8),
                            _SummaryRow(
                              icon: SessionTypeData.getIcon(
                                _selectedSessionType,
                              ),
                              label: s.type,
                              value: SessionTypeData.getLabel(
                                _selectedSessionType,
                                strings: s,
                              ),
                              isDark: isDark,
                            ),
                            const SizedBox(height: 8),
                            _SummaryRow(
                              icon: Icons.attach_money_rounded,
                              label: s.price,
                              value:
                                  '\$${kBookingFlatPriceUsd.toStringAsFixed(2)} $kBookingFlatCurrency',
                              isDark: isDark,
                            ),
                          ],
                        ),
                      ),

                    const WhatsAppSupportButton(),
                    const SizedBox(height: 100),
                  ],
                ),
              ),

              // Bottom button
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : Colors.white,
                  border: Border(
                    top: BorderSide(
                      color: isDark
                          ? AppColors.borderDark
                          : AppColors.borderLight,
                    ),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: SanadButton(
                    text: _isBooking ? s.loading : s.confirmBooking,
                    icon: _isBooking
                        ? null
                        : Icons.check_circle_outline_rounded,
                    onPressed:
                        (_selectedSlot != null && !_isBooking)
                            ? _confirmBooking
                            : null,
                    isFullWidth: true,
                    size: SanadButtonSize.large,
                    isLoading: _isBooking,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;

  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 10),
        Text(
          '$label:',
          style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: AppTypography.labelMedium.copyWith(
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

class _SuccessView extends StatefulWidget {
  final Therapist therapist;
  final DateTime date;
  final String time;
  final SessionType sessionType;
  final bool isDark;
  final S strings;

  const _SuccessView({
    required this.therapist,
    required this.date,
    required this.time,
    required this.sessionType,
    required this.isDark,
    required this.strings,
  });

  @override
  State<_SuccessView> createState() => _SuccessViewState();
}

class _SuccessViewState extends State<_SuccessView>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: widget.isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _scaleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: child,
                );
              },
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  size: 60,
                  color: AppColors.success,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              widget.strings.bookingConfirmed,
              style: AppTypography.headingMedium.copyWith(
                color: widget.isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${widget.strings.sessionBooked} ${widget.therapist.name}',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: widget.isDark
                    ? AppColors.backgroundDark
                    : AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 18,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        DateFormat('EEEE, MMMM d').format(widget.date),
                        style: AppTypography.labelMedium.copyWith(
                          color: widget.isDark
                              ? Colors.white
                              : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 18,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        widget.time,
                        style: AppTypography.labelMedium.copyWith(
                          color: widget.isDark
                              ? Colors.white
                              : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        SessionTypeData.getIcon(widget.sessionType),
                        size: 18,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        SessionTypeData.getLabel(
                          widget.sessionType,
                          strings: widget.strings,
                        ),
                        style: AppTypography.labelMedium.copyWith(
                          color: widget.isDark
                              ? Colors.white
                              : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.strings.confirmationEmail,
              style: AppTypography.caption.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
