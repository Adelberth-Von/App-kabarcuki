import 'dart:async';
import 'dart:math' as math;
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

class PixelSky extends StatefulWidget {
  final bool together;
  final DateTime? at;
  final bool animate;
  final String action;
  const PixelSky({super.key, this.together = false, this.at, this.animate = false, this.action='idle'});
  @override
  State<PixelSky> createState() => PixelSkyState();
}

class PixelSkyState extends State<PixelSky> with WidgetsBindingObserver {
  static const frameInterval = Duration(milliseconds: 83);
  static const frameCount = 120;
  final _frames = ValueNotifier<int>(0);
  int get frame => _frames.value % frameCount;
  _Scene? _previous;
  Timer? _timer;
  ScrollPosition? _scroll;
  bool _visible = true, _checkScheduled = false, _allowed = false;
  bool _foreground = true;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _foreground = WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
  }
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final scroll = Scrollable.maybeOf(context)?.position;
    if (_scroll != scroll) {
      _scroll?.removeListener(_checkVisible);
      _scroll = scroll;
      _scroll?.addListener(_checkVisible);
    }
    _allowed = TickerMode.valuesOf(context).enabled && !MediaQuery.disableAnimationsOf(context)
        && (ModalRoute.isCurrentOf(context) ?? true);
    _checkVisible();
    _sync();
  }
  @override
  void didUpdateWidget(PixelSky oldWidget) {
    super.didUpdateWidget(oldWidget);
    if(oldWidget.action!=widget.action || oldWidget.together!=widget.together) {
      _previous = _Scene(oldWidget.together, dayPhase(oldWidget.at ?? DateTime.now()), oldWidget.action);
      _frames.value=0;
    }
    _sync();
  }
  void _checkVisible() {
    if (_checkScheduled) return;
    _checkScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkScheduled = false;
      if (!mounted) return;
      final box = context.findRenderObject();
      final viewport = Scrollable.maybeOf(context)?.context.findRenderObject();
      if (box is RenderBox && box.hasSize) {
        final bounds = box.localToGlobal(Offset.zero) & box.size;
        final view = viewport is RenderBox && viewport.hasSize
            ? viewport.localToGlobal(Offset.zero) & viewport.size
            : Offset.zero & MediaQuery.sizeOf(context);
        _visible = bounds.overlaps(view);
      }
      _sync();
    });
  }
  void _sync() {
    final run = widget.animate && _foreground && _allowed && _visible;
    if (!run) {
      _timer?.cancel();
      _timer = null;
    } else {
      // Twelve bounded canvas repaints per second; the page never rebuilds.
      _timer ??= Timer.periodic(frameInterval, (_) {
        _frames.value++;
      });
    }
  }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _sync();
  }
  @override
  void dispose() {
    _timer?.cancel();
    _scroll?.removeListener(_checkVisible);
    WidgetsBinding.instance.removeObserver(this);
    _frames.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) => RepaintBoundary(child: CustomPaint(
      painter: _SkyPainter(_Scene(widget.together,
          dayPhase(widget.at ?? DateTime.now()), widget.action), _frames,
          previous: widget.animate && _allowed && _foreground ? _previous : null),
      size: const Size(420, 168)));
}

class _Scene {
  final bool together;
  final int phase;
  final String action;
  const _Scene(this.together, this.phase, this.action);
}

class _SkyPainter extends CustomPainter {
  final _Scene scene;
  final _Scene? previous;
  final ValueNotifier<int> frames;
  _SkyPainter(this.scene, this.frames, {this.previous}) : super(repaint: frames);
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    final blend = previous != null && frames.value < 8 ? frames.value / 8 : 1.0;
    if (blend < 1) {
      _World(canvas, size, previous!, frames.value).draw();
      canvas.saveLayer(Offset.zero & size, Paint()..color = Colors.white.withValues(alpha: blend));
      _World(canvas, size, scene, frames.value).draw();
      canvas.restore();
    } else {
      _World(canvas, size, scene, frames.value).draw();
    }
    canvas.restore();
  }
  @override
  bool shouldRepaint(_SkyPainter old) => scene.together != old.scene.together ||
      scene.phase != old.scene.phase || scene.action != old.scene.action || previous != old.previous;
}

// Each scene shares one hand-drawn 160 x 64 world. All movement stays on the
// integer pixel grid, with slower character poses over a smooth ambient cycle.
class _World {
  final Canvas c;
  final Size size;
  final _Scene scene;
  final int tick;
  final Paint p = Paint()..isAntiAlias = false;
  _World(this.c, this.size, this.scene, this.tick);
  int get frame => tick % PixelSkyState.frameCount;
  double get cycle => frame * math.pi * 2 / PixelSkyState.frameCount;
  int wave(double offset, int amount) => (math.sin(cycle + offset) * amount).round();
  int get phase => scene.phase;
  bool get night => phase == 3;
  bool get pair => scene.together;
  int get sky => [0xB7D7D4, 0xAAD6E3, 0xC799B8, 0x172A45][phase];
  int get horizon => [0xF7DDB5, 0xE5F1DA, 0xF6BD94, 0x385275][phase];
  int get leaf => [0x6C9F85, 0x65A17A, 0x926D81, 0x355E60][phase];
  int get leafLight => [0xA6C79B, 0xA7CE8A, 0xC99897, 0x537875][phase];
  int get ground => [0xA7BA91, 0xA3BD85, 0xB6988D, 0x486565][phase];
  int get accent => pair ? 0xC7829E : 0x6B8DA9;
  int get wood => night ? 0x735B6B : 0x9D7680;
  int get wall => [0xF5DDBE, 0xF6E5C9, 0xECC8AD, 0xC5ACB1][phase];
  int get window => night ? 0xFFE2A3 : 0xF8ECD0;
  void r(num x, num y, num w, num h, int color) {
    p.color = Color(0xFF000000 | color);
    c.drawRect(Rect.fromLTWH(x.toDouble(), y.toDouble(), w.toDouble(), h.toDouble()), p);
  }
  void draw() {
    c.drawColor(Color(0xFF000000 | sky), BlendMode.src);
    final u = math.max(size.width / 160, size.height / 64);
    c.save();
    c.translate((size.width - 160 * u) / 2, size.height - 64 * u);
    c.scale(u, u);
    // Eight broad colour bands keep the sky soft without blurring pixel edges.
    for (var i = 0; i < 8; i++) {
      r(0, i * 5, 160, 5, Color.lerp(Color(0xFF000000 | sky),
          Color(0xFF000000 | horizon), i / 9)!.toARGB32() & 0xFFFFFF);
    }
    celestial();
    cloud(9 + wave(0, 3), 12, night ? 0x52617C : 0xFFF1DA);
    cloud(99 + wave(2, 2), 8, night ? 0x465C78 : 0xFBEEDC);
    // Distant city lights and two stepped ridgelines give the world depth.
    final far = [0xA3BAB2, 0xA2C5BA, 0xB597AD, 0x405777][phase];
    for (var i = 0; i < 14; i++) {
      final x = i * 13 - 4, h = 4 + (i * 7) % 9;
      r(x, 40 - h, 9, h, far);
      if (night && i % 2 == 0) r(x + 2, 35 - h, 1, 2, 0xDCC598);
    }
    for (var i = 0; i < 16; i++) {
      r(i * 10, 36 + (i * 3) % 7, 10, 14, night ? 0x355460 : 0x88AC99);
      r(i * 10, 41 + (i * 5) % 4, 10, 11, leaf);
    }
    r(0, 47, 160, 17, ground);
    r(0, 49, 160, 2, night ? 0x698077 : 0xCDD0A1);
    r(0, 57, 160, 7, night ? 0x345657 : 0x8EA983);
    for (var i = 0; i < 20; i++) {
      r(i * 9 + 1, 59 + i % 4, 3, 1, night ? 0x4C6C65 : 0xB8C49A);
    }
    tree(5, 28, false); tree(143, 30, true);
    switch (scene.action) {
      case 'home': room(false); break;
      case 'meal': room(true); break;
      default: garden();
    }
    foreground();
    c.restore();
  }
  void cloud(int x, int y, int color) {
    r(x, y + 3, 25, 2, color); r(x + 4, y, 10, 3, color);
    r(x + 13, y + 1, 8, 2, color);
  }
  void celestial() {
    if (night) {
      r(124, 5, 10, 10, 0x67768A); r(123, 4, 10, 10, 0xFFE8B6);
      r(126, 2, 9, 10, sky); r(123, 8, 2, 4, 0xFFF4D4);
      for (var i = 0; i < 24; i++) {
        final x = 6 + (i * 37) % 149, y = 3 + (i * 11) % 22;
        final bright = (frame ~/ 8 + i * 2) % 7 < 3;
        r(x, y, 1, 1, bright ? 0xF8E7C6 : 0x778FA7);
        if (bright && i % 5 == 0) { r(x - 1, y, 3, 1, 0xB4C7CC); r(x, y - 1, 1, 3, 0xB4C7CC); }
      }
      // A shooting star appears briefly, entering and leaving the visible sky.
      if (frame >= 76 && frame < 88) {
        final x = 24 + (frame - 76) * 5;
        r(x, 8 + (frame - 76) ~/ 3, 3, 1, 0xF9EAC8);
        r(x - 5, 7 + (frame - 76) ~/ 3, 5, 1, 0x8EACC0);
      }
    } else {
      final y = phase == 2 ? 26 : phase == 0 ? 20 : 7;
      r(121, y - 2, 16, 16, phase == 2 ? 0xEBAB9B : 0xF4DFB5);
      r(124, y, 10, 12, 0xFFE4A4); r(122, y + 3, 14, 6, 0xFFEAB5);
      if (phase == 0) {
        final x = frame * 2 - 16;
        bird(x, 12 + wave(0, 2)); bird(x - 12, 15 + wave(1, 2));
      }
    }
  }
  void bird(int x, int y) {
    final up = frame ~/ 3 % 2;
    r(x, y, 1, 1, 0x63787E); r(x - 2, y - up, 2, 1, 0x63787E); r(x + 1, y - up, 2, 1, 0x63787E);
  }
  void tree(int x, int y, bool blossom) {
    r(x + 7, y + 8, 4, 22, night ? 0x6C6070 : 0x977A78);
    r(x + 4, y + 14, 5, 2, wood); r(x + 10, y + 11, 4, 2, wood);
    final base = blossom && pair ? (night ? 0x88657F : 0xCC9AAC) : leaf;
    final top = blossom && pair ? (night ? 0xAF8A9D : 0xF0BAC5) : leafLight;
    r(x + 1, y + 3, 16, 11, base); r(x - 1, y + 6, 20, 5, base);
    r(x + 4, y, 10, 4, top); r(x + 1, y + 4, 5, 4, top);
    r(x + 12, y + 3, 4, 3, top); r(x + 8, y + 8, 3, 2, top);
    r(x + 3, y + 10, 3, 2, night ? 0x3C5761 : 0x759782);
  }
  void cottage(int x, int y) {
    r(x, y + 9, 33, 23, 0x6E6475); r(x + 1, y + 10, 31, 21, wall);
    for (var i = 0; i < 5; i++) r(x - 3 + i * 3, y + 8 - i * 2, 39 - i * 6, 2, accent);
    r(x + 6, y + 3, 22, 1, pair ? 0xEDB4BF : 0xACC2CC);
    r(x + 25, y - 1, 4, 7, wood); r(x + 24, y - 2, 6, 2, 0xC3A39B);
    r(x + 5, y + 14, 11, 10, wood); r(x + 6, y + 15, 9, 8, window);
    r(x + 10, y + 15, 1, 8, wall); r(x + 6, y + 19, 9, 1, wall);
    r(x + 21, y + 17, 8, 14, wood); r(x + 22, y + 18, 6, 12, 0x748E8D);
    r(x + 26, y + 24, 1, 1, 0xFFE4AB);
    r(x - 2, y + 31, 37, 2, 0xB3978B);
    planter(x + 2, y + 25, true); r(x + 19, y + 30, 12, 1, 0xD9BFA9);
    if (night) { r(x + 3, y + 32, 16, 1, 0xCCBA91); r(x + 6, y + 33, 9, 1, 0xAEA48A); }
  }
  void garden() {
    cottage(24, 20);
    // A winding path and fence make walking belong to the scene.
    r(57, 53, 69, 4, night ? 0x78888A : 0xE0D4B7);
    r(61, 57, 65, 3, night ? 0x657E80 : 0xC8C5A5);
    for (var i = 0; i < 6; i++) r(66 + i * 9, 54 + i % 2, 5, 1, night ? 0xA4A792 : 0xF4E7C5);
    for (var i = 0; i < 4; i++) { r(113 + i * 7, 42, 3, 12, 0xDFC6B0); r(115 + i * 7, 44, 2, 11, 0xB09A98); }
    r(113, 46, 24, 2, 0xC6ADA1); r(113, 50, 24, 2, 0xC6ADA1);
    r(132, 38, 2, 15, wood); r(127, 35, 12, 6, accent); r(128, 36, 10, 3, 0xE5C9B6);
    r(131, 37, 3, 1, 0x9E7B89);
    final walking = scene.action == 'outside';
    final x = walking ? 78 + wave(0, 14) : 84;
    person(x, 33, 0, walking ? 'walk' : 'wave');
    if (pair) { person(62, 33, 1, walking ? 'wave' : 'wave'); heart(74, 23 + wave(2, 1)); }
    if (walking) {
      final puff = frame ~/ 5 % 3;
      r(x - 7, 54, 3 + puff, 1, night ? 0x7D9290 : 0xD7D3B7);
    }
    // A tiny resident cat grounds the quiet idle world.
    r(108, 49, 8, 4, 0xE7CDA8); r(113, 46, 5, 5, 0xE7CDA8);
    r(113, 45, 1, 2, 0xAF8C87); r(117, 45, 1, 2, 0xAF8C87);
    r(116, 48, 1, 1, 0x695864); r(105, 48 + wave(1, 1), 4, 2, 0xE7CDA8);
  }
  void room(bool eating) {
    // A dollhouse cutaway is a different world from the outdoor path.
    r(38, 17, 88, 39, 0x766578); r(40, 19, 84, 36, wall);
    r(40, 19, 84, 2, 0xE3C0AF); r(40, 43, 84, 12, night ? 0xAD919B : 0xDABAA0);
    for (var i = 0; i < 6; i++) r(41, 44 + i * 2, 82, 1, night ? 0x937C91 : 0xC9A78F);
    for (var i = 0; i < 4; i++) r(35 + i * 8, 17 - i * 2, 94 - i * 16, 2, accent);
    r(43, 16, 76, 1, pair ? 0xE9ADB8 : 0x9DB7C7);
    // Light spills onto floor without an expensive glow shader.
    if (night) { r(63, 47, 33, 3, 0xEBD1B0); r(66, 50, 29, 2, 0xD5B8A4); }
    r(65, 24, 29, 18, wood); r(67, 26, 25, 13, sky);
    r(67, 32, 25, 7, horizon); r(67, 35, 9, 4, leaf); r(80, 34, 12, 5, leafLight);
    r(78, 25, 2, 16, wall); r(66, 31, 28, 2, wall);
    r(63, 23, 4, 19, pair ? 0xBF8C9F : 0x8AA5AD);
    r(91, 23, 4, 19, pair ? 0xBF8C9F : 0x8AA5AD);
    r(64, 23, 1, 18, 0xF1D1B7); r(93, 23, 1, 18, 0xF1D1B7);
    r(49, 49, 58, 6, pair ? 0xAE7F96 : 0x7D98A5);
    r(52, 50, 52, 1, pair ? 0xDAB0B4 : 0xB0C0BE); r(52, 53, 52, 1, pair ? 0xDAB0B4 : 0xB0C0BE);
    if (eating) dining(); else living();
    planter(115, 43, false); planter(42, 45, true);
    r(47, 22, 9, 9, wood); r(48, 23, 7, 7, 0xFAE8C8);
    r(50, 25, 3, 3, 0xDBA886); r(52, 24, 2, 2, leafLight);
    if (pair) heart(77, 19 + wave(1, 1));
  }
  void living() {
    r(50, 40, 57, 12, wood); r(51, 39, 55, 10, accent);
    r(49, 43, 5, 9, accent); r(104, 43, 5, 9, accent);
    r(55, 44, 48, 5, pair ? 0xE0AAB3 : 0xA8BDC1);
    r(54, 49, 50, 2, pair ? 0xAA758F : 0x66849A);
    r(55, 51, 3, 3, wood); r(102, 51, 3, 3, wood);
    r(53, 40, 9, 7, window); r(96, 40, 8, 7, 0xDBC2B3);
    person(pair ? 66 : 76, 28, 0, 'read');
    if (pair) person(87, 28, 1, 'read');
    // Bookshelf and a shaded lamp add room-specific quiet motion.
    r(108, 24, 10, 16, wood); r(109, 25, 8, 14, 0xDCC1AC);
    for (var i = 0; i < 4; i++) { r(110 + i * 2, 26 + i % 2, 1, 6 - i % 2, i % 2 == 0 ? accent : 0x8FAD99); }
    r(108, 33, 10, 1, wood); r(110, 36, 6, 1, 0xBD8E8F);
    r(59, 27, 1, 16, wood); r(54, 27, 11, 3, window); r(56, 24, 7, 3, 0xF3CD9F);
    r(55, 42, 9, 2, wood);
    r(74, 51, 12, 3, 0xB08C80); r(75, 50, 10, 1, 0xE1C9AD);
    r(82, 48, 3, 3, window); r(85, 49, 1, 1, window);
    steam(82, 45, 0);
  }
  void dining() {
    r(43, 32, 17, 15, wood); r(44, 32, 15, 3, 0xEFE0BF);
    r(45, 36, 13, 10, accent); r(47, 37, 9, 6, 0x526879);
    r(48, 38, 7, 1, 0xF3D7A3); r(50, 44, 3, 1, 0xD9C6B0);
    r(45, 29, 10, 2, 0x8D7078); r(47, 27, 6, 2, 0xE0C8A7);
    r(115, 20, 1, 11, wood); r(111, 30, 9, 3, window); r(113, 28, 5, 2, 0xE7BF97);
    person(pair ? 68 : 78, 29, 0, 'eat');
    if (pair) person(91, 29, 1, 'eat');
    r(64, 45, 46, 4, wood); r(63, 44, 48, 2, 0xE4C4A0);
    r(67, 49, 3, 6, wood); r(104, 49, 3, 6, wood);
    bowl(pair ? 72 : 82, 41, 0);
    if (pair) bowl(95, 41, 3);
    r(63, 41, 4, 3, 0xF6E4C3); r(64, 40, 2, 1, 0xC3A38E);
    r(104, 40, 4, 4, accent); r(105, 38, 2, 2, 0x8EAA92);
    r(83, 22, 1, 7, wood); r(79, 28, 9, 2, 0xF8D3A0);
  }
  void bowl(int x, int y, int offset) {
    r(x, y, 9, 2, 0xF9EBCB); r(x + 1, y + 2, 7, 2, pair ? 0xB8879E : 0x7595A5);
    r(x + 3, y + 4, 3, 1, wood); r(x + 2, y - 1, 5, 1, 0xB9C28D);
    r(x + 5, y - 2, 2, 2, 0xDC9A75); steam(x + 3, y - 4, offset);
  }
  void steam(int x, int y, int offset) {
    final a = (frame ~/ 3 + offset) % 10;
    r(x + wave(offset.toDouble(), 1), y - a ~/ 3, 1, 2, night ? 0xE0D4C3 : 0xFFF2DA);
    r(x + 3 - wave(offset + 1.0, 1), y - 3 - a ~/ 4, 1, 2, night ? 0xC8C7B9 : 0xEEDBC7);
  }
  void planter(int x, int y, bool flowers) {
    r(x, y, 7, 4, night ? 0xA17B88 : 0xC09585); r(x + 1, y + 4, 5, 1, wood);
    r(x + 3, y - 7, 1, 7, leaf); r(x, y - 5, 3, 3, leafLight); r(x + 4, y - 8, 3, 3, leafLight);
    if (flowers) { r(x - 1, y - 5 + wave(0, 1), 3, 2, pair ? 0xEAB4BD : 0xF4D9A5); r(x + 4, y - 9, 3, 2, pair ? 0xF7D0CC : 0xFAE6B9); }
  }
  void heart(int x, int y) {
    r(x, y, 2, 2, 0xF0AEBB); r(x + 3, y, 2, 2, 0xF0AEBB);
    r(x, y + 2, 5, 1, 0xD78DAB); r(x + 1, y + 3, 3, 1, 0xD78DAB); r(x + 2, y + 4, 1, 1, 0xB97296);
  }
  void person(int x, int y, int identity, String pose) {
    final walk = pose == 'walk', sitting = pose == 'read' || pose == 'eat';
    final step = frame ~/ 3 % 4;
    final bob = walk && step % 2 == 1 ? 1 : 0;
    y -= bob;
    final hair = identity == 0 ? 0x514959 : 0x71546A;
    final skin = identity == 0 ? 0xEDBE9D : 0xE9B9A1;
    final shirt = identity == 0 ? accent : 0x9C9DC2;
    // Outlined hair, cheek highlights and a two-frame blink keep faces legible.
    r(x + 1, y, 7, 2, hair); r(x, y + 2, 9, 5, hair);
    r(x + 1, y + 3, 7, 6, skin); r(x + 2, y + 2, 3, 2, hair);
    r(x - 1, y + 5, 2, 2, skin); r(x + 8, y + 5, 1, 2, skin);
    if (identity == 1) { r(x - 1, y + 3, 2, 7, hair); r(x + 7, y + 2, 2, 8, hair); }
    final blink = (frame + identity * 11) % 120 > 112;
    r(x + 2, y + 6, 1, blink ? 1 : 2, hair); r(x + 6, y + 6, 1, blink ? 1 : 2, hair);
    r(x + 1, y + 8, 2, 1, 0xDB9B94); r(x + 6, y + 8, 2, 1, 0xDB9B94);
    r(x + 4, y + 8, 1, 1, 0xAE7880);
    r(x + 3, y + 9, 3, 1, skin); r(x, y + 10, 9, 8, shirt);
    r(x + 1, y + 10, 7, 1, identity == 0 ? 0xCBD7D2 : 0xD5C8D3);
    r(x + 4, y + 12, 1, 4, identity == 0 ? 0xABC0C1 : 0xC4BDD2);
    r(x, y + 17, 9, 1, 0x6F708A);
    if (walk) {
      r(x - 3, y + 10, 3, 7, 0xBB8C7C); r(x - 2, y + 9, 2, 2, 0xDBC3A1);
      r(x + 9, y + 12 + step % 2, 2, 5, shirt); r(x + 9, y + 17 + step % 2, 2, 1, skin);
      final leg = [0, 1, 0, -1][step];
      r(x + 1 + leg, y + 18, 3, 4, hair); r(x + 6 - leg, y + 18, 3, 4, hair);
      r(x + leg, y + 21, 4, 1, 0xF1DDC3); r(x + 6 - leg, y + 21, 4, 1, 0xF1DDC3);
    } else if (sitting) {
      r(x, y + 18, 9, 2, hair); r(x + 1, y + 19, 3, 3, hair); r(x + 6, y + 19, 3, 3, hair);
      if (pose == 'read') {
        r(x - 1, y + 14, 11, 2, skin); r(x, y + 15, 5, 4, 0xF4E1BA);
        r(x + 5, y + 15, 5, 4, 0xDBB9AA); r(x + 5, y + 14, 1, 5, wood);
        r(x + 1, y + 16, 3, 1, 0xBBA297);
        if (frame ~/ 15 % 2 == 0) r(x + 6, y + 16, 3, 1, 0xFFF0CF);
      } else {
        final reach = wave(identity * 1.7, 2);
        r(x - 2, y + 12, 2, 6, shirt); r(x - 2, y + 17, 3, 1, skin);
        r(x + 8, y + 13 - reach, 3, 2, skin); r(x + 10, y + 10 - reach, 1, 4, 0xEEE5CC);
      }
    } else {
      r(x + 1, y + 18, 3, 4, hair); r(x + 6, y + 18, 3, 4, hair);
      r(x, y + 21, 4, 1, 0xF1DDC3); r(x + 6, y + 21, 4, 1, 0xF1DDC3);
      r(x - 2, y + 11, 2, 6, shirt); r(x - 2, y + 17, 2, 1, skin);
      final greeting = frame ~/ 8 % 3;
      r(x + 9, y + 9, 2, 6, shirt); r(x + 9 + greeting % 2, y + 6, 2, 4, skin);
    }
  }
  void foreground() {
    // Flowers, swaying blades and light motes provide foreground parallax.
    for (final x in [9, 18, 133, 143, 152]) {
      r(x, 53, 1, 6, leaf); r(x - 2, 56, 2, 1, leafLight);
      r(x + 1 + wave(x / 9, 1), 52, 2, 3, leafLight);
      if (x % 2 == 1) { r(x - 1, 52, 3, 2, pair ? 0xECB5BE : 0xEEDDAD); r(x, 53, 1, 1, 0xCD9C85); }
    }
    if (night) {
      for (var i = 0; i < 7; i++) {
        final x = 15 + i * 21 + wave(i.toDouble(), 2), y = 39 + i % 4 * 3 + wave(i + 1.0, 2);
        r(x, y, 1, 1, (frame ~/ 6 + i) % 4 < 2 ? 0xFAE5A8 : 0xA4BB9E);
      }
    } else if (phase == 1) {
      final x = 128 + wave(0, 6), y = 38 + wave(2, 3), wing = frame ~/ 2 % 2;
      r(x, y, 1, 3, 0x7B6B81); r(x - 2, y - wing, 2, 2 + wing, 0xE9BD91); r(x + 1, y - wing, 2, 2 + wing, 0xF1D4A9);
    } else if (phase == 2 || pair) {
      for (var i = 0; i < 4; i++) {
        final t = (frame + i * 29) % 120;
        r(19 + i * 39 + (t / 18).round(), -6 + t * 2 ~/ 3, 2, 1, pair ? 0xE6ADBD : 0xE5B099);
      }
    }
    r(0, 63, 160, 1, night ? 0x2A4A51 : 0x74937A);
  }
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
  static const _icons = <String, List<List<int>>>{
    'brand': [
      [9,4,13,12,0x846379],
      [10,3,12,10,0xDCA4B6],
      [12,5,8,6,0xF8DFCF],
      [17,13,3,3,0xDCA4B6],
      [2,7,16,12,0x354F68],
      [1,9,18,8,0x354F68],
      [3,8,14,9,0x75A8AD],
      [4,9,12,7,0xFAEDCF],
      [4,18,5,2,0x354F68],
      [4,20,3,2,0x354F68],
      [5,18,3,2,0x75A8AD],
      [7,12,2,2,0x628796],
      [11,12,2,2,0xBE849B],
      [11,5,1,2,0xFFF1DA],
      [20,2,1,2,0xC399A4],
      [19,3,3,1,0xC399A4],
    ],
    'home': [
      [3,13,18,9,0x62526A],
      [4,13,16,8,0xE5C5A3],
      [5,14,14,6,0xF2DEB7],
      [1,10,22,3,0x435D79],
      [3,8,18,2,0x435D79],
      [5,6,14,2,0x435D79],
      [7,4,10,2,0x435D79],
      [9,2,6,2,0x435D79],
      [4,9,16,1,0x77A5AE],
      [7,7,10,1,0x77A5AE],
      [10,5,4,1,0x77A5AE],
      [17,3,3,5,0xB58B8D],
      [16,2,5,1,0xDFBEA2],
      [6,14,5,5,0xA48283],
      [7,15,3,3,0xFAE7AA],
      [8,15,1,3,0xF6F2D5],
      [14,16,4,6,0x657F8A],
      [15,17,2,4,0x8DA6A3],
      [17,19,1,1,0xFFE2B0],
      [13,22,7,1,0xC1A18F],
      [2,20,4,3,0xB1868A],
      [2,18,3,2,0x8CAA85],
      [4,17,2,2,0xB4C78B],
    ],
    'meal': [
      [2,13,20,3,0x4D6079],
      [3,16,18,3,0x4D6079],
      [5,19,14,2,0x4D6079],
      [8,21,8,2,0x4D6079],
      [3,14,18,2,0xF8ECC8],
      [5,17,14,2,0x8FAFB5],
      [8,20,8,1,0x75A0AD],
      [4,11,16,2,0xDDB99B],
      [6,9,12,2,0xF8E3B2],
      [8,8,8,1,0xFFF2CB],
      [6,11,3,1,0xF7D490],
      [13,10,3,3,0xD48B72],
      [14,10,1,1,0xECAA75],
      [17,8,4,4,0x6C927B],
      [18,7,3,2,0xA8BE89],
      [9,3,1,3,0x8DA6AD],
      [10,1,1,2,0xBBC9C5],
      [13,2,1,3,0x8DA6AD],
      [14,5,1,2,0xBBC9C5],
      [2,22,4,1,0xDEC7A7],
      [19,22,3,1,0xDEC7A7],
    ],
    'outside': [
      [8,2,7,2,0x4F485D],
      [7,4,9,5,0x4F485D],
      [8,5,7,5,0xEDC3A1],
      [9,4,4,2,0x4F485D],
      [9,7,1,1,0x4F485D],
      [13,7,1,1,0x4F485D],
      [8,9,2,1,0xD69794],
      [13,9,2,1,0xD69794],
      [7,11,9,7,0x66939D],
      [8,11,7,1,0xC8DAD1],
      [11,13,1,4,0xA5BFC0],
      [4,11,3,6,0xAE8182],
      [5,10,2,2,0xE0C4A6],
      [16,12,2,5,0x66939D],
      [16,17,2,1,0xEDC3A1],
      [8,18,3,4,0x4F485D],
      [14,18,3,3,0x4F485D],
      [7,22,4,1,0xEBDAC0],
      [14,21,5,1,0xEBDAC0],
      [19,5,3,1,0xBA8D9F],
      [21,4,1,3,0xBA8D9F],
    ],
    'heart': [
      [4,6,6,3,0x70566D],
      [14,6,6,3,0x70566D],
      [2,9,20,5,0x70566D],
      [4,14,16,3,0x70566D],
      [7,17,10,3,0x70566D],
      [10,20,4,2,0x70566D],
      [5,8,5,2,0xE9B3BD],
      [14,8,5,2,0xE9B3BD],
      [4,10,16,4,0xD995AD],
      [6,14,12,3,0xD995AD],
      [9,17,6,2,0xBE7C9B],
      [6,9,2,3,0xFADED2],
    ],
    'history': [
      [5,3,14,19,0x536F83],
      [6,4,12,17,0xE8D4B5],
      [4,6,3,2,0xBD98A0],
      [4,11,3,2,0xBD98A0],
      [4,16,3,2,0xBD98A0],
      [9,6,6,1,0xB1A69B],
      [9,9,6,1,0xB1A69B],
      [9,12,6,1,0xB1A69B],
      [12,15,8,6,0x75A5A8],
      [14,14,4,8,0x75A5A8],
      [15,16,1,4,0xFCEAC8],
      [15,19,3,1,0xFCEAC8],
    ],
    'location': [
      [7,2,10,2,0x59667F],
      [4,4,16,9,0x59667F],
      [6,13,12,4,0x59667F],
      [8,17,8,3,0x59667F],
      [10,20,4,3,0x59667F],
      [7,4,10,2,0xB588A4],
      [6,6,12,6,0xD5A1B1],
      [8,12,8,4,0xB588A4],
      [10,16,4,3,0xB588A4],
      [9,6,6,6,0xF9E5C6],
      [11,8,2,2,0x8DA6AF],
      [6,6,2,3,0xEBC5C9],
    ],
  };
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 24, size.height / 24);
    final paint = Paint()..isAntiAlias = false;
    for (final pixel in _icons[kind] ?? _icons['outside']!) {
      paint.color = Color(0xFF000000 | pixel[4]);
      canvas.drawRect(Rect.fromLTWH(pixel[0].toDouble(), pixel[1].toDouble(),
          pixel[2].toDouble(), pixel[3].toDouble()), paint);
    }
    canvas.restore();
  }
  @override
  bool shouldRepaint(_IconPainter old) => kind != old.kind;
}
