import 'package:flutter/material.dart';

import 'liquid_ui.dart';

/// Legacy compatibility entry point for screens that still reference the old
/// atmospheric background directly.
///
/// The former implementation owned an always-running ticker, rebuilt every
/// frame, and painted four very large blurred circles. Midnight Aura uses the
/// same static, repaint-stable backdrop as the application shell instead.
class AiAtmosphericBackground extends StatelessWidget {
  const AiAtmosphericBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppBackdrop(child: SizedBox.expand());
  }
}
