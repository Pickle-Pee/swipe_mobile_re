import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swipe_mobile_re/features/profile/application/public_profile_providers.dart';
import 'package:swipe_mobile_re/features/profile/domain/profile_models.dart';
import 'package:swipe_mobile_re/features/profile/public_profile_screen.dart';
import 'package:swipe_mobile_re/shared/ui/app_theme.dart';

import '../../helpers/golden_profile_image.dart';

late MemoryImage _primaryImage;
late MemoryImage _alternateImage;

void main() {
  const phoneSize = Size(390, 844);

  setUpAll(() async {
    final materialIcons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await materialIcons.load();
    _primaryImage = await createGoldenProfileImage();
    _alternateImage = await createGoldenProfileImage(alternate: true);
  });

  testWidgets('Profile normal golden', (tester) async {
    await _pumpGolden(tester, _data(_normalProfile), size: phoneSize);
    await expectLater(
      find.byKey(const Key('profile-golden-surface')),
      matchesGoldenFile('goldens/profile_normal.png'),
    );
  });

  testWidgets('Profile multiple photos golden', (tester) async {
    await _pumpGolden(tester, _data(_multiplePhotosProfile), size: phoneSize);
    await tester.drag(
      find.byKey(const Key('public-profile-scroll')),
      const Offset(0, -430),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('public-profile-gallery')), findsOneWidget);
    await expectLater(
      find.byKey(const Key('profile-golden-surface')),
      matchesGoldenFile('goldens/profile_multiple_photos.png'),
    );
  });

  testWidgets('Profile missing photo golden', (tester) async {
    await _pumpGolden(tester, _data(_missingPhotoProfile), size: phoneSize);
    await expectLater(
      find.byKey(const Key('profile-golden-surface')),
      matchesGoldenFile('goldens/profile_missing_photo.png'),
    );
  });

  testWidgets('Profile long content golden', (tester) async {
    await _pumpGolden(
      tester,
      _data(_longProfile),
      size: const Size(320, 568),
      textScale: 1.3,
    );
    await expectLater(
      find.byKey(const Key('profile-golden-surface')),
      matchesGoldenFile('goldens/profile_long_content.png'),
    );
  });

  testWidgets('Profile error golden', (tester) async {
    await _pumpGolden(
      tester,
      PublicProfileState(
        status: PublicProfileStatus.error,
        error: Exception('offline'),
      ),
      size: phoneSize,
      showActions: false,
    );
    await expectLater(
      find.byKey(const Key('profile-golden-surface')),
      matchesGoldenFile('goldens/profile_error.png'),
    );
  });
}

Future<void> _pumpGolden(
  WidgetTester tester,
  PublicProfileState state, {
  required Size size,
  double textScale = 1,
  bool showActions = true,
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
        child: RepaintBoundary(
          key: const Key('profile-golden-surface'),
          child: PublicProfileView(
            state: state,
            onBack: () {},
            onRetry: () {},
            enableHero: false,
            showActions: showActions,
            onPass: showActions ? () {} : null,
            onLike: showActions ? () {} : null,
            imageProviderBuilder: (photoUrl) {
              if (photoUrl == null || photoUrl.isEmpty) return null;
              return photoUrl.contains('alternate')
                  ? _alternateImage
                  : _primaryImage;
            },
          ),
        ),
      ),
    ),
  );

  final context = tester.element(find.byType(PublicProfileView));
  final decodeWidths = <int>{size.width.ceil()};
  final gallery = find.byKey(const Key('public-profile-gallery'));
  if (gallery.evaluate().isNotEmpty) {
    decodeWidths.add(tester.getSize(gallery).width.ceil());
  }
  await tester.runAsync(() async {
    await precacheImage(_primaryImage, context);
    await precacheImage(_alternateImage, context);
    for (final width in decodeWidths) {
      await precacheImage(
        ResizeImage.resizeIfNeeded(width, null, _primaryImage),
        context,
      );
      await precacheImage(
        ResizeImage.resizeIfNeeded(width, null, _alternateImage),
        context,
      );
    }
  });
  await tester.pumpAndSettle();
}

PublicProfileState _data(PublicUserProfile profile) =>
    PublicProfileState(status: PublicProfileStatus.data, profile: profile);

const _normalProfile = PublicUserProfile(
  id: 7,
  firstName: 'Mila',
  lastName: 'Stone',
  dateOfBirth: null,
  gender: 'female',
  city: 'Lisbon',
  aboutMe: 'Weekend walks, tiny galleries, and good coffee.',
  avatarUrl: 'memory://primary',
  interests: [
    ProfileInterest(id: 1, label: 'Travel'),
    ProfileInterest(id: 2, label: 'Ceramics'),
    ProfileInterest(id: 3, label: 'Jazz'),
  ],
  photos: [ProfilePhoto(id: 1, url: 'memory://primary', isAvatar: true)],
  facts: {'Gender': 'Female', 'Looking for': 'Long Term Relationship'},
);

const _multiplePhotosProfile = PublicUserProfile(
  id: 8,
  firstName: 'Mila',
  lastName: 'Stone',
  dateOfBirth: null,
  gender: 'female',
  city: 'Lisbon',
  aboutMe: 'A profile with a real ordered photo gallery.',
  avatarUrl: 'memory://primary',
  interests: [ProfileInterest(id: 1, label: 'Photography')],
  photos: [
    ProfilePhoto(id: 1, url: 'memory://primary', isAvatar: true),
    ProfilePhoto(id: 2, url: 'memory://alternate-1', isAvatar: false),
    ProfilePhoto(id: 3, url: 'memory://primary-2', isAvatar: false),
    ProfilePhoto(id: 4, url: 'memory://alternate-2', isAvatar: false),
  ],
  facts: {'Gender': 'Female'},
);

const _missingPhotoProfile = PublicUserProfile(
  id: 9,
  firstName: 'Noor',
  lastName: '',
  dateOfBirth: null,
  gender: '',
  city: 'Helsinki',
  aboutMe: 'The profile stays useful even when no photo is available.',
  avatarUrl: null,
  interests: [ProfileInterest(id: 1, label: 'Design')],
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
      'A deliberately long but real-looking test-only description used to '
      'verify wrapping, scrolling, and stable action controls at larger text.',
  avatarUrl: 'memory://alternate',
  interests: [
    ProfileInterest(id: 1, label: 'Contemporary architecture'),
    ProfileInterest(id: 2, label: 'Independent cinema'),
    ProfileInterest(id: 3, label: 'Long-distance cycling'),
    ProfileInterest(id: 4, label: 'Experimental cooking'),
    ProfileInterest(id: 5, label: 'Urban photography'),
  ],
  photos: [ProfilePhoto(id: 1, url: 'memory://alternate', isAvatar: true)],
  facts: {
    'Gender': 'Female',
    'Children preference': "Doesn't Matter",
    'Looking for': 'Long Term Relationship',
  },
);
