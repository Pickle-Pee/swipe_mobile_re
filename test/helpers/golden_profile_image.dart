import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

Future<MemoryImage> createGoldenProfileImage({bool alternate = false}) async {
  final pixels = Uint8List.fromList(
    alternate
        ? const [
            0xFF,
            0xAE,
            0x68,
            0xFF,
            0x72,
            0x54,
            0xD8,
            0xFF,
            0x35,
            0x8F,
            0xA3,
            0xFF,
            0x17,
            0x19,
            0x23,
            0xFF,
          ]
        : const [
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
          ],
  );
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
