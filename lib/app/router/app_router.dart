import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/chat/chat_list_screen.dart';
import '../../features/chat/chat_screen.dart';
import '../../features/auth/presentation/phone_auth_screen.dart';
import '../../features/discovery/discovery_screen.dart';
import '../../features/discovery/domain/discovery_models.dart';
import '../../features/likes/likes_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/onboarding/registration_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/profile/public_profile_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/subscription/subscription_screen.dart';
import '../shell/main_shell.dart';
import 'routes.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: Routes.onboarding,
    routes: [
      GoRoute(
        path: Routes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: Routes.authPhone,
        builder: (context, state) => const PhoneAuthScreen(),
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
        path: Routes.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: Routes.premium,
        builder: (context, state) => const SubscriptionScreen(),
      ),
    ],
  );
});
