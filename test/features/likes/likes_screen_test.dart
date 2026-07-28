import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swipe_mobile_re/features/likes/application/likes_providers.dart';
import 'package:swipe_mobile_re/features/likes/domain/likes_models.dart';
import 'package:swipe_mobile_re/features/likes/presentation/likes_components.dart';
import 'package:swipe_mobile_re/features/subscription/application/subscription_providers.dart';
import 'package:swipe_mobile_re/features/subscription/domain/subscription_models.dart';
import 'package:swipe_mobile_re/shared/ui/app_theme.dart';

void main() {
  group('LikesView', () {
    testWidgets('keeps premium content hidden while access is loading', (
      tester,
    ) async {
      await pumpLikes(
        tester,
        dataState,
        access: const SubscriptionAccessState(
          status: SubscriptionAccessStatus.loading,
        ),
      );

      expect(find.byKey(const Key('likes-loading')), findsOneWidget);
      expect(find.text('Mila'), findsNothing);
      expect(find.byKey(const Key('likes-premium-gate')), findsNothing);
    });

    testWidgets('locked Likes use real count and open Subscription', (
      tester,
    ) async {
      var opened = 0;
      await pumpLikes(tester, dataState, onOpenSubscription: () => opened++);

      expect(find.byKey(const Key('likes-locked')), findsOneWidget);
      expect(find.byKey(const Key('likes-real-count')), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('See who already likes you'), findsOneWidget);
      expect(find.text('Mila'), findsNothing);
      await tester.tap(find.text('View plans'));
      expect(opened, 1);
    });

    testWidgets('unlocked Likes show real fields and open the real profile', (
      tester,
    ) async {
      LikesUser? opened;
      await pumpLikes(
        tester,
        dataState,
        access: activeAccess,
        onOpenProfile: (user) => opened = user,
      );

      expect(find.byKey(const Key('likes-grid-likedMe')), findsOneWidget);
      expect(find.text('Mila'), findsOneWidget);
      expect(find.text('Lisbon'), findsOneWidget);
      expect(find.text('online'), findsNothing);
      expect(find.textContaining('compatibility'), findsNothing);
      await tester.tap(find.text('Mila'));
      expect(opened?.id, 1);
    });

    testWidgets('shows branded missing image without layout shift', (
      tester,
    ) async {
      await pumpLikes(tester, dataState, access: activeAccess);

      expect(find.byKey(const Key('likes-missing-image')), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    });

    testWidgets('premium empty state does not create fake demand', (
      tester,
    ) async {
      await pumpLikes(
        tester,
        const LikesState(status: LikesStatus.empty, data: emptyData),
        access: activeAccess,
      );

      expect(find.text('New likes will appear here'), findsOneWidget);
      expect(find.byKey(const Key('likes-real-count')), findsOneWidget);
      expect(find.text('0'), findsOneWidget);
      expect(find.byKey(const Key('likes-premium-gate')), findsNothing);
      expect(find.textContaining('people liked you'), findsNothing);
    });

    testWidgets('inactive empty state links to plans without fake profiles', (
      tester,
    ) async {
      var opened = 0;
      await pumpLikes(
        tester,
        const LikesState(status: LikesStatus.empty, data: emptyData),
        onOpenSubscription: () => opened++,
      );

      expect(find.text('New likes will appear here'), findsOneWidget);
      expect(
        find.text(
          'There are no incoming Likes right now. Premium '
          'reveals real profiles here when someone likes you.',
        ),
        findsOneWidget,
      );
      expect(find.byType(LikesProfileCard), findsNothing);
      expect(find.byKey(const Key('likes-premium-gate')), findsNothing);
      await tester.tap(find.text('View Premium plans'));
      expect(opened, 1);
    });

    testWidgets('error has retry and navigation remains available', (
      tester,
    ) async {
      var retries = 0;
      var backs = 0;
      await pumpLikes(
        tester,
        LikesState(status: LikesStatus.error, error: Exception('offline')),
        access: activeAccess,
        onRetry: () => retries++,
        onBack: () => backs++,
      );

      expect(find.text('Could not load Likes'), findsOneWidget);
      await tester.tap(find.text('Try again'));
      await tester.tap(find.byTooltip('Back'));
      expect(retries, 1);
      expect(backs, 1);
    });

    testWidgets('refresh error retains the grid with an inline retry', (
      tester,
    ) async {
      var retries = 0;
      await pumpLikes(
        tester,
        LikesState(
          status: LikesStatus.error,
          data: data,
          error: Exception('offline'),
        ),
        access: activeAccess,
        onRetry: () => retries++,
      );

      expect(find.text('Mila'), findsOneWidget);
      expect(find.byKey(const Key('likes-grid-likedMe')), findsOneWidget);
      await tester.tap(find.text('Retry'));
      expect(retries, 1);
    });

    testWidgets('category callbacks preserve the four existing lists', (
      tester,
    ) async {
      LikesCategory? selected;
      await pumpLikes(
        tester,
        dataState,
        access: activeAccess,
        onSelect: (value) => selected = value,
      );

      await tester.ensureVisible(find.text('Favorites'));
      await tester.tap(find.text('Favorites'));
      expect(selected, LikesCategory.favorites);
      await tester.ensureVisible(find.text('Matches'));
      await tester.tap(find.text('Matches'));
      expect(selected, LikesCategory.mutual);
    });

    testWidgets('long name fits a small viewport at text scale 1.3', (
      tester,
    ) async {
      await pumpLikes(
        tester,
        const LikesState(
          status: LikesStatus.data,
          data: LikesData(
            likedMe: [longUser],
            likedUsers: [],
            favorites: [],
            mutual: [],
          ),
        ),
        access: activeAccess,
        size: const Size(320, 568),
        textScale: 1.3,
      );

      expect(find.text(longUser.firstName), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

Future<void> pumpLikes(
  WidgetTester tester,
  LikesState state, {
  SubscriptionAccessState access = const SubscriptionAccessState(
    status: SubscriptionAccessStatus.inactive,
  ),
  VoidCallback? onBack,
  VoidCallback? onRetry,
  ValueChanged<LikesCategory>? onSelect,
  VoidCallback? onOpenSubscription,
  ValueChanged<LikesUser>? onOpenProfile,
  Size size = const Size(390, 844),
  double textScale = 1,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.midnight(),
      home: MediaQuery(
        data: MediaQueryData(
          size: size,
          devicePixelRatio: 1,
          textScaler: TextScaler.linear(textScale),
          disableAnimations: true,
        ),
        child: LikesView(
          state: state,
          access: access,
          onBack: onBack ?? () {},
          onRetry: onRetry ?? () {},
          onRefresh: () async {},
          onSelectCategory: onSelect ?? (_) {},
          onOpenSubscription: onOpenSubscription ?? () {},
          onOpenDiscovery: () {},
          onOpenProfile: onOpenProfile ?? (_) {},
          imageProviderBuilder: (_) => null,
        ),
      ),
    ),
  );
  await tester.pump();
}

const dataState = LikesState(status: LikesStatus.data, data: data);

const data = LikesData(
  likedMe: [mila, nora],
  likedUsers: [],
  favorites: [],
  mutual: [],
);

const emptyData = LikesData(
  likedMe: [],
  likedUsers: [],
  favorites: [],
  mutual: [],
);

const mila = LikesUser(
  id: 1,
  firstName: 'Mila',
  dateOfBirth: null,
  city: 'Lisbon',
  aboutMe: 'Weekend walks',
  status: 'online',
  avatarUrl: null,
  mutual: false,
);

const nora = LikesUser(
  id: 2,
  firstName: 'Nora',
  dateOfBirth: null,
  city: 'Oslo',
  aboutMe: 'Ceramics',
  status: '',
  avatarUrl: null,
  mutual: false,
);

const longUser = LikesUser(
  id: 3,
  firstName: 'Alexandria Catherine with an exceptionally long name',
  dateOfBirth: null,
  city: 'A city with a deliberately long real backend name',
  aboutMe: '',
  status: '',
  avatarUrl: null,
  mutual: false,
);

final activeAccess = SubscriptionAccessState(
  status: SubscriptionAccessStatus.active,
  activeSubscription: ActiveSubscription(
    subscriptionId: 7,
    name: 'Premium',
    startAt: DateTime.utc(2026, 7, 13),
    endAt: DateTime.utc(2026, 8, 12),
    renewable: false,
  ),
);
