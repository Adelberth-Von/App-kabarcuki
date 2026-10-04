import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

/// PixelButton:
/// - Pixel-perfect pixel edge outline
/// - Customizable colors for normal, hover, pressed, disabled, focused states
/// - Supports retro bitmap/font style text via TextStyle parameter
/// - Plays optional sound effects on click and hover
/// - Supports animations: glow on hover, scanline overlay on press
class PixelButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final bool enabled;
  final String label;
  final TextStyle? textStyle;

  final Color color;
  final Color hoverColor;
  final Color pressedColor;
  final Color disabledColor;
  final Color focusColor;
  final Color outlineColor;

  final double pixelEdgeThickness;

  final bool enableGlowAnimation;
  final bool enableScanlineAnimation;

  final String? clickSoundAsset; // e.g., 'assets/sounds/click.wav'
  final String? hoverSoundAsset; // e.g., 'assets/sounds/hover.wav'

  const PixelButton({
    Key? key,
    required this.label,
    this.onPressed,
    this.enabled = true,
    this.textStyle,
    this.color = const Color(0xFF222222),
    this.hoverColor = const Color(0xFF444444),
    this.pressedColor = const Color(0xFF666666),
    this.disabledColor = const Color(0xFF888888),
    this.focusColor = const Color(0xFF5555FF),
    this.outlineColor = const Color(0xFFFFFFFF),
    this.pixelEdgeThickness = 2.0,
    this.enableGlowAnimation = true,
    this.enableScanlineAnimation = true,
    this.clickSoundAsset,
    this.hoverSoundAsset,
  }) : super(key: key);

  @override
  _PixelButtonState createState() => _PixelButtonState();
}

class _PixelButtonState extends State<PixelButton> with SingleTickerProviderStateMixin {
  bool _hovering = false;
  bool _pressed = false;
  bool _focused = false;

  late final AnimationController _glowController;
  late final Animation<double> _glowAnimation;

  late final AudioPlayer _audioPlayer;

  @override
  void initState() {
    super.initState();

    _audioPlayer = AudioPlayer();

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _glowAnimation = Tween<double>(begin: 0.0, end: 12.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    )..addListener(() {
        setState(() {});
      });

    if (widget.enableGlowAnimation) {
      _glowController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _glowController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Color get _backgroundColor {
    if (!widget.enabled) return widget.disabledColor;
    if (_pressed) return widget.pressedColor;
    if (_hovering) return widget.hoverColor;
    if (_focused) return widget.focusColor;
    return widget.color;
  }

  void _playSound(String? asset) {
    if (asset == null) return;
    _audioPlayer.play(AssetSource(asset));
  }

  Widget _buildScanlineOverlay(Size size) {
    // Simple scanline overlay animated with opacity flicker
    return AnimatedOpacity(
      opacity: _pressed ? 0.25 : 0.0,
      duration: const Duration(milliseconds: 200),
      child: CustomPaint(
        size: size,
        painter: _ScanlinePainter(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    TextStyle textStyle = widget.textStyle ??
        const TextStyle(
          fontFamily: 'PressStart2P', // Example retro pixel font, include font in pubspec.yaml
          fontSize: 14,
          color: Colors.white,
          shadows: [
            Shadow(offset: Offset(1, 1), color: Colors.black, blurRadius: 0),
          ],
        );

    return FocusableActionDetector(
      enabled: widget.enabled,
      autofocus: false,
      onShowHoverHighlight: (hovering) {
        setState(() => _hovering = hovering);
        if (hovering) {
          _playSound(widget.hoverSoundAsset);
        }
      },
      onShowFocusHighlight: (focusing) {
        setState(() => _focused = focusing);
      },
      mouseCursor: widget.enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTapDown: widget.enabled
            ? (_) {
                setState(() => _pressed = true);
                _playSound(widget.clickSoundAsset);
              }
            : null,
        onTapUp: widget.enabled
            ? (_) {
                setState(() => _pressed = false);
                widget.onPressed?.call();
              }
            : null,
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          decoration: BoxDecoration(
            color: _backgroundColor,
            border: Border.all(
              color: widget.outlineColor,
              width: widget.pixelEdgeThickness,
              // For pixel perfect edges, consider a custom painter edge if needed
            ),
            boxShadow: widget.enableGlowAnimation && _hovering
                ? [
                    BoxShadow(
                      color: widget.outlineColor.withOpacity(0.75),
                      blurRadius: _glowAnimation.value,
                      spreadRadius: _glowAnimation.value / 2,
                    ),
                  ]
                : null,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Text(widget.label, style: textStyle),
              if (widget.enableScanlineAnimation) _buildScanlineOverlay(Size.infinite),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScanlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..strokeWidth = 1;

    // Draw horizontal scanlines spaced by 4 pixels
    for (double y = 0; y < size.height; y += 4) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
