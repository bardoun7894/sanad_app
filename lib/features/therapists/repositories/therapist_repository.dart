import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/firestore_cache_helper.dart';
import '../../therapist_portal/models/therapist_profile.dart';

final therapistRepositoryProvider = Provider((ref) => TherapistRepository());

class TherapistRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Demo therapists for when Firestore is empty

  Future<List<TherapistProfile>> getApprovedTherapists() async {
    try {
      final query = await _firestore
          .collection('therapists')
          .where('is_active', isEqualTo: true)
          .where('approval_status', isEqualTo: 'approved')
          .orderBy('rating', descending: true)
          .getCacheFirst();

      if (query.docs.isEmpty) return [];

      return query.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return TherapistProfile.fromJson(data);
      }).toList();
    } catch (e) {
      // Return empty list on error
      return [];
    }
  }

  Future<TherapistProfile?> getTherapistById(String id) async {
    try {
      final doc = await _firestore
          .collection('therapists')
          .doc(id)
          .getCacheFirst();
      if (!doc.exists) return null;

      final data = doc.data()!;
      data['id'] = doc.id;
      return TherapistProfile.fromJson(data);
    } catch (e) {
      return null;
    }
  }
}
