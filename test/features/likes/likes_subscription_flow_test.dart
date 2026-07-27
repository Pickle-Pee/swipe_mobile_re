import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:swipe_mobile_re/features/chat/application/chat_providers.dart';
import 'package:swipe_mobile_re/features/chat/domain/chat_models.dart';
import 'package:swipe_mobile_re/features/chat/domain/chat_repository.dart';
import 'package:swipe_mobile_re/features/discovery/application/discovery_providers.dart';
import 'package:swipe_mobile_re/features/discovery/domain/discovery_models.dart';
import 'package:swipe_mobile_re/features/discovery/domain/discovery_preferences.dart';
import 'package:swipe_mobile_re/features/discovery/domain/discovery_repository.dart';
import 'package:swipe_mobile_re/features/likes/application/likes_providers.dart';
import 'package:swipe_mobile_re/features/likes/domain/likes_models.dart';
import 'package:swipe_mobile_re/features/likes/domain/likes_repository.dart';
import 'package:swipe_mobile_re/features/likes/likes_screen.dart';
import 'package:swipe_mobile_re/features/match/match_screen.dart';
import 'package:swipe_mobile_re/features/profile/application/profile_providers.dart';
import 'package:swipe_mobile_re/features/profile/application/public_profile_providers.dart';
import 'package:swipe_mobile_re/features/profile/domain/profile_models.dart';
import 'package:swipe_mobile_re/features/profile/domain/profile_repository.dart';
import 'package:swipe_mobile_re/features/profile/domain/public_profile_repository.dart';
import 'package:swipe_mobile_re/features/profile/public_profile_screen.dart';
import 'package:swipe_mobile_re/features/subscription/application/subscription_providers.dart';
import 'package:swipe_mobile_re/features/subscription/domain/subscription_models.dart';
import 'package:swipe_mobile_re/features/subscription/domain/subscription_repository.dart';
import 'package:swipe_mobile_re/features/subscription/subscription_screen.dart';
import 'package:swipe_mobile_re/shared/ui/app_theme.dart';

void main() {
  testWidgets(
    'Likes gate -> checkout -> active -> Like back -> Match -> Chat',
    (tester) async {
      final subscriptionRepository = FlowSubscriptionRepository();
      final discoveryRepository = FlowDiscoveryRepository();
      final chatRepository = FlowChatRepository();
      final launcher = FlowPaymentLauncher();
      final router = flowRouter();
      final container = ProviderContainer(
        overrides: [
          likesRepositoryProvider.overrideWithValue(FlowLikesRepository()),
          subscriptionRepositoryProvider.overrideWithValue(
            subscriptionRepository,
          ),
          paymentUrlLauncherProvider.overrideWithValue(launcher),
          subscriptionProfileRefreshProvider.overrideWithValue(() async {}),
          subscriptionPollConfigProvider.overrideWithValue(
            const SubscriptionPollConfig(maxAttempts: 0),
          ),
          discoveryRepositoryProvider.overrideWithValue(discoveryRepository),
          publicProfileRepositoryProvider.overrideWithValue(
            FlowPublicProfileRepository(),
          ),
          profileRepositoryProvider.overrideWithValue(FlowProfileRepository()),
          chatRepositoryProvider.overrideWithValue(chatRepository),
        ],
      );
      addTearDown(container.dispose);
      addTearDown(router.dispose);

      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.midnight(),
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('likes-premium-gate')), findsOneWidget);
      expect(find.text('Mila'), findsNothing);
      await tester.tap(find.text('View plans'));
      await tester.pumpAndSettle();

      expect(find.byType(SubscriptionScreen), findsOneWidget);
      await tester.ensureVisible(find.text('Premium 90'));
      await tester.tap(find.text('Premium 90'));
      await tester.ensureVisible(find.text('Continue to payment'));
      await tester.tap(find.text('Continue to payment'));
      await tester.pumpAndSettle();

      expect(subscriptionRepository.checkoutPlanIds, [2]);
      expect(launcher.urls, [Uri.parse('https://pay.test/flow')]);
      await tester.drag(find.byType(Scrollable).last, const Offset(0, -360));
      await tester.pumpAndSettle();
      expect(find.text('Check payment'), findsOneWidget);
      expect(
        container.read(subscriptionAccessControllerProvider).hasPremiumAccess,
        isFalse,
      );

      subscriptionRepository.paymentSucceeded = true;
      await tester.tap(find.text('Check payment'));
      await tester.pumpAndSettle();
      expect(find.text('Premium is active'), findsOneWidget);
      expect(
        container.read(subscriptionAccessControllerProvider).hasPremiumAccess,
        isTrue,
      );

      await tester.tap(find.text('Open Likes'));
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, '/likes');
      expect(find.byKey(const Key('likes-premium-gate')), findsNothing);
      expect(find.text('Mila'), findsOneWidget);

      await tester.tap(find.text('Mila'));
      await tester.pumpAndSettle();
      final publicProfile = tester.widget<PublicProfileScreen>(
        find.byType(PublicProfileScreen),
      );
      expect(publicProfile.userId, 7);
      expect(publicProfile.fromLikes, isTrue);
      expect(find.byKey(const Key('public-profile-pass')), findsNothing);
      expect(find.byKey(const Key('public-profile-like')), findsOneWidget);

      await tester.tap(find.byKey(const Key('public-profile-like')));
      await tester.pumpAndSettle();
      expect(discoveryRepository.reactionCalls, 1);
      expect(
        container.read(likesControllerProvider).data!.pendingIncoming,
        isEmpty,
      );
      expect(find.byKey(const Key('match-action-panel')), findsOneWidget);

      await tester.tap(find.byKey(const Key('match-start-chat')));
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, '/chat/42');
      expect(find.byKey(const Key('flow-chat-destination')), findsOneWidget);
      expect(chatRepository.lookupCalls, 1);
      expect(chatRepository.createCalls, 0);
    },
  );
}

GoRouter flowRouter() => GoRouter(
  initialLocation: '/likes',
  routes: [
    GoRoute(path: '/likes', builder: (_, _) => const LikesScreen()),
    GoRoute(path: '/premium', builder: (_, _) => const SubscriptionScreen()),
    GoRoute(
      path: '/discover',
      builder: (_, _) => const Scaffold(body: Center(child: Text('Discover'))),
    ),
    GoRoute(
      path: '/discover/profile/:id',
      builder: (context, state) => PublicProfileScreen(
        userId: int.parse(state.pathParameters['id']!),
        fromLikes: state.uri.queryParameters['source'] == 'likes',
        initialProfile: state.extra as DiscoveryProfile?,
      ),
    ),
    GoRoute(
      path: '/match/:userId',
      builder: (context, state) => MatchScreen(
        userId: int.parse(state.pathParameters['userId']!),
        initialProfile: state.extra as DiscoveryProfile?,
      ),
    ),
    GoRoute(
      path: '/chat/:id',
      builder: (context, state) => Scaffold(
        body: Center(
          child: Text(
            'Chat ${state.pathParameters['id']}',
            key: const Key('flow-chat-destination'),
          ),
        ),
      ),
    ),
  ],
);

class FlowLikesRepository implements LikesRepository {
  @override
  Future<LikesData> getLikes() async => const LikesData(
    likedMe: [flowLike],
    likedUsers: [],
    favorites: [],
    mutual: [],
  );
}

class FlowSubscriptionRepository implements SubscriptionRepository {
  bool paymentSucceeded = false;
  final checkoutPlanIds = <int>[];

  @override
  Future<List<SubscriptionPlan>> getPlans() async => const [
    SubscriptionPlan(
      id: 1,
      name: 'Premium 30',
      priceMinor: 49900,
      currency: 'RUB',
      durationDays: 30,
      isActive: true,
      renewable: false,
    ),
    SubscriptionPlan(
      id: 2,
      name: 'Premium 90',
      priceMinor: 99900,
      currency: 'RUB',
      durationDays: 90,
      isActive: true,
      renewable: false,
    ),
  ];

  @override
  Future<ActiveSubscription?> getActiveSubscription() async =>
      paymentSucceeded ? flowActive : null;

  @override
  Future<CheckoutResponse> createCheckout(
    int subscriptionId,
    String idempotencyKey,
  ) async {
    checkoutPlanIds.add(subscriptionId);
    expect(idempotencyKey, isNotEmpty);
    return CheckoutResponse(
      orderId: 'flow-order',
      paymentUrl: Uri.parse('https://pay.test/flow'),
      status: PaymentStatus.pending,
      amountMinor: 99900,
      currency: 'RUB',
    );
  }

  @override
  Future<PaymentStatusResponse> getPaymentStatus(String orderId) async =>
      PaymentStatusResponse(
        orderId: orderId,
        status: paymentSucceeded
            ? PaymentStatus.succeeded
            : PaymentStatus.pending,
        subscriptionActivated: paymentSucceeded,
        subscription: paymentSucceeded ? flowActive : null,
        updatedAt: DateTime.utc(2026, 7, 22),
      );

  @override
  Future<ActiveSubscription> cancelRenewal() => throw UnimplementedError();

  @override
  Future<PaymentStatusResponse> setDemoPaymentResult(
    String orderId, {
    required bool success,
  }) => throw UnimplementedError();
}

class FlowPaymentLauncher implements PaymentUrlLauncher {
  final urls = <Uri>[];

  @override
  Future<bool> open(Uri url) async {
    urls.add(url);
    return true;
  }
}

class FlowDiscoveryRepository implements DiscoveryRepository {
  int reactionCalls = 0;

  @override
  Future<List<DiscoveryProfile>> getProfiles(
    DiscoveryPreferences preferences,
  ) async => const [];

  @override
  Future<DiscoveryReactionResult> react(
    int profileId,
    DiscoveryReaction reaction,
  ) async {
    expect(profileId, flowLike.id);
    expect(reaction, DiscoveryReaction.like);
    reactionCalls++;
    return const DiscoveryReactionResult(isMatch: true);
  }
}

class FlowPublicProfileRepository implements PublicProfileRepository {
  @override
  Future<PublicUserProfile> getProfile(int userId) async => flowPublicProfile;
}

class FlowProfileRepository implements ProfileRepository {
  @override
  Future<UserProfile> deletePhoto(
    int photoId, {
    bool wasAvatar = false,
  }) async => flowCurrentProfile;

  @override
  Future<ProfileEditCatalog> getEditCatalog() async =>
      const ProfileEditCatalog();

  @override
  Future<UserProfile> getCurrentProfile() async => flowCurrentProfile;

  @override
  Future<UserProfile> setAvatar(int photoId) async => flowCurrentProfile;

  @override
  Future<UserProfile> saveProfile(ProfileSaveRequest request) async =>
      flowCurrentProfile;

  @override
  Future<UserProfile> updateProfile(ProfileUpdate update) async =>
      flowCurrentProfile;

  @override
  Future<UserProfile> uploadPhoto(
    ProfilePhotoFile file, {
    bool isAvatar = false,
    void Function(int, int)? onProgress,
  }) async => flowCurrentProfile;
}

class FlowChatRepository implements ChatRepository {
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
  Future<ChatMessagePage> getMessages(
    int chatId, {
    String? before,
    int limit = 30,
  }) async =>
      const ChatMessagePage(items: [], nextCursor: null, hasMore: false);

  @override
  Future<int?> getChatIdByUserId(int userId) async {
    lookupCalls++;
    return 42;
  }
}

const flowLike = LikesUser(
  id: 7,
  firstName: 'Mila',
  dateOfBirth: null,
  city: 'Lisbon',
  aboutMe: 'Real incoming profile from the test repository.',
  status: '',
  avatarUrl: null,
  mutual: false,
);

final flowActive = ActiveSubscription(
  subscriptionId: 2,
  name: 'Premium 90',
  startAt: DateTime.utc(2026, 7, 22),
  endAt: DateTime.utc(2026, 10, 20),
  renewable: false,
);

const flowPublicProfile = PublicUserProfile(
  id: 7,
  firstName: 'Mila',
  lastName: 'Stone',
  dateOfBirth: null,
  gender: 'female',
  city: 'Lisbon',
  aboutMe: 'Real incoming profile from the test repository.',
  avatarUrl: null,
  interests: [ProfileInterest(id: 1, label: 'Travel')],
  photos: [],
  facts: {'Looking for': 'Long Term Relationship'},
);

const flowCurrentProfile = UserProfile(
  id: 1,
  firstName: 'Alex',
  lastName: 'North',
  dateOfBirth: null,
  city: 'Demo City',
  aboutMe: '',
  status: '',
  isSubscription: true,
  interests: [],
  photos: [],
);
