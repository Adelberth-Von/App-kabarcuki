import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:pixelify_flutter/src/utils/pixel_animation_params.dart';

/// JitterAnimation: small random or patterned offsets with rich customization.
/// Features include:
/// - Separate control for X and Y amplitude (strengthX, strengthY)
/// - Duration and curve for smooth or sharp jitter changes
/// - Looping and reversal control
/// - Decay/fade-out to smoothly stop
/// - Phase offset for staggered start timing
/// - Randomness control blending random jumps and smooth oscillations
/// - Manual trigger to start/stop jitter
class JitterAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final bool loop;
  final bool reverse;
  final double strengthX;
  final double strengthY;
  final double randomness; // 0.0 no jitter, 1.0 full random jumps
  final Curve curve;
  final double phaseOffset; // 0.0-1.0 stagger start timing
  final bool decay;
  final Duration? delay;

  const JitterAnimation({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 120),
    this.loop = true,
    this.reverse = true,
    this.strengthX = 2.0,
    this.strengthY = 2.0,
    this.randomness = 1.0,
    this.curve = Curves.linear,
    this.phaseOffset = 0.0,
    this.decay = false,
    this.delay,
  });

  @override
  State<JitterAnimation> createState() => _JitterAnimationState();
}

class _JitterAnimationState extends State<JitterAnimation> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;
  final Random _random = Random();

  double _decayFactor = 1.0;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(vsync: this, duration: widget.duration);

    final curved = CurvedAnimation(parent: _controller, curve: widget.curve);

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(curved)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          if (!widget.loop) {
            if (widget.decay) {
              _startDecay();
            } else {
              _controller.stop();
            }
          } else if (widget.reverse) {
            _controller.reverse();
          } else {
            _controller.forward(from: 0.0);
          }
        } else if (status == AnimationStatus.dismissed && widget.loop && widget.reverse) {
          _controller.forward();
        }
      });

    if (widget.delay != null && widget.delay! > Duration.zero) {
      Future.delayed(widget.delay!, () {
        if (mounted) _controller.forward(from: widget.phaseOffset);
      });
    } else {
      _controller.forward(from: widget.phaseOffset);
    }
  }

  void _startDecay() {
    Future.doWhile(() async {
      if (_decayFactor <= 0.01 || !mounted) return false;
      await Future.delayed(const Duration(milliseconds: 30));
      setState(() {
        _decayFactor *= 0.9;
      });
      return true;
    });
  }

  Offset _calculateOffset(double t) {
    // Smooth oscillation (sinusoidal)
    final smoothX = widget.strengthX * 0.5 * sin(2 * pi * t);
    final smoothY = widget.strengthY * 0.5 * sin(2 * pi * (t + 0.3));

    // Random jumps
    final randX = (_random.nextDouble() - 0.5) * 2 * widget.strengthX;
    final randY = (_random.nextDouble() - 0.5) * 2 * widget.strengthY;

    // Blend smooth oscillation and random jumps by randomness parameter
    double x = lerpDouble(smoothX, randX, widget.randomness)!;
    double y = lerpDouble(smoothY, randY, widget.randomness)!;

    // Apply decay factor if enabled
    if (widget.decay) {
      x *= _decayFactor;
      y *= _decayFactor;
    }

    return Offset(x, y);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      child: widget.child,
      builder: (context, child) {
        final offset = _calculateOffset(_animation.value);
        return Transform.translate(
          offset: offset,
          child: child,
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}


class JitterAnimationParams extends PixelAnimationParams {
  final Duration duration;
  final bool loop;
  final bool reverse;
  final double strengthX;
  final double strengthY;
  final double randomness; // 0.0 no jitter, 1.0 full random jumps
  final Curve curve;
  final double phaseOffset; // 0.0-1.0 stagger start timing
  final bool decay;
  final Duration? delay;

  const JitterAnimationParams({
    this.duration = const Duration(milliseconds: 120),
    this.loop = true,
    this.reverse = true,
    this.strengthX = 2.0,
    this.strengthY = 2.0,
    this.randomness = 1.0,
    this.curve = Curves.linear,
    this.phaseOffset = 0.0,
    this.decay = false,
    this.delay,
  });
}