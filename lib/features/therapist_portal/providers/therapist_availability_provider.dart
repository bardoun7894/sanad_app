import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/therapist_availability.dart';
import '../services/therapist_availability_service.dart';

/// State for therapist availability management
class TherapistAvailabilityState {
  final List<AvailabilitySlot> slots;
  final WeeklyAvailability? weeklyTemplate;
  final DateTime selectedDate;
  final bool isLoading;
  final bool isSaving;
  final String? error;
  final Set<String> selectedSlotIds;

  const TherapistAvailabilityState({
    this.slots = const [],
    this.weeklyTemplate,
    DateTime? selectedDate,
    this.isLoading = false,
    this.isSaving = false,
    this.error,
    this.selectedSlotIds = const {},
  }) : selectedDate = selectedDate ?? const _DefaultDate();

  /// Get slots for the selected date
  List<AvailabilitySlot> get slotsForSelectedDate {
    return slots.where((slot) {
      return slot.startTime.year == selectedDate.year &&
          slot.startTime.month == selectedDate.month &&
          slot.startTime.day == selectedDate.day;
    }).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  /// Get booked slots count
  int get bookedSlotsCount => slots.where((s) => s.isBooked).length;

  /// Get available slots count
  int get availableSlotsCount => slots.where((s) => s.isAvailable).length;

  /// Get total slots count for a specific day
  int getSlotsCountForDay(DateTime day) {
    return slots.where((slot) {
      return slot.startTime.year == day.year &&
          slot.startTime.month == day.month &&
          slot.startTime.day == day.day;
    }).length;
  }

  /// Check if a day has availability
  bool hasAvailabilityForDay(DateTime day) {
    return getSlotsCountForDay(day) > 0;
  }

  TherapistAvailabilityState copyWith({
    List<AvailabilitySlot>? slots,
    WeeklyAvailability? weeklyTemplate,
    DateTime? selectedDate,
    bool? isLoading,
    bool? isSaving,
    String? error,
    Set<String>? selectedSlotIds,
    bool clearError = false,
    bool clearTemplate = false,
  }) {
    return TherapistAvailabilityState(
      slots: slots ?? this.slots,
      weeklyTemplate: clearTemplate ? null : (weeklyTemplate ?? this.weeklyTemplate),
      selectedDate: selectedDate ?? this.selectedDate,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: clearError ? null : (error ?? this.error),
      selectedSlotIds: selectedSlotIds ?? this.selectedSlotIds,
    );
  }
}

/// Placeholder class for default date
class _DefaultDate implements DateTime {
  const _DefaultDate();

  DateTime get _now => DateTime.now();

  @override
  int get year => _now.year;
  @override
  int get month => _now.month;
  @override
  int get day => _now.day;
  @override
  int get hour => _now.hour;
  @override
  int get minute => _now.minute;
  @override
  int get second => _now.second;
  @override
  int get millisecond => _now.millisecond;
  @override
  int get microsecond => _now.microsecond;
  @override
  int get weekday => _now.weekday;
  @override
  bool get isUtc => _now.isUtc;
  @override
  String get timeZoneName => _now.timeZoneName;
  @override
  Duration get timeZoneOffset => _now.timeZoneOffset;
  @override
  int get millisecondsSinceEpoch => _now.millisecondsSinceEpoch;
  @override
  int get microsecondsSinceEpoch => _now.microsecondsSinceEpoch;

  @override
  DateTime add(Duration duration) => _now.add(duration);
  @override
  DateTime subtract(Duration duration) => _now.subtract(duration);
  @override
  Duration difference(DateTime other) => _now.difference(other);
  @override
  bool isAfter(DateTime other) => _now.isAfter(other);
  @override
  bool isBefore(DateTime other) => _now.isBefore(other);
  @override
  bool isAtSameMomentAs(DateTime other) => _now.isAtSameMomentAs(other);
  @override
  int compareTo(DateTime other) => _now.compareTo(other);
  @override
  DateTime toLocal() => _now.toLocal();
  @override
  DateTime toUtc() => _now.toUtc();
  @override
  String toIso8601String() => _now.toIso8601String();
  @override
  String toString() => _now.toString();
}

/// Provider for managing therapist availability
class TherapistAvailabilityNotifier extends StateNotifier<TherapistAvailabilityState> {
  final TherapistAvailabilityService _service;
  final String therapistId;
  StreamSubscription<List<AvailabilitySlot>>? _slotsSubscription;
  StreamSubscription<WeeklyAvailability?>? _templateSubscription;

  TherapistAvailabilityNotifier({
    required this.therapistId,
    TherapistAvailabilityService? service,
  })  : _service = service ?? TherapistAvailabilityService(),
        super(const TherapistAvailabilityState()) {
    _init();
  }

  void _init() {
    loadAvailability();
    _subscribeToTemplate();
  }

  /// Load availability slots for the current month
  Future<void> loadAvailability() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final now = DateTime.now();
      final from = DateTime(now.year, now.month, 1);
      final to = DateTime(now.year, now.month + 2, 0); // End of next month

      _slotsSubscription?.cancel();
      _slotsSubscription = _service.getAvailability(therapistId, from, to).listen(
        (slots) {
          state = state.copyWith(slots: slots, isLoading: false);
        },
        onError: (error) {
          state = state.copyWith(
            isLoading: false,
            error: 'Failed to load availability: $error',
          );
        },
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load availability: $e',
      );
    }
  }

  /// Subscribe to weekly template changes
  void _subscribeToTemplate() {
    _templateSubscription?.cancel();
    _templateSubscription = _service.getWeeklyTemplateStream(therapistId).listen(
      (template) {
        state = state.copyWith(weeklyTemplate: template);
      },
      onError: (error) {
        // Template errors are not critical
      },
    );
  }

  /// Load availability for a specific date range
  Future<void> loadAvailabilityForRange(DateTime from, DateTime to) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      _slotsSubscription?.cancel();
      _slotsSubscription = _service.getAvailability(therapistId, from, to).listen(
        (slots) {
          state = state.copyWith(slots: slots, isLoading: false);
        },
        onError: (error) {
          state = state.copyWith(
            isLoading: false,
            error: 'Failed to load availability: $error',
          );
        },
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load availability: $e',
      );
    }
  }

  /// Set selected date
  void setSelectedDate(DateTime date) {
    state = state.copyWith(selectedDate: date, selectedSlotIds: {});
  }

  /// Toggle slot selection
  void toggleSlotSelection(String slotId) {
    final newSelection = Set<String>.from(state.selectedSlotIds);
    if (newSelection.contains(slotId)) {
      newSelection.remove(slotId);
    } else {
      newSelection.add(slotId);
    }
    state = state.copyWith(selectedSlotIds: newSelection);
  }

  /// Clear slot selection
  void clearSelection() {
    state = state.copyWith(selectedSlotIds: {});
  }

  /// Add a single availability slot
  Future<void> addSlot({
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    state = state.copyWith(isSaving: true, clearError: true);

    try {
      final slot = AvailabilitySlot(
        id: '',
        therapistId: therapistId,
        startTime: startTime,
        endTime: endTime,
        isBooked: false,
        createdAt: DateTime.now(),
      );

      await _service.addSlot(slot);
      state = state.copyWith(isSaving: false);
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        error: 'Failed to add slot: $e',
      );
    }
  }

  /// Add multiple slots for a time range
  Future<void> addSlotsForTimeRange({
    required DateTime date,
    required int startHour,
    required int startMinute,
    required int endHour,
    required int endMinute,
    required int slotDurationMinutes,
  }) async {
    state = state.copyWith(isSaving: true, clearError: true);

    try {
      final slots = <AvailabilitySlot>[];
      var slotStart = DateTime(
        date.year,
        date.month,
        date.day,
        startHour,
        startMinute,
      );
      final rangeEnd = DateTime(
        date.year,
        date.month,
        date.day,
        endHour,
        endMinute,
      );

      while (slotStart.add(Duration(minutes: slotDurationMinutes)).isBefore(rangeEnd) ||
          slotStart.add(Duration(minutes: slotDurationMinutes)).isAtSameMomentAs(rangeEnd)) {
        final slotEnd = slotStart.add(Duration(minutes: slotDurationMinutes));

        slots.add(AvailabilitySlot(
          id: '',
          therapistId: therapistId,
          startTime: slotStart,
          endTime: slotEnd,
          isBooked: false,
          createdAt: DateTime.now(),
        ));

        slotStart = slotEnd;
      }

      if (slots.isNotEmpty) {
        await _service.addMultipleSlots(slots);
      }

      state = state.copyWith(isSaving: false);
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        error: 'Failed to add slots: $e',
      );
    }
  }

  /// Remove a single slot
  Future<void> removeSlot(String slotId) async {
    state = state.copyWith(isSaving: true, clearError: true);

    try {
      await _service.removeSlot(slotId);
      state = state.copyWith(isSaving: false);
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        error: 'Failed to remove slot: $e',
      );
    }
  }

  /// Remove selected slots
  Future<void> removeSelectedSlots() async {
    if (state.selectedSlotIds.isEmpty) return;

    state = state.copyWith(isSaving: true, clearError: true);

    try {
      await _service.removeMultipleSlots(state.selectedSlotIds.toList());
      state = state.copyWith(isSaving: false, selectedSlotIds: {});
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        error: 'Failed to remove slots: $e',
      );
    }
  }

  /// Save weekly template
  Future<void> saveWeeklyTemplate(WeeklyAvailability template) async {
    state = state.copyWith(isSaving: true, clearError: true);

    try {
      await _service.setWeeklyTemplate(template);
      state = state.copyWith(isSaving: false);
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        error: 'Failed to save template: $e',
      );
    }
  }

  /// Update availability for a specific day in the weekly template
  Future<void> updateDayAvailability(int day, List<TimeRange> timeRanges) async {
    state = state.copyWith(isSaving: true, clearError: true);

    try {
      await _service.updateDayAvailability(therapistId, day, timeRanges);
      state = state.copyWith(isSaving: false);
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        error: 'Failed to update day availability: $e',
      );
    }
  }

  /// Create default weekly template
  Future<void> createDefaultTemplate() async {
    state = state.copyWith(isSaving: true, clearError: true);

    try {
      final template = WeeklyAvailability.defaultTemplate(therapistId);
      await _service.setWeeklyTemplate(template);
      state = state.copyWith(isSaving: false);
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        error: 'Failed to create template: $e',
      );
    }
  }

  /// Auto-generate slots from template
  Future<int> autoGenerateSlots({int weeks = 2}) async {
    state = state.copyWith(isSaving: true, clearError: true);

    try {
      final count = await _service.autoGenerateSlots(therapistId, weeks);
      state = state.copyWith(isSaving: false);
      return count;
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        error: 'Failed to generate slots: $e',
      );
      return 0;
    }
  }

  /// Cleanup past unbooked slots
  Future<int> cleanupPastSlots() async {
    state = state.copyWith(isSaving: true, clearError: true);

    try {
      final count = await _service.cleanupPastSlots(therapistId);
      state = state.copyWith(isSaving: false);
      return count;
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        error: 'Failed to cleanup slots: $e',
      );
      return 0;
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  @override
  void dispose() {
    _slotsSubscription?.cancel();
    _templateSubscription?.cancel();
    super.dispose();
  }
}

/// Provider family for therapist availability
final therapistAvailabilityProvider = StateNotifierProvider.family<
    TherapistAvailabilityNotifier, TherapistAvailabilityState, String>(
  (ref, therapistId) => TherapistAvailabilityNotifier(therapistId: therapistId),
);

/// Provider for the currently authenticated therapist's availability
final currentTherapistAvailabilityProvider =
    StateNotifierProvider<TherapistAvailabilityNotifier, TherapistAvailabilityState>(
  (ref) {
    // This should be overridden with the actual therapist ID
    // For now, we throw an error if not properly configured
    throw UnimplementedError(
      'currentTherapistAvailabilityProvider must be overridden with actual therapist ID',
    );
  },
);
