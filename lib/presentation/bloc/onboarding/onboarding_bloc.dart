import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../core/network/network_info.dart';
import '../../../core/utils/logger.dart';
import '../../../domain/repositories/asset_repository.dart';
import '../../../domain/usecases/cache_assets_usecase.dart';

part 'onboarding_event.dart';
part 'onboarding_state.dart';

/// Manages the first-launch flow:
/// 1. Check camera permission
/// 2. If online: download and cache all 3D assets
/// 3. If offline + cached: proceed to camera
/// 4. If offline + no cache: show "connect to Wi-Fi" screen
@injectable
final class OnboardingBloc extends Bloc<OnboardingEvent, OnboardingState> {
  OnboardingBloc(
    this._cacheAssetsUseCase,
    this._assetRepository,
    this._networkInfo,
  ) : super(const OnboardingInitial()) {
    on<OnboardingCheck>(_onCheck);
    on<OnboardingPermissionGranted>(_onPermissionGranted);
    on<OnboardingPermissionDenied>(_onPermissionDenied);
    on<OnboardingDownloadProgress>(_onDownloadProgress);
    on<OnboardingComplete>(_onComplete);
  }

  final CacheAssetsUseCase _cacheAssetsUseCase;
  final AssetRepository _assetRepository;
  final NetworkInfo _networkInfo;

  Future<void> _onCheck(
    OnboardingCheck event,
    Emitter<OnboardingState> emit,
  ) async {
    emit(const OnboardingCheckingPermissions());
    // Permission request is handled in SplashScreen, which dispatches
    // OnboardingPermissionGranted or OnboardingPermissionDenied.
  }

  Future<void> _onPermissionGranted(
    OnboardingPermissionGranted event,
    Emitter<OnboardingState> emit,
  ) async {
    final hasCache = await _assetRepository.hasLocalCache();
    final isOnline = await _networkInfo.isConnected;

    if (!isOnline && hasCache) {
      AppLogger.i('OnboardingBloc: offline + cached → ready');
      emit(const OnboardingOfflineReady());
      return;
    }

    if (!isOnline && !hasCache) {
      AppLogger.w('OnboardingBloc: offline + no cache → blocked');
      emit(const OnboardingOfflineNoAssets());
      return;
    }

    // Online — start asset download
    emit(const OnboardingDownloading(0.0));
    final result = await _cacheAssetsUseCase();
    result.fold(
      (failure) {
        AppLogger.e('OnboardingBloc: asset download failed', failure.message);
        // Fallback: if some assets were cached, proceed anyway
        emit(
          hasCache
              ? const OnboardingOfflineReady()
              : const OnboardingOfflineNoAssets(),
        );
      },
      (_) {
        AppLogger.i('OnboardingBloc: all assets cached');
        emit(const OnboardingReady());
      },
    );
  }

  Future<void> _onPermissionDenied(
    OnboardingPermissionDenied event,
    Emitter<OnboardingState> emit,
  ) async {
    emit(const OnboardingPermissionRequired());
  }

  Future<void> _onDownloadProgress(
    OnboardingDownloadProgress event,
    Emitter<OnboardingState> emit,
  ) async {
    emit(OnboardingDownloading(event.progressPercent));
  }

  Future<void> _onComplete(
    OnboardingComplete event,
    Emitter<OnboardingState> emit,
  ) async {
    emit(const OnboardingReady());
  }
}
