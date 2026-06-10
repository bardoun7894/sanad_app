import 'package:cloud_firestore/cloud_firestore.dart';

/// A clinical/session note written by an admin or therapist about a patient.
///
/// Stored at `users/{userId}/clinical_notes/{noteId}` — the same per-patient
/// subcollection convention used by `reports`.
class ClinicalNote {
  final String id;
  final String text;
  final String authorId;
  final String authorName;
  final DateTime? createdAt;

  const ClinicalNote({
    required this.id,
    required this.text,
    required this.authorId,
    required this.authorName,
    this.createdAt,
  });

  factory ClinicalNote.fromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final ts = data['created_at'];
    return ClinicalNote(
      id: doc.id,
      text: (data['text'] as String?) ?? '',
      authorId: (data['author_id'] as String?) ?? '',
      authorName: (data['author_name'] as String?) ?? 'Unknown',
      createdAt: ts is Timestamp ? ts.toDate() : null,
    );
  }

  Map<String, dynamic> toMap() => {
        'text': text,
        'author_id': authorId,
        'author_name': authorName,
        // Client timestamp (not serverTimestamp) so the note is immediately
        // non-null and orderable — a pending serverTimestamp reads as null
        // locally and would make the just-added note jump out of order.
        'created_at': Timestamp.fromDate(createdAt ?? DateTime.now()),
      };
}
