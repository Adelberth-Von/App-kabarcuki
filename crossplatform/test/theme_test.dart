import 'package:abc/main.dart';
import 'package:abc/pixels.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixelify_flutter/pixelify_flutter.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'app_test.dart' show FakeBackend, show;
import '../tool/theme_preview.dart' show ThemePreviewBackend;

void main() {
  test('preview preferences and role setup operate without a native backend',
      () async {
    final backend = ThemePreviewBackend();
    await backend.invoke('preferences', {'nickname': 'Cuki', 'dark': true});
    await backend.invoke('setupSender');
    final snapshot = await backend.invoke('snapshot');
    expect(snapshot['profile']['nickname'], 'Cuki');
    expect(snapshot['profile']['dark'], true);
    expect(snapshot['role'], 'sender');
    expect(snapshot['state']['name'], 'Cuki');
  });

  testWidgets('both theme providers follow preferences across modal routes', (
    tester,
  ) async {
    final model = await show(tester, FakeBackend(together: true));
    var context = tester.element(find.byType(Shell));
    expect(ShadTheme.of(context).brightness, Brightness.light);
    expect(
      PixelTheme.of(context).accentColor,
      const Palette(false, true).accent,
    );
    expect(find.byType(ShadCard), findsWidgets);
    await tester.tap(find.text('Keluar').first);
    await tester.pumpAndSettle();
    context = tester.element(find.byType(AlertDialog));
    expect(
      PixelTheme.of(context).accentColor,
      const Palette(false, true).accent,
    );
    await model.prefs({'dark': true});
    await tester.pumpAndSettle();
    context = tester.element(find.byType(AlertDialog));
    expect(Theme.of(context).brightness, Brightness.dark);
    expect(ShadTheme.of(context).brightness, Brightness.dark);
    expect(
      PixelTheme.of(context).accentColor,
      const Palette(true, true).accent,
    );
    expect(PixelTheme.of(context).enableShaders, isFalse);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('static PixelText can be removed without a timer exception', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: PixelText(
          text: 'abc',
          style: TextStyle(fontFamily: 'Silkscreen'),
          flickerEnabled: false,
        ),
      ),
    );
    await tester.pumpWidget(const SizedBox.shrink());
    expect(tester.takeException(), isNull);
    expect(tester.binding.transientCallbackCount, 0);
  });

  testWidgets('wave entrypoint compiles and reduced motion stops its ticker', (
    tester,
  ) async {
    Widget fixture(bool reduced) => MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: reduced),
        child: const PixelAnimations(
          style: PixelAnimationStyle.wave,
          child: Text('wave'),
        ),
      ),
    );
    await tester.pumpWidget(fixture(false));
    await tester.pump(const Duration(milliseconds: 150));
    final moving = tester.widget<Transform>(find.byType(Transform));
    expect(moving.transform.storage[13], isNot(0));
    await tester.pumpWidget(fixture(true));
    await tester.pump();
    final still = tester.widget<Transform>(find.byType(Transform));
    expect(still.transform.storage[13], 0);
    expect(tester.binding.transientCallbackCount, 0);
    await tester.pumpWidget(const SizedBox.shrink());
    expect(tester.takeException(), isNull);
  });
}
