import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/chat/chat_list_screen.dart';
import '../../features/chat/chat_screen.dart';
import '../../features/auth/presentation/app_bootstrap_screen.dart';
import '../../features/auth/presentation/phone_auth_screen.dart';
import '../../features/auth/presentation/welcome_screen.dart';
import '../../features/discovery/discovery_screen.dart';
import '../../features/discovery/domain/discovery_models.dart';
import '../../features/likes/likes_screen.dart';
import '../../features/match/match_screen.dart';
import '../../features/onboarding/application/onboarding_providers.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/onboarding/registration_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/profile/edit_profile_screen.dart';
import '../../features/profile/domain/profile_models.dart';
import '../../features/profile/own_profile_preview_screen.dart';
import '../../features/profile/public_profile_screen.dart';
import '../../features/settings/account_settings_screen.dart';
import '../../features/settings/app_information_screen.dart';
import '../../features/settings/delete_account_screen.dart';
import '../../features/settings/discovery_preferences_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/subscription/subscription_screen.dart';
import '../shell/main_shell.dart';
import 'app_gate.dart';
import 'routes.dart';

final _routerRefreshProvider = Provider<_RouterRefreshNotifier>((ref) {
  final notifier = _RouterRefreshNotifier();
  ref.listen(appGateProvider, (_, _) => notifier.refresh());
  ref.listen(
    onboardingControllerProvider.select((state) => state.active),
    (_, _) => notifier.refresh(),
  );
  ref.onDispose(notifier.dispose);
  return notifier;
});

final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = ref.watch(_routerRefreshProvider);
  final router = GoRouter(
    initialLocation: Routes.bootstrap,
    refreshListenable: refresh,
    redirect: (context, state) {
      final gate = ref.read(appGateProvider);
      final path = state.uri.path;
      final isBootstrap = path == Routes.bootstrap;
      final isWelcome = path == Routes.welcome;
      final isPhone = path == Routes.authPhone;
      final isRegistration = path == Routes.register;
      final isPublic = isWelcome || isPhone || isRegistration;

      switch (gate.status) {
        case AppGateStatus.checkingSession:
        case AppGateStatus.loadingProfile:
        case AppGateStatus.unavailable:
          return isBootstrap ? null : Routes.bootstrap;
        case AppGateStatus.signedOut:
          return isPublic ? null : Routes.welcome;
        case AppGateStatus.onboardingRequired:
          return path == Routes.onboarding ? null : Routes.onboarding;
        case AppGateStatus.ready:
          if (path == Routes.onboarding) {
            return ref.read(onboardingControllerProvider).active
                ? null
                : Routes.discover;
          }
          return isBootstrap || isPublic ? Routes.discover : null;
      }
    },
    routes: [
      GoRoute(
        path: Routes.bootstrap,
        builder: (context, state) => const AppBootstrapScreen(),
      ),
      GoRoute(
        path: Routes.welcome,
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: Routes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: Routes.authPhone,
        builder: (context, state) {
          final arguments = state.extra;
          if (arguments is PhoneAuthArguments) {
            return PhoneAuthScreen(
              intent: arguments.intent,
              initialPhoneNumber: arguments.initialPhoneNumber,
            );
          }
          final intent = state.uri.queryParameters['intent'] == 'registration'
              ? AuthIntent.registration
              : AuthIntent.login;
          return PhoneAuthScreen(intent: intent);
        },
      ),
      GoRoute(
        path: Routes.register,
        builder: (context, state) {
          final arguments = state.extra;
          return RegistrationScreen(
            phoneNumber: arguments is RegistrationArguments
                ? arguments.phoneNumber
                : '',
          );
        },
      ),

      // Tabs shell: Discover is the FIRST tab
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.discover,
                builder: (context, state) => const DiscoveryScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.chats,
                builder: (context, state) => ChatListScreen(
                  initialUserId: int.tryParse(
                    state.uri.queryParameters['userId'] ?? '',
                  ),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.likes,
                builder: (context, state) => const LikesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.profile,
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),

      // Non-tab routes
      GoRoute(
        path: Routes.publicProfile,
        builder: (context, state) {
          final userId = int.tryParse(state.pathParameters['id'] ?? '');
          if (userId == null) {
            return const DiscoveryScreen();
          }
          return PublicProfileScreen(
            userId: userId,
            fromLikes: state.uri.queryParameters['source'] == 'likes',
            initialProfile: state.extra is DiscoveryProfile
                ? state.extra! as DiscoveryProfile
                : null,
          );
        },
      ),
      GoRoute(
        path: Routes.match,
        builder: (context, state) {
          final userId = int.tryParse(state.pathParameters['userId'] ?? '');
          if (userId == null) {
            return const DiscoveryScreen();
          }
          return MatchScreen(
            userId: userId,
            initialProfile: state.extra is DiscoveryProfile
                ? state.extra! as DiscoveryProfile
                : null,
          );
        },
      ),
      GoRoute(
        path: '/chat/:id',
        builder: (context, state) {
          final chatId = state.pathParameters['id'] ?? '';
          return ChatScreen(chatId: chatId);
        },
      ),
      GoRoute(
        path: Routes.editProfile,
        builder: (context, state) => EditProfileScreen(
          initialSection: state.extra is ProfileEditSection
              ? state.extra! as ProfileEditSection
              : null,
        ),
      ),
      GoRoute(
        path: Routes.profilePreview,
        builder: (context, state) => const OwnProfilePreviewScreen(),
      ),
      GoRoute(
        path: Routes.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: Routes.accountSettings,
        builder: (context, state) => const AccountSettingsScreen(),
      ),
      GoRoute(
        path: Routes.discoveryPreferences,
        builder: (context, state) => const DiscoveryPreferencesScreen(),
      ),
      GoRoute(
        path: Routes.deleteAccount,
        builder: (context, state) => const DeleteAccountScreen(),
      ),
      GoRoute(
        path: Routes.appInformation,
        builder: (context, state) => const AppInformationScreen(),
      ),
      GoRoute(
        path: Routes.premium,
        builder: (context, state) => const SubscriptionScreen(),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

class _RouterRefreshNotifier extends ChangeNotifier {
  void refresh() => notifyListeners();
}
