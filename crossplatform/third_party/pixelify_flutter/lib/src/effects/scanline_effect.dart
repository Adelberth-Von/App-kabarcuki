import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';import 'package:pixelify_flutter/src/utils/pixel_effect_params.dart';

class ScanlineEffect extends StatefulWidget {
  final Widget child;

  // Scanline parameters
  final double intensity; // Scanline brightness/opacity (0.0-1.0)
  final double thickness; // Thickness of each scanline in pixels
  final double spacing; // Space between scanlines in pixels
  final Color scanlineColor; // Color/tint of scanlines
  final bool animate; // Animate scanline flicker or movement
  final double animationSpeed; // Speed of scanline animation
  final double curvatureAmount; // Amount of screen curvature (0-1)
  final double glowIntensity; // Glow around bright areas
  final double colorBleedAmount; // Chromatic aberration effect amount
  final double noiseAmount; // Noise overlay opacity
  final double contrast; // Contrast adjustment of the output
  final double brightness; // Brightness adjustment of the output

  const ScanlineEffect({
    required this.child,
    this.intensity = 0.7,
    this.thickness = 1.0,
    this.spacing = 3.0,
    this.scanlineColor = Colors.black,
    this.animate = true,
    this.animationSpeed = 1.0,
    this.curvatureAmount = 0.1,
    this.glowIntensity = 0.1,
    this.colorBleedAmount = 0.05,
    this.noiseAmount = 0.05,
    this.contrast = 1.1,
    this.brightness = 1.0,
    Key? key,
  }) : super(key: key);

  @override
  State<ScanlineEffect> createState() => _ScanlineEffectState();
}

class _ScanlineEffectState extends State<ScanlineEffect> with SingleTickerProviderStateMixin {
  final GlobalKey _boundaryKey = GlobalKey();
  ui.FragmentProgram? _program;
  ui.Image? _snapshot;

  late final AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _loadShader();
    WidgetsBinding.instance.addPostFrameCallback((_) => _capture());

    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (1000 / widget.animationSpeed).round()),
    );

    if (widget.animate) {
      _animationController.repeat();
    }
  }

  Future<void> _loadShader() async {
    final program = await ShaderLoader.loadProgram('packages/retro_pixel_kit/shaders/scanline.frag');
    if (mounted) {
      setState(() {
        _program = program;
      });
    }
  }

  Future<void> _capture() async {
    if (!mounted) return;
    try {
      final boundary = _boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      final pixelRatio = MediaQuery.of(context).devicePixelRatio;
      final img = await boundary.toImage(pixelRatio: pixelRatio);
      if (!mounted) {
        img.dispose();
        return;
      }
      _snapshot?.dispose();
      setState(() => _snapshot = img);
    } catch (e) {
      debugPrint('Scanline capture error: $e');
    }
  }

  @override
  void didUpdateWidget(covariant ScanlineEffect oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.child != widget.child) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _capture());
    }
    if (widget.animate != oldWidget.animate) {
      if (widget.animate) {
        _animationController.repeat();
      } else {
        _animationController.stop();
      }
    }
  }

  @override
  void dispose() {
    _snapshot?.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        RepaintBoundary(
          key: _boundaryKey,
          child: Opacity(
            opacity: 0,
            child: widget.child,
          ),
        ),
        if (_snapshot != null && _program != null)
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (_, __) => CustomPaint(
                painter: _ScanlinePainter(
                  image: _snapshot!,
                  program: _program!,
                  intensity: widget.intensity,
                  thickness: widget.thickness,
                  spacing: widget.spacing,
                  scanlineColor: widget.scanlineColor,
                  animationValue: widget.animate ? _animationController.value : 0.0,
                  curvatureAmount: widget.curvatureAmount,
                  glowIntensity: widget.glowIntensity,
                  colorBleedAmount: widget.colorBleedAmount,
                  noiseAmount: widget.noiseAmount,
                  contrast: widget.contrast,
                  brightness: widget.brightness,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ScanlinePainter extends CustomPainter {
  final ui.FragmentProgram program;
  final ui.Image image;
  final double intensity;
  final double thickness;
  final double spacing;
  final Color scanlineColor;
  final double animationValue;
  final double curvatureAmount;
  final double glowIntensity;
  final double colorBleedAmount;
  final double noiseAmount;
  final double contrast;
  final double brightness;

  _ScanlinePainter({
    required this.program,
    required this.image,
    required this.intensity,
    required this.thickness,
    required this.spacing,
    required this.scanlineColor,
    required this.animationValue,
    required this.curvatureAmount,
    required this.glowIntensity,
    required this.colorBleedAmount,
    required this.noiseAmount,
    required this.contrast,
    required this.brightness,
  });

  @override
  void paint(Canvas canvas, Size size) {
    try {
      final shader = program.fragmentShader();

      shader.setImageSampler(0, image);
      shader.setFloat(0, size.width);
      shader.setFloat(1, size.height);
      shader.setFloat(2, intensity);
      shader.setFloat(3, thickness);
      shader.setFloat(4, spacing);
      shader.setFloat(5, scanlineColor.red / 255);
      shader.setFloat(6, scanlineColor.green / 255);
      shader.setFloat(7, scanlineColor.blue / 255);
      shader.setFloat(8, scanlineColor.opacity);
      shader.setFloat(9, animationValue);
      shader.setFloat(10, curvatureAmount);
      shader.setFloat(11, glowIntensity);
      shader.setFloat(12, colorBleedAmount);
      shader.setFloat(13, noiseAmount);
      shader.setFloat(14, contrast);
      shader.setFloat(15, brightness);

      final paint = Paint()..shader = shader;
      canvas.drawRect(Offset.zero & size, paint);
    } catch (e) {
      debugPrint('Scanline shader failed at runtime: $e');
    }
  }

  @override
  bool shouldRepaint(covariant _ScanlinePainter old) {
    return old.image != image ||
        old.intensity != intensity ||
        old.thickness != thickness ||
        old.spacing != spacing ||
        old.scanlineColor != scanlineColor ||
        old.animationValue != animationValue ||
        old.curvatureAmount != curvatureAmount ||
        old.glowIntensity != glowIntensity ||
        old.colorBleedAmount != colorBleedAmount ||
        old.noiseAmount != noiseAmount ||
        old.contrast != contrast ||
        old.brightness != brightness ||
        old.program != program;
  }
}

/// ShaderLoader loads FragmentProgram safely and provides helpful errors.
class ShaderLoader {
  static Future<ui.FragmentProgram?> loadProgram(String asset) async {
    try {
      return await ui.FragmentProgram.fromAsset(asset);
    } catch (e) {
      if (kDebugMode) {
        print('Failed to load shader: $e');
      }
      return null;
    }
  }
}

/// Parameters class for passing scanline effect parameters consistently.
class ScanlineEffectParams extends PixelEffectParams {
  final double intensity;
  final double thickness;
  final double spacing;
  final Color scanlineColor;
  final bool animate;
  final double animationSpeed;
  final double curvatureAmount;
  final double glowIntensity;
  final double colorBleedAmount;
  final double noiseAmount;
  final double contrast;
  final double brightness;

  const ScanlineEffectParams({
    this.intensity = 0.7,
    this.thickness = 1.0,
    this.spacing = 3.0,
    this.scanlineColor = Colors.black,
    this.animate = true,
    this.animationSpeed = 1.0,
    this.curvatureAmount = 0.1,
    this.glowIntensity = 0.1,
    this.colorBleedAmount = 0.05,
    this.noiseAmount = 0.05,
    this.contrast = 1.1,
    this.brightness = 1.0,
  });
}
