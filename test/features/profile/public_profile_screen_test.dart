import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swipe_mobile_re/features/profile/application/public_profile_providers.dart';
import 'package:swipe_mobile_re/features/profile/domain/profile_models.dart';
import 'package:swipe_mobile_re/features/profile/public_profile_screen.dart';
import 'package:swipe_mobile_re/shared/ui/app_theme.dart';

void main() {
  testWidgets('shows neutral loading and profile error states', (tester) async {
    await _pump(
      tester,
      const PublicProfileState(status: PublicProfileStatus.loading),
    );
    expect(find.byKey(const Key('public-profile-loading')), findsOneWidget);

    await _pump(
      tester,
      PublicProfileState(
        status: PublicProfileStatus.error,
        error: Exception('offline'),
      ),
    );
    expect(find.byKey(const Key('public-profile-error')), findsOneWidget);
    expect(find.text('Could not load profile'), findsOneWidget);
  });

  testWidgets('renders only real non-empty sections and readable facts', (
    tester,
  ) async {
    await _pump(tester, _data(_profile));

    expect(find.text('Mila Stone'), findsOneWidget);
    expect(find.text('Lisbon'), findsOneWidget);
    expect(find.text(_profile.aboutMe), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const Key('public-profile-interests')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Travel'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const Key('public-profile-facts')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Looking for'), findsOneWidget);
    expect(find.text('Long Term Relationship'), findsOneWidget);
    expect(find.textContaining('compatibility'), findsNothing);
    expect(find.textContaining('online'), findsNothing);
  });

  testWidgets('one image stays in hero and multiple images create gallery', (
    tester,
  ) async {
    await _pump(tester, _data(_oneImageProfile));
    expect(find.byKey(const Key('public-profile-photos')), findsNothing);

    await _pump(tester, _data(_profile));
    expect(find.byKey(const Key('public-profile-photos')), findsOneWidget);
    expect(find.byKey(const Key('public-profile-gallery')), findsOneWidget);
  });

  testWidgets('missing image uses shared deterministic placeholder', (
    tester,
  ) async {
    await _pump(tester, _data(_emptyProfile));

    expect(find.bySemanticsLabel('Profile photo of Noor'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('empty optional fields do not reserve sections', (tester) async {
    await _pump(tester, _data(_emptyProfile));

    expect(find.byKey(const Key('public-profile-about')), findsNothing);
    expect(find.byKey(const Key('public-profile-interests')), findsNothing);
    expect(find.byKey(const Key('public-profile-facts')), findsNothing);
    expect(find.byKey(const Key('public-profile-photos')), findsNothing);
  });

  testWidgets('Back, Like and Pass expose callbacks', (tester) async {
    var back = 0;
    var likes = 0;
    var passes = 0;
    await _pump(
      tester,
      _data(_profile),
      showActions: true,
      onBack: () => back++,
      onLike: () => likes++,
      onPass: () => passes++,
    );

    await tester.tap(find.byKey(const Key('public-profile-back')));
    await tester.tap(find.byKey(const Key('public-profile-pass')));
    await tester.tap(find.byKey(const Key('public-profile-like')));

    expect(back, 1);
    expect(passes, 1);
    expect(likes, 1);
  });

  testWidgets('reaction loading is action-specific and blocks both actions', (
    tester,
  ) async {
    await _pump(tester, _data(_profile), showActions: true, passLoading: true);

    expect(
      find.descendant(
        of: find.byKey(const Key('public-profile-pass')),
        matching: find.byType(CircularProgressIndicator),
      ),
      findsOneWidget,
    );
    final like = tester.widget<ElevatedButton>(
      find.descendant(
        of: find.byKey(const Key('public-profile-like')),
        matching: find.byType(ElevatedButton),
      ),
    );
    expect(like.onPressed, isNull);
  });

  testWidgets('reaction error stays visible and can retry', (tester) async {
    var retries = 0;
    await _pump(
      tester,
      _data(_profile),
      showActions: true,
      reactionError: Exception('offline'),
      onRetryReaction: () => retries++,
    );

    expect(
      find.byKey(const Key('public-profile-reaction-error')),
      findsOneWidget,
    );
    await tester.tap(find.text('Retry'));
    expect(retries, 1);
  });

  testWidgets(
    'long content, many interests and text scale 1.3 fit compact UI',
    (tester) async {
      await _pump(
        tester,
        _data(_longProfile),
        size: const Size(320, 568),
        textScale: 1.3,
        showActions: true,
      );

      expect(find.byKey(const Key('public-profile-scroll')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

Future<void> _pump(
  WidgetTester tester,
  PublicProfileState state, {
  Size size = const Size(390, 844),
  double textScale = 1,
  bool showActions = false,
  bool passLoading = false,
  bool likeLoading = false,
  Object? reactionError,
  VoidCallback? onBack,
  VoidCallback? onPass,
  VoidCallback? onLike,
  VoidCallback? onRetryReaction,
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
        child: PublicProfileView(
          state: state,
          onBack: onBack ?? () {},
          onRetry: () {},
          enableHero: false,
          showActions: showActions,
          passLoading: passLoading,
          likeLoading: likeLoading,
          reactionError: reactionError,
          onRetryReaction: onRetryReaction,
          onPass: showActions && !passLoading && !likeLoading
              ? onPass ?? () {}
              : null,
          onLike: showActions && !passLoading && !likeLoading
              ? onLike ?? () {}
              : null,
          imageProviderBuilder: (_) => null,
        ),
      ),
    ),
  );
  await tester.pump();
}

PublicProfileState _data(PublicUserProfile profile) =>
    PublicProfileState(status: PublicProfileStatus.data, profile: profile);

const _profile = PublicUserProfile(
  id: 7,
  firstName: 'Mila',
  lastName: 'Stone',
  dateOfBirth: null,
  gender: 'female',
  city: 'Lisbon',
  aboutMe: 'Weekend walks, tiny galleries, and good coffee.',
  avatarUrl: 'memory://avatar',
  interests: [
    ProfileInterest(id: 1, label: 'Travel'),
    ProfileInterest(id: 2, label: 'Ceramics'),
  ],
  photos: [
    ProfilePhoto(id: 1, url: 'memory://avatar', isAvatar: true),
    ProfilePhoto(id: 2, url: 'memory://second', isAvatar: false),
    ProfilePhoto(id: 3, url: 'memory://third', isAvatar: false),
  ],
  facts: {'Gender': 'Female', 'Looking for': 'Long Term Relationship'},
);

const _oneImageProfile = PublicUserProfile(
  id: 8,
  firstName: 'Ira',
  lastName: '',
  dateOfBirth: null,
  gender: '',
  city: '',
  aboutMe: 'One real image.',
  avatarUrl: 'memory://avatar',
  interests: [],
  photos: [ProfilePhoto(id: 1, url: 'memory://avatar', isAvatar: true)],
  facts: {},
);

const _emptyProfile = PublicUserProfile(
  id: 9,
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

const _longProfile = PublicUserProfile(
  id: 10,
  firstName: 'Alexandria Catherine with an exceptionally long name',
  lastName: 'Montgomery-Wellington',
  dateOfBirth: null,
  gender: 'female',
  city: 'A very long city name that must remain readable on compact screens',
  aboutMe:
      'A deliberately long but real-looking test-only description repeated to '
      'verify wrapping, scrolling, and stable action controls at larger text.',
  avatarUrl: null,
  interests: [
    ProfileInterest(id: 1, label: 'Contemporary architecture'),
    ProfileInterest(id: 2, label: 'Independent cinema'),
    ProfileInterest(id: 3, label: 'Long-distance cycling'),
    ProfileInterest(id: 4, label: 'Experimental cooking'),
    ProfileInterest(id: 5, label: 'Urban photography'),
  ],
  photos: [],
  facts: {
    'Gender': 'Female',
    'Children preference': "Doesn't Matter",
    'Looking for': 'Long Term Relationship',
  },
);
