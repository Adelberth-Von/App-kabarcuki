import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

/// Widget that shows a pixelated retro shimmer loading overlay
/// over the child widget until the provided future completes.
/// After the future completes, shows the actual child content.
class PixelFutureShimmer<T> extends StatefulWidget {
  final Future<T> future;
  final Widget Function(BuildContext context, T? snapshotData) builder;
  final Duration shimmerDuration;
  final List<Color> shimmerColors;
  final double pixelSize;

  const PixelFutureShimmer({
    Key? key,
    required this.future,
    required this.builder,
    this.shimmerDuration = const Duration(seconds: 3),
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
  _PixelFutureShimmerState<T> createState() => _PixelFutureShimmerState<T>();
}

class _PixelFutureShimmerState<T> extends State<PixelFutureShimmer<T>> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  bool _loading = true;
  T? _data;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(vsync: this, duration: widget.shimmerDuration)..repeat();
    _animation = Tween(begin: -1.0, end: 2.0).animate(_controller);

    widget.future.then((value) {
      if (mounted) {
        setState(() {
          _loading = false;
          _data = value;
          _controller.stop();
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  CustomPainter _pixelatePainter(Size size) => _PixelatePainter(pixelSize: widget.pixelSize);

  @override
  Widget build(BuildContext context) {
    if (!_loading) {
      // Show actual content after loading finishes
      return widget.builder(context, _data);
    }

    // Show pixelated shimmer while loading
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final gradient = LinearGradient(
          colors: widget.shimmerColors,
          tileMode: TileMode.mirror,
        );

        return ShaderMask(
          shaderCallback: (bounds) => gradient.createShader(Rect.fromLTWH(
            _animation.value * bounds.width,
            0,
            bounds.width,
            bounds.height,
          )),
          blendMode: BlendMode.srcATop,
          child: Stack(
            children: [
              widget.builder(context, null), // Render layout or placeholders in original shape
              Positioned.fill(
                child: CustomPaint(
                  painter: _pixelatePainter(MediaQuery.of(context).size),
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

    final random = Random();

    for (double y = 0; y < size.height; y += pixelSize) {
      for (double x = 0; x < size.width; x += pixelSize) {
        if (random.nextBool()) {
          canvas.drawRect(Rect.fromLTWH(x, y, pixelSize, pixelSize), paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PixelatePainter oldDelegate) => false;
}



// usage

// PixelFutureShimmer<List<String>>(
//   future: fetchItemsFromApi(),
//   pixelSize: 8,
//   shimmerColors: [
//     Colors.red,
//     Colors.yellow,
//     Colors.blue,
//   ],
//   builder: (context, data) {
//     if (data == null) {
//       // Render simple blank layout representing content shape for shimmer
//       return Container(
//         width: 300,
//         height: 100,
//         color: Colors.grey.shade800,
//       );
//     }
//     // Render actual loaded content
//     return ListView(
//       children: data.map((item) => ListTile(title: Text(item))).toList(),
//     );
//   },
// )
