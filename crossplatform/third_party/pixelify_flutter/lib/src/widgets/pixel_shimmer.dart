import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';

class PixelShimmer extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final List<Color> shimmerColors;
  final double pixelSize; // size of pixel blocks

  const PixelShimmer({
    Key? key,
    required this.child,
    this.duration = const Duration(seconds: 3),
    this.shimmerColors = const [
      Colors.red,
      Colors.orange,
      Colors.yellow,
      Colors.green,
      Colors.blue,
      Colors.indigo,
      Colors.purple,
    ],
    this.pixelSize = 6.0,
  }) : super(key: key);

  @override
  _PixelShimmerState createState() => _PixelShimmerState();
}

class _PixelShimmerState extends State<PixelShimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  late final Gradient _gradient;

  @override
  void initState() {
    super.initState();

    _gradient = LinearGradient(
      colors: widget.shimmerColors,
      tileMode: TileMode.mirror,
    );

    _controller = AnimationController(vsync: this, duration: widget.duration)..repeat();
    _animation = Tween(begin: -1.0, end: 2.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Pixelate painter to give pixel block effect.
  CustomPainter _pixelatePainter(Size size) => _PixelatePainter(pixelSize: widget.pixelSize);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return _gradient.createShader(Rect.fromLTWH(
              _animation.value * bounds.width,
              0,
              bounds.width,
              bounds.height,
            ));
          },
          blendMode: BlendMode.srcATop,
          child: Stack(
            children: [
              widget.child,
              // Pixelation overlay using CustomPaint
              Positioned.fill(
                child: CustomPaint(
                  painter: _pixelatePainter(context.size ?? Size.zero),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PixelatePainter extends CustomPainter {
  final double pixelSize;
  _PixelatePainter({required this.pixelSize});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.15)
      ..style = PaintingStyle.fill;

    for (double y = 0; y < size.height; y += pixelSize) {
      for (double x = 0; x < size.width; x += pixelSize) {
        // Draw pixel squares randomly scattered with a slight flicker effect
        if (Random().nextBool()) {
          canvas.drawRect(Rect.fromLTWH(x, y, pixelSize, pixelSize), paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PixelatePainter oldDelegate) => false;
}




// Usage 

// PixelShimmer(
//   pixelSize: 8,
//   shimmerColors: [
//     Colors.red,
//     Colors.orange,
//     Colors.yellow,
//     Colors.green,
//     Colors.blue,
//     Colors.indigo,
//     Colors.purple,
//   ],
//   duration: Duration(seconds: 2),
//   child: Container(
//     width: 200,
//     height: 100,
//     color: Colors.grey.shade800,
//     alignment: Alignment.center,
//     child: Text(
//       'Loading...',
//       style: TextStyle(color: Colors.white, fontSize: 22, fontFamily: 'PressStart2P'),
//     ),
//   ),
// )