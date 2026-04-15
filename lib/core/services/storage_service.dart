import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

class StorageService {
  final FirebaseStorage _storage;

  StorageService({FirebaseStorage? storage})
    : _storage = storage ?? FirebaseStorage.instance;

  /// Upload file bytes to Firebase Storage and return the download URL
  ///
  /// [path]: The storage path (e.g., 'profile_photos/user123.jpg')
  /// [data]: The file bytes to upload
  /// [contentType]: MIME type (e.g., 'image/jpeg')
  Future<String> uploadFile({
    required String path,
    required Uint8List data,
    String? contentType,
  }) async {
    try {
      final ref = _storage.ref().child(path);
      final metadata = SettableMetadata(contentType: contentType);

      // putData works on all platforms (mobile, web, desktop)
      final uploadTask = ref.putData(data, metadata);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading file: $e');
      throw Exception('Failed to upload file: $e');
    }
  }

  /// Delete a file from Firebase Storage
  ///
  /// [path]: The storage path or download URL to delete
  Future<void> deleteFile(String path) async {
    try {
      Reference ref;
      if (path.startsWith('http')) {
        ref = _storage.refFromURL(path);
      } else {
        ref = _storage.ref().child(path);
      }
      await ref.delete();
    } catch (e) {
      debugPrint('Error deleting file: $e');
      // We don't throw here as the file might already be gone
    }
  }
}
