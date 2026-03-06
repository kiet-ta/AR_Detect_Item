import 'package:equatable/equatable.dart';

/// A 3D model asset paired with bilingual audio for a vocabulary word.
final class Asset3DEntity extends Equatable {
  const Asset3DEntity({
    required this.label,
    required this.localModelPath,
    required this.localAudioPathEn,
    required this.localAudioPathVi,
    required this.vocabularyEn,
    required this.vocabularyVi,
    required this.category,
    this.remoteModelPath,
    this.version = 1,
  });

  /// Classifier label, maps to TFLite output (e.g. 'apple').
  final String label;

  /// Absolute path to the locally cached .glb file.
  final String localModelPath;

  /// Absolute path to the locally cached English audio file.
  final String localAudioPathEn;

  /// Absolute path to the locally cached Vietnamese audio file.
  final String localAudioPathVi;

  /// English vocabulary word (e.g. 'Apple').
  final String vocabularyEn;

  /// Vietnamese vocabulary word (e.g. 'Quả Táo').
  final String vocabularyVi;

  /// Vocabulary category (e.g. 'food', 'animals').
  final String category;

  /// Firebase Storage path for remote download.
  final String? remoteModelPath;

  /// Asset version for cache invalidation.
  final int version;

  /// Whether this asset is fully cached and ready to display offline.
  bool get isReadyOffline =>
      localModelPath.isNotEmpty &&
      localAudioPathEn.isNotEmpty &&
      localAudioPathVi.isNotEmpty;

  @override
  List<Object?> get props => [
        label,
        localModelPath,
        localAudioPathEn,
        localAudioPathVi,
        vocabularyEn,
        vocabularyVi,
        category,
        version,
      ];
}
