import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';

import '../../../core/constants/firestore_collections.dart';
import '../../../core/errors/exceptions.dart';
import '../../models/asset_3d_model.dart';
import '../../models/usage_log_model.dart';

/// Centralized Firestore operations for Magic Doodle.
///
/// All collection names come from [FirestoreCollections] constants.
/// Methods wrap Firestore exceptions into [ServerException].
@injectable
final class FirestoreService {
  FirestoreService(this._firestore);

  final FirebaseFirestore _firestore;

  // --- Asset Manifest ---

  /// Fetches the full list of available 3D assets from the manifest.
  Future<List<Asset3DModel>> fetchAssetManifest() async {
    try {
      final snapshot =
          await _firestore.collection(FirestoreCollections.assetManifest).get();
      return snapshot.docs
          .map((doc) => Asset3DModel.fromFirestore(doc.data()))
          .toList();
    } on FirebaseException catch (e) {
      throw ServerException(
          'Firestore fetchAssetManifest failed: ${e.message}');
    }
  }

  // --- Usage Logs ---

  /// Writes a [UsageLogModel] to Firestore.
  Future<void> writeUsageLog(UsageLogModel log) async {
    try {
      await _firestore
          .collection(FirestoreCollections.usageLogs)
          .doc(log.sessionId)
          .set(log.toFirestore());
    } on FirebaseException catch (e) {
      throw ServerException('Firestore writeUsageLog failed: ${e.message}');
    }
  }

  // --- Failed Drawings ---

  /// Writes failed drawing metadata (no binary — binary goes to Storage).
  Future<void> writeFailedDrawingMetadata({
    required String drawingId,
    required String storagePath,
    required double confidence,
  }) async {
    try {
      await _firestore
          .collection(FirestoreCollections.failedDrawings)
          .doc(drawingId)
          .set({
        FirestoreCollections.fieldLabel: drawingId,
        FirestoreCollections.fieldConfidence: confidence,
        FirestoreCollections.fieldNeedsRetraining: true,
        FirestoreCollections.fieldTimestamp: FieldValue.serverTimestamp(),
        'storage_path': storagePath,
      });
    } on FirebaseException catch (e) {
      throw ServerException(
        'Firestore writeFailedDrawingMetadata failed: ${e.message}',
      );
    }
  }
}
