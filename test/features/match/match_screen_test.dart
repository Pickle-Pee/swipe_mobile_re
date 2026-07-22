import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swipe_mobile_re/features/match/match_screen.dart';
import 'package:swipe_mobile_re/features/profile/domain/profile_models.dart';
import 'package:swipe_mobile_re/shared/ui/app_theme.dart';

void main() {
  testWidgets('renders real match data and both actions', (tester) async {
    await _pump(tester);

    expect(find.text('Это взаимно!'), findsOneWidget);
    expect(find.textContaining('Mila Stone'), findsOneWidget);
    expect(find.text('Начать общение'), findsOneWidget);
    expect(find.text('Продолжить просмотр'), findsOneWidget);
    expect(find.textContaining('compatibility'), findsNothing);
  });

  testWidgets('missing matched photo uses the shared placeholder', (
    tester,
  ) async {
    await _pump(tester, matched: _missingPhotoProfile);

    expect(find.byKey(const Key('match-matched-photo')), findsOneWidget);
    expect(
      find.bySemanticsLabel('Matched profile photo unavailable'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Start chat and Continue callbacks are wired', (tester) async {
    var starts = 0;
    var continues = 0;
    await _pump(
      tester,
      onStartChat: () => starts++,
      onContinue: () => continues++,
    );

    await tester.tap(find.byKey(const Key('match-start-chat')));
    await tester.tap(find.byKey(const Key('match-continue')));

    expect(starts, 1);
    expect(continues, 1);
  });

  testWidgets('chat loading blocks duplicate actions', (tester) async {
    await _pump(tester, openingChat: true);

    expect(
      find.descendant(
        of: find.byKey(const Key('match-start-chat')),
        matching: find.byType(CircularProgressIndicator),
      ),
      findsOneWidget,
    );
    final secondary = tester.widget<OutlinedButton>(
      find.descendant(
        of: find.byKey(const Key('match-continue')),
        matching: find.byType(OutlinedButton),
      ),
    );
    expect(secondary.onPressed, isNull);
  });

  testWidgets('chat error remains on Match and permits retry or continue', (
    tester,
  ) async {
    var retries = 0;
    var continues = 0;
    await _pump(
      tester,
      chatError: Exception('offline'),
      onStartChat: () => retries++,
      onContinue: () => continues++,
    );

    expect(find.byKey(const Key('match-chat-error')), findsOneWidget);
    await tester.tap(find.byKey(const Key('match-start-chat')));
    await tester.tap(find.byKey(const Key('match-continue')));
    expect(retries, 1);
    expect(continues, 1);
  });

  testWidgets('profile loading and error never render fake match content', (
    tester,
  ) async {
    await _pump(tester, matched: null, profileLoading: true);
    expect(find.byKey(const Key('match-loading')), findsOneWidget);
    expect(find.text('Это взаимно!'), findsNothing);

    await _pump(tester, matched: null, profileError: Exception('offline'));
    expect(find.text('Match unavailable'), findsOneWidget);
  });

  testWidgets('reduced motion and compact viewport stay overflow-free', (
    tester,
  ) async {
    await _pump(
      tester,
      size: const Size(320, 568),
      textScale: 1.3,
      reduceMotion: true,
    );

    expect(find.text('Это взаимно!'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ordinary rebuild does not restart completed reveal', (
    tester,
  ) async {
    await _pump(tester, reduceMotion: false, settle: true);
    final before = tester
        .widgetList<FadeTransition>(find.byType(FadeTransition))
        .map((widget) => widget.opacity.value)
        .toList();

    await _pump(tester, reduceMotion: false, settle: false);
    await tester.pump();
    final after = tester
        .widgetList<FadeTransition>(find.byType(FadeTransition))
        .map((widget) => widget.opacity.value)
        .toList();

    expect(before, everyElement(1));
    expect(after, everyElement(1));
  });
}

Future<void> _pump(
  WidgetTester tester, {
  PublicUserProfile? matched = _matchedProfile,
  bool profileLoading = false,
  Object? profileError,
  bool openingChat = false,
  Object? chatError,
  VoidCallback? onStartChat,
  VoidCallback? onContinue,
  Size size = const Size(390, 844),
  double textScale = 1,
  bool reduceMotion = true,
  bool settle = false,
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
          disableAnimations: reduceMotion,
        ),
        child: MatchView(
          key: const Key('match-view'),
          matchedProfile: matched,
          currentProfile: _currentProfile,
          profileLoading: profileLoading,
          profileError: profileError,
          openingChat: openingChat,
          chatError: chatError,
          onBack: () {},
          onRetryProfile: () {},
          onStartChat: onStartChat ?? () {},
          onContinue: onContinue ?? () {},
          imageProviderBuilder: (_) => null,
        ),
      ),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
}

const _matchedProfile = PublicUserProfile(
  id: 7,
  firstName: 'Mila',
  lastName: 'Stone',
  dateOfBirth: null,
  gender: 'female',
  city: 'Lisbon',
  aboutMe: '',
  avatarUrl: 'memory://matched',
  interests: [],
  photos: [ProfilePhoto(id: 1, url: 'memory://matched', isAvatar: true)],
  facts: {},
);

const _missingPhotoProfile = PublicUserProfile(
  id: 8,
  firstName: 'Noor',
  lastName: '',
  dateOfBirth: null,
  gender: '',
  city: '',
  aboutMe: '',
  avatarUrl: null,
  interests: [],
  photos: [],
  facts: {},
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
  photos: [ProfilePhoto(id: 2, url: 'memory://current', isAvatar: true)],
);
