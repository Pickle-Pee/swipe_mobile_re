import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swipe_mobile_re/features/discovery/application/discovery_providers.dart';
import 'package:swipe_mobile_re/features/discovery/discovery_screen.dart';
import 'package:swipe_mobile_re/features/discovery/domain/discovery_models.dart';
import 'package:swipe_mobile_re/features/discovery/domain/discovery_repository.dart';
import 'package:swipe_mobile_re/shared/ui/app_theme.dart';

void main() {
  group('DiscoveryView states', () {
    testWidgets('shows loading skeleton', (tester) async {
      await _pumpView(
        tester,
        const DiscoveryState(status: DiscoveryStatus.loading),
      );

      expect(find.byKey(const Key('discovery-loading')), findsOneWidget);
      expect(find.text('Loading'), findsNothing);
    });

    testWidgets('shows real profile data and only three compact interests', (
      tester,
    ) async {
      await _pumpView(tester, _dataState(_profile));

      expect(find.text('Mila'), findsOneWidget);
      expect(find.text('Lisbon'), findsOneWidget);
      expect(find.text('Travel'), findsOneWidget);
      expect(find.text('Ceramics'), findsOneWidget);
      expect(find.text('Jazz'), findsOneWidget);
      expect(find.text('Climbing'), findsNothing);
      expect(find.textContaining('compatibility'), findsNothing);
    });

    testWidgets('shows empty feed and invokes reload', (tester) async {
      var retries = 0;
      await _pumpView(
        tester,
        const DiscoveryState(
          status: DiscoveryStatus.empty,
          emptyReason: DiscoveryEmptyReason.noProfiles,
        ),
        onRetry: () => retries++,
      );

      expect(find.text('No profiles nearby'), findsOneWidget);
      await tester.tap(find.text('Reload profiles'));
      expect(retries, 1);
    });

    testWidgets('shows end-of-feed copy separately', (tester) async {
      await _pumpView(
        tester,
        const DiscoveryState(
          status: DiscoveryStatus.empty,
          emptyReason: DiscoveryEmptyReason.endOfFeed,
        ),
      );

      expect(find.text("You're all caught up"), findsOneWidget);
      expect(find.text('Check again'), findsOneWidget);
    });

    testWidgets('shows API error and retries', (tester) async {
      var retries = 0;
      await _pumpView(
        tester,
        DiscoveryState(
          status: DiscoveryStatus.error,
          error: Exception('offline'),
        ),
        onRetry: () => retries++,
      );

      expect(find.text('Discovery is offline'), findsOneWidget);
      expect(
        find.text('Could not complete the request. Please try again.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Try again'));
      expect(retries, 1);
    });

    testWidgets('keeps data visible for a reaction error and retries inline', (
      tester,
    ) async {
      var retries = 0;
      await _pumpView(
        tester,
        DiscoveryState(
          status: DiscoveryStatus.error,
          profiles: [_profile],
          failedReaction: DiscoveryReaction.like,
          error: Exception('offline'),
        ),
        onRetryInline: () => retries++,
      );

      expect(find.text('Mila'), findsOneWidget);
      expect(find.byKey(const Key('discovery-inline-error')), findsOneWidget);
      await tester.tap(find.byKey(const Key('discovery-inline-retry')));
      expect(retries, 1);
    });

    testWidgets('shows a deterministic missing image state', (tester) async {
      await _pumpView(tester, _dataState(_profile));

      expect(find.byKey(const Key('profile-media-missing')), findsOneWidget);
    });

    testWidgets('shows Like-specific loading and blocks both actions', (
      tester,
    ) async {
      await _pumpView(
        tester,
        DiscoveryState(
          status: DiscoveryStatus.data,
          profiles: [_profile],
          processingReaction: DiscoveryReaction.like,
        ),
      );

      expect(
        find.descendant(
          of: find.byKey(const Key('discovery-like')),
          matching: find.byType(CircularProgressIndicator),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('discovery-pass')),
          matching: find.byType(CircularProgressIndicator),
        ),
        findsNothing,
      );
    });

    testWidgets('shows Pass-specific loading and blocks both actions', (
      tester,
    ) async {
      await _pumpView(
        tester,
        DiscoveryState(
          status: DiscoveryStatus.data,
          profiles: [_profile],
          processingReaction: DiscoveryReaction.pass,
        ),
      );

      expect(
        find.descendant(
          of: find.byKey(const Key('discovery-pass')),
          matching: find.byType(CircularProgressIndicator),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('discovery-like')),
          matching: find.byType(CircularProgressIndicator),
        ),
        findsNothing,
      );
    });

    testWidgets('top controls preserve Likes and Chats callbacks', (
      tester,
    ) async {
      var likes = 0;
      var chats = 0;
      await _pumpView(
        tester,
        _dataState(_profile),
        onOpenLikes: () => likes++,
        onOpenChats: () => chats++,
      );

      await tester.tap(find.byKey(const Key('discovery-open-likes')));
      await tester.tap(find.byKey(const Key('discovery-open-chats')));
      expect(likes, 1);
      expect(chats, 1);
    });

    testWidgets('long content at text scale 1.3 fits a compact screen', (
      tester,
    ) async {
      await _pumpView(
        tester,
        _dataState(_longProfile),
        size: const Size(320, 568),
        textScale: 1.3,
      );

      expect(find.text(_longProfile.firstName), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('DiscoveryScreen integration', () {
    testWidgets('double Like tap starts one repository request', (
      tester,
    ) async {
      final repository = _FakeDiscoveryRepository([_profile]);
      await _pumpScreen(tester, repository);

      await tester.tap(find.byKey(const Key('discovery-like')));
      await tester.tap(find.byKey(const Key('discovery-like')));

      expect(repository.reactionCalls, 1);
      repository.reactionCompleter.complete(
        const DiscoveryReactionResult(isMatch: false),
      );
      await tester.pumpAndSettle();
    });

    testWidgets('profile details opens with already loaded real data', (
      tester,
    ) async {
      final repository = _FakeDiscoveryRepository([_profile]);
      await _pumpScreen(tester, repository);

      await tester.tap(find.byTooltip('Profile details'));
      await tester.pumpAndSettle();

      expect(find.text('About'), findsOneWidget);
      expect(find.text(_profile.aboutMe), findsOneWidget);
      expect(find.text('Details'), findsOneWidget);
      expect(find.text('170'), findsOneWidget);
    });
  });
}

final _profile = DiscoveryProfile(
  id: 7,
  firstName: 'Mila',
  dateOfBirth: null,
  city: 'Lisbon',
  aboutMe: 'Weekend walks, tiny galleries, and good coffee.',
  photoUrl: null,
  interests: const [
    DiscoveryInterest(id: 1, label: 'Travel'),
    DiscoveryInterest(id: 2, label: 'Ceramics'),
    DiscoveryInterest(id: 3, label: 'Jazz'),
    DiscoveryInterest(id: 4, label: 'Climbing'),
  ],
  attributes: const {'Height': '170'},
);

final _longProfile = DiscoveryProfile(
  id: 8,
  firstName: 'Alexandria Catherine with an exceptionally long name',
  dateOfBirth: null,
  city: 'A very long city name that must remain readable',
  aboutMe: 'Long but real profile content for compact layout coverage.',
  photoUrl: null,
  interests: const [
    DiscoveryInterest(id: 1, label: 'Contemporary architecture'),
    DiscoveryInterest(id: 2, label: 'Independent cinema'),
    DiscoveryInterest(id: 3, label: 'Long-distance cycling'),
  ],
  attributes: const {},
);

DiscoveryState _dataState(DiscoveryProfile profile) =>
    DiscoveryState(status: DiscoveryStatus.data, profiles: [profile]);

Future<void> _pumpView(
  WidgetTester tester,
  DiscoveryState state, {
  VoidCallback? onRetry,
  VoidCallback? onRetryInline,
  VoidCallback? onOpenLikes,
  VoidCallback? onOpenChats,
  Size size = const Size(390, 844),
  double textScale = 1,
}) async {
  await _setTestView(tester, size);
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
        child: DiscoveryView(
          state: state,
          onLike: () {},
          onPass: () {},
          onRetry: onRetry ?? () {},
          onRetryInline: onRetryInline ?? () {},
          onOpenLikes: onOpenLikes ?? () {},
          onOpenChats: onOpenChats ?? () {},
          onOpenProfile: (_) {},
        ),
      ),
    ),
  );
  await tester.pump();
}

Future<void> _pumpScreen(
  WidgetTester tester,
  _FakeDiscoveryRepository repository,
) async {
  await _setTestView(tester, const Size(390, 844));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [discoveryRepositoryProvider.overrideWithValue(repository)],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.midnight(),
        home: const DiscoveryScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _setTestView(WidgetTester tester, Size size) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
}

class _FakeDiscoveryRepository implements DiscoveryRepository {
  _FakeDiscoveryRepository(this.profiles);

  final List<DiscoveryProfile> profiles;
  final reactionCompleter = Completer<DiscoveryReactionResult>();
  int reactionCalls = 0;

  @override
  Future<List<DiscoveryProfile>> getProfiles() async => profiles;

  @override
  Future<DiscoveryReactionResult> react(
    int profileId,
    DiscoveryReaction reaction,
  ) {
    reactionCalls++;
    return reactionCompleter.future;
  }
}
