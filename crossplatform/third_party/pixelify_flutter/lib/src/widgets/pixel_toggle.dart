import 'package:flutter/material.dart';

/// PixelToggle: pixel style toggle switch with blinking or flipping animation.
/// Supports size, color customizations and multiple toggle effect styles.
class PixelToggle extends StatefulWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color onColor;
  final Color offColor;
  final double size;
  final bool blinking;
  final bool flipAnimation;

  const PixelToggle({
    Key? key,
    required this.value,
    required this.onChanged,
    this.onColor = Colors.greenAccent,
    this.offColor = Colors.grey,
    this.size = 30,
    this.blinking = false,
    this.flipAnimation = false,
  }) : super(key: key);

  @override
  _PixelToggleState createState() => _PixelToggleState();
}

class _PixelToggleState extends State<PixelToggle> with SingleTickerProviderStateMixin {
  late bool _value;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _value = widget.value;

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    if (widget.flipAnimation) {
      if (_value) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void didUpdateWidget(PixelToggle oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.value != _value) {
      setState(() => _value = widget.value);

      if (widget.flipAnimation) {
        if (_value) {
          _controller.forward();
        } else {
          _controller.reverse();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget toggle;

    if (widget.flipAnimation) {
      toggle = AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final angle = _controller.value * 3.1416; // 0 to pi radians flip
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.rotationY(angle),
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                color: angle < 1.57 ? widget.offColor : widget.onColor,
                borderRadius: BorderRadius.zero,
                border: Border.all(color: Colors.black, width: 2),
              ),
            ),
          );
        },
      );
    } else if (widget.blinking) {
      toggle = _BlinkingPixelToggle(
        size: widget.size,
        onColor: widget.onColor,
        offColor: widget.offColor,
        value: _value,
      );
    } else {
      toggle = Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: _value ? widget.onColor : widget.offColor,
          borderRadius: BorderRadius.zero,
          border: Border.all(color: Colors.black, width: 2),
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        widget.onChanged(!_value);
      },
      child: toggle,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

/// Blinking effect pixel toggle widget.
class _BlinkingPixelToggle extends StatefulWidget {
  final double size;
  final Color onColor;
  final Color offColor;
  final bool value;

  const _BlinkingPixelToggle({
    Key? key,
    required this.size,
    required this.onColor,
    required this.offColor,
    required this.value,
  }) : super(key: key);

  @override
  State<_BlinkingPixelToggle> createState() => _BlinkingPixelToggleState();
}

class _BlinkingPixelToggleState extends State<_BlinkingPixelToggle> with SingleTickerProviderStateMixin {
  late AnimationController _blinkController;

  @override
  void initState() {
    super.initState();
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _blinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _blinkController,
      builder: (context, child) {
        double opacity = widget.value ? _blinkController.value : 1.0;
        return Opacity(
          opacity: opacity,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: widget.value ? widget.onColor : widget.offColor,
              borderRadius: BorderRadius.zero,
              border: Border.all(color: Colors.black, width: 2),
            ),
          ),
        );
      },
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

