import 'package:flutter/material.dart';

/// Global PixelTheme for consistent styling across widgets and effects.
/// Wrap your root widget with PixelTheme to customize accent color, scale,
/// or shader usage.
/// 
class PixelTheme extends InheritedWidget {
  final Color accentColor;
  final double pixelScale;
  final bool enableShaders;

  const PixelTheme({
    super.key,
    required Widget child,
    this.accentColor = Colors.cyan,
    this.pixelScale = 1.0,
    this.enableShaders = true,
  }) : super(child: child);

  static PixelTheme of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<PixelTheme>() ?? const PixelTheme(child: SizedBox.shrink());
  }

  @override
  bool updateShouldNotify(PixelTheme oldWidget) {
    return accentColor != oldWidget.accentColor ||
        pixelScale != oldWidget.pixelScale ||
        enableShaders != oldWidget.enableShaders;
  }
}
