import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:pixelify_flutter/src/utils/pixel_effect_params.dart';

/// GlitchEffect widget: creates a dynamic glitch visual effect on its child.
/// Features included:
/// - Random horizontal slices displacement
/// - RGB channel color split with customizable colors
/// - Animated noise overlay
/// - Scanlines overlay
/// - Flicker brightness pulse
/// - Intensity and frequency controls
class GlitchEffect extends StatefulWidget {
  final Widget child;
  final double intensity; // Overall glitch strength
  final Duration frequency; // How often glitch refreshes
  final List<Color> glitchColors; // Colors used for RGB split
  final bool enableNoise; // Enable noise overlay
  final bool enableScanLines; // Enable scanlines overlay
  final double scanLineOpacity; // Opacity level of scanlines
  final double noiseIntensity; // Intensity of noise overlay

  const GlitchEffect({
    required this.child,
    this.intensity = 0.3,
    this.frequency = const Duration(milliseconds: 200),
    this.glitchColors = const [Colors.red, Colors.green, Colors.blue],
    this.enableNoise = true,
    this.enableScanLines = true,
    this.scanLineOpacity = 0.2,
    this.noiseIntensity = 0.1,
    Key? key,
  }) : super(key: key);

  @override
  State<GlitchEffect> createState() => _GlitchEffectState();
}

class _GlitchEffectState extends State<GlitchEffect> with SingleTickerProviderStateMixin {
  final Random _random = Random();
  List<_Slice> _slices = const [];
  late final Ticker _ticker;
  Duration _lastTick = Duration.zero;

  double _flickerOpacity = 0.0;
  double _noiseSeed = 0.0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick)..start();
  }

  void _tick(Duration elapsed) {
    if (elapsed - _lastTick >= widget.frequency) {
      _lastTick = elapsed;
      _generateSlices();
      _flickerOpacity = _random.nextDouble() * widget.intensity;
      _noiseSeed += 0.1;
    } else {
      _flickerOpacity *= 0.9; // Flicker fade out
    }
    setState(() {});
  }

  void _generateSlices() {
    _slices = List.generate(8, (_) {
      final dy = _random.nextDouble();
      final h = 0.02 + _random.nextDouble() * 0.18;
      final dx = (_random.nextDouble() - 0.5) * 2 * widget.intensity;
      return _Slice(dy: dy, h: h, dx: dx);
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth;
      final height = constraints.maxHeight;

      Widget scanLines = const SizedBox.shrink();
      if (widget.enableScanLines) {
        scanLines = IgnorePointer(
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(0),
                  Colors.black.withOpacity(widget.scanLineOpacity),
                  Colors.black.withOpacity(0),
                ],
                stops: const [0.0, 0.5, 1.0],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                tileMode: TileMode.repeated,
              ),
            ),
          ),
        );
      }

      Widget noise = const SizedBox.shrink();
      if (widget.enableNoise) {
        noise = IgnorePointer(
          child: CustomPaint(
            size: Size(width, height),
            painter: _NoisePainter(intensity: widget.noiseIntensity, seed: _noiseSeed),
          ),
        );
      }

      final List<Widget> colorSlices = [];
      for (final s in _slices) {
        colorSlices.addAll([
          _coloredSlice(widget.glitchColors.isNotEmpty ? widget.glitchColors[0] : Colors.red, s, width, height, -widget.intensity * 6),
          _coloredSlice(widget.glitchColors.length > 1 ? widget.glitchColors[1] : Colors.green, s, width, height, 0),
          _coloredSlice(widget.glitchColors.length > 2 ? widget.glitchColors[2] : Colors.blue, s, width, height, widget.intensity * 6),
        ]);
      }

      return Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          widget.child,
          ..._slices.map((s) => _displacedSlice(s, width, height)),
          ...colorSlices,
          noise,
          scanLines,
          if (_flickerOpacity > 0)
            Opacity(
              opacity: _flickerOpacity,
              child: Container(color: Colors.white.withOpacity(0.1)),
            ),
        ],
      );
    });
  }

  Positioned _displacedSlice(_Slice s, double width, double height) {
    return Positioned(
      top: height * s.dy,
      left: s.dx * width * 0.2,
      right: -s.dx * width * 0.2,
      height: height * s.h,
      child: ClipRect(
        child: Align(
          alignment: Alignment(0, -1 + (s.dy * 2)),
          heightFactor: 1,
          widthFactor: 1,
          child: widget.child,
        ),
      ),
    );
  }

  Positioned _coloredSlice(Color color, _Slice s, double width, double height, double horizontalOffset) {
    return Positioned(
      top: height * s.dy,
      left: s.dx * width * 0.3 + horizontalOffset,
      right: -s.dx * width * 0.3,
      height: height * s.h,
      child: ClipRect(
        child: Align(
          alignment: Alignment.center,
          heightFactor: 1,
          widthFactor: 1,
          child: ColorFiltered(
            colorFilter: ColorFilter.mode(color, BlendMode.screen),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

class _Slice {
  final double dy;
  final double h;
  final double dx;

  const _Slice({required this.dy, required this.h, required this.dx});
}

class _NoisePainter extends CustomPainter {
  final double intensity;
  final double seed;
  final Random _random = Random();

  _NoisePainter({required this.intensity, required this.seed});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(intensity);
    final count = (size.width * size.height / 1500).toInt();
    for (int i = 0; i < count; i++) {
      final x = _random.nextDouble() * size.width;
      final y = _random.nextDouble() * size.height;
      canvas.drawRect(Rect.fromCenter(center: Offset(x, y), width: 1, height: 1), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _NoisePainter oldDelegate) =>
      oldDelegate.seed != seed || oldDelegate.intensity != intensity;
}




/// Params class for consistency with your project structure
class GlitchEffectParams extends PixelEffectParams {
  final double intensity; // Overall glitch strength
  final Duration frequency; // How often glitch refreshes
  final List<Color> glitchColors; // Colors used for RGB split
  final bool enableNoise; // Enable noise overlay
  final bool enableScanLines; // Enable scanlines overlay
  final double scanLineOpacity; // Opacity level of scanlines
  final double noiseIntensity; // Intensity of noise overlay

  const GlitchEffectParams({
    this.intensity = 0.3,
    this.frequency = const Duration(milliseconds: 200),
    this.glitchColors = const [Colors.red, Colors.green, Colors.blue],
    this.enableNoise = true,
    this.enableScanLines = true,
    this.scanLineOpacity = 0.2,
    this.noiseIntensity = 0.1,
  });
}
