import 'package:flutter/material.dart';
import 'package:pixelarticons/pixelarticons.dart';
import 'package:pixelify_flutter/pixelify_flutter.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'pixels.dart';

/// Pixelify exposes PixelText. This wrapper keeps headings consistent and quiet.
class PixelifyText extends StatelessWidget {
  final String text;
  final double size;
  final Color? color;
  final TextAlign align;
  const PixelifyText(
    this.text, {
    super.key,
    this.size = 18,
    this.color,
    this.align = TextAlign.start,
  });

  @override
  Widget build(BuildContext context) => DefaultTextStyle.merge(
    textAlign: align,
    child: PixelText(
      text: text,
      flickerEnabled: false,
      style: TextStyle(
        fontFamily: 'Silkscreen',
        fontSize: size,
        fontWeight: FontWeight.w400,
        height: 1.35,
        color: color ?? ShadTheme.of(context).colorScheme.foreground,
      ),
    ),
  );
}

/// One short implicit animation per press. No idle ticker or animation timer.
class CozyPress extends StatefulWidget {
  final Widget child;
  final bool enabled, animate;
  const CozyPress({
    super.key,
    required this.child,
    this.enabled = true,
    this.animate = true,
  });
  @override
  State<CozyPress> createState() => _CozyPressState();
}

class _CozyPressState extends State<CozyPress> {
  int? pointer;
  bool pressed = false;
  void setPressed(bool value) {
    if (mounted && pressed != value) setState(() => pressed = value);
  }

  @override
  void didUpdateWidget(CozyPress oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.enabled) {
      pressed = false;
      pointer = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final motion =
        widget.animate &&
        !MediaQuery.disableAnimationsOf(context) &&
        TickerMode.valuesOf(context).enabled;
    final down = pressed && widget.enabled && motion;
    return Listener(
      onPointerDown: (event) {
        if (widget.enabled && pointer == null) {
          pointer = event.pointer;
          setPressed(true);
        }
      },
      onPointerUp: (event) {
        if (pointer == event.pointer) {
          pointer = null;
          setPressed(false);
        }
      },
      onPointerCancel: (event) {
        if (pointer == event.pointer) {
          pointer = null;
          setPressed(false);
        }
      },
      child: AnimatedContainer(
        duration: motion ? const Duration(milliseconds: 130) : Duration.zero,
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0, down ? 3 : 0, 0),
        child: AnimatedScale(
          scale: down ? .975 : 1,
          duration: motion ? const Duration(milliseconds: 130) : Duration.zero,
          curve: Curves.easeOutCubic,
          child: widget.child,
        ),
      ),
    );
  }
}

class CozyCard extends StatelessWidget {
  final Palette palette;
  final Widget child;
  final Color? color;
  final EdgeInsets padding;
  const CozyCard({
    super.key,
    required this.palette,
    required this.child,
    this.color,
    this.padding = const EdgeInsets.all(18),
  });
  @override
  Widget build(BuildContext context) => ShadCard(
    backgroundColor: color ?? palette.card,
    padding: EdgeInsets.zero,
    radius: const BorderRadius.all(Radius.circular(14)),
    border: ShadBorder.all(color: palette.border, width: 1.5),
    shadows: [
      BoxShadow(color: palette.shadow, offset: const Offset(0, 4)),
      BoxShadow(
        color: palette.shadow.withValues(alpha: .25),
        blurRadius: 18,
        offset: const Offset(0, 7),
      ),
    ],
    child: Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(13),
      clipBehavior: Clip.antiAlias,
      child: Padding(padding: padding, child: child),
    ),
  );
}

class CozyButton extends StatelessWidget {
  final Palette palette;
  final String label;
  final VoidCallback? onPressed;
  final bool secondary, animate, busy;
  final IconData? icon;
  const CozyButton({
    super.key,
    required this.palette,
    required this.label,
    required this.onPressed,
    this.secondary = false,
    this.animate = true,
    this.busy = false,
    this.icon,
  });
  @override
  Widget build(BuildContext context) {
    final foreground = secondary
        ? palette.accent
        : palette.dark
        ? palette.bg
        : Colors.white;
    return CozyPress(
      enabled: onPressed != null && !busy,
      animate: animate,
      child: ShadButton(
        onPressed: busy ? null : onPressed,
        enabled: !busy && onPressed != null,
        width: double.infinity,
        expands: true,
        height: 0, // Grow with translated labels and accessibility font sizes.
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        backgroundColor: secondary ? palette.tint : palette.accent,
        hoverBackgroundColor: secondary ? palette.tint : palette.accent,
        pressedBackgroundColor: secondary ? palette.tint : palette.accent,
        foregroundColor: foreground,
        decoration: ShadDecoration(
          border: ShadBorder.all(
            color: secondary ? palette.border : palette.edge,
            width: 2,
            radius: BorderRadius.circular(10),
          ),
          shadows: [BoxShadow(color: palette.edge, offset: const Offset(0, 4))],
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (busy) ...[
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: foreground,
                  ),
                ),
                const SizedBox(width: 10),
              ] else if (icon != null) ...[
                Icon(icon, size: 20, color: foreground),
                const SizedBox(width: 10),
              ],
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: foreground,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

ShadDecoration cozyInputDecoration(Palette p, {bool error = false}) =>
    ShadDecoration(
      color: p.card,
      hasError: error,
      border: ShadBorder.all(
        color: p.border,
        width: 2,
        radius: BorderRadius.circular(10),
      ),
      focusedBorder: ShadBorder.all(
        color: p.accent,
        width: 2,
        radius: BorderRadius.circular(10),
      ),
      errorBorder: ShadBorder.all(
        color: p.danger,
        width: 2,
        radius: BorderRadius.circular(10),
      ),
      shadows: [BoxShadow(color: p.shadow, offset: const Offset(0, 3))],
      disableSecondaryBorder: true,
    );

class CozyIconTile extends StatelessWidget {
  final Palette palette;
  final IconData icon;
  final Color? tone;
  final double size;
  const CozyIconTile(
    this.icon, {
    super.key,
    required this.palette,
    this.tone,
    this.size = 24,
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: (tone ?? palette.accent).withValues(alpha: .12),
      border: Border.all(color: (tone ?? palette.accent).withValues(alpha: .2)),
      borderRadius: BorderRadius.circular(9),
    ),
    child: Icon(icon, size: size, color: tone ?? palette.accent),
  );
}

IconData actionIcon(String kind) => switch (kind) {
  'outside' => Pixel.humanrun,
  'meal' => Pixel.coffee,
  _ => Pixel.home,
};

class CozyActionCard extends StatelessWidget {
  final Palette palette;
  final String kind, label;
  final VoidCallback? onPressed;
  final bool wide, animate;
  const CozyActionCard({
    super.key,
    required this.palette,
    required this.kind,
    required this.label,
    required this.onPressed,
    this.wide = false,
    this.animate = true,
  });
  @override
  Widget build(BuildContext context) {
    final tone = kind == 'outside'
        ? palette.amber
        : kind == 'meal'
        ? palette.green
        : palette.accent;
    final icon = CozyIconTile(
      actionIcon(kind),
      palette: palette,
      tone: tone,
      size: 32,
    );
    final title = PixelifyText(label, size: 12, align: TextAlign.center);
    return CozyPress(
      enabled: onPressed != null,
      animate: animate,
      child: CozyCard(
        palette: palette,
        padding: EdgeInsets.zero,
        color: Color.alphaBlend(tone.withValues(alpha: .05), palette.card),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(13),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 14, 10, 14),
            child: wide
                ? Row(
                    children: [
                      icon,
                      const SizedBox(width: 14),
                      Expanded(child: title),
                      Icon(Pixel.plus, color: tone, size: 18),
                    ],
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Align(
                        alignment: Alignment.centerRight,
                        child: Icon(Pixel.plus, size: 12, color: tone),
                      ),
                      icon,
                      const SizedBox(height: 12),
                      title,
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// The aspect ratio shows the complete 160x64 world instead of cropping it.
class CozyScene extends StatelessWidget {
  final Palette palette;
  final String title, caption, action;
  final bool animate;
  final DateTime? at;
  const CozyScene({
    super.key,
    required this.palette,
    required this.title,
    required this.caption,
    this.action = 'idle',
    this.animate = false,
    this.at,
  });
  @override
  Widget build(BuildContext context) => CozyCard(
    palette: palette,
    padding: EdgeInsets.zero,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              ...[palette.amber, palette.accent, palette.green].map(
                (color) => Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Container(width: 5, height: 5, color: color),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: PixelifyText(title, size: 9, color: palette.muted),
              ),
              Icon(
                palette.together ? Pixel.heart : Pixel.cloud,
                size: 16,
                color: palette.accent,
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            border: Border.symmetric(
              horizontal: BorderSide(color: palette.border, width: 1.5),
            ),
          ),
          child: AspectRatio(
            aspectRatio: 160 / 64,
            child: PixelSky(
              together: palette.together,
              at: at,
              action: action,
              animate: animate,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Pixel.message, size: 16, color: palette.accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  caption,
                  style: TextStyle(
                    color: palette.muted,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class CozyFooter extends StatelessWidget {
  final Palette palette;
  const CozyFooter({super.key, required this.palette});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 18),
    child: Column(
      children: [
        Icon(Pixel.heart, color: palette.accent, size: 16),
        const SizedBox(height: 9),
        PixelifyText(
          'Developed by Terrence',
          size: 9,
          color: palette.muted,
          align: TextAlign.center,
        ),
      ],
    ),
  );
}

class CozyBackdrop extends StatelessWidget {
  final Palette palette;
  final Widget child;
  const CozyBackdrop({super.key, required this.palette, required this.child});
  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Positioned.fill(
        child: IgnorePointer(
          child: RepaintBoundary(
            child: CustomPaint(painter: _PaperPainter(palette)),
          ),
        ),
      ),
      child,
    ],
  );
}

class _PaperPainter extends CustomPainter {
  final Palette p;
  _PaperPainter(this.p);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..isAntiAlias = false;
    paint.color = p.accent.withValues(alpha: p.dark ? .07 : .05);
    // Static, sparse paper grain; no shader, blur, or recurring repaint.
    for (double x = 9; x < size.width; x += 22) {
      for (double y = 12; y < size.height; y += 22) {
        canvas.drawRect(Rect.fromLTWH(x, y, 1, 1), paint);
      }
    }
    paint.color = p.tint.withValues(alpha: .55);
    canvas.drawRect(Rect.fromLTWH(size.width - 52, 78, 52, 8), paint);
    canvas.drawRect(Rect.fromLTWH(size.width - 24, 58, 8, 52), paint);
    canvas.drawRect(Rect.fromLTWH(0, size.height - 116, 30, 6), paint);
  }

  @override
  bool shouldRepaint(_PaperPainter old) =>
      old.p.dark != p.dark || old.p.together != p.together;
}

class CozyNavigation extends StatelessWidget {
  final Palette palette;
  final List<String> labels;
  final int selected;
  final ValueChanged<int> onSelected;
  final bool animate;
  const CozyNavigation({
    super.key,
    required this.palette,
    required this.labels,
    required this.selected,
    required this.onSelected,
    this.animate = true,
  });
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: palette.card,
      border: Border(top: BorderSide(color: palette.border, width: 1.5)),
    ),
    child: SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(
            3,
            (i) => Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: CozyPress(
                  animate: animate,
                  child: Semantics(
                    selected: i == selected,
                    button: true,
                    child: Material(
                      color: i == selected ? palette.tint : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      child: InkWell(
                        key: ValueKey('tab-$i'),
                        borderRadius: BorderRadius.circular(10),
                        onTap: () => onSelected(i),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 9,
                            horizontal: 3,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                [Pixel.home, Pixel.book, Pixel.sliders][i],
                                size: 22,
                                color: i == selected
                                    ? palette.accent
                                    : palette.muted,
                              ),
                              const SizedBox(height: 5),
                              Text(
                                labels[i],
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: i == selected
                                      ? palette.accent
                                      : palette.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
