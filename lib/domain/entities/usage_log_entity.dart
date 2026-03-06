import 'package:equatable/equatable.dart';

/// A learning session record — used for the parent dashboard
/// and for the Data Flywheel analytics pipeline.
final class UsageLogEntity extends Equatable {
  const UsageLogEntity({
    required this.sessionId,
    required this.wordsLearned,
    required this.durationSeconds,
    required this.startedAt,
    this.isOffline = false,
    this.isSynced = false,
  });

  /// Unique session identifier (UUID v4).
  final String sessionId;

  /// List of vocabulary labels successfully recognized in this session.
  final List<String> wordsLearned;

  /// Total session duration in seconds.
  final int durationSeconds;

  /// UTC timestamp of session start.
  final DateTime startedAt;

  /// True if the session occurred without internet connectivity.
  final bool isOffline;

  /// True if this log has been synced to Firestore.
  final bool isSynced;

  UsageLogEntity copyWith({
    String? sessionId,
    List<String>? wordsLearned,
    int? durationSeconds,
    DateTime? startedAt,
    bool? isOffline,
    bool? isSynced,
  }) {
    return UsageLogEntity(
      sessionId: sessionId ?? this.sessionId,
      wordsLearned: wordsLearned ?? this.wordsLearned,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      startedAt: startedAt ?? this.startedAt,
      isOffline: isOffline ?? this.isOffline,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  @override
  List<Object?> get props => [
        sessionId,
        wordsLearned,
        durationSeconds,
        startedAt,
        isOffline,
        isSynced,
      ];
}
