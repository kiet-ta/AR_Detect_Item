part of 'onboarding_bloc.dart';

sealed class OnboardingState extends Equatable {
  const OnboardingState();

  @override
  List<Object?> get props => [];
}

final class OnboardingInitial extends OnboardingState {
  const OnboardingInitial();
}

final class OnboardingCheckingPermissions extends OnboardingState {
  const OnboardingCheckingPermissions();
}

final class OnboardingPermissionRequired extends OnboardingState {
  const OnboardingPermissionRequired();
}

final class OnboardingDownloading extends OnboardingState {
  const OnboardingDownloading(this.progressPercent);
  final double progressPercent;

  @override
  List<Object?> get props => [progressPercent];
}

final class OnboardingReady extends OnboardingState {
  const OnboardingReady();
}

final class OnboardingOfflineReady extends OnboardingState {
  const OnboardingOfflineReady();
}

final class OnboardingOfflineNoAssets extends OnboardingState {
  const OnboardingOfflineNoAssets();
}
