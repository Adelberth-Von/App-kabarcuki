import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

enum PixelTextEffect { none, flicker, glitch, scanline, pixelate }

/// PixelText widget combines pixel font rendering and multiple retro text effects
/// into a single configurable widget with styling parameters.
///
/// Features:
/// - Pixel font rendering (use pixel/bitmap font in fontFamily)
/// - Flicker effect (random opacity flickering)
/// - Glitch effect (color-shifted offset layers)
/// - Scanline overlay (horizontal lines)
/// - Pixelation effect (scaling transform simulating pixel blocks)
/// - Multiple palette color mode (random character colors from palette)
class PixelText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final PixelTextEffect effect;
  final Duration effectDuration;
  final List<Color>? palette; // Colors to randomly apply per character if using palette mode
  final bool enablePaletteColors;
  final double pixelScale; // >1 for pixelate effect size
  final double scanlineOpacity;
  final double scanlineSpacing;

  /// If true, flicker effect cycles continuously
  final bool flickerEnabled;

  const PixelText({
    Key? key,
    required this.text,
    required this.style,
    this.effect = PixelTextEffect.none,
    this.effectDuration = const Duration(milliseconds: 300),
    this.palette,
    this.enablePaletteColors = false,
    this.pixelScale = 4.0,
    this.scanlineOpacity = 0.15,
    this.scanlineSpacing = 4.0,
    this.flickerEnabled = true,
  })  : assert(pixelScale >= 1.0),
        super(key: key);

  @override
  _PixelTextState createState() => _PixelTextState();
}

class _PixelTextState extends State<PixelText> with SingleTickerProviderStateMixin {
  double _opacity = 1.0;
  Offset _glitchOffset1 = Offset.zero;
  Offset _glitchOffset2 = Offset.zero;

  Timer? _effectTimer;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    if (widget.effect == PixelTextEffect.flicker && widget.flickerEnabled) {
      _startFlickerTimer();
    } else if (widget.effect == PixelTextEffect.glitch) {
      _startGlitchTimer();
    }
  }

  void _startFlickerTimer() {
    _effectTimer?.cancel();
    _effectTimer = Timer.periodic(widget.effectDuration, (_) {
      setState(() {
        _opacity = 0.7 + _random.nextDouble() * 0.3;
      });
    });
  }

  void _startGlitchTimer() {
    _effectTimer?.cancel();
    _effectTimer = Timer.periodic(widget.effectDuration, (_) {
      setState(() {
        _glitchOffset1 = Offset(_random.nextDouble() * 4 - 2, _random.nextDouble() * 4 - 2);
        _glitchOffset2 = Offset(_random.nextDouble() * 4 - 2, _random.nextDouble() * 4 - 2);
      });
    });
  }

  @override
  void dispose() {
    _effectTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    TextStyle baseStyle = widget.style;

    Widget textWidget;

    if (widget.enablePaletteColors && widget.palette != null && widget.palette!.isNotEmpty) {
      textWidget = _buildPaletteText(widget.text, baseStyle, widget.palette!);
    } else {
      textWidget = Text(widget.text, style: baseStyle);
    }

    switch (widget.effect) {
      case PixelTextEffect.flicker:
        return Opacity(
          opacity: _opacity,
          child: textWidget,
        );

      case PixelTextEffect.glitch:
        return Stack(
          children: [
            textWidget,
            Positioned(
              left: _glitchOffset1.dx,
              top: _glitchOffset1.dy,
              child: Text(widget.text,
                  style: baseStyle.copyWith(color: Colors.red.withOpacity(0.6))),
            ),
            Positioned(
              left: _glitchOffset2.dx,
              top: _glitchOffset2.dy,
              child: Text(widget.text,
                  style: baseStyle.copyWith(color: Colors.blue.withOpacity(0.6))),
            ),
          ],
        );

      case PixelTextEffect.scanline:
        return ScanlineOverlay(
          opacity: widget.scanlineOpacity,
          spacing: widget.scanlineSpacing,
          child: textWidget,
        );

      case PixelTextEffect.pixelate:
        return TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: widget.pixelScale, end: 1.0),
          duration: const Duration(seconds: 2),
          builder: (context, scale, child) {
            return Transform.scale(
              scale: scale,
              alignment: Alignment.topLeft,
              child: child,
            );
          },
          child: textWidget,
        );

      case PixelTextEffect.none:
      default:
        return textWidget;
    }
  }

  Widget _buildPaletteText(String text, TextStyle style, List<Color> palette) {
    final spans = <TextSpan>[];

    for (int i = 0; i < text.length; i++) {
      final color = palette[_random.nextInt(palette.length)];
      spans.add(TextSpan(text: text[i], style: style.copyWith(color: color)));
    }

    return RichText(text: TextSpan(children: spans));
  }
}

/// ScanlineOverlay widget adds horizontal scanlines over its child widget.
class ScanlineOverlay extends StatelessWidget {
  final Widget child;
  final double opacity;
  final double spacing;

  const ScanlineOverlay({
    Key? key,
    required this.child,
    this.opacity = 0.15,
    this.spacing = 4.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Positioned.fill(
          child: CustomPaint(
            painter: _ScanlinePainter(opacity: opacity, spacing: spacing),
          ),
        ),
      ],
    );
  }
}

class _ScanlinePainter extends CustomPainter {
  final double opacity;
  final double spacing;

  _ScanlinePainter({required this.opacity, required this.spacing});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(opacity)
      ..strokeWidth = 1;

    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ScanlinePainter oldDelegate) => false;
}



// usage

// class PixelTextDemo extends StatelessWidget {
//   final pixelFontStyle = const TextStyle(
//     fontFamily: 'PressStart2P', // Include bitmap pixel font in your assets
//     fontSize: 28,
//     shadows: [Shadow(color: Colors.black, offset: Offset(1, 1))],
//   );

//   final paletteColors = [
//     Colors.cyanAccent,
//     Colors.limeAccent,
//     Colors.yellowAccent,
//     Colors.orangeAccent,
//     Colors.purpleAccent,
//   ];

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       body: Center(
//         child: Column(mainAxisSize: MainAxisSize.min, children: [
//           PixelText(
//             text: 'PIXELATE',
//             style: pixelFontStyle,
//             effect: PixelTextEffect.pixelate,
//             pixelScale: 8,
//           ),
//           const SizedBox(height: 24),
//           PixelText(
//             text: 'FLICKER',
//             style: pixelFontStyle,
//             effect: PixelTextEffect.flicker,
//             flickerEnabled: true,
//           ),
//           const SizedBox(height: 24),
//           PixelText(
//             text: 'GLITCH',
//             style: pixelFontStyle,
//             effect: PixelTextEffect.glitch,
//           ),
//           const SizedBox(height: 24),
//           PixelText(
//             text: 'SCANLINES',
//             style: pixelFontStyle,
//             effect: PixelTextEffect.scanline,
//           ),
//           const SizedBox(height: 24),
//           PixelText(
//             text: 'PALETTE',
//             style: pixelFontStyle,
//             enablePaletteColors: true,
//             palette: paletteColors,
//           ),
//         ]),
//       ),
//     );
//   }
// }
