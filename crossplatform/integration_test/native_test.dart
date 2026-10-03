import 'package:abc/main.dart';
import 'package:abc/model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  // Initialize the engine accessibility client before the test records its
  // handle baseline. Keep our own handle scoped to this integration suite.
  final semantics = binding.ensureSemantics();
  // Register tests synchronously. Awaiting in main can let the live runner
  // complete an empty suite before testWidgets has been registered.
  setUpAll(() async {await Future<void>.delayed(const Duration(seconds: 1));});
  tearDownAll(semantics.dispose);
  testWidgets(
      'native pairing, confirmations, local preferences and history survive restart',
      (tester) async {
    final backend = NativeBackend();
    final before = await backend.invoke('snapshot');
    const cleanup=bool.fromEnvironment('QA_CLEANUP');
    if(cleanup)expect(before['role'],'',reason:'Cleanup tests require a fresh disposable simulator.');
    if(before['role']=='') {
      var changes=0;final subscription=backend.changes.listen((_)=>changes++);
      await Future<void>.delayed(const Duration(milliseconds:200));
      final initial=changes;
      for(var i=0;i<10;i++){await backend.invoke('snapshot');}
      await Future<void>.delayed(const Duration(milliseconds:200));
      expect(changes-initial,lessThanOrEqualTo(2),reason:'Read-only snapshots must not produce an update feedback loop.');
      await subscription.cancel();
    }
    final originalCode = (before['role'] == 'sender')
        ? (await backend.invoke('pairCode'))['code']
        : null;
    if (originalCode != null)
      expect((await backend.invoke('pairCode'))['code'], originalCode);
    await backend.invoke('preferences', {
      'nickname': 'Cuki',
      'language': 'id',
      'clock12': false,
      'dark': false,
      'relationship': false
    });
    // This test never deletes an existing pairing. Use a fresh simulator for a full queue.
    expect(number(before['pending']), lessThan(23),
        reason:
            'Use a fresh disposable simulator when the existing queue is full.');
    if (before['role'] == '')
      await backend.invoke('setupSender');
    else
      expect(before['role'], 'sender');
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
      for (var i = 0; model.busy && i < 300; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(model.error, isNull);
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
    final expectedMeal=model.mealNow();
    await tap(find.byKey(const ValueKey('meal-0')));
    await tap(find.byKey(const ValueKey('confirm-status')));
    expect(model.events.first['label'], expectedMeal);
    expect(model.state['location'], 'outside');
    await tap(find.text('Riwayat').last);
    await binding.takeScreenshot('abc-history');
    await tap(find.byKey(const ValueKey('detail-0')));
    await binding.takeScreenshot('abc-detail');
    expect(find.text(model.copy['senderTime']), findsOneWidget);
    await tap(find.byTooltip('Tutup'));
    if (const bool.fromEnvironment('QA_LOCATION')) {
      await tap(find.text('Beranda').last);
      await tap(find.byKey(const ValueKey('status-home')));
      if (!tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value)
        await tap(find.byType(Switch).last);
      await tap(find.byKey(const ValueKey('confirm-status')));
      expect(model.events.first['gps'], isA<Map>());
      expect(number(model.events.first['gps']['accuracy']), greaterThan(0));
      await tap(find.text('Riwayat').last);
      await tap(find.byKey(const ValueKey('detail-0')));
      await binding.takeScreenshot('abc-detail-gps');
      await tap(find.byTooltip('Tutup'));
    }
    await tap(find.text('Pengaturan').last);
    await tap(find.byKey(const ValueKey('time-format')));
    await tap(find.byKey(const ValueKey('clock-12')));
    expect(model.clock12, true);
    if (model.snapshot['platform']=='android') {
      await model.prefs({'animations':false});
      expect((await backend.invoke('qaSurfaceProbe'))['widgetAnimated'],false);
      await model.prefs({'animations':true});
      await model.command('record',{'kind':'home','shareLocation':false});
      await backend.invoke('qaSurfaceProbe',{'seed':true});
      for(final twelve in [false,true,false,true]) {
        await model.prefs({'clock12':twelve});
        var surfaces=await backend.invoke('qaSurfaceProbe');
        // NotificationManager posts through the system service asynchronously.
        for(var i=0;i<20 && surfaces.containsKey('notification') && RegExp(r'\b(AM|PM)\b').hasMatch(surfaces['notification'] as String)!=twelve;i++) {
          await Future<void>.delayed(const Duration(milliseconds:100));
          surfaces=await backend.invoke('qaSurfaceProbe');
        }
        final texts=surfaces.entries.where((e)=>e.value is String && (e.key.startsWith('widget')||e.key=='notification'||e.key=='notificationExpanded'));
        expect(texts.length,greaterThanOrEqualTo(3));
        for(final text in texts)expect(RegExp(r'\b(AM|PM)\b').hasMatch(text.value as String),twelve,reason:text.key);
        if(surfaces.containsKey('notification'))expect(surfaces['onlyAlertOnce'],true);
        expect(number(surfaces['chimeDurationMs']),inInclusiveRange(900,1200),reason:'The packaged chime must decode on this Android version.');
        expect(surfaces['notificationChannel'],'updates_pixel_v1');
        if(cleanup)expect(surfaces['chimeSound'],endsWith('/raw/abc_chime'));
      }
    }
    await tap(find.byKey(const ValueKey('theme-relationship')));
    await backend.invoke('preferences', {'dark': true});
    await model.refresh();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text(model.copy['appearance']).first);
    await tester.pumpAndSettle();
    await binding.takeScreenshot('abc-appearance-dark');
    await backend.invoke('preferences', {'dark': false});
    await model.refresh();
    await tester.pumpAndSettle();
    await binding.takeScreenshot('abc-appearance-light');
    await tap(find.text('Beranda').last);
    await tester.ensureVisible(find.byKey(const ValueKey('greeting')));
    await tester.pumpAndSettle();
    await binding.takeScreenshot('abc-relationship-home');
    await backend.invoke('preferences', {'dark': true});
    await model.refresh();
    await tester.pumpAndSettle();
    await binding.takeScreenshot('abc-relationship-dark-home');
    await backend.invoke('preferences', {'dark': false});
    await model.refresh();
    await tester.pumpAndSettle();
    await tap(find.text('Pengaturan').last);
    await tester.ensureVisible(find.text(model.copy['settings']).first);
    await tester.pumpAndSettle();
    await binding.takeScreenshot('abc-settings');
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
    expect(restored.events.any((e) => e['label'] == expectedMeal), true);
    restored.dispose();
    await backend.invoke('preferences', {
      'language': 'id',
      'clock12': false,
      'dark': false,
      'relationship': false
    });
    if(cleanup) {
      final seeded=await backend.invoke('qaCleanupProbe',{'seed':true});
      expect(seeded['secretsClear'],false);expect(seeded['filesClear'],false);
      await backend.invoke('prepareUninstall');
      await Future<void>.delayed(const Duration(milliseconds:500));
      final cleaned=await backend.invoke('qaCleanupProbe');
      for(final check in cleaned.entries)expect(check.value,true,reason:check.key);
      final empty=await backend.invoke('snapshot');
      expect(empty['role'],'');expect(empty['pending'],0);
      expect((empty['state'] as Map)['events'],isEmpty);
      expect((empty['profile'] as Map)['nickname']??'','');
      expect((empty['profile'] as Map)['clock12']??false,false);
      await expectLater(backend.invoke('pairCode'),throwsA(isA<PlatformException>()));
      debugPrint('QA PASS: app files, preferences, queue, history, pairing secrets and notifications cleared.');
    }
    binding.reportData ??= <String,dynamic>{};
    binding.reportData!['nativeCompleted']=true;
    binding.reportData!['cleanupVerified']=cleanup;
    debugPrint('QA PASS: native UI, preferences, history and screenshots completed.');
  });
}
