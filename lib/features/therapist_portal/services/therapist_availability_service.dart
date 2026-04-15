import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/therapist_availability.dart';

/// Service for managing therapist availability
class TherapistAvailabilityService {
  final FirebaseFirestore _firestore;

  TherapistAvailabilityService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Collection references
  CollectionReference<Map<String, dynamic>> get _availabilityCollection =>
      _firestore.collection('therapist_availability');

  CollectionReference<Map<String, dynamic>> get _weeklyAvailabilityCollection =>
      _firestore.collection('therapist_weekly_availability');

  /// Get availability slots for a therapist in a date range
  Stream<List<AvailabilitySlot>> getAvailability(
    String therapistId,
    DateTime from,
    DateTime to,
  ) {
    return _availabilityCollection
        .where('therapist_id', isEqualTo: therapistId)
        .where('start_time', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
        .where('start_time', isLessThanOrEqualTo: Timestamp.fromDate(to))
        .orderBy('start_time')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => AvailabilitySlot.fromFirestore(doc))
          .toList();
    });
  }

  /// Get available (not booked) slots for a therapist
  Stream<List<AvailabilitySlot>> getAvailableSlots(
    String therapistId,
    DateTime from,
    DateTime to,
  ) {
    return _availabilityCollection
        .where('therapist_id', isEqualTo: therapistId)
        .where('is_booked', isEqualTo: false)
        .where('start_time', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
        .where('start_time', isLessThanOrEqualTo: Timestamp.fromDate(to))
        .orderBy('start_time')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => AvailabilitySlot.fromFirestore(doc))
          .where((slot) => !slot.isPast) // Filter out past slots
          .toList();
    });
  }

  /// Get availability slots for today
  Stream<List<AvailabilitySlot>> getTodaysAvailability(String therapistId) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return getAvailability(therapistId, startOfDay, endOfDay);
  }

  /// Add a single availability slot
  Future<String> addSlot(AvailabilitySlot slot) async {
    try {
      // Check for conflicts
      final conflicts = await _checkConflicts(
        slot.therapistId,
        slot.startTime,
        slot.endTime,
      );

      if (conflicts.isNotEmpty) {
        throw Exception('Time slot conflicts with existing availability');
      }

      final docRef = await _availabilityCollection.add(slot.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to add slot: $e');
    }
  }

  /// Add multiple slots at once
  Future<List<String>> addMultipleSlots(List<AvailabilitySlot> slots) async {
    try {
      final batch = _firestore.batch();
      final docIds = <String>[];

      for (final slot in slots) {
        final docRef = _availabilityCollection.doc();
        batch.set(docRef, slot.toFirestore());
        docIds.add(docRef.id);
      }

      await batch.commit();
      return docIds;
    } catch (e) {
      throw Exception('Failed to add slots: $e');
    }
  }

  /// Remove an availability slot
  Future<void> removeSlot(String slotId) async {
    try {
      final doc = await _availabilityCollection.doc(slotId).get();
      if (doc.exists) {
        final data = doc.data();
        if (data?['is_booked'] == true) {
          throw Exception('Cannot remove a booked slot');
        }
      }

      await _availabilityCollection.doc(slotId).delete();
    } catch (e) {
      throw Exception('Failed to remove slot: $e');
    }
  }

  /// Remove multiple slots
  Future<void> removeMultipleSlots(List<String> slotIds) async {
    try {
      final batch = _firestore.batch();

      for (final slotId in slotIds) {
        batch.delete(_availabilityCollection.doc(slotId));
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to remove slots: $e');
    }
  }

  /// Mark a slot as booked
  Future<void> markSlotBooked(String slotId, String bookingId) async {
    try {
      await _availabilityCollection.doc(slotId).update({
        'is_booked': true,
        'booking_id': bookingId,
      });
    } catch (e) {
      throw Exception('Failed to mark slot as booked: $e');
    }
  }

  /// Mark a slot as available (unbook)
  Future<void> markSlotAvailable(String slotId) async {
    try {
      await _availabilityCollection.doc(slotId).update({
        'is_booked': false,
        'booking_id': null,
      });
    } catch (e) {
      throw Exception('Failed to mark slot as available: $e');
    }
  }

  /// Get weekly availability template
  Future<WeeklyAvailability?> getWeeklyTemplate(String therapistId) async {
    try {
      final doc = await _weeklyAvailabilityCollection.doc(therapistId).get();
      if (!doc.exists) return null;
      return WeeklyAvailability.fromFirestore(doc);
    } catch (e) {
      throw Exception('Failed to get weekly template: $e');
    }
  }

  /// Get weekly availability template as stream
  Stream<WeeklyAvailability?> getWeeklyTemplateStream(String therapistId) {
    return _weeklyAvailabilityCollection.doc(therapistId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return WeeklyAvailability.fromFirestore(doc);
    });
  }

  /// Set weekly availability template
  Future<void> setWeeklyTemplate(WeeklyAvailability template) async {
    try {
      await _weeklyAvailabilityCollection
          .doc(template.therapistId)
          .set(template.toFirestore());
    } catch (e) {
      throw Exception('Failed to set weekly template: $e');
    }
  }

  /// Update weekly availability for a specific day
  Future<void> updateDayAvailability(
    String therapistId,
    int day,
    List<TimeRange> timeRanges,
  ) async {
    try {
      await _weeklyAvailabilityCollection.doc(therapistId).set({
        'weekly_slots.$day': timeRanges.map((r) => r.toMap()).toList(),
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to update day availability: $e');
    }
  }

  /// Generate slots from weekly template for a date range
  Future<List<AvailabilitySlot>> generateSlotsFromTemplate(
    String therapistId,
    DateTime from,
    DateTime to,
    int slotDurationMinutes,
  ) async {
    try {
      final template = await getWeeklyTemplate(therapistId);
      if (template == null) return [];

      final slots = <AvailabilitySlot>[];
      var currentDate = from;

      while (currentDate.isBefore(to)) {
        final dayOfWeek = currentDate.weekday % 7; // 0 = Sunday

        final dayRanges = template.weeklySlots[dayOfWeek] ?? [];

        for (final range in dayRanges) {
          var slotStart = DateTime(
            currentDate.year,
            currentDate.month,
            currentDate.day,
            range.startHour,
            range.startMinute,
          );

          final rangeEnd = DateTime(
            currentDate.year,
            currentDate.month,
            currentDate.day,
            range.endHour,
            range.endMinute,
          );

          while (slotStart.add(Duration(minutes: slotDurationMinutes)).isBefore(rangeEnd) ||
              slotStart.add(Duration(minutes: slotDurationMinutes)).isAtSameMomentAs(rangeEnd)) {
            final slotEnd = slotStart.add(Duration(minutes: slotDurationMinutes));

            slots.add(AvailabilitySlot(
              id: '', // Will be assigned by Firestore
              therapistId: therapistId,
              startTime: slotStart,
              endTime: slotEnd,
              isBooked: false,
              createdAt: DateTime.now(),
            ));

            slotStart = slotEnd;
          }
        }

        currentDate = currentDate.add(const Duration(days: 1));
      }

      return slots;
    } catch (e) {
      throw Exception('Failed to generate slots: $e');
    }
  }

  /// Auto-generate slots for next N weeks
  Future<int> autoGenerateSlots(String therapistId, int weeks) async {
    try {
      final now = DateTime.now();
      final from = DateTime(now.year, now.month, now.day);
      final to = from.add(Duration(days: weeks * 7));

      final template = await getWeeklyTemplate(therapistId);
      if (template == null) {
        throw Exception('No weekly template found');
      }

      final slots = await generateSlotsFromTemplate(
        therapistId,
        from,
        to,
        template.slotDurationMinutes,
      );

      if (slots.isEmpty) return 0;

      await addMultipleSlots(slots);
      return slots.length;
    } catch (e) {
      throw Exception('Failed to auto-generate slots: $e');
    }
  }

  /// Check for conflicts with existing slots
  Future<List<AvailabilitySlot>> _checkConflicts(
    String therapistId,
    DateTime startTime,
    DateTime endTime,
  ) async {
    // Get slots that might overlap
    final snapshot = await _availabilityCollection
        .where('therapist_id', isEqualTo: therapistId)
        .where('start_time', isLessThan: Timestamp.fromDate(endTime))
        .get();

    final conflicts = <AvailabilitySlot>[];

    for (final doc in snapshot.docs) {
      final slot = AvailabilitySlot.fromFirestore(doc);
      // Check if this slot overlaps with the new one
      if (slot.endTime.isAfter(startTime)) {
        conflicts.add(slot);
      }
    }

    return conflicts;
  }

  /// Delete all past availability slots (cleanup)
  Future<int> cleanupPastSlots(String therapistId) async {
    try {
      final now = DateTime.now();
      final snapshot = await _availabilityCollection
          .where('therapist_id', isEqualTo: therapistId)
          .where('end_time', isLessThan: Timestamp.fromDate(now))
          .where('is_booked', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      return snapshot.docs.length;
    } catch (e) {
      throw Exception('Failed to cleanup past slots: $e');
    }
  }
}
