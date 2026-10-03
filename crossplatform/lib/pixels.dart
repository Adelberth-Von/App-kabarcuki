import 'dart:async';
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
  final _frames = ValueNotifier<int>(0);
  int get frame => _frames.value;
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
    if(oldWidget.action!=widget.action || oldWidget.together!=widget.together)_frames.value=0;
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
      // Four small canvas repaints/second. No ticker or whole-page rebuild.
      _timer ??= Timer.periodic(const Duration(milliseconds: 250), (_) {
        _frames.value = (_frames.value + 1) % 16;
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
      painter: _SkyPainter(widget.together,
          dayPhase(widget.at ?? DateTime.now()), _frames,widget.action),
      size: const Size(420, 112)));
}

class _SkyPainter extends CustomPainter {
  final bool together;
  final int phase;
  final ValueNotifier<int> frames;
  final String action;
  _SkyPainter(this.together, this.phase, this.frames,this.action) : super(repaint: frames);
  @override
  void paint(Canvas c, Size size) {
    final sky = [0xDEEAE7, 0xDCECF7, 0xF8D4C1, 0x293451][phase];
    final paint = Paint()..isAntiAlias = false;
    final frame = frames.value;
    final sway = frame ~/ 4 % 2;
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
        final color = (frame ~/ 4 + x) % 3 == 0 ? 0xA5AEC0 : 0xE2D7BB;
        r(x, 4 + x % 9, 1, 3, color);
        r(x - 1, 5 + x % 9, 3, 1, color);
      }
    } else {
      r(83, phase == 2 ? 16 : 6, 8, 8, 0xEBA669);
      r(85, phase == 2 ? 14 : 4, 4, 12, 0xF6C97E);
      r(13 + sway, 9, 16, 2, 0xFFFAE9);
      r(16 + sway, 7, 8, 2, 0xFFFAE9);
      r(61 - sway, 12, 12, 2, 0xFFFAE9);
    }
    // Time-of-day motion: morning birds, noon butterflies, dusk leaves,
    // and tiny fireflies at night. All share the same four-fps canvas timer.
    if(phase==0) {
      final x=43+frame;
      r(x,7+sway,2,1,0x7C8C91);r(x+3,7+sway,2,1,0x7C8C91);r(x+2,8,1,1,0x7C8C91);
    } else if(phase==1) {
      r(78+sway,24-frame%3,1,3,0xAF7399);r(76+sway,24-frame%3,2,2,0xE9B879);r(79+sway,24-frame%3,2,2,0xE9B879);
    } else if(phase==2) {
      r(95-frame%8,24+frame%6,2,1,0xD89D73);
    } else {
      r(43+frame%5,25-frame%3,1,1,frame%2==0?0xF9E9A4:0x687D75);
      r(82-frame%6,27-frame%4,1,1,frame%2==1?0xF9E9A4:0x687D75);
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
    if(action=='home') {r(29,23,4,8,0xF8DEA5);r(17,29,19,2,0xCFAF93);}
    r(91, 24, 2, 8, 0x817462);
    r(87, 17, 10, 8, phase == 3 ? 0x657B70 : 0x7D9D7C);
    r(89, 14, 6, 4, phase == 3 ? 0x657B70 : 0x7D9D7C);
    void person(int x, int shirt,{bool walking=false,bool eating=false,bool waving=false,bool resting=false}) {
      final bob=walking ? sway : 0;
      r(x, 21-bob, 5, 2, 0x4E4550);
      r(x, 23-bob, 5, 4, 0xEDC8AE);
      if (frame != 12) {
        r(x + 1, 25-bob, 1, 1, 0x4E4550);
        r(x + 3, 25-bob, 1, 1, 0x4E4550);
      }
      r(x - 1, 27-bob, 7, 4, shirt);
      if (waving || (action=='idle' && frame >= 6 && frame <= 9)) {
        r(x - 3, 25-sway, 2, 4, shirt);
        r(x - 3, 23-sway, 2, 2, 0xEDC8AE);
      }
      if(walking) {r(x-3,26-bob,3,5,0xBC967C);r(x-sway,31,2,3-sway,0x4E4550);r(x+3+sway,31,2,2+sway,0x4E4550);}
      else {r(x,31,resting?4:2,resting?2:3,0x4E4550);r(x+3,31,2,3,0x4E4550);}
      if(eating){r(x+5,frame%4<2?26:28,3,1,0xEDC8AE);r(x+7,frame%4<2?24:26,1,3,0xD5B785);}
      if(resting){r(x-1,28,4,3,0xF4DCB6);r(x+3,28,3,3,0xD1B3D7);}
    }
    final shirt=together?0xA76B8B:0x7980A5;
    if(action=='outside') {
      person(49+frame~/2,shirt,walking:true);
      if(together)person(38,0x9683AD,waving:true);
      r(76,30,5,1,0xE7DCC4);r(79,29,2,3,0xE7DCC4);
    } else if(action=='meal') {
      person(50,shirt,eating:true);if(together)person(68,0x9683AD,eating:true);
      r(46,31,together?30:20,2,0xB78C76);r(48,33,2,3,0x886C67);r(together?72:62,33,2,3,0x886C67);
      for(final x in together?[57,65]:[57]) {r(x,29,5,2,0xE6D7B5);r(x+1,28,3,1,0x8EA986);r(x+2+sway,25,1,2,0xF4EBDC);}
    } else if(action=='home') {
      r(47,29,together?30:16,6,together?0xBD91AA:0x98A0BF);
      person(52,shirt,resting:true);if(together)person(68,0x9683AD,waving:frame<8,resting:frame>=8);
      r(81,27,1,7,0x9E8470);r(78,25,7,2,phase==3?0xFFE5A3:0xE3CFAB);
    } else {
      person(53,shirt);if(together)person(67,0x9683AD);
    }
    if(together) {
      final x=action=='outside'?40:61,y=13-sway;
      r(x,y,2,2,0xCA779A);r(x+3,y,2,2,0xCA779A);r(x,y+2,5,1,0xCA779A);r(x+1,y+3,3,1,0xCA779A);r(x+2,y+4,1,1,0xCA779A);
    }
    r(45, 34, 32, 1, phase == 3 ? 0x68756B : 0xDADEC2);
    for (final x in [7, 42, 81, 103]) {
      r(x, 30, 1, 3, 0x698E71);
      r(x - 1 + sway, 28, 3, 2, together ? 0xECAAC0 : 0xF5DC96);
    }
    c.restore();
  }

  @override
  bool shouldRepaint(_SkyPainter old) =>
      together != old.together || phase != old.phase || action!=old.action;
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
