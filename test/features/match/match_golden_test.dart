import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swipe_mobile_re/features/match/match_screen.dart';
import 'package:swipe_mobile_re/features/profile/domain/profile_models.dart';
import 'package:swipe_mobile_re/shared/ui/app_theme.dart';

import '../../helpers/golden_profile_image.dart';

late MemoryImage _currentImage;
late MemoryImage _matchedImage;

void main() {
  const phoneSize = Size(390, 844);

  setUpAll(() async {
    final materialIcons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await materialIcons.load();
    _currentImage = await createGoldenProfileImage();
    _matchedImage = await createGoldenProfileImage(alternate: true);
  });

  testWidgets('Match normal golden', (tester) async {
    await _pumpGolden(tester, matched: _matchedProfile, size: phoneSize);
    await expectLater(
      find.byKey(const Key('match-golden-surface')),
      matchesGoldenFile('goldens/match_normal.png'),
    );
  });

  testWidgets('Match missing photo golden', (tester) async {
    await _pumpGolden(tester, matched: _missingPhotoProfile, size: phoneSize);
    await expectLater(
      find.byKey(const Key('match-golden-surface')),
      matchesGoldenFile('goldens/match_missing_photo.png'),
    );
  });

  testWidgets('Match chat error golden', (tester) async {
    await _pumpGolden(
      tester,
      matched: _matchedProfile,
      size: phoneSize,
      chatError: Exception('offline'),
    );
    await expectLater(
      find.byKey(const Key('match-golden-surface')),
      matchesGoldenFile('goldens/match_chat_error.png'),
    );
  });
}

Future<void> _pumpGolden(
  WidgetTester tester, {
  required PublicUserProfile matched,
  required Size size,
  Object? chatError,
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
          disableAnimations: true,
        ),
        child: RepaintBoundary(
          key: const Key('match-golden-surface'),
          child: MatchView(
            matchedProfile: matched,
            currentProfile: _currentProfile,
            profileLoading: false,
            openingChat: false,
            chatError: chatError,
            onBack: () {},
            onRetryProfile: () {},
            onStartChat: () {},
            onContinue: () {},
            imageProviderBuilder: (photoUrl) {
              if (photoUrl == null || photoUrl.isEmpty) return null;
              return photoUrl.contains('matched')
                  ? _matchedImage
                  : _currentImage;
            },
          ),
        ),
      ),
    ),
  );

  final context = tester.element(find.byType(MatchView));
  await tester.runAsync(() async {
    await precacheImage(_currentImage, context);
    await precacheImage(_matchedImage, context);
    await precacheImage(
      ResizeImage.resizeIfNeeded(142, null, _currentImage),
      context,
    );
    await precacheImage(
      ResizeImage.resizeIfNeeded(142, null, _matchedImage),
      context,
    );
  });
  await tester.pumpAndSettle();
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
