import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/sanad_button.dart';
import '../../../core/l10n/language_provider.dart';
import '../models/therapist.dart';
import '../../../core/widgets/whatsapp_support_button.dart';

class BookingSheet extends ConsumerStatefulWidget {
  final Therapist therapist;

  const BookingSheet({super.key, required this.therapist});

  @override
  ConsumerState<BookingSheet> createState() => _BookingSheetState();
}

class _BookingSheetState extends ConsumerState<BookingSheet> {
  DateTime _selectedDate = DateTime.now();
  String? _selectedTime;
  SessionType? _selectedSessionType;
  bool _showSuccess = false;

  final List<String> _availableTimes = [
    '9:00 AM',
    '10:00 AM',
    '11:00 AM',
    '2:00 PM',
    '3:00 PM',
    '4:00 PM',
    '5:00 PM',
    '6:00 PM',
  ];

  List<DateTime> _getWeekDates() {
    final now = DateTime.now();
    return List.generate(14, (index) => now.add(Duration(days: index)));
  }

  void _confirmBooking() {
    if (_selectedTime == null || _selectedSessionType == null) return;

    HapticFeedback.mediumImpact();

    setState(() {
      _showSuccess = true;
    });

    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) {
        Navigator.of(context).pop();
        Navigator.of(context).pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = ref.watch(stringsProvider);

    if (_showSuccess) {
      return _SuccessView(
        therapist: widget.therapist,
        date: _selectedDate,
        time: _selectedTime!,
        sessionType: _selectedSessionType!,
        isDark: isDark,
        strings: s,
      );
    }

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
                            color: isDark ? Colors.white : AppColors.textLight,
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

                    // Session type
                    Text(
                      s.selectSessionType,
                      style: AppTypography.labelLarge.copyWith(
                        color: isDark ? Colors.white : AppColors.textLight,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: widget.therapist.sessionTypes.map((type) {
                        final isSelected = _selectedSessionType == type;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              setState(() {
                                _selectedSessionType = type;
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? (isDark
                                          ? AppColors.primary.withValues(
                                              alpha: 0.2,
                                            )
                                          : AppColors.softBlue)
                                    : (isDark
                                          ? AppColors.backgroundDark
                                          : AppColors.backgroundLight),
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radiusMd,
                                ),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primary
                                      : (isDark
                                            ? AppColors.borderDark
                                            : AppColors.borderLight),
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    SessionTypeData.getIcon(type),
                                    size: 28,
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.textMuted,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    SessionTypeData.getLabel(type, strings: s),
                                    style: AppTypography.labelSmall.copyWith(
                                      color: isSelected
                                          ? AppColors.primary
                                          : AppColors.textMuted,
                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    // Date selection
                    Text(
                      s.selectDate,
                      style: AppTypography.labelLarge.copyWith(
                        color: isDark ? Colors.white : AppColors.textLight,
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
                                _selectedTime = null;
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
                                    DateFormat(
                                      'E',
                                    ).format(date).substring(0, 3),
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
                                                : AppColors.textLight),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    DateFormat('MMM').format(date),
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
                        color: isDark ? Colors.white : AppColors.textLight,
                      ),
                    ),
                    const SizedBox(height: 12),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 8,
                            childAspectRatio: 2,
                          ),
                      itemCount: _availableTimes.length,
                      itemBuilder: (context, index) {
                        final time = _availableTimes[index];
                        final isSelected = _selectedTime == time;
                        // Simulate some unavailable slots
                        final isAvailable = index != 2 && index != 5;

                        return GestureDetector(
                          onTap: isAvailable
                              ? () {
                                  HapticFeedback.lightImpact();
                                  setState(() {
                                    _selectedTime = time;
                                  });
                                }
                              : null,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color: !isAvailable
                                  ? (isDark
                                        ? AppColors.borderDark
                                        : AppColors.borderLight)
                                  : isSelected
                                  ? AppColors.primary
                                  : (isDark
                                        ? AppColors.backgroundDark
                                        : AppColors.backgroundLight),
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusSm,
                              ),
                              border: Border.all(
                                color: !isAvailable
                                    ? Colors.transparent
                                    : isSelected
                                    ? AppColors.primary
                                    : (isDark
                                          ? AppColors.borderDark
                                          : AppColors.borderLight),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                time,
                                style: AppTypography.labelSmall.copyWith(
                                  color: !isAvailable
                                      ? AppColors.textMuted.withValues(
                                          alpha: 0.5,
                                        )
                                      : isSelected
                                      ? Colors.white
                                      : (isDark
                                            ? AppColors.textDark
                                            : AppColors.textLight),
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  decoration: !isAvailable
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),

                    // Summary
                    if (_selectedSessionType != null && _selectedTime != null)
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
                                'ar',
                              ).format(_selectedDate),
                              isDark: isDark,
                            ),
                            const SizedBox(height: 8),
                            _SummaryRow(
                              icon: Icons.access_time_rounded,
                              label: s.time,
                              value: _selectedTime!,
                              isDark: isDark,
                            ),
                            const SizedBox(height: 8),
                            _SummaryRow(
                              icon: SessionTypeData.getIcon(
                                _selectedSessionType!,
                              ),
                              label: s.type,
                              value: SessionTypeData.getLabel(
                                _selectedSessionType!,
                                strings: s,
                              ),
                              isDark: isDark,
                            ),
                            const SizedBox(height: 8),
                            _SummaryRow(
                              icon: Icons.attach_money_rounded,
                              label: s.price,
                              value: widget.therapist.formattedPrice,
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
                    text: s.confirmBooking,
                    icon: Icons.check_circle_outline_rounded,
                    onPressed:
                        (_selectedTime != null && _selectedSessionType != null)
                        ? _confirmBooking
                        : null,
                    isFullWidth: true,
                    size: SanadButtonSize.large,
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
              color: isDark ? Colors.white : AppColors.textLight,
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
                color: widget.isDark ? Colors.white : AppColors.textLight,
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
                              : AppColors.textLight,
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
                              : AppColors.textLight,
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
                              : AppColors.textLight,
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
