import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:pixelify_flutter/src/utils/pixel_effect_params.dart';
import '../utils/shader_loader.dart';
import 'package:flutter/rendering.dart';

/// PixelateEffect: applies pixelation with shader fallback to image scaling,
/// supporting customizable pixel size, color tint, edge softness, blend intensity,
/// region of effect (mask), and animation support.
class PixelateEffect extends StatefulWidget {
  final Widget child;
  final double pixelSize; // size of pixel blocks
  final Color? pixelColor; // optional tint color on pixels (null = no tint)
  final double intensity; // 0.0 (no pixelation) to 1.0 (full pixelation)
  final bool softEdges; // if true, pixel edges softened (anti-aliased)
  final Rect? region; // optional rectangular region to apply effect
  final Duration? animationDuration; // optional animation duration for pixel size
  final Curve animationCurve;

  const PixelateEffect({
    required this.child,
    this.pixelSize = 8.0,
    this.pixelColor,
    this.intensity = 1.0,
    this.softEdges = false,
    this.region,
    this.animationDuration,
    this.animationCurve = Curves.linear,
    Key? key,
  }) : super(key: key);

  @override
  State<PixelateEffect> createState() => _PixelateEffectState();
}

class _PixelateEffectState extends State<PixelateEffect> with SingleTickerProviderStateMixin {
  final GlobalKey _boundaryKey = GlobalKey();
  ui.FragmentProgram? _program;
  ui.Image? _snapshot;

  late AnimationController? _controller;
  late Animation<double>? _animation;

  @override
  void initState() {
    super.initState();
    _loadShader();

    if (widget.animationDuration != null) {
      _controller = AnimationController(vsync: this, duration: widget.animationDuration!);
      _animation = Tween<double>(begin: 1.0, end: widget.pixelSize).animate(
        CurvedAnimation(parent: _controller!, curve: widget.animationCurve),
      )..addListener(() => setState(() {}));
      _controller!.repeat(reverse: true);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => _capture());
  }

  Future<void> _loadShader() async {
    try {
      final program = await ShaderLoader.loadProgram('packages/retro_pixel_kit/shaders/pixelate.frag');
      if (mounted) {
        setState(() {
          _program = program;
        });
      }
    } catch (e) {
      debugPrint('Failed to load pixelate shader: $e');
    }
  }

  Future<void> _capture() async {
    try {
      final boundary = _boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      final fallbackPixelRatio = 1 / (widget.pixelSize * (widget.intensity.clamp(0, 1)));
      final shaderPixelRatio = MediaQuery.of(context).devicePixelRatio;

      final useShader = _program != null;

      final pixelRatio = useShader ? shaderPixelRatio : fallbackPixelRatio.clamp(0.1, 1.0);

      final img = await boundary.toImage(pixelRatio: pixelRatio);
      if (mounted) {
        setState(() {
          _snapshot = img;
        });
      }
    } catch (e) {
      debugPrint('Snapshot capture error: $e');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant PixelateEffect oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) => _capture());
  }

  @override
  Widget build(BuildContext context) {
    final childToCapture = RepaintBoundary(key: _boundaryKey, child: widget.child);

    if (_snapshot == null) {
      return childToCapture;
    }

    final currentPixelSize = _animation?.value ?? (widget.pixelSize * widget.intensity);

    return CustomPaint(
      painter: _PixelatePainter(
        image: _snapshot!,
        program: _program,
        pixelSize: currentPixelSize,
        pixelColor: widget.pixelColor,
        softEdges: widget.softEdges,
        region: widget.region,
      ),
      child: Offstage(child: childToCapture),
    );
  }
}

class _PixelatePainter extends CustomPainter {
  final ui.FragmentProgram? program;
  final ui.Image image;
  final double pixelSize;
  final Color? pixelColor;
  final bool softEdges;
  final Rect? region;

  _PixelatePainter({
    required this.image,
    this.program,
    required this.pixelSize,
    this.pixelColor,
    this.softEdges = false,
    this.region,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (program != null) {
      try {
        final shader = program!.fragmentShader();
        shader.setImageSampler(0, image);
        shader.setFloat(0, size.width);
        shader.setFloat(1, size.height);
        shader.setFloat(2, pixelSize);
        shader.setFloat(3, softEdges ? 1.0 : 0.0);
        if (pixelColor != null) {
          shader.setFloat(4, pixelColor!.red / 255);
          shader.setFloat(5, pixelColor!.green / 255);
          shader.setFloat(6, pixelColor!.blue / 255);
          shader.setFloat(7, pixelColor!.opacity);
        } else {
          shader.setFloat(4, 1.0);
          shader.setFloat(5, 1.0);
          shader.setFloat(6, 1.0);
          shader.setFloat(7, 1.0);
        }
        // Region uniform: x, y, width, height, or pass 0,0,0,0 for full
        if (region != null) {
          shader.setFloat(8, region!.left);
          shader.setFloat(9, region!.top);
          shader.setFloat(10, region!.width);
          shader.setFloat(11, region!.height);
        } else {
          shader.setFloat(8, 0);
          shader.setFloat(9, 0);
          shader.setFloat(10, 0);
          shader.setFloat(11, 0);
        }

        final paint = Paint()..shader = shader;
        canvas.drawRect(Offset.zero & size, paint);
        return;
      } catch (e) {
        debugPrint('Shader paint failed: $e');
      }
    }

    // Fallback: scale down and up the image for pixelation
    final paint = Paint()..filterQuality = FilterQuality.none;
    final srcRect = region != null
        ? Rect.fromLTWH(region!.left, region!.top, region!.width, region!.height)
        : Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());

    // final dstRect = region != null
    //     ? Rect.fromLTWH(region!.left, region!.top, region!.width, region!.height)
    //     : Offset.zero & size;

    canvas.save();

    // Clip region if specified
    if (region != null) {
      canvas.clipRect(region!);
    }

    // Draw scaled down image then scale up to create pixel effect
    double scale = pixelSize > 0 ? 1 / pixelSize : 1;

    canvas.scale(scale, scale);

    canvas.drawImageRect(
      image,
      srcRect,
      Offset.zero & Size(size.width * scale, size.height * scale),
      paint,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _PixelatePainter old) {
    return old.image != image ||
        old.pixelSize != pixelSize ||
        old.program != program ||
        old.pixelColor != pixelColor ||
        old.softEdges != softEdges ||
        old.region != region;
  }
}


/// Params class for consistency with your project structure
class PixelateEffectParams extends PixelEffectParams {
  final double pixelSize;
  final Color? pixelColor;
  final double intensity;
  final bool softEdges;
  final Rect? region;
  final Duration? animationDuration;

  const PixelateEffectParams({
    this.pixelSize = 8.0,
    this.pixelColor,
    this.intensity = 1.0,
    this.softEdges = false,
    this.region,
    this.animationDuration,
  });
}
