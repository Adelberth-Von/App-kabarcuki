import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:pixelify_flutter/src/utils/pixel_effect_params.dart';
import 'package:pixelify_flutter/src/utils/shader_loader.dart';


class BloomEffect extends StatefulWidget {
  final Widget child;
  final double intensity;
  final double threshold;
  final Color glowColor;

  const BloomEffect({
    required this.child,
    this.intensity = 4.0,
    this.threshold = 0.5,
    this.glowColor = Colors.white,
    Key? key,
  }) : super(key: key);

  @override
  _BloomEffectState createState() => _BloomEffectState();
}

class _BloomEffectState extends State<BloomEffect> {
  ui.FragmentShader? shader;
  bool loadFailed = false;

  @override
  void initState() {
    super.initState();
    _loadShader();
  }

  Future<void> _loadShader() async {
    try {
      final program = await ShaderLoader.loadProgram('shaders/bloom.frag');
      setState(() {
        shader = program?.fragmentShader();
      });
    } catch (e) {
      setState(() {
        loadFailed = true;
      });
      debugPrint('Shader load failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loadFailed || shader == null) {
      return widget.child; // fallback if shader not loaded
    }

    return ShaderMask(
      shaderCallback: (bounds) {
        shader!
          ..setFloat(0, widget.intensity)
          ..setFloat(1, widget.threshold)
          ..setFloat(2, widget.glowColor.red / 255)
          ..setFloat(3, widget.glowColor.green / 255)
          ..setFloat(4, widget.glowColor.blue / 255)
          ..setFloat(5, widget.glowColor.opacity);
        // Return the FragmentShader instance directly (no createShader call)
        return shader!;
      },
      blendMode: BlendMode.plus,
      child: widget.child,
    );
  }
}


/// Params class for consistency with your project structure
class BloomEffectParams extends PixelEffectParams {
  final double intensity;
  final double threshold;
  final Color glowColor;

  const BloomEffectParams({
    this.intensity = 4.0,
    this.threshold = 0.5,
    this.glowColor = Colors.white,
  });
}
