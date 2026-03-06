import 'package:hive_flutter/hive_flutter.dart';

import '../../domain/entities/usage_log_entity.dart';

part 'usage_log_model.g.dart';

/// Hive-persisted + Firestore-compatible DTO for [UsageLogEntity].
@HiveType(typeId: 1)
final class UsageLogModel extends HiveObject {
  UsageLogModel({
    required this.sessionId,
    required this.wordsLearned,
    required this.durationSeconds,
    required this.startedAtMs,
    this.isOffline = false,
    this.isSynced = false,
  });

  @HiveField(0)
  final String sessionId;

  @HiveField(1)
  final List<String> wordsLearned;

  @HiveField(2)
  final int durationSeconds;

  @HiveField(3)
  final int startedAtMs;

  @HiveField(4)
  final bool isOffline;

  @HiveField(5)
  bool isSynced;

  UsageLogEntity toEntity() => UsageLogEntity(
        sessionId: sessionId,
        wordsLearned: List<String>.from(wordsLearned),
        durationSeconds: durationSeconds,
        startedAt:
            DateTime.fromMillisecondsSinceEpoch(startedAtMs, isUtc: true),
        isOffline: isOffline,
        isSynced: isSynced,
      );

  factory UsageLogModel.fromEntity(UsageLogEntity entity) => UsageLogModel(
        sessionId: entity.sessionId,
        wordsLearned: List<String>.from(entity.wordsLearned),
        durationSeconds: entity.durationSeconds,
        startedAtMs: entity.startedAt.millisecondsSinceEpoch,
        isOffline: entity.isOffline,
        isSynced: entity.isSynced,
      );

  Map<String, dynamic> toFirestore() => {
        'session_id': sessionId,
        'words_learned': wordsLearned,
        'duration_seconds': durationSeconds,
        'timestamp': DateTime.fromMillisecondsSinceEpoch(startedAtMs),
        'is_offline': isOffline,
      };
}
