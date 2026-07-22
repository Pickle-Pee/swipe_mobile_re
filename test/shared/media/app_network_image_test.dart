import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swipe_mobile_re/shared/media/app_network_image.dart';

void main() {
  test('returns null for missing and SVG media', () {
    expect(appNetworkImage(null), isNull);
    expect(appNetworkImage('  '), isNull);
    expect(appNetworkImage('/service/get_file/demo-avatar-01.svg'), isNull);
    expect(
      appNetworkImage('https://example.test/avatar.SVG?version=2'),
      isNull,
    );
  });

  test('keeps absolute raster URLs', () {
    final provider = appNetworkImage('https://example.test/avatar.png');

    expect(provider, isA<NetworkImage>());
    expect((provider! as NetworkImage).url, 'https://example.test/avatar.png');
  });

  test('resolves relative raster URLs against the configured backend', () {
    final provider = appNetworkImage('/service/get_file/avatar.webp');

    expect(provider, isA<NetworkImage>());
    expect(
      (provider! as NetworkImage).url,
      contains('/service/get_file/avatar.webp'),
    );
  });
}
