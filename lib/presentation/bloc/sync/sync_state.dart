part of 'sync_bloc.dart';

sealed class SyncState extends Equatable {
  const SyncState();

  @override
  List<Object?> get props => [];
}

final class SyncIdle extends SyncState {
  const SyncIdle();
}

final class SyncOffline extends SyncState {
  const SyncOffline();
}

final class SyncUploading extends SyncState {
  const SyncUploading();
}

final class SyncComplete extends SyncState {
  const SyncComplete(this.uploadedCount);
  final int uploadedCount;

  @override
  List<Object?> get props => [uploadedCount];
}

final class SyncFailed extends SyncState {
  const SyncFailed(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}
