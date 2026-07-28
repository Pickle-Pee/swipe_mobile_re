import 'package:flutter/widgets.dart';

import '../../core/config/config.dart';

/// Resolves backend media URLs that Flutter's raster image pipeline can decode.
///
/// Demo avatars are currently seeded as SVG files. `ImageProvider` does not
/// decode SVG, so returning null lets every consumer use its existing,
/// deterministic fallback instead of producing repeated platform decoder
/// errors.
ImageProvider<Object>? appNetworkImage(String? value) {
  final source = value?.trim();
  if (source == null || source.isEmpty) return null;

  final parsed = Uri.tryParse(source);
  if (parsed == null) return null;
  final resolved = parsed.hasScheme
      ? parsed
      : Uri.parse(AppConfig.baseAppUrl).resolveUri(parsed);

  if (resolved.path.toLowerCase().endsWith('.svg')) return null;
  return NetworkImage(resolved.toString());
}
