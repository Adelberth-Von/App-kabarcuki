import 'dart:ui' as ui;
import 'package:flutter/services.dart';

/// ShaderLoader loads FragmentProgram safely and provides helpful errors.
class ShaderLoader {
  /// Attempt to load a FragmentProgram from asset path. If asset missing or
  /// platform doesn't support shaders, this throws — caller should handle.
  static Future<ui.FragmentProgram?> loadProgram(String asset) async {
    try {
      final program = await ui.FragmentProgram.fromAsset(asset);
      return program;
    } on MissingPluginException catch (e) {
      // Shader not supported on current platform/render backend.
      throw Exception('Shaders not supported: $e');
    } catch (e) {
      // Asset missing or compile error; propagate for caller to degrade gracefully.
      throw Exception('Failed to load shader $asset: $e');
    }
  }
}
