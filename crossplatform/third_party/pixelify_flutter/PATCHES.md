# Local compatibility patch — pixelify_flutter 0.0.1

Source: https://pub.dev/packages/pixelify_flutter/versions/0.0.1
Repository: https://github.com/jyothish-ram/pixelify_flutter
The original MIT LICENSE is retained. This directory contains the upstream
library, shaders, package manifest and README; it is not a new published package.

The upstream entrypoint does not compile: `wave_animation.dart` is empty, while
`PixelAnimations` references `WaveAnimation` and `WaveAnimationParams`. This
copy supplies those two missing classes. Wave motion respects TickerMode,
system reduced motion and app visibility. It is not enabled in the main UI.

`PixelText` also declared its nullable timer as `late` without initializing it
for a static effect. It now starts as null, allowing static text to be disposed
without throwing LateInitializationError. The application uses static text.

The app declares the normal package constraint and a local dependency override.
No global pub cache is modified. Replace this override after a working upstream
version has been tested. The main PixelTheme currently disables shader effects;
the existing lightweight scene painter handles animated illustrations.
