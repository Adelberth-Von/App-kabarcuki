# Pixelify Flutter 

[![pub package](https://img.shields.io/pub/v/pixelify_flutter.svg)](https://pub.dev/packages/pixelify_flutter)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A comprehensive Flutter package for creating retro pixel-art style UI components, animations, and visual effects. Transform your Flutter app into a nostalgic gaming experience with authentic pixel-perfect widgets and shader-powered effects.

## ✨ Features

### 🎨 Pixel Widgets
- **PixelButton** - Interactive buttons with hover effects, sound support, and scanline animations
- **PixelText** - Text with multiple retro effects (flicker, glitch, scanline, pixelate)
- **PixelPanel** - Containers with various retro styles (CRT, paper grain, glowing borders)
- **PixelSlider** - Segmented sliders with pixel-perfect styling
- **PixelToggle** - Toggle switches with blinking and flip animations
- **PixelProgressBar** - Progress indicators with segmented, smooth, and icon-filled styles
- **PixelTextField** - Input fields with retro styling
- **PixelShimmer** - Loading shimmer effects with pixelated overlays

### 🎭 Visual Effects
- **Pixelate Effect** - Shader-based pixelation with customizable pixel size
- **Bloom Effect** - Glowing bloom effects for that retro CRT look
- **Scanline Effect** - Authentic CRT scanline overlays
- **Glitch Effect** - Digital glitch distortions with color shifting
- **Noise Effect** - Film grain and static noise overlays

### 🎬 Animations
- **Fade Animation** - Smooth opacity transitions
- **Flicker Animation** - Random opacity flickering effects
- **Jitter Animation** - Position-based shake animations
- **Wave Animation** - Sine wave motion effects

### 🎯 Core Features
- **PixelTheme** - Global theming system for consistent styling
- **Shader Support** - Hardware-accelerated effects using Fragment Shaders
- **Audio Integration** - Built-in sound effects for interactive elements
- **Customizable Parameters** - Extensive customization options for all components

## 📦 Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  pixelify_flutter: ^0.0.1
  audioplayers: ^6.5.0  # For sound effects
```

Then run:

```bash
flutter pub get
```

## 🚀 Quick Start

### Basic Setup

```dart
import 'package:flutter/material.dart';
import 'package:pixelify_flutter/pixelify_flutter.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: PixelTheme(
        accentColor: Colors.cyanAccent,
        pixelScale: 1.0,
        enableShaders: true,
        child: MyHomePage(),
      ),
    );
  }
}
```

### Simple Pixel Button

```dart
PixelButton(
  label: 'START GAME',
  onPressed: () => print('Game started!'),
  color: Colors.black87,
  hoverColor: Colors.grey[800]!,
  outlineColor: Colors.cyanAccent,
  enableGlowAnimation: true,
  clickSoundAsset: 'assets/sounds/click.wav',
)
```

## 📚 Widget Gallery

### 🔘 PixelButton

Interactive retro-style buttons with multiple visual and audio effects.

```dart
PixelButton(
  label: 'PIXEL BUTTON',
  onPressed: () {},
  textStyle: TextStyle(
    fontFamily: 'PressStart2P',
    fontSize: 14,
    color: Colors.white,
  ),
  color: Colors.black87,
  hoverColor: Colors.grey[700]!,
  pressedColor: Colors.grey[600]!,
  outlineColor: Colors.greenAccent,
  pixelEdgeThickness: 3.0,
  enableGlowAnimation: true,
  enableScanlineAnimation: true,
  clickSoundAsset: 'assets/sounds/click.wav',
  hoverSoundAsset: 'assets/sounds/hover.wav',
)
```

### 📝 PixelText

Text with various retro effects and styling options.

```dart
// Glitch Effect
PixelText(
  text: 'GLITCH TEXT',
  style: TextStyle(
    fontFamily: 'PressStart2P',
    fontSize: 24,
    color: Colors.white,
  ),
  effect: PixelTextEffect.glitch,
  effectDuration: Duration(milliseconds: 200),
)

// Palette Colors
PixelText(
  text: 'RAINBOW TEXT',
  style: TextStyle(fontFamily: 'PressStart2P', fontSize: 20),
  enablePaletteColors: true,
  palette: [
    Colors.red, Colors.orange, Colors.yellow,
    Colors.green, Colors.blue, Colors.purple,
  ],
)
```

### 🎛️ PixelSlider

Segmented sliders with pixel-perfect styling.

```dart
PixelSlider(
  value: sliderValue,
  onChanged: (value) => setState(() => sliderValue = value),
  divisions: 10,
  activeColor: Colors.cyanAccent,
  inactiveColor: Colors.grey[700]!,
  segmentWidth: 8.0,
  height: 16,
  handleSize: 24,
)
```

### 🔄 PixelToggle

Toggle switches with various animation styles.

```dart
// Blinking Toggle
PixelToggle(
  value: toggleValue,
  onChanged: (value) => setState(() => toggleValue = value),
  blinking: true,
  onColor: Colors.greenAccent,
  offColor: Colors.grey,
  size: 32,
)

// Flip Animation Toggle
PixelToggle(
  value: toggleValue,
  onChanged: (value) => setState(() => toggleValue = value),
  flipAnimation: true,
  onColor: Colors.purpleAccent,
  size: 32,
)
```

### 📊 PixelProgressBar

Progress bars with multiple visual styles.

```dart
// Segmented Style
PixelProgressBar(
  progress: 0.7,
  style: PixelProgressBarStyle.segmented,
  segments: 20,
  fillColor: Colors.cyanAccent,
  backgroundColor: Colors.black54,
  showScanlines: true,
  showGlow: true,
)

// Icon Filled Style
PixelProgressBar(
  progress: 0.5,
  style: PixelProgressBarStyle.iconFilled,
  icon: Icon(Icons.star, color: Colors.yellowAccent),
  fillColor: Colors.purpleAccent,
  showGlow: true,
)
```

### 🖼️ PixelPanel

Containers with various retro styling options.

```dart
PixelPanel(
  width: 320,
  height: 200,
  style: PixelPanelStyle.oldScreenCRT,
  borderColor: Colors.greenAccent,
  borderThickness: 4,
  showScanlines: true,
  child: Center(
    child: Text(
      'RETRO PANEL',
      style: TextStyle(
        color: Colors.greenAccent,
        fontFamily: 'PressStart2P',
      ),
    ),
  ),
)
```

## 🎨 Effects & Animations

### Wrapper Widgets

Apply effects and animations to any widget using wrapper components:

```dart
// Pixelate Effect
PixelEffects(
  effect: PixelEffectStyle.pixelate,
  params: PixelateEffectParams(
    pixelSize: 8.0,
    intensity: 1.0,
    softEdges: false,
  ),
  child: YourWidget(),
)

// Glitch Effect
PixelEffects(
  effect: PixelEffectStyle.glitch,
  params: GlitchEffectParams(
    intensity: 0.5,
    frequency: Duration(milliseconds: 100),
    enableNoise: true,
  ),
  child: YourWidget(),
)

// Fade Animation
PixelAnimations(
  style: PixelAnimationStyle.fade,
  params: FadeAnimationParams(
    duration: Duration(seconds: 2),
    loop: true,
    reverse: true,
  ),
  child: YourWidget(),
)
```

### Available Effects

| Effect | Description | Key Parameters |
|--------|-------------|----------------|
| **Pixelate** | Shader-based pixelation | `pixelSize`, `intensity`, `softEdges` |
| **Bloom** | Glowing bloom effect | `intensity`, `threshold`, `glowColor` |
| **Scanline** | CRT scanline overlay | `thickness`, `spacing`, `animate` |
| **Glitch** | Digital distortion | `intensity`, `frequency`, `glitchColors` |
| **Noise** | Film grain effect | `intensity`, `density`, `dotSize` |

### Available Animations

| Animation | Description | Key Parameters |
|-----------|-------------|----------------|
| **Fade** | Opacity transitions | `duration`, `beginOpacity`, `endOpacity` |
| **Flicker** | Random opacity changes | `minOpacity`, `maxOpacity`, `randomness` |
| **Jitter** | Position-based shaking | `strengthX`, `strengthY`, `randomness` |
| **Wave** | Sine wave motion | `amplitude`, `frequency`, `direction` |

## 🎵 Audio Integration

Many widgets support built-in sound effects:

```dart
PixelButton(
  label: 'SOUND BUTTON',
  onPressed: () {},
  clickSoundAsset: 'assets/sounds/click.wav',
  hoverSoundAsset: 'assets/sounds/hover.wav',
)
```

Add sound files to your `pubspec.yaml`:

```yaml
flutter:
  assets:
    - assets/sounds/
```

## 🎨 Theming

Use `PixelTheme` to maintain consistent styling across your app:

```dart
PixelTheme(
  accentColor: Colors.cyanAccent,
  pixelScale: 1.2,
  enableShaders: true,
  child: MaterialApp(
    home: YourHomePage(),
  ),
)
```

Access theme values in widgets:

```dart
final theme = PixelTheme.of(context);
final accentColor = theme.accentColor;
```

## 🖼️ Shader Requirements

For optimal visual effects, include shader files in your `pubspec.yaml`:

```yaml
flutter:
  shaders:
    - shaders/bloom.frag
    - shaders/pixelate.frag
    - shaders/scanline.frag
```

## 📱 Example App

```dart
class RetroGameUI extends StatefulWidget {
  @override
  _RetroGameUIState createState() => _RetroGameUIState();
}

class _RetroGameUIState extends State<RetroGameUI> {
  double health = 0.8;
  bool soundEnabled = true;
  double volume = 0.6;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: PixelTheme(
        accentColor: Colors.cyanAccent,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Glitch Title
              PixelText(
                text: 'RETRO GAME',
                style: TextStyle(
                  fontFamily: 'PressStart2P',
                  fontSize: 32,
                  color: Colors.white,
                ),
                effect: PixelTextEffect.glitch,
              ),
              
              SizedBox(height: 40),
              
              // Health Bar
              PixelProgressBar(
                progress: health,
                style: PixelProgressBarStyle.segmented,
                fillColor: Colors.redAccent,
                showGlow: true,
              ),
              
              SizedBox(height: 30),
              
              // Volume Slider
              PixelSlider(
                value: volume,
                onChanged: (value) => setState(() => volume = value),
                divisions: 10,
                activeColor: Colors.greenAccent,
              ),
              
              SizedBox(height: 30),
              
              // Sound Toggle
              PixelToggle(
                value: soundEnabled,
                onChanged: (value) => setState(() => soundEnabled = value),
                blinking: true,
              ),
              
              SizedBox(height: 40),
              
              // Start Button
              PixelButton(
                label: 'START GAME',
                onPressed: () => print('Game Started!'),
                enableGlowAnimation: true,
                clickSoundAsset: 'assets/sounds/start.wav',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

## 🎯 Best Practices

1. **Font Setup**: Use pixel fonts like `PressStart2P` for authentic retro styling
2. **Color Palette**: Stick to retro color schemes (neon colors on dark backgrounds)
3. **Performance**: Enable shaders only when needed for better performance on older devices
4. **Audio**: Keep sound files small and in appropriate formats (WAV, MP3)
5. **Theming**: Use `PixelTheme` for consistent styling across your app

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request. For major changes, please open an issue first to discuss what you would like to change - see the [CONTRIBUTING](CONTRIBUTING.md) file for details.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🔗 Links

- [Homepage](https://jyothish-ram.me/projects/pixelify_flutter)
- [Repository](https://github.com/jyothish-ram/pixelify_flutter)
- [Issues](https://github.com/jyothish-ram/pixelify_flutter/issues)
- [Pub.dev](https://pub.dev/packages/pixelify_flutter)
- [Developer](https://jyothish-ram.me)
- [Support Us](https://buymeacoffee.com/jyothish.ram)
---

Made with ☕ ❤️ 🎧 