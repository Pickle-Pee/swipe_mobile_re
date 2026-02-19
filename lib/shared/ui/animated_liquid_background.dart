import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../theme/tokens.dart';

class AiAtmosphericBackground extends StatefulWidget {
  const AiAtmosphericBackground({super.key});

  @override
  State<AiAtmosphericBackground> createState() =>
      _AiAtmosphericBackgroundState();
}

class _AiAtmosphericBackgroundState extends State<AiAtmosphericBackground>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((d) => setState(() => _elapsed = d))..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _AtmosPainter(time: _elapsed.inMilliseconds / 1000.0),
      child: const SizedBox.expand(),
    );
  }
}

class _AtmosPainter extends CustomPainter {
  _AtmosPainter({required this.time});

  final double time;

  @override
  void paint(Canvas canvas, Size size) {
    // Helper to draw soft glow field
    void drawField({
      required Color color,
      required Offset center,
      required double radius,
      required double opacity,
      required double blurSigma,
      BlendMode blendMode = BlendMode.softLight,
    }) {
      final paint = Paint()
        ..color = color.withOpacity(opacity)
        ..blendMode = blendMode
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, blurSigma);

      canvas.drawCircle(center, radius, paint);
    }

    // Ultra slow drift + breathing
    final t = time;

    Offset drift(
      double speedX,
      double speedY,
      double phase, {
      double amp = 0.16,
    }) {
      return Offset(
        size.width * (0.5 + amp * math.sin(t * speedX + phase)),
        size.height * (0.5 + amp * math.cos(t * speedY + phase)),
      );
    }

    double breathe(double speed, double phase, {double amp = 0.10}) {
      return 1.0 + amp * math.sin(t * speed + phase);
    }

    // На Figma такие поля ОЧЕНЬ большие и ОЧЕНЬ размытые
    final baseR = size.longestSide;

    // 1) Warm/pink haze (низ/бок)
    drawField(
      color: AppTokens.pinkSoft,
      center: drift(0.010, 0.013, 1.4, amp: 0.18),
      radius: baseR * 1.35 * breathe(0.020, 0.3, amp: 0.10),
      opacity: 0.16,
      blurSigma: 260,
    );

    // 2) Violet depth (центр/верх)
    drawField(
      color: AppTokens.violet,
      center: drift(0.009, 0.015, 2.1, amp: 0.16),
      radius: baseR * 1.55 * breathe(0.018, 1.1, amp: 0.09),
      opacity: 0.14,
      blurSigma: 280,
    );

    // 3) Cyan “intelligence” glow (второй слой, слабее)
    drawField(
      color: AppTokens.cyan,
      center: drift(0.012, 0.009, 0.7, amp: 0.15),
      radius: baseR * 1.45 * breathe(0.022, 2.0, amp: 0.10),
      opacity: 0.10,
      blurSigma: 300,
    );

    // 4) Доп. “тонкий” холодный слой для объёма (очень слабый)
    drawField(
      color: AppTokens.blueSoft,
      center: drift(0.007, 0.011, 3.0, amp: 0.14),
      radius: baseR * 1.70 * breathe(0.016, 0.9, amp: 0.07),
      opacity: 0.06,
      blurSigma: 340,
    );
  }

  @override
  bool shouldRepaint(covariant _AtmosPainter old) => old.time != time;
}
