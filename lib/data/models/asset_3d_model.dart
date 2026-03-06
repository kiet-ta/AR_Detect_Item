import '../../domain/entities/asset_3d_entity.dart';

/// Firestore document DTO for [Asset3DEntity].
/// The [localModelPath], [localAudioPathEn], [localAudioPathVi] fields
/// are resolved at runtime after the files are cached to device storage.
final class Asset3DModel {
  const Asset3DModel({
    required this.label,
    required this.remoteModelPath,
    required this.remoteAudioPathEn,
    required this.remoteAudioPathVi,
    required this.vocabularyEn,
    required this.vocabularyVi,
    required this.category,
    required this.version,
    this.localModelPath = '',
    this.localAudioPathEn = '',
    this.localAudioPathVi = '',
  });

  final String label;
  final String remoteModelPath;
  final String remoteAudioPathEn;
  final String remoteAudioPathVi;
  final String vocabularyEn;
  final String vocabularyVi;
  final String category;
  final int version;
  final String localModelPath;
  final String localAudioPathEn;
  final String localAudioPathVi;

  Asset3DEntity toEntity() => Asset3DEntity(
        label: label,
        localModelPath: localModelPath,
        localAudioPathEn: localAudioPathEn,
        localAudioPathVi: localAudioPathVi,
        vocabularyEn: vocabularyEn,
        vocabularyVi: vocabularyVi,
        category: category,
        remoteModelPath: remoteModelPath,
        version: version,
      );

  factory Asset3DModel.fromFirestore(Map<String, dynamic> doc) {
    return Asset3DModel(
      label: doc['label'] as String,
      remoteModelPath: doc['storage_path'] as String,
      remoteAudioPathEn: doc['audio_path_en'] as String? ?? '',
      remoteAudioPathVi: doc['audio_path_vi'] as String? ?? '',
      vocabularyEn: doc['vocabulary_en'] as String,
      vocabularyVi: doc['vocabulary_vi'] as String,
      category: doc['category'] as String,
      version: (doc['version'] as num?)?.toInt() ?? 1,
    );
  }

  Asset3DModel withLocalPaths({
    required String modelPath,
    required String audioEnPath,
    required String audioViPath,
  }) {
    return Asset3DModel(
      label: label,
      remoteModelPath: remoteModelPath,
      remoteAudioPathEn: remoteAudioPathEn,
      remoteAudioPathVi: remoteAudioPathVi,
      vocabularyEn: vocabularyEn,
      vocabularyVi: vocabularyVi,
      category: category,
      version: version,
      localModelPath: modelPath,
      localAudioPathEn: audioEnPath,
      localAudioPathVi: audioViPath,
    );
  }
}
