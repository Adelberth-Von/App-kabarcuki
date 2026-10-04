import 'package:flutter/material.dart';

enum PixelProgressBarStyle { segmented, smooth, iconFilled }

class PixelProgressBar extends StatefulWidget {
  final double progress; // 0.0 to 1.0
  final PixelProgressBarStyle style;
  final int segments;
  final double segmentWidth;
  final double height;
  final Color fillColor;
  final Color backgroundColor;
  final bool showScanlines;
  final bool showGlow;
  final List<Color>? glowColors;
  final Duration fillAnimationDuration;
  final Widget? icon;
  final double iconSize;

  const PixelProgressBar({
    Key? key,
    required this.progress,
    this.style = PixelProgressBarStyle.segmented,
    this.segments = 15,
    this.segmentWidth = 12,
    this.height = 20,
    this.fillColor = Colors.cyanAccent,
    this.backgroundColor = Colors.black54,
    this.showScanlines = true,
    this.showGlow = true,
    this.glowColors,
    this.fillAnimationDuration = const Duration(milliseconds: 1000),
    this.icon,
    this.iconSize = 24,
  }) : super(key: key);

  @override
  _PixelProgressBarState createState() => _PixelProgressBarState();
}

class _PixelProgressBarState extends State<PixelProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  double _oldProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _oldProgress = widget.progress;
    _animationController = AnimationController(
      vsync: this,
      duration: widget.fillAnimationDuration,
    );
    _animation = Tween<double>(begin: _oldProgress, end: widget.progress)
        .animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut))
      ..addListener(() {
        setState(() {});
      });
    _animationController.forward();
  }

  @override
  void didUpdateWidget(PixelProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.progress != oldWidget.progress) {
      _oldProgress = _animation.value;
      _animationController.duration = widget.fillAnimationDuration;
      _animation = Tween<double>(begin: _oldProgress, end: widget.progress)
          .animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut))
        ..addListener(() {
          setState(() {});
        });
      _animationController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Widget _buildSegmentedBar() {
    int fillCount = (widget.segments * _animation.value).floor();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(widget.segments, (index) {
        bool filled = index < fillCount;
        return Container(
          width: widget.segmentWidth,
          height: widget.height,
          margin: const EdgeInsets.symmetric(horizontal: 1),
          decoration: BoxDecoration(
            color: filled ? widget.fillColor : widget.backgroundColor,
            boxShadow: filled && widget.showGlow
                ? [
                    BoxShadow(
                      color: (widget.glowColors?.first ?? widget.fillColor).withOpacity(0.7),
                      blurRadius: 4,
                      spreadRadius: 1,
                      offset: const Offset(0, 0),
                    ),
                  ]
                : null,
            border: Border.all(color: Colors.black, width: 1),
          ),
          child: filled && widget.showScanlines
              ? CustomPaint(painter: _ScanlinePainter(opacity: 0.15, spacing: 3))
              : null,
        );
      }),
    );
  }

  Widget _buildSmoothBar() {
    return Container(
      width: widget.segmentWidth * widget.segments + (widget.segments - 1) * 2,
      height: widget.height,
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        border: Border.all(color: Colors.black, width: 1),
      ),
      child: Stack(
        children: [
          FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: _animation.value.clamp(0, 1),
            child: Container(
              decoration: BoxDecoration(
                color: widget.fillColor,
                boxShadow: widget.showGlow
                    ? [
                        BoxShadow(
                          color: (widget.glowColors?.first ?? widget.fillColor).withOpacity(0.8),
                          blurRadius: 6,
                          spreadRadius: 2,
                          offset: const Offset(0, 0),
                        )
                      ]
                    : null,
              ),
              child:
                  widget.showScanlines ? CustomPaint(painter: _ScanlinePainter(opacity: 0.2, spacing: 3)) : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconFilledBar() {
    final double totalWidth = widget.segmentWidth * widget.segments + (widget.segments - 1) * 2;
    double fillWidth = totalWidth * _animation.value;

    int fillCount = (widget.segments * _animation.value).floor();

    return Container(
      width: totalWidth,
      height: widget.height,
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        border: Border.all(color: Colors.black, width: 1),
      ),
      child: Stack(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(widget.segments, (index) {
              bool filled = index < fillCount;
              return Container(
                width: widget.segmentWidth,
                height: widget.height,
                margin: const EdgeInsets.symmetric(horizontal: 1),
                decoration: BoxDecoration(
                  color: filled ? Colors.transparent : widget.backgroundColor,
                  border: Border.all(color: Colors.black, width: 1),
                ),
              );
            }),
          ),
          if (widget.icon != null)
            Positioned(
              left: fillWidth - widget.iconSize / 2,
              top: (widget.height - widget.iconSize) / 2,
              child: SizedBox(
                width: widget.iconSize,
                height: widget.iconSize,
                child: widget.icon,
              ),
            ),
          FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: _animation.value.clamp(0, 1),
            child: Container(
              height: widget.height,
              decoration: BoxDecoration(
                color: widget.fillColor.withOpacity(0.8),
                boxShadow: widget.showGlow
                    ? [
                        BoxShadow(
                          color: (widget.glowColors?.first ?? widget.fillColor).withOpacity(0.8),
                          blurRadius: 6,
                          spreadRadius: 2,
                          offset: const Offset(0, 0),
                        )
                      ]
                    : null,
              ),
              child: widget.showScanlines
                  ? CustomPaint(painter: _ScanlinePainter(opacity: 0.1, spacing: 3))
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.style) {
      case PixelProgressBarStyle.segmented:
        return _buildSegmentedBar();
      case PixelProgressBarStyle.smooth:
        return _buildSmoothBar();
      case PixelProgressBarStyle.iconFilled:
        return _buildIconFilledBar();
    }
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

// class SamplePixelProgressBar extends StatefulWidget {
//   @override
//   _SamplePixelProgressBarState createState() => _SamplePixelProgressBarState();
// }

// class _SamplePixelProgressBarState extends State<SamplePixelProgressBar> {
//   double progress = 0.0;

//   @override
//   void initState() {
//     super.initState();
//     _simulateProgress();
//   }

//   void _simulateProgress() {
//     Future.delayed(const Duration(milliseconds: 200), () {
//       setState(() {
//         progress += 0.05;
//         if (progress > 1) progress = 0.0;
//       });
//       _simulateProgress();
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         PixelProgressBar(
//           progress: progress,
//           style: PixelProgressBarStyle.segmented,
//           segments: 20,
//           segmentWidth: 12,
//           height: 20,
//           fillColor: Colors.cyanAccent,
//           backgroundColor: Colors.black38,
//           showScanlines: true,
//           showGlow: true,
//         ),
//         SizedBox(height: 30),
//         PixelProgressBar(
//           progress: progress,
//           style: PixelProgressBarStyle.smooth,
//           segments: 20,
//           segmentWidth: 12,
//           height: 20,
//           fillColor: Colors.orangeAccent,
//           backgroundColor: Colors.black87,
//           showScanlines: true,
//           showGlow: false,
//         ),
//         SizedBox(height: 30),
//         PixelProgressBar(
//           progress: progress,
//           style: PixelProgressBarStyle.iconFilled,
//           segments: 15,
//           segmentWidth: 14,
//           height: 28,
//           fillColor: Colors.purpleAccent,
//           backgroundColor: Colors.black54,
//           icon: Icon(Icons.star, color: Colors.yellowAccent),
//           iconSize: 28,
//           showGlow: true,
//           showScanlines: true,
//         ),
//       ],
//     );
//   }
// }
