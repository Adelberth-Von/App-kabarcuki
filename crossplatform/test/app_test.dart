import 'dart:async';
import 'dart:convert';
import 'package:abc/main.dart';
import 'package:abc/model.dart';
import 'package:abc/pixels.dart';
import 'package:abc/strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeBackend extends Backend {
  final updates = StreamController<void>.broadcast();
  @override
  Stream<void> get changes => updates.stream;
  final Map<String, dynamic> data;
  final List<String> calls = [];
  Map<String, dynamic> lastArguments = {};
  FakeBackend({
    String language = 'id',
    String nickname = 'Cuki',
    String role = 'sender',
    bool dark = false,
    bool together = false,
    bool gps = true,
  }) : data = {
         'profile': {
           'nickname': nickname,
           'language': language,
           'dark': dark,
           'relationship': together,
           'clock12': false,
           'animations': false,
         },
         'role': together ? 'duplex' : role,
         'mode': together ? 'seirama' : 'oneWay',
         'reciprocity': together ? 'active' : 'none',
         'enabled': true,
         'platform': 'android',
         'connection': 'sent',
         'pending': 0,
         'mealsToday': [false, false, false],
         'zone': {'id': 'Asia/Jakarta', 'short': 'WIB', 'country': 'Indonesia'},
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
                 'offsetMinutes': 420,
               },
               if (gps)
                 'gps': {
                   'lat': -7.7956,
                   'lon': 110.3695,
                   'accuracy': 12,
                   'at': 1704103200000,
                   'zone': 'Asia/Jakarta',
                   'city': 'Yogyakarta',
                   'place': 'Gondomanan',
                 },
             },
             {
               'kind': 'meal',
               'at': 1704103100000,
               'label': 'Sarapan',
               'zone': 'Asia/Jakarta',
               'gpsCaptured': true,
             },
             {
               'kind': 'outside',
               'at': 1704103000000,
               'label': 'Keluar',
               'zone': 'Asia/Jakarta',
             },
           ],
         },
       };
  @override
  Future<Map<String, dynamic>> invoke(
    String name, [
    Map<String, dynamic> args = const {},
  ]) async {
    calls.add(name);
    lastArguments = args;
    if (name == 'pairCode')
      return {
        'code': data['mode'] == 'seirama'
            ? 'KB2.test-only-no-real-capability'
            : 'KB1.test-only-no-real-capability',
      };
    if (name == 'snapshot') return data;
    if (name == 'preferences') {
      for (final entry in args.entries) {
        data['profile'][entry.key] = entry.value;
      }
    }
    if (name == 'setupSender') data['role'] = 'sender';
    if (name == 'enableSeirama') {
      if (args['confirmed'] != true)
        throw PlatformException(code: 'consent_required');
      data['originalRole'] = data['role'];
      if (data['role'] == 'receiver') {
        data['peerState'] = jsonDecode(jsonEncode(data['state']));
        data['state'] = {
          'name': data['profile']['nickname'],
          'outside': 'Keluar',
          'home': 'Kost',
          'meal': 'Makan',
          'events': <dynamic>[],
        };
      }
      data['mode'] = 'seirama';
      data['role'] = 'duplex';
      data['reciprocity'] = 'unlinked';
      data['profile']['relationship'] = false;
    }
    if (name == 'joinSeirama') {
      if (args['confirmed'] != true)
        throw PlatformException(code: 'consent_required');
      data['reciprocity'] = 'waiting';
    }
    if (name == 'disableSeirama') {
      if (args['confirmed'] != true)
        throw PlatformException(code: 'consent_required');
      data['role'] = data['originalRole'] ?? 'sender';
      data['mode'] = 'oneWay';
      data['reciprocity'] = 'none';
      data.remove('peerState');
    }
    if (name == 'prepareUninstall') {
      data['profile'] = <String, dynamic>{};
      data['role'] = '';
      data['state'] = <String, dynamic>{'events': <dynamic>[]};
    }
    if (name == 'record') {
      final s = data['state'] as Map;
      s['events'] = [
        {
          'kind': args['kind'],
          'at': DateTime.now().millisecondsSinceEpoch,
          'label': args['kind'] == 'meal'
              ? (AppModel(this)..snapshot = data).mealNow()
              : 'Keluar',
          'zone': 'Asia/Jakarta',
        },
        ...s['events'] as List,
      ];
    }
    return {'snapshot': data};
  }
}

Future<AppModel> show(
  WidgetTester tester,
  FakeBackend backend, {
  Size size = const Size(400, 900),
  double scale = 1,
}) async {
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
  testWidgets(
    'native updates coalesce, idle has no polling and disposal stops listening',
    (tester) async {
      final b = FakeBackend();
      final m = AppModel(b);
      await m.init();
      await tester.pump(const Duration(minutes: 1));
      expect(b.calls, ['snapshot']);
      b.data['state']['location'] = 'outside';
      for (var i = 0; i < 10; i++) {
        b.updates.add(null);
      }
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 81));
      expect(b.calls.where((c) => c == 'snapshot').length, 2);
      expect(m.state['location'], 'outside');
      m.stopObserving();
      b.updates.add(null);
      await tester.pump(const Duration(seconds: 6));
      expect(b.calls.length, 2);
      m.startObserving();
      b.updates.add(null);
      await tester.pump();
      m.dispose();
      await tester.pump(const Duration(seconds: 6));
      expect(b.calls.length, 2);
      await b.updates.close();
    },
  );
  testWidgets(
    'pixel motion repaints at twelve fps and pauses for preferences, reduced motion and lifecycle',
    (tester) async {
      final key = GlobalKey<PixelSkyState>();
      Widget scene({
        bool animate = true,
        bool reduce = false,
        bool enabled = true,
      }) => MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            size: const Size(800, 600),
            disableAnimations: reduce,
          ),
          child: TickerMode(
            enabled: enabled,
            child: Center(
              child: PixelSky(key: key, animate: animate),
            ),
          ),
        ),
      );
      await tester.pumpWidget(scene());
      final initial = key.currentState!.frame;
      await tester.pump(const Duration(seconds: 1));
      expect(
        key.currentState!.frame,
        (initial + 12) % PixelSkyState.frameCount,
      );
      for (final w in [
        scene(animate: false),
        scene(reduce: true),
        scene(enabled: false),
      ]) {
        await tester.pumpWidget(w);
        final at = key.currentState!.frame;
        await tester.pump(const Duration(seconds: 1));
        expect(key.currentState!.frame, at);
      }
      await tester.pumpWidget(scene());
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      final paused = key.currentState!.frame;
      await tester.pump(const Duration(seconds: 1));
      expect(key.currentState!.frame, paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump(const Duration(milliseconds: 83));
      expect(key.currentState!.frame, (paused + 1) % PixelSkyState.frameCount);
      await close(tester);
    },
  );
  testWidgets('pixel motion stops outside the viewport and under a dialog', (
    tester,
  ) async {
    final key = GlobalKey<PixelSkyState>();
    final scroll = ScrollController();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => SingleChildScrollView(
              controller: scroll,
              child: Column(
                children: [
                  PixelSky(key: key, animate: true),
                  TextButton(
                    onPressed: () => showDialog<void>(
                      context: context,
                      builder: (_) =>
                          const AlertDialog(content: Text('Covered')),
                    ),
                    child: const Text('Open'),
                  ),
                  const SizedBox(height: 2000),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pump(const Duration(milliseconds: 300));
    final covered = key.currentState!.frame;
    await tester.pump(const Duration(seconds: 1));
    expect(key.currentState!.frame, covered);
    await tester.tapAt(const Offset(5, 5));
    await tester.pump(const Duration(milliseconds: 300));
    scroll.jumpTo(1000);
    await tester.pump();
    final hidden = key.currentState!.frame;
    await tester.pump(const Duration(seconds: 1));
    expect(key.currentState!.frame, hidden);
    scroll.jumpTo(0);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 83));
    expect(key.currentState!.frame, (hidden + 1) % PixelSkyState.frameCount);
    await close(tester);
    scroll.dispose();
  });
  testWidgets(
    'system battery saver freezes the home scene and its preference persists',
    (tester) async {
      final b = FakeBackend();
      final m = await show(tester, b);
      await m.prefs({'animations': true});
      await tester.pump();
      final sky = tester.state<PixelSkyState>(find.byType(PixelSky).first);
      b.data['energySaver'] = true;
      b.updates.add(null);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      final at = sky.frame;
      await tester.pump(const Duration(seconds: 1));
      expect(sky.frame, at);
      b.data['energySaver'] = false;
      b.updates.add(null);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      final resumed = sky.frame;
      await tester.pump(const Duration(milliseconds: 83));
      expect(sky.frame, (resumed + 1) % PixelSkyState.frameCount);
      await tester.tap(find.text(m.copy['settings']).last);
      await tester.pumpAndSettle();
      await tapVisible(tester, find.byKey(const ValueKey('pixel-animations')));
      expect(m.animations, false);
      expect(b.data['profile']['animations'], false);
      await close(tester);
      await b.updates.close();
    },
  );
  testWidgets(
    'all status, meal windows and open detail timestamps switch both ways',
    (tester) async {
      final b = FakeBackend();
      final at = 1704103200000;
      b.data['state'] = Map<String, dynamic>.from(b.data['state'] as Map);
      b.data['state'].addAll({
        'mealAt': at,
        'breakfastAt': at,
        'lunchAt': at,
        'dinnerAt': at,
        'gps': b.data['state']['events'][0]['gps'],
      });
      b.data['mealsToday'] = [true, true, true];
      final m = await show(tester, b);
      expect(find.textContaining('05.00 – 10.00'), findsNothing);
      await m.prefs({'clock12': true});
      await tester.pumpAndSettle();
      expect(find.textContaining('AM'), findsWidgets);
      // Empty meals use schedule ranges rather than saved timestamps.
      b.data['state']['breakfastAt'] = 0;
      b.data['mealsToday'] = [false, true, true];
      await m.refresh();
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const ValueKey('meal-0')));
      await tester.pumpAndSettle();
      expect(find.textContaining('5.00 AM – 10.00 AM'), findsOneWidget);
      await tapVisible(tester, find.text(m.copy['history']).last);
      await tapVisible(tester, find.byKey(const ValueKey('detail-0')));
      final utc24 = m.stamp(
        at,
        inZone: const {'offsetMinutes': 0, 'short': 'UTC'},
      );
      expect(find.text(utc24), findsOneWidget);
      await m.prefs({'clock12': false});
      await tester.pumpAndSettle();
      expect(find.textContaining(' AM'), findsNothing);
      expect(find.textContaining(' PM'), findsNothing);
      expect(
        find.text(
          m.stamp(at, inZone: const {'offsetMinutes': 0, 'short': 'UTC'}),
        ),
        findsOneWidget,
      );
      await m.prefs({'clock12': true});
      await tester.pumpAndSettle();
      expect(find.textContaining(' AM'), findsWidgets);
      expect(find.text(utc24), findsOneWidget);
      await close(tester);
      await b.updates.close();
    },
  );
  testWidgets(
    'cancel removal preserves data; confirm cleans before the system uninstall request',
    (tester) async {
      final b = FakeBackend();
      await show(tester, b);
      await tapVisible(tester, find.text(Copy('id')['settings']).last);
      await tapVisible(
        tester,
        find.byKey(const ValueKey('remove-application')),
      );
      await tapVisible(tester, find.text(Copy('id')['cancel']));
      expect(b.calls.contains('prepareUninstall'), false);
      expect(b.data['profile']['nickname'], 'Cuki');
      await tapVisible(
        tester,
        find.byKey(const ValueKey('remove-application')),
      );
      await tapVisible(tester, find.text(Copy('id')['continue']));
      expect(
        b.calls.indexOf('prepareUninstall'),
        lessThan(b.calls.indexOf('uninstall')),
      );
      expect(b.data['role'], '');
      expect(b.data['state']['events'], isEmpty);
      expect(b.data['profile'], isEmpty);
      expect(find.byKey(const ValueKey('nickname-input')), findsOneWidget);
      await close(tester);
      await b.updates.close();
    },
  );
  test('24-hour and AM/PM boundaries, minutes and origin offsets', () {
    for (final pair in {
      0: '12.05 AM',
      1: '1.05 AM',
      11: '11.05 AM',
      12: '12.05 PM',
      13: '1.05 PM',
      23: '11.05 PM',
    }.entries) {
      expect(clockDigits(DateTime(2026, 1, 1, pair.key, 5), true), pair.value);
    }
    expect(clockDigits(DateTime(2026, 1, 1, 0, 5), false), '00.05');
    final instant = DateTime.utc(2026, 1, 1, 5).millisecondsSinceEpoch;
    expect(
      formatClock(
        instant,
        zone: {'offsetMinutes': 420, 'short': 'WIB', 'country': 'Indonesia'},
      ),
      '12.00 WIB - Indonesia',
    );
    expect(
      formatClock(
        instant,
        clock12: true,
        zone: {'offsetMinutes': 60, 'short': 'CET', 'country': 'Deutschland'},
      ),
      '6.00 AM CET - Deutschland',
    );
    expect(
      formatClock(instant, zone: {'offsetMinutes': 120, 'short': 'CEST'}),
      '07.00 CEST',
    );
  });
  test(
    'nickname rejects whitespace, control characters and excessive length',
    () {
      expect(validNickname(' Cuki '), true);
      for (final name in ['', '  ', 'a\nb', 'a\u007fb', 'x' * 25]) {
        expect(validNickname(name), false);
      }
    },
  );
  test('scene follows local time independently of light and dark colors', () {
    expect(dayPhase(DateTime(2026, 1, 1, 4)), 3);
    expect(dayPhase(DateTime(2026, 1, 1, 5)), 0);
    expect(dayPhase(DateTime(2026, 1, 1, 11)), 1);
    expect(dayPhase(DateTime(2026, 1, 1, 15)), 2);
    expect(dayPhase(DateTime(2026, 1, 1, 18)), 3);
    expect(const Palette(false, true).bg, const Color(0xFFFCF2EE));
    expect(const Palette(true, true).bg, const Color(0xFF242136));
  });
  test('only three languages and custom labels retain their spelling', () {
    expect(languages.keys.toList(), ['id', 'en', 'de']);
    expect(Copy('de').label('Sarapan'), 'Frühstück');
    expect(Copy('en').label('My place'), 'My place');
  });
  testWidgets('nickname is required before pairing and appears in greeting', (
    tester,
  ) async {
    final b = FakeBackend(nickname: '', role: '');
    await show(tester, b);
    await tapVisible(tester, find.byKey(const ValueKey('onboarding-continue')));
    expect(find.text(Copy('id')['nameError']), findsOneWidget);
    expect(b.calls.contains('preferences'), false);
    await tester.enterText(
      find.byKey(const ValueKey('nickname-input')),
      '  Cuki  ',
    );
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
    },
  );
  testWidgets('repeated widget actions keep one confirmation and one update', (
    tester,
  ) async {
    final b = FakeBackend();
    final model = await show(tester, b);
    await tapVisible(tester, find.byKey(const ValueKey('status-outside')));
    model.snapshot['quickAction'] = 'meal';
    model.notifyListeners();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('confirm-status')), findsOneWidget);
    await tapVisible(tester, find.byKey(const ValueKey('confirm-status')));
    expect(b.calls.where((s) => s == 'record').length, 1);
    expect(b.lastArguments['kind'], 'outside');
    await close(tester);
  });
  testWidgets(
    'daily meal control follows local schedule instead of tapped category',
    (tester) async {
      final b = FakeBackend();
      await show(tester, b);
      await tapVisible(tester, find.byKey(const ValueKey('meal-0')));
      expect(find.byKey(const ValueKey('confirm-status')), findsOneWidget);
      expect(b.calls.contains('record'), false);
      await tapVisible(tester, find.byKey(const ValueKey('confirm-status')));
      expect(
        b.data['state']['events'][0]['label'],
        (AppModel(b)..snapshot = b.data).mealNow(),
      );
      await close(tester);
    },
  );
  testWidgets(
    'details show event GPS, original time and the distinction when GPS is pruned',
    (tester) async {
      final b = FakeBackend();
      await show(tester, b);
      await tapVisible(tester, find.text('Riwayat').last);
      await tapVisible(tester, find.byKey(const ValueKey('detail-0')));
      expect(find.text('-7.795600, 110.369500'), findsNothing);
      expect(
        find.byWidgetPredicate(
          (w) => w is SelectableText && w.data == 'Yogyakarta',
        ),
        findsOneWidget,
      );
      expect(find.text('Gondomanan'), findsOneWidget);
      expect(find.textContaining('±12'), findsOneWidget);
      expect(find.text(Copy('id')['senderTime']), findsOneWidget);
      await tapVisible(tester, find.byKey(const ValueKey('open-map')));
      expect(b.lastArguments['lat'], -7.7956);
      expect(b.lastArguments['lon'], 110.3695);
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
    },
  );
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
    },
  );
  testWidgets(
    'Seirama requires confirmation and keeps the existing own history',
    (tester) async {
      final b = FakeBackend();
      final before = jsonEncode(b.data['state']);
      await show(tester, b);
      await tapVisible(tester, find.text(Copy('id')['settings']).last);
      await tapVisible(tester, find.byKey(const ValueKey('mode-seirama')));
      expect(b.calls.contains('enableSeirama'), false);
      await tapVisible(tester, find.byKey(const ValueKey('cancel-mode')));
      expect(b.data['role'], 'sender');
      expect(jsonEncode(b.data['state']), before);
      await tapVisible(tester, find.byKey(const ValueKey('mode-seirama')));
      await tapVisible(tester, find.byKey(const ValueKey('confirm-mode')));
      expect(b.data['role'], 'duplex');
      expect(b.data['mode'], 'seirama');
      expect(jsonEncode(b.data['state']), before);
      expect(find.byKey(const ValueKey('seirama-own-code')), findsOneWidget);
      await tester.tap(find.byTooltip(Copy('id')['close']));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('status-outside')), findsOneWidget);
      await close(tester);
    },
  );
  testWidgets(
    'legacy Seirama appearance asks for consent before creating a sharing mode',
    (tester) async {
      final b = FakeBackend();
      b.data['profile']['relationship'] = true;
      await show(tester, b);
      expect(find.byKey(const ValueKey('confirm-mode')), findsOneWidget);
      expect(b.calls.contains('enableSeirama'), false);
      await tapVisible(tester, find.byKey(const ValueKey('cancel-mode')));
      expect(b.data['role'], 'sender');
      expect(b.data['mode'], 'oneWay');
      expect(b.calls.contains('enableSeirama'), false);
      await close(tester);
    },
  );
  testWidgets(
    'two personal stories never overwrite and peer history follows clock preferences',
    (tester) async {
      final b = FakeBackend(together: true);
      final other =
          jsonDecode(jsonEncode(b.data['state'])) as Map<String, dynamic>;
      other.addAll({
        'name': 'Mira',
        'revision': 1,
        'location': 'outside',
        'events': [
          {
            'kind': 'meal',
            'at': 1704103300000,
            'label': 'Makan malam',
            'zone': 'Europe/Berlin',
            'originInfo': {
              'offsetMinutes': 60,
              'short': 'CET',
              'country': 'Deutschland',
            },
          },
        ],
      });
      b.data['peerState'] = other;
      b.data['peerLocalTimes'] = {
        '1704103300000': {
          'offsetMinutes': 420,
          'short': 'WIB',
          'country': 'Indonesia',
        },
      };
      b.data['state']['revision'] = 99;
      final peerBefore = jsonEncode(other);
      final model = await show(tester, b);
      await tapVisible(tester, find.byKey(const ValueKey('status-home')));
      await tapVisible(tester, find.byKey(const ValueKey('confirm-status')));
      expect(jsonEncode(b.data['peerState']), peerBefore);
      await tapVisible(tester, find.text(Copy('id')['history']).last);
      await tapVisible(tester, find.byKey(const ValueKey('history-peer')));
      expect(find.text('Makan malam'), findsOneWidget);
      await tapVisible(tester, find.byKey(const ValueKey('detail-0')));
      expect(find.text('Kabar dari Mira'), findsOneWidget);
      await model.prefs({'clock12': true});
      await tester.pumpAndSettle();
      expect(find.textContaining(' AM'), findsWidgets);
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is SelectableText && w.data == model.peerStamp(1704103300000),
        ),
        findsOneWidget,
      );
      expect(jsonEncode(b.data['peerState']), peerBefore);
      await close(tester);
    },
  );
  testWidgets('partner connection remains reachable above the keyboard', (
    tester,
  ) async {
    final b = FakeBackend(together: true);
    await show(tester, b, size: const Size(360, 800));
    await tapVisible(tester, find.text(Copy('id')['settings']).last);
    await tapVisible(tester, find.byKey(const ValueKey('mode-seirama')));
    await tester.enterText(
      find.byKey(const ValueKey('seirama-peer-code')),
      'KB2.fixture',
    );
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();
    final connect = find.byKey(const ValueKey('join-seirama'));
    await tester.ensureVisible(connect);
    await tester.pumpAndSettle();
    expect(tester.getBottomRight(connect).dy, lessThanOrEqualTo(500));
    expect(tester.takeException(), isNull);
    await tapVisible(tester, connect);
    expect(find.text(Copy('id')['joinSeiramaTitle']), findsOneWidget);
    expect(b.calls.contains('joinSeirama'), false);
    await close(tester);
  });
  for (final lang in languages.keys) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('$lang at font scale $scale has no layout errors', (
        tester,
      ) async {
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
        await tapVisible(tester, find.byKey(const ValueKey('mode-oneway')));
        expect(tester.takeException(), isNull);
        await close(tester);
      });
    }
  }
}
