import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:pixelify_flutter/src/utils/pixel_effect_params.dart';

/// NoiseEffect: customizable animated noise overlay for grain, static, or retro effects.
class NoiseEffect extends StatefulWidget {
  final double intensity; // Opacity of noise (0.0 - 1.0)
  final int density; // Number of noise points per update
  final double dotSize; // Size of each noise dot in pixels
  final Duration animationSpeed; // How often noise pattern updates
  final Color color; // Noise color, usually white or gray
  final bool animate; // Enable or disable animation
  final BlendMode blendMode; // Blend mode for noise overlay
  final Rect? region; // Optional clipping region for partial noise effect

  const NoiseEffect({
    Key? key,
    this.intensity = 0.2,
    this.density = 2000,
    this.dotSize = 1.5,
    this.animationSpeed = const Duration(milliseconds: 100),
    this.color = Colors.white,
    this.animate = true,
    this.blendMode = BlendMode.screen,
    this.region,
  }) : super(key: key);

  @override
  State<NoiseEffect> createState() => _NoiseEffectState();
}

class _NoiseEffectState extends State<NoiseEffect> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late List<Offset> _points;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _generateNoisePoints();

    _controller = AnimationController(vsync: this, duration: widget.animationSpeed);

    if (widget.animate) {
      _controller.repeat();
    }

    _controller.addListener(() {
      if (widget.animate) {
        _generateNoisePoints();
        setState(() {});
      }
    });
  }

  void _generateNoisePoints() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final Size? size = context.size;
      if (size == null || size.width == 0 || size.height == 0) return;

      final Rect clipRect = widget.region ?? Offset.zero & size;

      _points = List.generate(widget.density, (index) {
        final dx = _random.nextDouble() * clipRect.width + clipRect.left;
        final dy = _random.nextDouble() * clipRect.height + clipRect.top;
        return Offset(dx, dy);
      });
    });
  }

  @override
  void didUpdateWidget(covariant NoiseEffect oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animationSpeed != oldWidget.animationSpeed) {
      _controller.duration = widget.animationSpeed;
      if (widget.animate) _controller.repeat();
    }
    if (widget.animate != oldWidget.animate) {
      if (widget.animate) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    }
    if (widget.density != oldWidget.density || widget.region != oldWidget.region) {
      _generateNoisePoints();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _NoisePainter(
        points: _points,
        intensity: widget.intensity,
        dotSize: widget.dotSize,
        color: widget.color,
        blendMode: widget.blendMode,
        region: widget.region,
      ),
      child: Container(),
    );
  }
}

class _NoisePainter extends CustomPainter {
  final List<Offset> points;
  final double intensity;
  final double dotSize;
  final Color color;
  final BlendMode blendMode;
  final Rect? region;

  _NoisePainter({
    required this.points,
    required this.intensity,
    required this.dotSize,
    required this.color,
    required this.blendMode,
    this.region,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (region != null) {
      canvas.clipRect(region!);
    }

    final paint = Paint()
      ..color = color.withOpacity(intensity)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = dotSize
      ..blendMode = blendMode;

    canvas.drawPoints(PointMode.points, points, paint);
  }

  @override
  bool shouldRepaint(covariant _NoisePainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.intensity != intensity ||
        oldDelegate.dotSize != dotSize ||
        oldDelegate.color != color ||
        oldDelegate.blendMode != blendMode ||
        oldDelegate.region != region;
  }
}



/// Params class for consistency with your project structure
class NoiseEffectParams extends PixelEffectParams {
  final double intensity; // Opacity of noise (0.0 - 1.0)
  final int density; // Number of noise points per update
  final double dotSize; // Size of each noise dot in pixels
  final Duration animationSpeed; // How often noise pattern updates
  final Color color; // Noise color, usually white or gray
  final bool animate; // Enable or disable animation
  final BlendMode blendMode; // Blend mode for noise overlay
  final Rect? region; 

  const NoiseEffectParams({
   this.intensity = 0.2,
    this.density = 2000,
    this.dotSize = 1.5,
    this.animationSpeed = const Duration(milliseconds: 100),
    this.color = Colors.white,
    this.animate = true,
    this.blendMode = BlendMode.screen,
    this.region,
  });
}