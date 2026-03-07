import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../core/utils/logger.dart';
import '../../../domain/repositories/sync_repository.dart';
import '../../../domain/usecases/sync_failed_drawings_usecase.dart';

part 'sync_event.dart';
part 'sync_state.dart';

/// Monitors connectivity and runs the Data Flywheel upload in background.
/// Registered as a singleton — runs for the entire app lifetime.
@singleton
final class SyncBloc extends Bloc<SyncEvent, SyncState> {
  SyncBloc(
    this._syncUseCase,
    this._syncRepository,
  ) : super(const SyncIdle()) {
    on<SyncStartMonitoring>(_onStartMonitoring);
    on<SyncConnectivityOnline>(_onOnline);
    on<SyncConnectivityOffline>(_onOffline);
  }

  final SyncFailedDrawingsUseCase _syncUseCase;
  final SyncRepository _syncRepository;
  StreamSubscription<ConnectivityStatus>? _connectivitySub;

  Future<void> _onStartMonitoring(
    SyncStartMonitoring event,
    Emitter<SyncState> emit,
  ) async {
    _connectivitySub?.cancel();
    _connectivitySub = _syncRepository.connectivityStream.listen((status) {
      if (status == ConnectivityStatus.online) {
        add(const SyncConnectivityOnline());
      } else {
        add(const SyncConnectivityOffline());
      }
    });
  }

  Future<void> _onOnline(
    SyncConnectivityOnline event,
    Emitter<SyncState> emit,
  ) async {
    final queuedCount = await _syncRepository.getQueuedDrawingCount();
    if (queuedCount == 0) {
      emit(const SyncIdle());
      return;
    }

    emit(const SyncUploading());
    AppLogger.i('SyncBloc: uploading $queuedCount failed drawings');

    final result = await _syncUseCase();
    result.fold(
      (failure) {
        AppLogger.w('SyncBloc: upload failed', failure.message);
        emit(SyncFailed(failure.message));
      },
      (count) {
        AppLogger.i('SyncBloc: uploaded $count drawings');
        emit(SyncComplete(count));
      },
    );
  }

  Future<void> _onOffline(
    SyncConnectivityOffline event,
    Emitter<SyncState> emit,
  ) async {
    emit(const SyncOffline());
  }

  @override
  Future<void> close() {
    _connectivitySub?.cancel();
    return super.close();
  }
}
