import 'package:flutter/material.dart';
import 'package:pixelify_flutter/src/utils/pixel_animation_params.dart';

/// FadeAnimation: opacity fade in/out with full customization.
/// Features:
/// - Control over opacity range (start/end)
/// - Duration and curve
/// - Repeat and reverse control
/// - Delay before start
/// - Manual trigger support
class FadeAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Curve curve;
  final bool loop;
  final bool reverse;
  final Duration delay;
  final double beginOpacity;
  final double endOpacity;
  final VoidCallback? onFadeComplete;

  const FadeAnimation({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 600),
    this.curve = Curves.linear,
    this.loop = true,
    this.reverse = true,
    this.delay = Duration.zero,
    this.beginOpacity = 0.0,
    this.endOpacity = 1.0,
    this.onFadeComplete,
  });

  @override
  State<FadeAnimation> createState() => _FadeAnimationState();
}

class _FadeAnimationState extends State<FadeAnimation> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    final curvedAnimation = CurvedAnimation(parent: _controller, curve: widget.curve);

    _animation = Tween<double>(begin: widget.beginOpacity, end: widget.endOpacity).animate(curvedAnimation)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          if (!widget.loop) {
            widget.onFadeComplete?.call();
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
        if (mounted) _controller.forward();
      });
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value.clamp(0.0, 1.0),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}


class FadeAnimationParams extends PixelAnimationParams {
  final Duration duration;
  final Curve curve;
  final bool loop;
  final bool reverse;
  final Duration delay;
  final double beginOpacity;
  final double endOpacity;
  final VoidCallback? onFadeComplete;

  const FadeAnimationParams({
    this.duration = const Duration(milliseconds: 600),
    this.curve = Curves.linear,
    this.loop = true,
    this.reverse = true,
    this.delay = Duration.zero,
    this.beginOpacity = 0.0,
    this.endOpacity = 1.0,
    this.onFadeComplete,
  });
}
