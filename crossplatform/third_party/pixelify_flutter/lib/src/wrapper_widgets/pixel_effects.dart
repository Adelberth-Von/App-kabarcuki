import 'package:flutter/material.dart';
import 'package:pixelify_flutter/src/effects/noise_effect.dart';
import 'package:pixelify_flutter/src/utils/pixel_effect_params.dart';
import '../effects/pixelate_effect.dart';
import '../effects/scanline_effect.dart';
import '../effects/bloom_effect.dart';
import '../effects/glitch_effect.dart';
import 'package:flutter/widgets.dart';


/// Defines the available effect styles
enum PixelEffectStyle {
  pixelate,
  scanline,
  bloom,
  glitch,
  noise
}

/// Wrapper widget to apply pixel-art style effects
class PixelEffects extends StatelessWidget {
  final Widget? child;
  final PixelEffectStyle effect;
  final PixelEffectParams? params;

  const PixelEffects({
    super.key,
    required this.child,
    required this.effect,
    this.params,
  });

  @override
  Widget build(BuildContext context) {
    switch (effect) {

      //Pixalate
      case PixelEffectStyle.pixelate:
        final c = (params as PixelateEffectParams?) ?? const PixelateEffectParams();
        return PixelateEffect(pixelSize: c.pixelSize, pixelColor: c.pixelColor, intensity: c.intensity, softEdges: c.softEdges, region: c.region, animationDuration: c.animationDuration,child: child!,);

      //Scanline
      case PixelEffectStyle.scanline:
        final c = (params as ScanlineEffectParams?) ?? const ScanlineEffectParams();
        return ScanlineEffect(thickness: c.thickness, spacing: c.spacing, scanlineColor: c.scanlineColor, animate: c.animate, animationSpeed: c.animationSpeed, curvatureAmount: c.curvatureAmount, glowIntensity: c.glowIntensity, colorBleedAmount: c.colorBleedAmount, noiseAmount: c.noiseAmount, contrast: c.contrast, brightness: c.brightness, child: child!);

      //Bloom
      case PixelEffectStyle.bloom:
        final c = (params as BloomEffectParams?) ?? const BloomEffectParams();
        return BloomEffect(intensity: c.intensity, threshold: c.threshold, glowColor:c.glowColor, child: child!);

      //Noise
      case PixelEffectStyle.noise:
        final c = (params as NoiseEffectParams?) ?? const NoiseEffectParams();
        return NoiseEffect(intensity: c.intensity, density: c.density, dotSize: c.dotSize, animationSpeed: c.animationSpeed, color: c.color, animate:c.animate, blendMode: c.blendMode, region: c.region,);

      //Glitch
      case PixelEffectStyle.glitch:
        final c = (params as GlitchEffectParams?) ?? const GlitchEffectParams();
        return GlitchEffect(intensity: c.intensity, frequency: c.frequency, glitchColors: c.glitchColors, enableNoise: c.enableNoise, enableScanLines: c.enableScanLines, scanLineOpacity: c.scanLineOpacity, noiseIntensity: c.noiseIntensity, child: child!);
    }
  }
}




