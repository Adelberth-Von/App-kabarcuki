import 'dart:math' as math;
import 'package:flutter/widgets.dart';
import '../utils/pixel_animation_params.dart';

class WaveAnimationParams extends PixelAnimationParams {
  final Duration duration;
  final Curve curve;
  final bool loop, reverse;
  final double phaseOffset, amplitude, frequency;
  final Axis direction;

  const WaveAnimationParams({
    this.duration = const Duration(seconds: 2),
    this.curve = Curves.linear,
    this.loop = true,
    this.reverse = false,
    this.phaseOffset = 0,
    this.amplitude = 4,
    this.frequency = 1,
    this.direction = Axis.vertical,
  });
}

class WaveAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Curve curve;
  final bool loop, reverse;
  final double phaseOffset, amplitude, frequency;
  final Axis direction;

  const WaveAnimation({
    super.key,
    required this.child,
    this.duration = const Duration(seconds: 2),
    this.curve = Curves.linear,
    this.loop = true,
    this.reverse = false,
    this.phaseOffset = 0,
    this.amplitude = 4,
    this.frequency = 1,
    this.direction = Axis.vertical,
  }) : assert(duration > Duration.zero);

  @override
  State<WaveAnimation> createState() => _WaveAnimationState();
}

class _WaveAnimationState extends State<WaveAnimation>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _controller;
  bool _allowed = false;
  bool _foreground = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _foreground =
        WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _allowed =
        TickerMode.valuesOf(context).enabled &&
        !(MediaQuery.maybeOf(context)?.disableAnimations ?? false);
    _sync();
  }

  @override
  void didUpdateWidget(WaveAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    _controller.duration = widget.duration;
    if (oldWidget.loop != widget.loop ||
        oldWidget.reverse != widget.reverse ||
        oldWidget.duration != widget.duration) {
      _controller.stop();
    }
    _sync();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _sync();
  }

  void _sync() {
    if (!_allowed || !_foreground) {
      _controller.stop();
      return;
    }
    if (_controller.isAnimating) return;
    if (widget.loop) {
      _controller.repeat(reverse: widget.reverse);
    } else if (!_controller.isCompleted) {
      _controller.forward();
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    child: widget.child,
    builder: (context, child) {
      final value = _allowed
          ? math.sin(
                  (widget.curve.transform(_controller.value) *
                              widget.frequency +
                          widget.phaseOffset) *
                      2 *
                      math.pi,
                ) *
                widget.amplitude
          : 0.0;
      return Transform.translate(
        offset: widget.direction == Axis.horizontal
            ? Offset(value, 0)
            : Offset(0, value),
        child: child,
      );
    },
  );

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }
}
