import 'package:abc/cozy_ui.dart';
import 'package:abc/pixels.dart';
import 'package:abc/strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'app_test.dart' show FakeBackend, show, close, tapVisible;

void main() {
  testWidgets(
    'press cancellation restores the button without sending an action',
    (tester) async {
      var calls = 0;
      await tester.pumpWidget(
        ShadApp(
          home: Center(
            child: SizedBox(
              width: 250,
              child: CozyButton(
                palette: const Palette(false, false),
                label: 'Lanjutkan',
                onPressed: () => calls++,
              ),
            ),
          ),
        ),
      );
      final press = await tester.startGesture(
        tester.getCenter(find.byType(ShadButton)),
      );
      await tester.pump(const Duration(milliseconds: 130));
      expect(
        tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale,
        lessThan(1),
      );
      await press.cancel();
      await tester.pumpAndSettle();
      expect(tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, 1);
      expect(calls, 0);
      await tester.tap(find.byType(ShadButton));
      await tester.pumpAndSettle();
      expect(calls, 1);
      expect(tester.binding.transientCallbackCount, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('reduced motion keeps a button still and preserves its action', (
    tester,
  ) async {
    var calls = 0;
    await tester.pumpWidget(
      ShadApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Center(
            child: SizedBox(
              width: 250,
              child: CozyButton(
                palette: const Palette(true, false),
                label: 'Continue',
                onPressed: () => calls++,
              ),
            ),
          ),
        ),
      ),
    );
    final press = await tester.startGesture(
      tester.getCenter(find.byType(ShadButton)),
    );
    await tester.pump();
    expect(tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, 1);
    await press.up();
    await tester.pumpAndSettle();
    expect(calls, 1);
    expect(tester.binding.transientCallbackCount, 0);
  });

  for (final lang in languages.keys) {
    testWidgets(
      'welcome and role selection fit $lang at 200% text with a keyboard',
      (tester) async {
        final backend = FakeBackend(nickname: '', role: '', language: lang);
        await show(tester, backend, size: const Size(360, 800), scale: 2);
        expect(find.text(Copy(lang)['nameHint']), findsOneWidget);
        expect(find.text('Developed by Terrence'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.enterText(
          find.byKey(const ValueKey('nickname-input')),
          'Nara',
        );
        await tapVisible(
          tester,
          find.byKey(const ValueKey('onboarding-continue')),
        );
        expect(find.text(Copy(lang).fill('hello', 'Nara')), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tapVisible(tester, find.text(Copy(lang)['receiver']).last);
        expect(find.byType(ShadInput), findsOneWidget);
        await tester.enterText(
          find.byKey(const ValueKey('pair-code-input')),
          'KB2.fixture',
        );
        tester.view.viewInsets = const FakeViewPadding(bottom: 300);
        addTearDown(tester.view.resetViewInsets);
        await tester.pumpAndSettle();
        await tester.ensureVisible(
          find.byKey(const ValueKey('setup-receiver')),
        );
        await tester.pumpAndSettle();
        expect(
          tester
              .getBottomRight(find.byKey(const ValueKey('setup-receiver')))
              .dy,
          lessThanOrEqualTo(500),
        );
        expect(tester.takeException(), isNull);
        await close(tester);
      },
    );
  }

  testWidgets('appearance cards apply immediately and footer is reachable', (
    tester,
  ) async {
    final backend = FakeBackend();
    final model = await show(tester, backend);
    await model.prefs({'clock12': true});
    await tester.pumpAndSettle();
    await tapVisible(tester, find.byKey(const ValueKey('tab-2')));
    await tapVisible(tester, find.byKey(const ValueKey('appearance-dark')));
    expect(model.dark, true);
    expect(model.clock12, true);
    expect(
      ShadTheme.of(tester.element(find.byType(CozyFooter))).brightness,
      Brightness.dark,
    );
    await tapVisible(tester, find.byKey(const ValueKey('appearance-light')));
    expect(model.dark, false);
    await tester.ensureVisible(find.byKey(const ValueKey('developer-credit')));
    await tester.pumpAndSettle();
    expect(find.text('Developed by Terrence'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await close(tester);
  });
}
