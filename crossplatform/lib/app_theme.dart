import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'pixels.dart';

/// Both UI systems use the same palette, including Seirama's local appearance.
abstract final class AbcThemes {
  static const cardRadius = BorderRadius.all(Radius.circular(14));

  static ShadThemeData shad({required bool dark, required bool together}) {
    final p = Palette(dark, together);
    final brightness = dark ? Brightness.dark : Brightness.light;
    return ShadThemeData(
      brightness: brightness,
      radius: const BorderRadius.all(Radius.circular(10)),
      textTheme: ShadTextTheme(family: 'sans-serif'),
      colorScheme: ShadColorScheme.fromName('violet', brightness: brightness)
          .copyWith(
            background: p.bg,
            foreground: p.ink,
            card: p.card,
            cardForeground: p.ink,
            popover: p.card,
            popoverForeground: p.ink,
            primary: p.accent,
            primaryForeground: dark ? p.bg : Colors.white,
            secondary: p.tint,
            secondaryForeground: p.ink,
            muted: p.tint,
            mutedForeground: p.muted,
            accent: p.tint,
            accentForeground: p.ink,
            border: p.border,
            input: p.border,
            ring: p.accent,
            selection: p.tint,
          ),
      cardTheme: const ShadCardTheme(
        radius: cardRadius,
        padding: EdgeInsets.all(18),
        columnCrossAxisAlignment: CrossAxisAlignment.stretch,
        shadows: [],
      ),
      decoration: ShadDecoration(
        border: ShadBorder.all(
          color: p.border,
          width: 1.5,
          radius: const BorderRadius.all(Radius.circular(10)),
        ),
        focusedBorder: ShadBorder.all(
          color: p.accent,
          width: 2,
          radius: const BorderRadius.all(Radius.circular(10)),
        ),
      ),
    );
  }

  /// Theme Material routes (sheets, time pickers) inside the single ShadApp.
  static ThemeData material({required bool dark, required bool together}) {
    final p = Palette(dark, together);
    final brightness = dark ? Brightness.dark : Brightness.light;
    final scheme =
        ColorScheme.fromSeed(
          seedColor: p.accent,
          brightness: brightness,
        ).copyWith(
          primary: p.accent,
          onPrimary: dark ? p.bg : Colors.white,
          surface: p.card,
          onSurface: p.ink,
          outline: p.border,
        );
    final inputBorder = OutlineInputBorder(
      borderRadius: const BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide(color: p.border),
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: p.bg,
      fontFamily: 'sans-serif',
      textTheme: ThemeData(brightness: brightness).textTheme.apply(
        fontFamily: 'sans-serif',
        bodyColor: p.ink,
        displayColor: p.ink,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: p.card,
        indicatorColor: p.tint,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.card,
        border: inputBorder,
        enabledBorder: inputBorder,
        focusedBorder: inputBorder.copyWith(
          borderSide: BorderSide(color: p.accent, width: 2),
        ),
        contentPadding: const EdgeInsets.all(16),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 54),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 50),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.bg,
        showDragHandle: true,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.card,
        shape: RoundedRectangleBorder(
          borderRadius: cardRadius,
          side: BorderSide(color: p.border, width: 1.5),
        ),
        titleTextStyle: TextStyle(
          fontFamily: 'Silkscreen',
          fontSize: 18,
          height: 1.4,
          color: p.ink,
        ),
        contentTextStyle: TextStyle(
          fontFamily: 'sans-serif',
          fontSize: 14,
          height: 1.5,
          color: p.ink,
        ),
      ),
    );
  }
}
