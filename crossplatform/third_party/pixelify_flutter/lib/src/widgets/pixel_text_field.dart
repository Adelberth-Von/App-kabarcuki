import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

enum PixelCursorStyle { block, underline, bar, scanlineFlicker }
enum PixelFieldDesign { classic, neon, outlined, pixel }

class PixelTextField extends FormField<String> {
  final TextEditingController? controller;
  final String placeholder;
  final TextStyle? textStyle;
  final TextStyle? placeholderStyle;
  final Color highlightColor;
  final PixelCursorStyle cursorStyle;
  final PixelFieldDesign design;
  final Duration cursorBlinkDuration;
  final String? inputSoundAsset;
  final double fontSize;
  final bool autofocus;

  PixelTextField({
    Key? key,
    this.controller,
    this.placeholder = '',
    this.textStyle,
    this.placeholderStyle,
    this.highlightColor = Colors.cyanAccent,
    this.cursorStyle = PixelCursorStyle.block,
    this.design = PixelFieldDesign.classic,
    this.cursorBlinkDuration = const Duration(milliseconds: 500),
    this.inputSoundAsset,
    this.fontSize = 18,
    this.autofocus = false,
    FormFieldValidator<String>? validator,
    FormFieldSetter<String>? onSaved,
    String? initialValue,
    bool enabled = true,
    AutovalidateMode autovalidateMode = AutovalidateMode.disabled,
  }) : super(
          key: key,
          validator: validator,
          onSaved: onSaved,
          initialValue:
              controller != null ? controller.text : (initialValue ?? ''),
          autovalidateMode: autovalidateMode,
          enabled: enabled,
          builder: (FormFieldState<String> state) {
            final _PixelTextFieldState fieldState =
                state as _PixelTextFieldState;

            return fieldState._buildField(state);
          },
        );

  @override
  FormFieldState<String> createState() => _PixelTextFieldState();
}

class _PixelTextFieldState extends FormFieldState<String>
    with SingleTickerProviderStateMixin {
  TextEditingController? _internalController;
  TextEditingController get _effectiveController =>
      widget.controller ?? _internalController!;

  late FocusNode _focusNode;
  bool _isFocused = false;
  bool _showCursor = true;
  Timer? _blinkTimer;

  late AudioPlayer _audioPlayer;

  @override
  PixelTextField get widget => super.widget as PixelTextField;

  @override
  void initState() {
    super.initState();

    if (widget.controller == null) {
      _internalController = TextEditingController(text: widget.initialValue);
    }

    _focusNode = FocusNode();
    _focusNode.addListener(_handleFocusChange);

    _effectiveController.addListener(_handleTextChange);

    _audioPlayer = AudioPlayer();

    _startCursorTimer();
  }

  void _handleFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
      if (_isFocused) {
        _startCursorTimer();
      } else {
        _showCursor = false;
        _blinkTimer?.cancel();
      }
    });
  }

  void _startCursorTimer() {
    _blinkTimer?.cancel();
    _showCursor = true;
    _blinkTimer = Timer.periodic(widget.cursorBlinkDuration, (timer) {
      setState(() {
        _showCursor = !_showCursor;
      });
    });
  }

  void _handleTextChange() {
    if (_effectiveController.text != value) {
      didChange(_effectiveController.text);
    }
  }

  @override
  void didUpdateWidget(PixelTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller?.removeListener(_handleTextChange);
      widget.controller?.addListener(_handleTextChange);
      if (oldWidget.controller == null && _internalController != null) {
        _internalController?.dispose();
        _internalController = null;
      } else if (widget.controller == null) {
        _internalController = TextEditingController(text: value);
        _internalController?.addListener(_handleTextChange);
      }
    }
    if (widget.initialValue != oldWidget.initialValue &&
        widget.initialValue != _effectiveController.text) {
      _effectiveController.text = widget.initialValue ?? '';
      setValue(widget.initialValue);
    }
  }

  @override
  void dispose() {
    _blinkTimer?.cancel();
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    _internalController?.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _playInputSound() {
    if (widget.inputSoundAsset != null) {
      _audioPlayer.play(AssetSource(widget.inputSoundAsset!));
    }
  }

  Widget _buildCursor(Size size) {
    final cursorHeight = widget.fontSize;
    final color = widget.highlightColor;

    switch (widget.cursorStyle) {
      case PixelCursorStyle.block:
        if (!_showCursor || !_isFocused) return const SizedBox.shrink();
        return Container(
          width: widget.fontSize * 0.6,
          height: cursorHeight,
          color: color,
        );
      case PixelCursorStyle.underline:
        if (!_showCursor || !_isFocused) return const SizedBox.shrink();
        return Positioned(
          bottom: 0,
          child: Container(
            width: widget.fontSize * 0.6,
            height: 3,
            color: color,
          ),
        );
      case PixelCursorStyle.bar:
        if (!_showCursor || !_isFocused) return const SizedBox.shrink();
        return Container(
          width: 2,
          height: cursorHeight,
          color: color,
        );
      case PixelCursorStyle.scanlineFlicker:
        if (!_isFocused) return const SizedBox.shrink();
        return AnimatedOpacity(
          opacity: _showCursor ? 0.7 : 0.2,
          duration: const Duration(milliseconds: 100),
          child: Container(
            width: widget.fontSize * 0.6,
            height: cursorHeight,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  color.withOpacity(0.7),
                  color.withOpacity(0.3),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.4, 0.6, 1.0],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        );
    }
  }

  InputDecoration _getInputDecoration() {
    switch (widget.design) {
      case PixelFieldDesign.classic:
        return InputDecoration(
          filled: true,
          fillColor: Colors.black,
          hintText: widget.placeholder,
          hintStyle: widget.placeholderStyle ??
              TextStyle(
                color: Colors.grey.shade600,
                fontFamily: 'PressStart2P',
                fontSize: widget.fontSize,
              ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: BorderSide(color: widget.highlightColor, width: 2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: BorderSide(color: widget.highlightColor, width: 3),
          ),
          errorText: errorText,
        );
      case PixelFieldDesign.neon:
        return InputDecoration(
          filled: true,
          fillColor: Colors.black,
          hintText: widget.placeholder,
          hintStyle: widget.placeholderStyle ??
              TextStyle(
                color: Colors.cyanAccent.shade200,
                fontFamily: 'PressStart2P',
                fontSize: widget.fontSize,
              ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: BorderSide(color: Colors.cyanAccent, width: 3),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: BorderSide(color: Colors.cyanAccent.shade100, width: 4),
          ),
          errorText: errorText,
        );
      case PixelFieldDesign.outlined:
        return InputDecoration(
          filled: false,
          hintText: widget.placeholder,
          hintStyle: widget.placeholderStyle ??
              TextStyle(
                color: Colors.white70,
                fontFamily: 'PressStart2P',
                fontSize: widget.fontSize,
              ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: BorderSide(color: Colors.white54, width: 2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: BorderSide(color: widget.highlightColor, width: 3),
          ),
          errorText: errorText,
        );
      case PixelFieldDesign.pixel:
        return InputDecoration(
          filled: true,
          fillColor: Colors.black,
          hintText: widget.placeholder,
          hintStyle: widget.placeholderStyle ??
              TextStyle(
                color: Colors.grey.shade500,
                fontFamily: 'PressStart2P',
                fontSize: widget.fontSize,
              ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: BorderSide(color: Colors.grey.shade700, width: 3),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: BorderSide(color: widget.highlightColor, width: 4),
          ),
          errorText: errorText,
        );
    }
  }

  Widget _buildField(FormFieldState<String> state) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).requestFocus(_focusNode);
      },
      child: Stack(
        children: [
          TextField(
            enabled: widget.enabled,
            focusNode: _focusNode,
            controller: _effectiveController,
            cursorWidth: 0, // hide default cursor
            style: widget.textStyle ??
                TextStyle(
                  fontFamily: 'PressStart2P', // Use your pixel font here
                  fontSize: widget.fontSize,
                  color: Colors.white,
                ),
            decoration: _getInputDecoration(),
            autofocus: widget.autofocus,
            onChanged: (text) {
              _playInputSound();
              state.didChange(text);
            },
          ),
          Positioned(
            left: _calcCursorOffset(),
            top: 12,
            child: SizedBox(
              width: widget.fontSize * 0.6,
              height: widget.fontSize,
              child: _buildCursor(Size(widget.fontSize * 0.6, widget.fontSize)),
            ),
          ),
          if (state.hasError)
            Positioned(
              bottom: -20,
              child: Text(
                state.errorText ?? '',
                style: const TextStyle(color: Colors.redAccent, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  double _calcCursorOffset() {
    final text = _effectiveController.text;
    final textPainter = TextPainter(
      text: TextSpan(
        text: text.isEmpty ? ' ' : text,
        style: widget.textStyle ??
            TextStyle(
              fontFamily: 'PressStart2P',
              fontSize: widget.fontSize,
            ),
      ),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    return textPainter.width + 8; // offset margin
  }
}


// usage

// final _formKey = GlobalKey<FormState>();
// final _textController = TextEditingController();

// Form(
//   key: _formKey,
//   child: Column(
//     children: [
//       PixelTextField(
//         controller: _textController,
//         formKey: _formKey,
//         placeholder: 'ENTER YOUR NAME',
//         highlightColor: Colors.cyanAccent,
//         cursorStyle: PixelCursorStyle.scanlineFlicker,
//         design: PixelFieldDesign.pixel,
//         inputSoundAsset: 'assets/sounds/keypress.wav',
//         fontSize: 18,
//         validator: (value) {
//           if (value == null || value.isEmpty) return 'Required';
//           return null;
//         },
//         onSaved: (value) {
//           print('Saved: $value');
//         },
//       ),
//       ElevatedButton(
//         onPressed: () {
//           if (_formKey.currentState?.validate() ?? false) {
//             _formKey.currentState?.save();
//           }
//         },
//         child: const Text('Submit'),
//       ),
//     ],
//   ),
// );
