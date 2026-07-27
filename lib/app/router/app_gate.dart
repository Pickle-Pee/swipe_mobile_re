import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/application/auth_providers.dart';
import '../../features/auth/application/auth_state.dart';
import '../../features/onboarding/domain/onboarding_models.dart';
import '../../features/profile/application/profile_providers.dart';

enum AppGateStatus {
  checkingSession,
  signedOut,
  loadingProfile,
  onboardingRequired,
  ready,
  unavailable,
}

class AppGateState {
  const AppGateState(this.status, {this.error});

  final AppGateStatus status;
  final Object? error;
}

final appGateProvider = Provider<AppGateState>((ref) {
  final auth = ref.watch(authControllerProvider);
  switch (auth.status) {
    case AuthStatus.initial:
    case AuthStatus.restoring:
    case AuthStatus.signingOut:
      return const AppGateState(AppGateStatus.checkingSession);
    case AuthStatus.unauthenticated:
    case AuthStatus.submitting:
      return const AppGateState(AppGateStatus.signedOut);
    case AuthStatus.restoreError:
      return AppGateState(AppGateStatus.unavailable, error: auth.error);
    case AuthStatus.authenticated:
      final profileState = ref.watch(profileControllerProvider);
      switch (profileState.status) {
        case ProfileStatus.initial:
        case ProfileStatus.loading:
          return const AppGateState(AppGateStatus.loadingProfile);
        case ProfileStatus.error:
          return AppGateState(
            AppGateStatus.unavailable,
            error: profileState.error,
          );
        case ProfileStatus.empty:
        case ProfileStatus.data:
          final profile = profileState.profile;
          if (profile == null) {
            return const AppGateState(AppGateStatus.loadingProfile);
          }
          return OnboardingReadiness.fromProfile(profile).isComplete
              ? const AppGateState(AppGateStatus.ready)
              : const AppGateState(AppGateStatus.onboardingRequired);
      }
  }
});
