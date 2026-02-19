import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../theme/tokens.dart';

class ShaderLiquidLayer extends StatefulWidget {
  const ShaderLiquidLayer({
    super.key,
    this.intensity = 0.55,
    this.softness = 0.45,
  });

  final double intensity;
  final double softness;

  @override
  State<ShaderLiquidLayer> createState() => _ShaderLiquidLayerState();
}

class _ShaderLiquidLayerState extends State<ShaderLiquidLayer> {
  ui.FragmentProgram? _program;
  late final Ticker _ticker;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _load();
    _ticker = Ticker((d) => setState(() => _elapsed = d))..start();
  }

  Future<void> _load() async {
    _program = await ui.FragmentProgram.fromAsset('assets/shaders/liquid.frag');
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final program = _program;
    if (program == null) return const SizedBox.expand();

    final timeSec = _elapsed.inMilliseconds / 1000.0;

    return LayoutBuilder(
      builder: (context, c) {
        final size = Size(c.maxWidth, c.maxHeight);
        final shader = program.fragmentShader();

        // uniforms order must match: uSize, uTime, c1..c4, intensity, softness
        shader.setFloat(0, size.width);
        shader.setFloat(1, size.height);
        shader.setFloat(2, timeSec);

        // Colors as RGBA floats 0..1
        void setColor(int baseIndex, Color color) {
          shader.setFloat(baseIndex + 0, color.red / 255.0);
          shader.setFloat(baseIndex + 1, color.green / 255.0);
          shader.setFloat(baseIndex + 2, color.blue / 255.0);
          shader.setFloat(baseIndex + 3, 1.0);
        }

        // pick your brand accents
        setColor(3, AppTokens.blueSoft);
        setColor(7, AppTokens.violet);
        setColor(11, AppTokens.pinkSoft);
        setColor(15, AppTokens.cyan);

        shader.setFloat(19, widget.intensity);
        shader.setFloat(20, widget.softness);

        return CustomPaint(
          painter: _ShaderPainter(shader),
          child: const SizedBox.expand(),
        );
      },
    );
  }
}

class _ShaderPainter extends CustomPainter {
  _ShaderPainter(this.shader);
  final ui.FragmentShader shader;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..shader = shader;
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(covariant _ShaderPainter oldDelegate) => true;
}
