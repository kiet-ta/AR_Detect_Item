import 'package:firebase_storage/firebase_storage.dart';
import 'package:injectable/injectable.dart';

import '../../../core/errors/exceptions.dart';

/// Firebase Storage operations: download assets, upload failed drawings.
@injectable
final class FirebaseStorageService {
  FirebaseStorageService(this._storage);

  final FirebaseStorage _storage;

  /// Downloads a file from [remotePath] and returns its bytes.
  ///
  /// Used for 3D models (.glb) and audio files (.mp3).
  Future<List<int>> downloadFile(String remotePath) async {
    try {
      final ref = _storage.ref(remotePath);
      // Cap download size: 50MB (model) or 5MB (audio)
      const maxDownloadBytes = 50 * 1024 * 1024; // 50 MB
      final bytes = await ref.getData(maxDownloadBytes);
      if (bytes == null || bytes.isEmpty) {
        throw ServerException('Downloaded empty file from: $remotePath');
      }
      return bytes;
    } on FirebaseException catch (e) {
      throw ServerException(
        'Firebase Storage download failed [$remotePath]: ${e.message}',
      );
    }
  }

  /// Uploads a failed drawing image (grayscale bytes) to Storage.
  ///
  /// Returns the Storage path of the uploaded file.
  Future<String> uploadFailedDrawing({
    required String drawingId,
    required List<int> imageBytes,
  }) async {
    try {
      final path = 'failed_drawings/$drawingId.jpg';
      final ref = _storage.ref(path);
      await ref.putData(
        imageBytes as dynamic,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      return path;
    } on FirebaseException catch (e) {
      throw ServerException(
        'Firebase Storage upload failed [$drawingId]: ${e.message}',
      );
    }
  }
}
