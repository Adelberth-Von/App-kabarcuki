import 'package:flutter/material.dart';
import 'model.dart';

class Palette {
  final bool dark, together;
  const Palette(this.dark, this.together);
  Color hex(int value) => Color(0xFF000000 | value);
  Color get bg => hex(dark
      ? (together ? 0x211A24 : 0x161B26)
      : (together ? 0xFFF5F7 : 0xF7F7FC));
  Color get card => hex(dark ? (together ? 0x312532 : 0x232A3B) : 0xFFFFFF);
  Color get ink => hex(dark ? 0xF6F3FC : (together ? 0x4C3044 : 0x292D45));
  Color get muted => hex(dark ? 0xC1BCCD : (together ? 0x795C71 : 0x666B84));
  Color get accent => hex(dark
      ? (together ? 0xF5B1CA : 0xC2B8FF)
      : (together ? 0xAF4B76 : 0x6552BC));
  Color get tint => hex(dark
      ? (together ? 0x4C3347 : 0x383455)
      : (together ? 0xF8DFE9 : 0xEBE7FC));
  Color get border => hex(dark
      ? (together ? 0x493346 : 0x3B4256)
      : (together ? 0xF0E0E7 : 0xE9E9F3));
  Color get green => hex(dark ? 0xBDDCC0 : 0x397254);
}

class PixelSky extends StatelessWidget {
  final bool together;
  final DateTime? at;
  const PixelSky({super.key, this.together = false, this.at});
  @override
  Widget build(BuildContext context) => CustomPaint(
      painter: _SkyPainter(together, dayPhase(at ?? DateTime.now())),
      size: const Size(420, 112));
}

class _SkyPainter extends CustomPainter {
  final bool together;
  final int phase;
  _SkyPainter(this.together, this.phase);
  @override
  void paint(Canvas c, Size size) {
    final sky = [0xDEEAE7, 0xDCECF7, 0xF8D4C1, 0x293451][phase];
    final paint = Paint()..isAntiAlias = false;
    c.drawColor(Color(0xFF000000 | sky), BlendMode.src);
    final u = (size.width / 112).clamp(0.0, size.height / 38);
    c.save();
    c.translate((size.width - 112 * u) / 2, (size.height - 38 * u) / 2);
    c.scale(u, u);
    void r(int x, int y, int w, int h, int color) {
      paint.color = Color(0xFF000000 | color);
      c.drawRect(
          Rect.fromLTWH(x.toDouble(), y.toDouble(), w.toDouble(), h.toDouble()),
          paint);
    }

    if (phase == 3) {
      r(84, 5, 7, 7, 0xFFE5AA);
      r(87, 4, 5, 6, sky);
      for (final x in [9, 25, 47, 67, 102]) {
        r(x, 4 + x % 9, 1, 3, 0xE2D7BB);
        r(x - 1, 5 + x % 9, 3, 1, 0xE2D7BB);
      }
    } else {
      r(83, phase == 2 ? 16 : 6, 8, 8, 0xEBA669);
      r(85, phase == 2 ? 14 : 4, 4, 12, 0xF6C97E);
      r(13, 9, 16, 2, 0xFFFAE9);
      r(16, 7, 8, 2, 0xFFFAE9);
      r(61, 12, 12, 2, 0xFFFAE9);
    }
    r(
        0,
        31,
        112,
        7,
        phase == 3
            ? 0x40584E
            : together
                ? 0xB6BEA0
                : 0xAAC4A8);
    r(0, 30, 112, 1, phase == 3 ? 0x6D8670 : 0x8DA98E);
    final roof = together ? 0xA16B83 : 0x7980A5;
    r(16, 19, 21, 12, 0xE6CCAC);
    r(13, 17, 27, 3, roof);
    r(17, 14, 19, 3, roof);
    r(21, 11, 11, 3, roof);
    r(20, 22, 5, 5, 0xFFE7A0);
    r(29, 23, 4, 8, 0x58665A);
    r(91, 24, 2, 8, 0x817462);
    r(87, 17, 10, 8, phase == 3 ? 0x657B70 : 0x7D9D7C);
    r(89, 14, 6, 4, phase == 3 ? 0x657B70 : 0x7D9D7C);
    void person(int x, int shirt) {
      r(x, 21, 5, 2, 0x4E4550);
      r(x, 23, 5, 4, 0xEDC8AE);
      r(x - 1, 27, 7, 4, shirt);
      r(x, 31, 2, 3, 0x4E4550);
      r(x + 3, 31, 2, 3, 0x4E4550);
    }

    person(53, together ? 0xA76B8B : 0x7980A5);
    if (together) {
      person(67, 0x9683AD);
      r(61, 14, 2, 2, 0xCA779A);
      r(64, 14, 2, 2, 0xCA779A);
      r(61, 16, 5, 1, 0xCA779A);
      r(62, 17, 3, 1, 0xCA779A);
      r(63, 18, 1, 1, 0xCA779A);
      r(60, 28, 7, 2, 0xEDC8AE);
    }
    r(45, 34, 32, 1, phase == 3 ? 0x68756B : 0xDADEC2);
    for (final x in [7, 42, 81, 103]) {
      r(x, 30, 1, 3, 0x698E71);
      r(x - 1, 28, 3, 2, together ? 0xECAAC0 : 0xF5DC96);
    }
    c.restore();
  }

  @override
  bool shouldRepaint(_SkyPainter old) =>
      together != old.together || phase != old.phase;
}

class PixelIcon extends StatelessWidget {
  final String kind;
  final double size;
  const PixelIcon(this.kind, {super.key, this.size = 36});
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
      child: CustomPaint(size: Size.square(size), painter: _IconPainter(kind)));
}

class _IconPainter extends CustomPainter {
  final String kind;
  _IconPainter(this.kind);
  @override
  void paint(Canvas c, Size size) {
    c.scale(size.width / 24, size.height / 24);
    final p = Paint()..isAntiAlias = false;
    void r(int x, int y, int w, int h, int color) {
      p.color = Color(0xFF000000 | color);
      c.drawRect(
          Rect.fromLTWH(x.toDouble(), y.toDouble(), w.toDouble(), h.toDouble()),
          p);
    }

    if (kind == 'brand') {
      r(3, 4, 18, 14, 0x7463C3);
      r(1, 6, 22, 10, 0x7463C3);
      r(5, 18, 4, 3, 0x7463C3);
      r(5, 21, 2, 2, 0x7463C3);
      r(5, 7, 14, 8, 0xF8F3EC);
      r(7, 10, 2, 2, 0x7463C3);
      r(11, 10, 2, 2, 0x7463C3);
      r(15, 10, 2, 2, 0xCE7C9C);
    } else if (kind == 'home') {
      r(5, 12, 14, 10, 0xDDBE9D);
      r(3, 10, 18, 3, 0x7B7BAC);
      r(5, 8, 14, 2, 0x7B7BAC);
      r(7, 6, 10, 2, 0x7B7BAC);
      r(9, 4, 6, 2, 0x7B7BAC);
      r(8, 14, 3, 3, 0xFFF3C6);
      r(13, 16, 3, 6, 0x756A89);
    } else if (kind == 'meal') {
      r(3, 12, 18, 3, 0x777098);
      r(5, 15, 14, 4, 0x777098);
      r(8, 19, 8, 2, 0x777098);
      r(5, 9, 14, 3, 0xF3DDAF);
      r(8, 7, 8, 2, 0xF3DDAF);
      r(9, 3, 1, 3, 0xBDADCA);
      r(13, 2, 1, 3, 0xBDADCA);
      r(16, 8, 3, 3, 0x94AD8B);
    } else {
      r(10, 2, 6, 3, 0x655775);
      r(11, 5, 5, 5, 0xE4B691);
      r(9, 10, 7, 8, 0x8881B2);
      r(7, 11, 2, 6, 0xBDB09E);
      r(10, 18, 2, 5, 0x655775);
      r(14, 18, 2, 5, 0x655775);
      r(9, 22, 3, 1, 0x655775);
      r(14, 22, 4, 1, 0x655775);
    }
  }

  @override
  bool shouldRepaint(_IconPainter old) => kind != old.kind;
}
