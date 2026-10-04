import 'package:flutter/material.dart';

/// Simple palettes and nearest color mapping helper.
class Palette {
  final List<Color> colors;
  const Palette(this.colors);

  static final gameboy = Palette([Color(0xFF0F380F), Color(0xFF306230), Color(0xFF8BAC0F), Color(0xFF9BBC0F)]);

  Color nearest(Color c) {
    double best = double.infinity;
    Color nearest = colors.first;
    for (final col in colors) {
      final d = _distSq(c, col);
      if (d < best) { best = d; nearest = col; }
    }
    return nearest;
  }

  static double _distSq(Color a, Color b) {
    final dr = a.red - b.red;
    final dg = a.green - b.green;
    final db = a.blue - b.blue;
    return dr * dr + dg * dg + db * db.toDouble();
  }
}
