import 'dart:math';
import 'package:flutter/material.dart';

enum PixelPanelStyle { pixelOutline, glowingBorder, paperGrain, oldScreenCRT }

class PixelPanel extends StatelessWidget {
  final Widget child;
  final double width;
  final double height;
  final PixelPanelStyle style;
  final double borderThickness;
  final double glowRadius;
  final bool showScanlines;
  final bool showPixelation;
  final Color borderColor;
  final List<Color>? gradientColors;

  const PixelPanel({
    super.key,
    required this.child,
    this.width = 300,
    this.height = 200,
    this.style = PixelPanelStyle.pixelOutline,
    this.borderThickness = 4.0,
    this.glowRadius = 10.0,
    this.showScanlines = true,
    this.showPixelation = true,
    this.borderColor = Colors.white,
    this.gradientColors,
  });

  Widget _buildBackground(BuildContext context) {
    switch (style) {
      case PixelPanelStyle.paperGrain:
        return Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradientColors ??
                      [
                        Colors.grey.shade300,
                        Colors.grey.shade100,
                        Colors.grey.shade300,
                      ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            Positioned.fill(child: _NoiseOverlay(intensity: 0.1, pixelSize: 2)),
          ],
        );

      case PixelPanelStyle.oldScreenCRT:
        return Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors:
                      gradientColors ?? [Colors.black87, Colors.black, Colors.black87],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            Positioned.fill(
              child: _ScanlineOverlay(
                opacity: 0.12,
                spacing: 3,
              ),
            ),
            if (showPixelation)
              Positioned.fill(child: _NoiseOverlay(intensity: 0.06, pixelSize: 4)),
          ],
        );

      case PixelPanelStyle.glowingBorder:
      case PixelPanelStyle.pixelOutline:
      default:
        return Container(
          color: Colors.black,
        );
    }
  }

  BoxDecoration _buildBorder() {
    switch (style) {
      case PixelPanelStyle.pixelOutline:
        return BoxDecoration(
          border: Border.all(
            color: borderColor,
            width: borderThickness,
          ),
        );

      case PixelPanelStyle.glowingBorder:
        return BoxDecoration(
          border: Border.all(
            color: borderColor,
            width: borderThickness / 2,
          ),
          boxShadow: [
            BoxShadow(
              color: borderColor.withOpacity(0.9),
              blurRadius: glowRadius,
              spreadRadius: glowRadius / 2,
            )
          ],
        );

      default:
        return BoxDecoration();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: _buildBorder(),
      child: Stack(
        children: [
          _buildBackground(context),
          Padding(
            padding: EdgeInsets.all(borderThickness),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _NoiseOverlay extends StatelessWidget {
  final double intensity;
  final double pixelSize;

  const _NoiseOverlay({Key? key, required this.intensity, required this.pixelSize})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _NoisePainter(intensity: intensity, pixelSize: pixelSize),
    );
  }
}

class _NoisePainter extends CustomPainter {
  final double intensity;
  final double pixelSize;
  final Random _random = Random();

  _NoisePainter({required this.intensity, required this.pixelSize});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(intensity)
      ..style = PaintingStyle.fill;

    for (double y = 0; y < size.height; y += pixelSize) {
      for (double x = 0; x < size.width; x += pixelSize) {
        if (_random.nextBool()) {
          canvas.drawRect(Rect.fromLTWH(x, y, pixelSize, pixelSize), paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _NoisePainter oldDelegate) => false;
}

class _ScanlineOverlay extends StatelessWidget {
  final double opacity;
  final double spacing;

  const _ScanlineOverlay({
    Key? key,
    this.opacity = 0.1,
    this.spacing = 4.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ScanlinePainter(opacity: opacity, spacing: spacing),
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

// PixelPanel(
//   width: 320,
//   height: 180,
//   style: PixelPanelStyle.oldScreenCRT,
//   borderThickness: 5,
//   glowRadius: 15,
//   borderColor: Colors.greenAccent,
//   child: Center(
//     child: Text(
//       ' retro pixel panel ',
//       style: TextStyle(
//         color: Colors.greenAccent,
//         fontFamily: 'PressStart2P',
//         fontSize: 16,
//       ),
//     ),
//   ),
// );
