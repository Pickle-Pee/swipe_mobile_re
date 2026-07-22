import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:swipe_mobile_re/features/chat/application/chat_providers.dart';
import 'package:swipe_mobile_re/features/chat/domain/chat_models.dart';
import 'package:swipe_mobile_re/features/chat/domain/chat_repository.dart';
import 'package:swipe_mobile_re/features/discovery/application/discovery_providers.dart';
import 'package:swipe_mobile_re/features/discovery/discovery_screen.dart';
import 'package:swipe_mobile_re/features/discovery/domain/discovery_models.dart';
import 'package:swipe_mobile_re/features/discovery/domain/discovery_repository.dart';
import 'package:swipe_mobile_re/features/match/match_screen.dart';
import 'package:swipe_mobile_re/features/profile/application/profile_providers.dart';
import 'package:swipe_mobile_re/features/profile/application/public_profile_providers.dart';
import 'package:swipe_mobile_re/features/profile/domain/profile_models.dart';
import 'package:swipe_mobile_re/features/profile/domain/profile_repository.dart';
import 'package:swipe_mobile_re/features/profile/domain/public_profile_repository.dart';
import 'package:swipe_mobile_re/features/profile/public_profile_screen.dart';
import 'package:swipe_mobile_re/shared/ui/app_theme.dart';

void main() {
  testWidgets(
    'Discovery -> Profile -> mutual Match -> existing Chat uses one flow',
    (tester) async {
      final discoveryRepository = _FakeDiscoveryRepository();
      final chatRepository = _FakeChatRepository(existingChatId: 42);
      final router = _router();
      addTearDown(router.dispose);

      await _pumpApp(
        tester,
        router: router,
        discoveryRepository: discoveryRepository,
        chatRepository: chatRepository,
      );

      await tester.tap(find.byTooltip('Profile details'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('public-profile-scroll')), findsOneWidget);

      await tester.tap(find.byKey(const Key('public-profile-like')));
      await tester.pumpAndSettle();
      expect(find.text('Это взаимно!'), findsOneWidget);
      expect(discoveryRepository.reactionCalls, 1);

      await tester.tap(find.byKey(const Key('match-start-chat')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('chat-destination')), findsOneWidget);
      expect(chatRepository.lookupCalls, 1);
      expect(chatRepository.createCalls, 0);
      expect(router.routeInformationProvider.value.uri.path, '/chat/42');
    },
  );

  testWidgets('system Back closes Match and returns to current Discovery', (
    tester,
  ) async {
    final router = _router(initialLocation: '/match/7');
    addTearDown(router.dispose);
    await _pumpApp(
      tester,
      router: router,
      discoveryRepository: _FakeDiscoveryRepository(),
      chatRepository: _FakeChatRepository(existingChatId: 42),
    );
    expect(find.text('Это взаимно!'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(router.routeInformationProvider.value.uri.path, '/discover');
    expect(find.byType(DiscoveryScreen), findsOneWidget);
  });
}

GoRouter _router({String initialLocation = '/discover'}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/discover',
        builder: (context, state) => const DiscoveryScreen(),
      ),
      GoRoute(
        path: '/discover/profile/:id',
        builder: (context, state) => PublicProfileScreen(
          userId: int.parse(state.pathParameters['id']!),
          initialProfile: state.extra as DiscoveryProfile?,
        ),
      ),
      GoRoute(
        path: '/match/:userId',
        builder: (context, state) => MatchScreen(
          userId: int.parse(state.pathParameters['userId']!),
          initialProfile: state.extra as DiscoveryProfile? ?? _discovery,
        ),
      ),
      GoRoute(
        path: '/chat/:id',
        builder: (context, state) => Scaffold(
          body: Center(
            child: Text(
              'Chat ${state.pathParameters['id']}',
              key: const Key('chat-destination'),
            ),
          ),
        ),
      ),
    ],
  );
}

Future<void> _pumpApp(
  WidgetTester tester, {
  required GoRouter router,
  required _FakeDiscoveryRepository discoveryRepository,
  required _FakeChatRepository chatRepository,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 844);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        discoveryRepositoryProvider.overrideWithValue(discoveryRepository),
        publicProfileRepositoryProvider.overrideWithValue(
          _FakePublicProfileRepository(),
        ),
        profileRepositoryProvider.overrideWithValue(_FakeProfileRepository()),
        chatRepositoryProvider.overrideWithValue(chatRepository),
      ],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.midnight(),
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _FakeDiscoveryRepository implements DiscoveryRepository {
  int reactionCalls = 0;

  @override
  Future<List<DiscoveryProfile>> getProfiles() async => [_discovery];

  @override
  Future<DiscoveryReactionResult> react(
    int profileId,
    DiscoveryReaction reaction,
  ) async {
    reactionCalls++;
    return const DiscoveryReactionResult(isMatch: true);
  }
}

class _FakePublicProfileRepository implements PublicProfileRepository {
  @override
  Future<PublicUserProfile> getProfile(int userId) async => _publicProfile;
}

class _FakeProfileRepository implements ProfileRepository {
  @override
  Future<UserProfile> getCurrentProfile() async => _currentProfile;

  @override
  Future<UserProfile> setAvatar(int photoId) async => _currentProfile;

  @override
  Future<UserProfile> updateProfile(ProfileUpdate update) async =>
      _currentProfile;

  @override
  Future<UserProfile> uploadPhoto(
    ProfilePhotoFile file, {
    bool isAvatar = false,
    void Function(int, int)? onProgress,
  }) async => _currentProfile;
}

class _FakeChatRepository implements ChatRepository {
  _FakeChatRepository({required this.existingChatId});

  final int? existingChatId;
  int lookupCalls = 0;
  int createCalls = 0;

  @override
  Future<int> createChat(int userId) async {
    createCalls++;
    return 43;
  }

  @override
  Future<List<ChatSummary>> getChats() async => const [];

  @override
  Future<ChatDetails> getChatDetails(int chatId) => throw UnimplementedError();

  @override
  Future<int?> getChatIdByUserId(int userId) async {
    lookupCalls++;
    return existingChatId;
  }
}

const _discovery = DiscoveryProfile(
  id: 7,
  firstName: 'Mila',
  dateOfBirth: null,
  city: 'Lisbon',
  aboutMe: 'Real profile from the fake repository.',
  photoUrl: null,
  interests: [DiscoveryInterest(id: 1, label: 'Travel')],
  attributes: {'Height': '170 cm'},
);

const _publicProfile = PublicUserProfile(
  id: 7,
  firstName: 'Mila',
  lastName: 'Stone',
  dateOfBirth: null,
  gender: 'female',
  city: 'Lisbon',
  aboutMe: 'Real profile from the fake repository.',
  avatarUrl: null,
  interests: [ProfileInterest(id: 1, label: 'Travel')],
  photos: [],
  facts: {'Height': '170 cm'},
);

const _currentProfile = UserProfile(
  id: 1,
  firstName: 'Alex',
  lastName: 'North',
  dateOfBirth: null,
  city: 'Demo City',
  aboutMe: '',
  status: '',
  isSubscription: false,
  interests: [],
  photos: [],
);
