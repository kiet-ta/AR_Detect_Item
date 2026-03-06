part of 'sync_bloc.dart';

sealed class SyncEvent {
  const SyncEvent();
}

/// Start monitoring connectivity (called on app start).
final class SyncStartMonitoring extends SyncEvent {
  const SyncStartMonitoring();
}

/// Connectivity changed to online — trigger upload.
final class SyncConnectivityOnline extends SyncEvent {
  const SyncConnectivityOnline();
}

/// Connectivity changed to offline.
final class SyncConnectivityOffline extends SyncEvent {
  const SyncConnectivityOffline();
}
