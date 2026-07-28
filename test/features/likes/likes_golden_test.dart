import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swipe_mobile_re/features/likes/application/likes_providers.dart';
import 'package:swipe_mobile_re/features/likes/domain/likes_models.dart';
import 'package:swipe_mobile_re/features/likes/presentation/likes_components.dart';
import 'package:swipe_mobile_re/features/subscription/application/subscription_providers.dart';
import 'package:swipe_mobile_re/features/subscription/domain/subscription_models.dart';
import 'package:swipe_mobile_re/shared/ui/app_theme.dart';

import '../../helpers/golden_profile_image.dart';

late MemoryImage profileImage;

void main() {
  const size = Size(390, 844);

  setUpAll(() async {
    final materialIcons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await materialIcons.load();
    profileImage = await createGoldenProfileImage();
  });

  testWidgets('Likes locked golden', (tester) async {
    await pumpLikesGolden(
      tester,
      dataState,
      inactiveAccess,
      size: size,
      imageProviderBuilder: (_) => profileImage,
    );
    await expectLikesGolden(tester, 'goldens/likes_locked.png');
  });

  testWidgets('Likes unlocked golden', (tester) async {
    await pumpLikesGolden(
      tester,
      dataState,
      activeAccess,
      size: size,
      imageProviderBuilder: (_) => profileImage,
    );
    await expectLikesGolden(tester, 'goldens/likes_unlocked.png');
  });

  testWidgets('Likes loading golden', (tester) async {
    await pumpLikesGolden(
      tester,
      const LikesState(status: LikesStatus.loading),
      const SubscriptionAccessState(status: SubscriptionAccessStatus.loading),
      size: size,
    );
    await expectLikesGolden(tester, 'goldens/likes_loading.png');
  });

  testWidgets('Likes empty golden', (tester) async {
    await pumpLikesGolden(
      tester,
      const LikesState(status: LikesStatus.empty, data: emptyData),
      activeAccess,
      size: size,
    );
    await expectLikesGolden(tester, 'goldens/likes_empty.png');
  });

  testWidgets('Likes error golden', (tester) async {
    await pumpLikesGolden(
      tester,
      LikesState(status: LikesStatus.error, error: Exception('offline')),
      activeAccess,
      size: size,
    );
    await expectLikesGolden(tester, 'goldens/likes_error.png');
  });

  testWidgets('Likes missing image golden', (tester) async {
    await pumpLikesGolden(
      tester,
      const LikesState(
        status: LikesStatus.data,
        data: LikesData(
          likedMe: [missingImageUser],
          likedUsers: [],
          favorites: [],
          mutual: [],
        ),
      ),
      activeAccess,
      size: size,
    );
    await expectLikesGolden(tester, 'goldens/likes_missing_image.png');
  });
}

Future<void> pumpLikesGolden(
  WidgetTester tester,
  LikesState state,
  SubscriptionAccessState access, {
  required Size size,
  LikesImageProviderBuilder? imageProviderBuilder,
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
        child: TickerMode(
          enabled: false,
          child: RepaintBoundary(
            key: const Key('likes-golden-surface'),
            child: LikesView(
              state: state,
              access: access,
              onBack: () {},
              onRetry: () {},
              onRefresh: () async {},
              onSelectCategory: (_) {},
              onOpenSubscription: () {},
              onOpenDiscovery: () {},
              onOpenProfile: (_) {},
              imageProviderBuilder: imageProviderBuilder,
            ),
          ),
        ),
      ),
    ),
  );

  if (imageProviderBuilder != null) {
    final context = tester.element(find.byType(LikesView));
    await tester.runAsync(() async {
      await precacheImage(profileImage, context);
      await precacheImage(
        ResizeImage.resizeIfNeeded(420, null, profileImage),
        context,
      );
    });
  }
  await tester.pumpAndSettle();
}

Future<void> expectLikesGolden(WidgetTester tester, String path) => expectLater(
  find.byKey(const Key('likes-golden-surface')),
  matchesGoldenFile(path),
);

const dataState = LikesState(status: LikesStatus.data, data: data);

const data = LikesData(
  likedMe: [mila, nora, ava, lea],
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
  aboutMe: '',
  status: '',
  avatarUrl: 'memory://mila',
  mutual: false,
);

const nora = LikesUser(
  id: 2,
  firstName: 'Nora',
  dateOfBirth: null,
  city: 'Oslo',
  aboutMe: '',
  status: '',
  avatarUrl: 'memory://nora',
  mutual: false,
);

const ava = LikesUser(
  id: 3,
  firstName: 'Ava',
  dateOfBirth: null,
  city: 'Rome',
  aboutMe: '',
  status: '',
  avatarUrl: 'memory://ava',
  mutual: false,
);

const lea = LikesUser(
  id: 4,
  firstName: 'Lea',
  dateOfBirth: null,
  city: 'Paris',
  aboutMe: '',
  status: '',
  avatarUrl: 'memory://lea',
  mutual: false,
);

const missingImageUser = LikesUser(
  id: 5,
  firstName: 'Noor',
  dateOfBirth: null,
  city: 'Tallinn',
  aboutMe: '',
  status: '',
  avatarUrl: null,
  mutual: false,
);

const inactiveAccess = SubscriptionAccessState(
  status: SubscriptionAccessStatus.inactive,
);

final activeAccess = SubscriptionAccessState(
  status: SubscriptionAccessStatus.active,
  activeSubscription: ActiveSubscription(
    subscriptionId: 1,
    name: 'Premium',
    startAt: DateTime.utc(2026, 7, 22),
    endAt: DateTime.utc(2026, 8, 21),
    renewable: false,
  ),
);
