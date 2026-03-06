part of 'onboarding_bloc.dart';

sealed class OnboardingEvent {
  const OnboardingEvent();
}

/// Check if this is the first launch and what setup is needed.
final class OnboardingCheck extends OnboardingEvent {
  const OnboardingCheck();
}

/// User granted camera permission.
final class OnboardingPermissionGranted extends OnboardingEvent {
  const OnboardingPermissionGranted();
}

/// User denied camera permission.
final class OnboardingPermissionDenied extends OnboardingEvent {
  const OnboardingPermissionDenied();
}

/// Asset download progress updated.
final class OnboardingDownloadProgress extends OnboardingEvent {
  const OnboardingDownloadProgress(this.progressPercent);
  final double progressPercent;
}

/// All assets downloaded and cached.
final class OnboardingComplete extends OnboardingEvent {
  const OnboardingComplete();
}
