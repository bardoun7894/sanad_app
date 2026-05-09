// lib/features/booking/providers/booking_unlock_provider.dart
//
// Streams the bank_transfer_unlocked flag from Firestore for a given booking.
// The flag defaults to false on new bookings; admin sets it to true via
// BookingService.unlockBankTransfer(bookingId).

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Emits `true` when the admin has unlocked bank transfer for [bookingId],
/// `false` otherwise (including when the field is absent on legacy docs).
///
/// The screen watches this provider so it updates live — no restart required.
final bankTransferUnlockedProvider =
    StreamProvider.family<bool, String>((ref, bookingId) {
  return FirebaseFirestore.instance
      .collection('bookings')
      .doc(bookingId)
      .snapshots()
      .map((snap) {
    if (!snap.exists) return false;
    return (snap.data()!['bank_transfer_unlocked'] as bool?) ?? false;
  });
});
