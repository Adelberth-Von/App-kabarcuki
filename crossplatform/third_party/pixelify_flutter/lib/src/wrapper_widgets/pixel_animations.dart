import 'package:flutter/widgets.dart';
import 'package:pixelify_flutter/src/animations/fade_animation.dart';
import 'package:pixelify_flutter/src/animations/flicker_animation.dart';
import 'package:pixelify_flutter/src/animations/jitter_animation.dart';
import 'package:pixelify_flutter/src/animations/wave_animation.dart';
import 'package:pixelify_flutter/src/utils/pixel_animation_params.dart';

enum PixelAnimationStyle{
  fade,
  flicker,
  jitter,
  wave
}

class PixelAnimations extends StatefulWidget {
  final Widget? child;
  final PixelAnimationStyle style;
  final PixelAnimationParams? params;

  const PixelAnimations({
    super.key,
    this.child,
    required this.style,
    this.params
    });

  @override
  State<PixelAnimations> createState() => _PixelAnimationsState();
}

class _PixelAnimationsState extends State<PixelAnimations> {
  @override
  Widget build(BuildContext context) {
    switch (widget.style) {

      //Fade
      case PixelAnimationStyle.fade:
        final c = (widget.params as FadeAnimationParams?) ?? const FadeAnimationParams();
        if (widget.child == null) {
          throw ArgumentError('child not found');
        }
        return FadeAnimation(duration: c.duration, curve: c.curve, loop: c.loop, reverse: c.reverse, delay: c.delay, beginOpacity: c.beginOpacity, endOpacity: c.endOpacity, onFadeComplete: c.onFadeComplete,child: widget.child!,);
      
      //Flicker
      case PixelAnimationStyle.flicker:
        final c = (widget.params as FlickerAnimationParams?) ?? const FlickerAnimationParams();
        if (widget.child == null) {
          throw ArgumentError('child not found');
        }
        return FlickerAnimation(duration: c.duration, loop: c.loop, reverse: c.reverse, delay: c.delay, minOpacity: c.minOpacity, maxOpacity: c.maxOpacity, randomness: c.randomness, curve: c.curve, colorShiftAmount: c.colorShiftAmount, phaseOffset: c.phaseOffset, onFlickerComplete: c.onFlickerComplete,child: widget.child!,);
      
      //Jitter
      case PixelAnimationStyle.jitter:
        final c = (widget.params as JitterAnimationParams?) ?? const JitterAnimationParams();
        if (widget.child == null) {
          throw ArgumentError('child not found');
        }
        return JitterAnimation(duration: c.duration, curve: c.curve, loop: c.loop, reverse: c.reverse, strengthX: c.strengthX, strengthY: c.strengthY, randomness: c.randomness, phaseOffset: c.phaseOffset, decay: c.decay, delay: c.delay,child: widget.child!,);
      
      //Wave
      case PixelAnimationStyle.wave:
        final c = (widget.params as WaveAnimationParams?) ?? const WaveAnimationParams();
        if (widget.child == null) {
          throw ArgumentError('child not found');
        }
        return WaveAnimation(duration: c.duration, curve: c.curve, loop: c.loop, reverse: c.reverse, phaseOffset: c.phaseOffset, amplitude: c.amplitude, frequency: c.frequency, direction: c.direction,child: widget.child!,);
      
    }
  }
}