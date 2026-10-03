import 'package:abc/main.dart';
import 'package:abc/model.dart';
import 'package:abc/pixels.dart';
import 'package:abc/strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeBackend implements Backend {
  final Map<String, dynamic> data;
  final List<String> calls = [];
  FakeBackend(
      {String language = 'id',
      String nickname = 'Cuki',
      String role = 'sender',
      bool dark = false,
      bool together = false,
      bool gps = true})
      : data = {
          'profile': {
            'nickname': nickname,
            'language': language,
            'dark': dark,
            'relationship': together,
            'clock12': false
          },
          'role': role,
          'enabled': true,
          'platform': 'android',
          'connection': 'sent',
          'pending': 0,
          'mealsToday': [false, false, false],
          'zone': {
            'id': 'Asia/Jakarta',
            'short': 'WIB',
            'country': 'Indonesia'
          },
          'state': {
            'name': 'Cuki',
            'outside': 'Keluar',
            'home': 'Kost',
            'meal': 'Makan',
            'zone': 'Asia/Jakarta',
            'windows': [5, 10, 10, 15, 17, 22],
            'location': 'home',
            'locationAt': 1704103200000,
            'homeAt': 1704103200000,
            'events': [
              {
                'kind': 'home',
                'at': 1704103200000,
                'label': 'Di kost',
                'zone': 'Asia/Jakarta',
                'originInfo': {
                  'short': 'WIB',
                  'country': 'Indonesia',
                  'offsetMinutes': 420
                },
                if (gps)
                  'gps': {
                    'lat': -7.7956,
                    'lon': 110.3695,
                    'accuracy': 12,
                    'at': 1704103200000,
                    'zone': 'Asia/Jakarta'
                  }
              },
              {
                'kind': 'meal',
                'at': 1704103100000,
                'label': 'Sarapan',
                'zone': 'Asia/Jakarta',
                'gpsCaptured': true
              },
              {
                'kind': 'outside',
                'at': 1704103000000,
                'label': 'Keluar',
                'zone': 'Asia/Jakarta'
              }
            ]
          }
        };
  @override
  Future<Map<String, dynamic>> invoke(String name,
      [Map<String, dynamic> args = const {}]) async {
    calls.add(name);
    if (name == 'snapshot') return data;
    if (name == 'preferences') {
      for (final entry in args.entries) {
        data['profile'][entry.key] = entry.value;
      }
    }
    if (name == 'setupSender') data['role'] = 'sender';
    if (name == 'record') {
      final s = data['state'] as Map;
      s['events'] = [
        {
          'kind': args['kind'],
          'at': DateTime.now().millisecondsSinceEpoch,
          'label':
              args['kind'] == 'meal' ? args['category'] ?? 'Makan' : 'Keluar',
          'zone': 'Asia/Jakarta'
        },
        ...s['events'] as List
      ];
    }
    return {'snapshot': data};
  }
}

Future<AppModel> show(WidgetTester tester, FakeBackend backend,
    {Size size = const Size(400, 900), double scale = 1}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  final model = AppModel(backend);
  await tester.pumpWidget(AbcApp(model: model));
  await tester.pumpAndSettle();
  return model;
}

Future<void> close(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pumpAndSettle();
}

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  test('24-hour and AM/PM boundaries, minutes and origin offsets', () {
    for (final pair in {
      0: '12.05 AM',
      1: '1.05 AM',
      11: '11.05 AM',
      12: '12.05 PM',
      13: '1.05 PM',
      23: '11.05 PM'
    }.entries) {
      expect(clockDigits(DateTime(2026, 1, 1, pair.key, 5), true), pair.value);
    }
    expect(clockDigits(DateTime(2026, 1, 1, 0, 5), false), '00.05');
    final instant = DateTime.utc(2026, 1, 1, 5).millisecondsSinceEpoch;
    expect(
        formatClock(instant, zone: {
          'offsetMinutes': 420,
          'short': 'WIB',
          'country': 'Indonesia'
        }),
        '12.00 WIB - Indonesia');
    expect(
        formatClock(instant, clock12: true, zone: {
          'offsetMinutes': 60,
          'short': 'CET',
          'country': 'Deutschland'
        }),
        '6.00 AM CET - Deutschland');
    expect(formatClock(instant, zone: {'offsetMinutes': 120, 'short': 'CEST'}),
        '07.00 CEST');
  });
  test('nickname rejects whitespace, control characters and excessive length',
      () {
    expect(validNickname(' Cuki '), true);
    for (final name in ['', '  ', 'a\nb', 'a\u007fb', 'x' * 25]) {
      expect(validNickname(name), false);
    }
  });
  test('scene follows local time independently of light and dark colors', () {
    expect(dayPhase(DateTime(2026, 1, 1, 4)), 3);
    expect(dayPhase(DateTime(2026, 1, 1, 5)), 0);
    expect(dayPhase(DateTime(2026, 1, 1, 11)), 1);
    expect(dayPhase(DateTime(2026, 1, 1, 15)), 2);
    expect(dayPhase(DateTime(2026, 1, 1, 18)), 3);
    expect(const Palette(false, true).bg, const Color(0xFFFFF5F7));
    expect(const Palette(true, true).bg, const Color(0xFF211A24));
  });
  test('only three languages and custom labels retain their spelling', () {
    expect(languages.keys.toList(), ['id', 'en', 'de']);
    expect(Copy('de').label('Sarapan'), 'Frühstück');
    expect(Copy('en').label('My place'), 'My place');
  });
  testWidgets('nickname is required before pairing and appears in greeting',
      (tester) async {
    final b = FakeBackend(nickname: '', role: '');
    await show(tester, b);
    await tapVisible(tester, find.byKey(const ValueKey('onboarding-continue')));
    expect(find.text(Copy('id')['nameError']), findsOneWidget);
    expect(b.calls.contains('preferences'), false);
    await tester.enterText(
        find.byKey(const ValueKey('nickname-input')), '  Cuki  ');
    await tapVisible(tester, find.byKey(const ValueKey('onboarding-continue')));
    expect(b.data['profile']['nickname'], 'Cuki', reason: b.calls.join(','));
    expect(find.text('Hai, Cuki'), findsOneWidget);
    await close(tester);
  });
  testWidgets(
      'status only sends after explicit confirmation; cancel preserves history',
      (tester) async {
    final b = FakeBackend();
    await show(tester, b);
    await tapVisible(tester, find.byKey(const ValueKey('status-outside')));
    expect(b.calls.contains('record'), false);
    await tapVisible(tester, find.byKey(const ValueKey('cancel-status')));
    expect(b.calls.contains('record'), false);
    await tapVisible(tester, find.byKey(const ValueKey('status-outside')));
    await tapVisible(tester, find.byKey(const ValueKey('confirm-status')));
    expect(b.calls.where((s) => s == 'record').length, 1);
    await close(tester);
  });
  testWidgets('daily meal control works and chooses the selected category',
      (tester) async {
    final b = FakeBackend();
    await show(tester, b);
    await tapVisible(tester, find.byKey(const ValueKey('meal-0')));
    expect(find.byKey(const ValueKey('confirm-status')), findsOneWidget);
    expect(b.calls.contains('record'), false);
    await tapVisible(tester, find.byKey(const ValueKey('confirm-status')));
    expect(b.data['state']['events'][0]['label'], 'Sarapan');
    await close(tester);
  });
  testWidgets(
      'details show event GPS, original time and the distinction when GPS is pruned',
      (tester) async {
    final b = FakeBackend();
    await show(tester, b);
    await tapVisible(tester, find.text('Riwayat').last);
    await tapVisible(tester, find.byKey(const ValueKey('detail-0')));
    expect(find.text('-7.795600, 110.369500'), findsOneWidget);
    expect(find.textContaining('±12'), findsOneWidget);
    expect(find.text(Copy('id')['senderTime']), findsOneWidget);
    await tester.tap(find.byTooltip(Copy('id')['close']));
    await tester.pumpAndSettle();
    await tapVisible(tester, find.byKey(const ValueKey('detail-1')));
    expect(find.text(Copy('id')['eventGpsExpired']), findsOneWidget);
    expect(find.text('-7.79560, 110.36950'), findsNothing);
    await tester.tap(find.byTooltip(Copy('id')['close']));
    await tester.pumpAndSettle();
    await tapVisible(tester, find.byKey(const ValueKey('detail-2')));
    expect(find.text(Copy('id')['eventNoGps']), findsOneWidget);
    await close(tester);
  });
  testWidgets(
      'clock setting applies immediately and language options are limited',
      (tester) async {
    final b = FakeBackend();
    await show(tester, b);
    await tapVisible(tester, find.text('Pengaturan').last);
    await tapVisible(tester, find.text(Copy('id')['timeFormat']));
    await tapVisible(tester, find.byKey(const ValueKey('clock-12')));
    expect(b.data['profile']['clock12'], true, reason: b.calls.join(','));
    await tapVisible(tester, find.text(Copy('id')['language']));
    expect(find.byKey(const ValueKey('language-de')), findsOneWidget);
    await tapVisible(tester, find.byKey(const ValueKey('language-de')));
    expect(find.text(Copy('de')['settings']), findsWidgets);
    expect(b.data['profile']['language'], 'de');
    await close(tester);
  });
  for (final lang in languages.keys) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('$lang at font scale $scale has no layout errors',
          (tester) async {
        final b = FakeBackend(language: lang, dark: true, together: true);
        await show(tester, b, size: const Size(360, 800), scale: scale);
        expect(tester.takeException(), isNull);
        await tapVisible(tester, find.text(Copy(lang)['history']).last);
        expect(tester.takeException(), isNull);
        await tapVisible(tester, find.byKey(const ValueKey('detail-0')));
        expect(tester.takeException(), isNull);
        await tester.tap(find.byTooltip(Copy(lang)['close']));
        await tester.pumpAndSettle();
        await tapVisible(tester, find.text(Copy(lang)['settings']).last);
        await tapVisible(tester, find.byKey(const ValueKey('theme-default')));
        expect(tester.takeException(), isNull);
        await close(tester);
      });
    }
  }
}
