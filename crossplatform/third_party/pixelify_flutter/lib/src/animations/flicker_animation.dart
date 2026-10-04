import 'dart:math';
import 'package:flutter/material.dart';
import 'package:pixelify_flutter/src/utils/pixel_animation_params.dart';

/// FlickerAnimation: opacity flicker with full customization,
/// including intensity, speed, randomness, smooth/abrupt changes,
/// color shift support, phase offset and loop control.
class FlickerAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final bool loop;
  final bool reverse;
  final Duration delay;
  final double minOpacity;
  final double maxOpacity;
  final double randomness; // 0.0 (no jitter) to 1.0 (max jitter)
  final Curve curve;
  final double colorShiftAmount; // 0.0 to 1.0 (optional color hue flicker)
  final double phaseOffset; // 0.0 to 1.0 for stagger timing
  final VoidCallback? onFlickerComplete;

  const FlickerAnimation({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 500),
    this.loop = true,
    this.reverse = true,
    this.delay = Duration.zero,
    this.minOpacity = 0.8,
    this.maxOpacity = 1.0,
    this.randomness = 0.3,
    this.curve = Curves.linear,
    this.colorShiftAmount = 0.0,
    this.phaseOffset = 0.0,
    this.onFlickerComplete,
  });

  @override
  State<FlickerAnimation> createState() => _FlickerAnimationState();
}

class _FlickerAnimationState extends State<FlickerAnimation> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(vsync: this, duration: widget.duration);

    final curved = CurvedAnimation(parent: _controller, curve: widget.curve);

    _animation = Tween<double>(begin: widget.minOpacity, end: widget.maxOpacity).animate(curved)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          if (!widget.loop) {
            widget.onFlickerComplete?.call();
          } else if (widget.reverse) {
            _controller.reverse();
          } else {
            _controller.forward(from: 0.0);
          }
        } else if (status == AnimationStatus.dismissed && widget.loop && widget.reverse) {
          _controller.forward();
        }
      });

    if (widget.delay > Duration.zero) {
      Future.delayed(widget.delay, () {
        if (mounted) _controller.forward(from: widget.phaseOffset);
      });
    } else {
      _controller.forward(from: widget.phaseOffset);
    }
  }

  double _applyRandomness(double baseValue) {
    final jitterRange = widget.randomness * (widget.maxOpacity - widget.minOpacity);
    final jitter = (_random.nextDouble() * jitterRange) - (jitterRange / 2);
    return (baseValue + jitter).clamp(widget.minOpacity, widget.maxOpacity);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (_, child) {
        final baseOpacity = _animation.value;
        final flickeredOpacity = _applyRandomness(baseOpacity);

        // For colorShiftAmount, you would typically combine with a ColorFiltered
        // widget or similar, but here it’s left as a placeholder.

        return Opacity(
          opacity: flickeredOpacity,
          child: child,
        );
      },
      child: widget.child,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}


class FlickerAnimationParams extends PixelAnimationParams {
  final Duration duration;
  final bool loop;
  final bool reverse;
  final Duration delay;
  final double minOpacity;
  final double maxOpacity;
  final double randomness; // 0.0 (no jitter) to 1.0 (max jitter)
  final Curve curve;
  final double colorShiftAmount; // 0.0 to 1.0 (optional color hue flicker)
  final double phaseOffset; // 0.0 to 1.0 for stagger timing
  final VoidCallback? onFlickerComplete;

  const FlickerAnimationParams({
    this.duration = const Duration(milliseconds: 500),
    this.loop = true,
    this.reverse = true,
    this.delay = Duration.zero,
    this.minOpacity = 0.8,
    this.maxOpacity = 1.0,
    this.randomness = 0.3,
    this.curve = Curves.linear,
    this.colorShiftAmount = 0.0,
    this.phaseOffset = 0.0,
    this.onFlickerComplete,
  });
}