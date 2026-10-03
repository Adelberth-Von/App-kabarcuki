import 'package:abc/main.dart';
import 'package:abc/model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
      'native pairing, confirmations, local preferences and history survive restart',
      (tester) async {
    final backend = NativeBackend();
    final before = await backend.invoke('snapshot');
    final originalCode = (before['role'] == 'sender')
        ? (await backend.invoke('pairCode'))['code']
        : null;
    if (originalCode != null) expect((await backend.invoke('pairCode'))['code'], originalCode);
    await backend.invoke('preferences', {
      'nickname': 'Cuki',
      'language': 'id',
      'clock12': false,
      'dark': false,
      'relationship': false
    });
    // This test never deletes an existing pairing. Use a fresh simulator for a full queue.
    expect(number(before['pending']),lessThan(23),reason:'Use a fresh disposable simulator when the existing queue is full.');
    if (before['role']=='') await backend.invoke('setupSender');
    else expect(before['role'],'sender');
    final model = AppModel(backend);
    await tester.pumpWidget(AbcApp(model: model));
    await tester.pumpAndSettle();
    expect(find.text('Hai, Cuki'), findsOneWidget);
    if (model.snapshot['platform'] == 'android') {
      await binding.convertFlutterSurfaceToImage();
      await tester.pump();
    }
    await binding.takeScreenshot('abc-home');
    Future<void> tap(Finder f) async {
      await tester.ensureVisible(f);
      await tester.pumpAndSettle();
      await tester.tap(f);
      await tester.pumpAndSettle();
      for (var i=0;model.busy && i<300;i++) {await tester.pump(const Duration(milliseconds:100));}
      expect(model.error,isNull);
      await tester.pumpAndSettle();
    }

    final count = model.events.length,
        revision = number(model.state['revision']);
    await tap(find.byKey(const ValueKey('status-outside')));
    await binding.takeScreenshot('abc-confirm');
    await tap(find.byKey(const ValueKey('cancel-status')));
    expect(model.events.length, count);
    expect(number(model.state['revision']), revision);
    await tap(find.byKey(const ValueKey('status-outside')));
    await tap(find.byKey(const ValueKey('confirm-status')));
    expect(number(model.state['revision']), revision + 1);
    expect(model.events.first['kind'], 'outside');
    await tap(find.byKey(const ValueKey('meal-0')));
    await tap(find.byKey(const ValueKey('confirm-status')));
    expect(model.events.first['label'], 'Sarapan');
    expect(model.state['location'], 'outside');
    await tap(find.text('Riwayat').last);
    await binding.takeScreenshot('abc-history');
    await tap(find.byKey(const ValueKey('detail-0')));
    await binding.takeScreenshot('abc-detail');
    expect(find.text(model.copy['senderTime']),findsOneWidget);
    await tap(find.byTooltip('Tutup'));
    await tap(find.text('Pengaturan').last);
    await tap(find.byKey(const ValueKey('time-format')));
    await tap(find.byKey(const ValueKey('clock-12')));
    expect(model.clock12, true);
    await tap(find.byKey(const ValueKey('theme-relationship')));
    await backend.invoke('preferences', {'dark': true});
    await model.refresh();
    await tester.pumpAndSettle();
    await binding.takeScreenshot('abc-appearance-dark');
    await backend.invoke('preferences', {'dark': false});
    await model.refresh();
    await tester.pumpAndSettle();
    await binding.takeScreenshot('abc-appearance-light');
    await tap(find.byKey(const ValueKey('language-settings')));
    await tap(find.byKey(const ValueKey('language-de')));
    expect(model.language, 'de');
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    final restored = AppModel(backend);
    await restored.init();
    expect(restored.nickname, 'Cuki');
    expect(restored.clock12, true);
    expect(restored.together, true);
    expect(restored.dark, false);
    expect(restored.language, 'de');
    expect(restored.events.first['label'], 'Sarapan');
    restored.dispose();
    await backend.invoke('preferences', {
      'language': 'id',
      'clock12': false,
      'dark': false,
      'relationship': false
    });
  });
}
