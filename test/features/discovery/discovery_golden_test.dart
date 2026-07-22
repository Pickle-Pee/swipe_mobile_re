import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swipe_mobile_re/features/discovery/application/discovery_providers.dart';
import 'package:swipe_mobile_re/features/discovery/discovery_screen.dart';
import 'package:swipe_mobile_re/features/discovery/domain/discovery_models.dart';
import 'package:swipe_mobile_re/shared/ui/app_theme.dart';
import 'package:swipe_mobile_re/shared/ui/glass_tabbar.dart';

late MemoryImage _testProfileImage;

void main() {
  const size = Size(390, 844);

  setUpAll(() async {
    final materialIcons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await materialIcons.load();
    _testProfileImage = await _createTestProfileImage();
  });

  testWidgets('Discovery normal golden', (tester) async {
    await _pumpGolden(tester, _dataState(_normalProfile), size);
    expect(find.byType(RawImage), findsOneWidget);
    await expectLater(
      find.byKey(const Key('discovery-golden-surface')),
      matchesGoldenFile('goldens/discovery_normal.png'),
    );
  });

  testWidgets('Discovery loading golden', (tester) async {
    await _pumpGolden(
      tester,
      const DiscoveryState(status: DiscoveryStatus.loading),
      size,
    );
    await expectLater(
      find.byKey(const Key('discovery-golden-surface')),
      matchesGoldenFile('goldens/discovery_loading.png'),
    );
  });

  testWidgets('Discovery empty golden', (tester) async {
    await _pumpGolden(
      tester,
      const DiscoveryState(
        status: DiscoveryStatus.empty,
        emptyReason: DiscoveryEmptyReason.noProfiles,
      ),
      size,
    );
    await expectLater(
      find.byKey(const Key('discovery-golden-surface')),
      matchesGoldenFile('goldens/discovery_empty.png'),
    );
  });

  testWidgets('Discovery error golden', (tester) async {
    await _pumpGolden(
      tester,
      DiscoveryState(
        status: DiscoveryStatus.error,
        error: Exception('offline'),
      ),
      size,
    );
    await expectLater(
      find.byKey(const Key('discovery-golden-surface')),
      matchesGoldenFile('goldens/discovery_error.png'),
    );
  });

  testWidgets('Discovery long content golden', (tester) async {
    await _pumpGolden(tester, _dataState(_longProfile), size, textScale: 1.3);
    await expectLater(
      find.byKey(const Key('discovery-golden-surface')),
      matchesGoldenFile('goldens/discovery_long_content.png'),
    );
  });

  testWidgets('Discovery missing image golden', (tester) async {
    await _pumpGolden(
      tester,
      _dataState(_missingImageProfile),
      size,
      useTestImage: false,
    );
    await expectLater(
      find.byKey(const Key('discovery-golden-surface')),
      matchesGoldenFile('goldens/discovery_missing_image.png'),
    );
  });
}

final _normalProfile = DiscoveryProfile(
  id: 10,
  firstName: 'Mila',
  dateOfBirth: null,
  city: 'Lisbon',
  aboutMe: 'Weekend walks and tiny galleries.',
  photoUrl: 'memory://profile',
  interests: const [
    DiscoveryInterest(id: 1, label: 'Travel'),
    DiscoveryInterest(id: 2, label: 'Ceramics'),
    DiscoveryInterest(id: 3, label: 'Jazz'),
  ],
  attributes: const {},
);

final _longProfile = DiscoveryProfile(
  id: 11,
  firstName: 'Alexandria Catherine with an exceptionally long name',
  dateOfBirth: null,
  city: 'A very long city name that must remain readable',
  aboutMe: 'Long content used only to verify layout resilience.',
  photoUrl: 'memory://profile',
  interests: const [
    DiscoveryInterest(id: 1, label: 'Contemporary architecture'),
    DiscoveryInterest(id: 2, label: 'Independent cinema'),
    DiscoveryInterest(id: 3, label: 'Long-distance cycling'),
  ],
  attributes: const {},
);

final _missingImageProfile = DiscoveryProfile(
  id: 12,
  firstName: 'Noor',
  dateOfBirth: null,
  city: 'Helsinki',
  aboutMe: '',
  photoUrl: null,
  interests: const [DiscoveryInterest(id: 1, label: 'Design')],
  attributes: const {},
);

DiscoveryState _dataState(DiscoveryProfile profile) =>
    DiscoveryState(status: DiscoveryStatus.data, profiles: [profile]);

Future<void> _pumpGolden(
  WidgetTester tester,
  DiscoveryState state,
  Size size, {
  double textScale = 1,
  bool useTestImage = true,
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
          key: const Key('discovery-golden-surface'),
          child: Stack(
            fit: StackFit.expand,
            children: [
              DiscoveryView(
                state: state,
                onLike: () {},
                onPass: () {},
                onRetry: () {},
                onRetryInline: () {},
                onOpenLikes: () {},
                onOpenChats: () {},
                onOpenProfile: (_) {},
                imageProviderBuilder: useTestImage
                    ? (_) => _testProfileImage
                    : null,
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: GlassNavigationBar(
                  currentIndex: 0,
                  onSelected: (_) {},
                  destinations: const [
                    GlassNavigationDestination(
                      label: 'Discover',
                      icon: Icons.explore_outlined,
                    ),
                    GlassNavigationDestination(
                      label: 'Chats',
                      icon: Icons.chat_bubble_outline_rounded,
                    ),
                    GlassNavigationDestination(
                      label: 'Likes',
                      icon: Icons.favorite_border_rounded,
                    ),
                    GlassNavigationDestination(
                      label: 'Profile',
                      icon: Icons.person_outline_rounded,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  if (useTestImage) {
    await tester.runAsync(
      () => precacheImage(
        _testProfileImage,
        tester.element(find.byType(DiscoveryView)),
      ),
    );
  }
  await tester.pumpAndSettle();
}

Future<MemoryImage> _createTestProfileImage() async {
  final pixels = Uint8List.fromList(const [
    0xFF,
    0x4F,
    0x7B,
    0xFF,
    0x8B,
    0x6C,
    0xFF,
    0xFF,
    0x5A,
    0x3A,
    0x68,
    0xFF,
    0x17,
    0x19,
    0x23,
    0xFF,
  ]);
  final buffer = await ui.ImmutableBuffer.fromUint8List(pixels);
  final descriptor = ui.ImageDescriptor.raw(
    buffer,
    width: 2,
    height: 2,
    rowBytes: 8,
    pixelFormat: ui.PixelFormat.rgba8888,
  );
  final codec = await descriptor.instantiateCodec();
  final frame = await codec.getNextFrame();
  final encoded = await frame.image.toByteData(format: ui.ImageByteFormat.png);
  final bytes = encoded!.buffer.asUint8List(
    encoded.offsetInBytes,
    encoded.lengthInBytes,
  );
  frame.image.dispose();
  codec.dispose();
  descriptor.dispose();
  buffer.dispose();
  return MemoryImage(bytes);
}
