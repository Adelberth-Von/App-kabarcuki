import 'package:flutter/material.dart';

/// PixelSlider: slider with pixel segmented track and pixel handle.
/// Supports smooth or stepped value changes, color and size customization.
class PixelSlider extends StatefulWidget {
  final double value;
  final ValueChanged<double> onChanged;
  final Color activeColor;
  final Color inactiveColor;
  final double segmentWidth; // width of each pixel segment
  final int? divisions; // for stepped slider, null for smooth
  final double height;
  final double handleSize;

  const PixelSlider({
    Key? key,
    required this.value,
    required this.onChanged,
    this.activeColor = Colors.cyanAccent,
    this.inactiveColor = Colors.grey,
    this.segmentWidth = 6.0,
    this.divisions,
    this.height = 12,
    this.handleSize = 20,
  }) : super(key: key);

  @override
  _PixelSliderState createState() => _PixelSliderState();
}

class _PixelSliderState extends State<PixelSlider> {
  late double _localValue;

  @override
  void initState() {
    super.initState();
    _localValue = widget.value;
  }

  @override
  void didUpdateWidget(PixelSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _localValue) {
      _localValue = widget.value;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        final box = context.findRenderObject() as RenderBox;
        final localPosition = box.globalToLocal(details.globalPosition);
        double percent = (localPosition.dx / box.size.width).clamp(0.0, 1.0);
        if (widget.divisions != null) {
          int div = widget.divisions!;
          percent = (percent * div).round() / div;
        }
        setState(() {
          _localValue = percent;
        });
        widget.onChanged(_localValue);
      },
      onTapDown: (details) {
        final box = context.findRenderObject() as RenderBox;
        final localPosition = box.globalToLocal(details.globalPosition);
        double percent = (localPosition.dx / box.size.width).clamp(0.0, 1.0);
        if (widget.divisions != null) {
          int div = widget.divisions!;
          percent = (percent * div).round() / div;
        }
        setState(() {
          _localValue = percent;
        });
        widget.onChanged(_localValue);
      },
      child: SizedBox(
        height: widget.height,
        child: CustomPaint(
          painter: _PixelSliderPainter(
            value: _localValue,
            activeColor: widget.activeColor,
            inactiveColor: widget.inactiveColor,
            segmentWidth: widget.segmentWidth,
            divisions: widget.divisions,
            height: widget.height,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final handleX = constraints.maxWidth * _localValue - widget.handleSize / 2;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: handleX.clamp(0.0, constraints.maxWidth - widget.handleSize),
                    top: (widget.height - widget.handleSize) / 2,
                    child: _PixelHandle(size: widget.handleSize, color: widget.activeColor),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _PixelSliderPainter extends CustomPainter {
  final double value;
  final Color activeColor;
  final Color inactiveColor;
  final double segmentWidth;
  final int? divisions;
  final double height;

  _PixelSliderPainter({
    required this.value,
    required this.activeColor,
    required this.inactiveColor,
    required this.segmentWidth,
    this.divisions,
    required this.height,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Draw inactive segments
    int segmentCount = (size.width / segmentWidth).floor();

    // If divisions is set, clamp segments to divisions count
    if (divisions != null) {
      segmentCount = divisions!;
    }

    final segmentHeight = height;
    // final steps = segmentCount;

    for (int i = 0; i < segmentCount; i++) {
      final segmentLeft = i * segmentWidth;
      paint.color = (i / (segmentCount - 1) <= value) ? activeColor : inactiveColor;
      canvas.drawRect(Rect.fromLTWH(segmentLeft, 0, segmentWidth - 1, segmentHeight), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _PixelSliderPainter oldDelegate) {
    return oldDelegate.value != value ||
        oldDelegate.activeColor != activeColor ||
        oldDelegate.inactiveColor != inactiveColor;
  }
}

class _PixelHandle extends StatelessWidget {
  final double size;
  final Color color;

  const _PixelHandle({Key? key, required this.size, required this.color}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.zero,
        boxShadow: [
          BoxShadow(
            color: Colors.black87,
            offset: const Offset(2, 2),
            blurRadius: 0,
          ),
        ],
      ),
    );
  }
}



// usage

// class MyRetroUI extends StatefulWidget {
//   @override
//   State<MyRetroUI> createState() => _MyRetroUIState();
// }

// class _MyRetroUIState extends State<MyRetroUI> {
//   double sliderValue = 0.4;
//   bool toggleValue = true;

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       body: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             PixelSlider(
//               value: sliderValue,
//               onChanged: (v) => setState(() => sliderValue = v),
//               divisions: 10,
//               activeColor: Colors.cyanAccent,
//               inactiveColor: Colors.grey.shade700,
//             ),
//             const SizedBox(height: 50),
//             PixelToggle(
//               value: toggleValue,
//               onChanged: (v) => setState(() => toggleValue = v),
//               blinking: true,
//             ),
//             const SizedBox(height: 20),
//             PixelToggle(
//               value: toggleValue,
//               onChanged: (v) => setState(() => toggleValue = v),
//               flipAnimation: true,
//               onColor: Colors.deepPurpleAccent,
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

