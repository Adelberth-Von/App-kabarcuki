import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'model.dart';
import 'pixels.dart';
import 'strings.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(AbcApp(model: AppModel(NativeBackend())));
}

class AbcApp extends StatefulWidget {
  final AppModel model;
  const AbcApp({super.key, required this.model});
  @override
  State<AbcApp> createState() => _AbcAppState();
}

class _AbcAppState extends State<AbcApp> with WidgetsBindingObserver {
  Timer? _clock;
  AppModel get model => widget.model;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    model.init();
    model.addListener(_startClock);
    _startClock();
  }

  void _startClock() {
    _clock?.cancel();
    if (WidgetsBinding.instance.lifecycleState != null &&
        WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    _clock = Timer(Duration(milliseconds: 60000 - now % 60000), () {
      if (!mounted) return;
      model.refresh(silent: true);
      _startClock();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      model.refresh();
      model.startObserving();
      _startClock();
    } else {
      model.stopObserving();
      _clock?.cancel();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _clock?.cancel();
    model.removeListener(_startClock);
    model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
      animation: model,
      builder: (context, _) {
        final p = Palette(model.dark, model.together);
        final scheme = ColorScheme.fromSeed(
                seedColor: p.accent,
                brightness: model.dark ? Brightness.dark : Brightness.light)
            .copyWith(
                primary: p.accent,
                onPrimary: model.dark ? p.bg : Colors.white,
                surface: p.card,
                onSurface: p.ink,
                outline: p.border);
        return MaterialApp(
            title: 'abc',
            debugShowCheckedModeBanner: false,
            locale: Locale(model.language),
            supportedLocales: const [Locale('id'), Locale('en'), Locale('de')],
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: scheme,
              scaffoldBackgroundColor: p.bg,
              fontFamily: 'sans-serif',
              textTheme: ThemeData(
                      brightness:
                          model.dark ? Brightness.dark : Brightness.light)
                  .textTheme
                  .apply(bodyColor: p.ink, displayColor: p.ink),
              navigationBarTheme: NavigationBarThemeData(
                  backgroundColor: p.card, indicatorColor: p.tint),
              inputDecorationTheme: InputDecorationTheme(
                  filled: true,
                  fillColor: p.card,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: p.border)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: p.border)),
                  contentPadding: const EdgeInsets.all(16)),
              filledButtonTheme: FilledButtonThemeData(
                  style: FilledButton.styleFrom(
                      minimumSize: const Size(48, 54),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)))),
              outlinedButtonTheme: OutlinedButtonThemeData(
                  style: OutlinedButton.styleFrom(
                      minimumSize: const Size(48, 50),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)))),
              bottomSheetTheme: BottomSheetThemeData(
                  backgroundColor: p.bg, showDragHandle: true),
            ),
            home: AnnotatedRegion<SystemUiOverlayStyle>(
                value: SystemUiOverlayStyle(
                    statusBarColor: p.bg,
                    statusBarIconBrightness:
                        model.dark ? Brightness.light : Brightness.dark,
                    statusBarBrightness:
                        model.dark ? Brightness.dark : Brightness.light,
                    systemNavigationBarColor: p.card,
                    systemNavigationBarIconBrightness:
                        model.dark ? Brightness.light : Brightness.dark),
                child: Shell(model: model)));
      });
}

class Shell extends StatefulWidget {
  final AppModel model;
  const Shell({super.key, required this.model});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  AppModel get m => widget.model;
  Copy get t => m.copy;
  Palette get p => Palette(m.dark, m.together);
  int tab = 0;
  bool receiving = false;
  final nickname = TextEditingController(), code = TextEditingController();
  String? nameError;
  @override
  void initState() {
    super.initState();
    m.addListener(_quickAction);
  }

  void _quickAction() {
    final action = m.snapshot.remove('quickAction');
    if (m.sender &&
        m.nickname.isNotEmpty &&
        ['outside', 'home', 'meal'].contains(action)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => tab = 0);
          confirmStatus(action as String);
        }
      });
    }
  }

  @override
  void dispose() {
    m.removeListener(_quickAction);
    nickname.dispose();
    code.dispose();
    super.dispose();
  }

  Text small(String value) =>
      Text(value, style: TextStyle(color: p.muted, fontSize: 13, height: 1.45));
  Widget card(Widget child,
          {EdgeInsets padding = const EdgeInsets.all(18), Color? color}) =>
      Material(
          color: color ?? p.card,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
              side: BorderSide(color: p.border)),
          clipBehavior: Clip.antiAlias,
          child: Padding(padding: padding, child: child));
  Widget page(List<Widget> children, {String storage = 'page'}) => SafeArea(
      bottom: false,
      child: SingleChildScrollView(
          key: PageStorageKey(storage),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
          child: Center(
              child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 620),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: children
                          .map((child) => Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: child))
                          .toList())))));
  Widget header(String title, String subtitle) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: const TextStyle(
                fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -.8)),
        const SizedBox(height: 6),
        small(subtitle)
      ]);
  Widget primary(String label, VoidCallback? tap, {String? key}) =>
      FilledButton(
          key: key == null ? null : ValueKey(key),
          onPressed: m.busy ? null : tap,
          child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: m.busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(label, textAlign: TextAlign.center)));
  Widget rowSetting(String title, IconData icon, VoidCallback tap,
          {String? subtitle, bool danger = false, String? key}) =>
      ListTile(
          key: key == null ? null : ValueKey(key),
          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
          leading: Icon(icon, color: danger ? Colors.redAccent : p.accent),
          title: Text(title,
              style: TextStyle(
                  color: danger ? Colors.redAccent : p.ink,
                  fontWeight: FontWeight.w600)),
          subtitle: subtitle == null ? null : small(subtitle),
          trailing: Icon(Icons.chevron_right_rounded, color: p.muted),
          onTap: m.busy ? null : tap);
  @override
  Widget build(BuildContext context) {
    if (m.loading)
      return Scaffold(
          body: Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
        const PixelIcon('brand', size: 72),
        const SizedBox(height: 16),
        const Text('abc',
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800)),
        const SizedBox(height: 20),
        CircularProgressIndicator(color: p.accent)
      ])));
    final needsName = m.nickname.isEmpty;
    return Scaffold(
        body: Column(children: [
          if (m.error != null)
            SafeArea(
                bottom: false,
                child: MaterialBanner(content: Text(t[m.error!]), actions: [
                  TextButton(
                      onPressed: () {
                        m.error = null;
                        m.refresh();
                      },
                      child: Text(t['retry']))
                ])),
          Expanded(
              child: needsName
                  ? onboarding()
                  : m.role.isEmpty
                      ? setup()
                      : tab == 0
                          ? home()
                          : tab == 1
                              ? history()
                              : settings())
        ]),
        bottomNavigationBar: needsName || m.role.isEmpty
            ? null
            : NavigationBar(
                selectedIndex: tab,
                onDestinationSelected: (value) => setState(() => tab = value),
                destinations: [
                    NavigationDestination(
                        icon: const Icon(Icons.home_outlined),
                        selectedIcon: const Icon(Icons.home_rounded),
                        label: t['home']),
                    NavigationDestination(
                        icon: const Icon(Icons.history_rounded),
                        label: t['history']),
                    NavigationDestination(
                        icon: const Icon(Icons.tune_rounded),
                        label: t['settings'])
                  ]));
  }

  Widget onboarding() => page([
        Row(children: [
          const PixelIcon('brand', size: 42),
          const SizedBox(width: 12),
          const Text('abc',
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800)),
          const Spacer(),
          languageButton()
        ]),
        ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: const SizedBox(height: 130, child: PixelSky())),
        header(t['welcome'], t['welcomeBody']),
        TextField(
            key: const ValueKey('nickname-input'),
            controller: nickname,
            maxLength: 24,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
                labelText: t['nickname'],
                hintText: t['nameHint'],
                errorText: nameError),
            onChanged: (_) {
              if (nameError != null) setState(() => nameError = null);
            },
            onSubmitted: (_) => saveWelcome()),
        primary(t['continue'], saveWelcome, key: 'onboarding-continue'),
        small(t['tagline']),
      ], storage: 'welcome');
  Future<void> saveWelcome() async {
    if (!validNickname(nickname.text)) {
      setState(() => nameError = t['nameError']);
      return;
    }
    FocusScope.of(context).unfocus();
    await m.prefs({'nickname': nickname.text.trim()});
  }

  Widget languageButton() => TextButton.icon(
      onPressed: chooseLanguage,
      icon: const Icon(Icons.language_rounded, size: 18),
      label: Text(languages[m.language]!));
  Widget setup() => page([
        Row(children: [
          const PixelIcon('brand', size: 36),
          const SizedBox(width: 10),
          const Text('abc',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
          const Spacer(),
          languageButton()
        ]),
        header(t['hello'].replaceAll('{x}', m.nickname), t['setupBody']),
        card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const PixelIcon('outside', size: 48),
          const SizedBox(height: 12),
          Text(t['sender'],
              style:
                  const TextStyle(fontSize: 21, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          small(t['senderBody']),
          const SizedBox(height: 16),
          primary(t['sender'], () => m.command('setupSender'),
              key: 'setup-sender')
        ])),
        card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.favorite_outline_rounded, color: p.accent, size: 32),
          const SizedBox(height: 12),
          Text(t['receiver'],
              style:
                  const TextStyle(fontSize: 21, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          small(t['receiverBody']),
          const SizedBox(height: 16),
          if (!receiving)
            OutlinedButton(
                onPressed: () => setState(() => receiving = true),
                child: Text(t['receiver']))
          else ...[
            TextField(
                key: const ValueKey('pair-code-input'),
                controller: code,
                minLines: 2,
                maxLines: 4,
                autocorrect: false,
                enableSuggestions: false,
                decoration: InputDecoration(
                    labelText: t['pairCode'], helperText: t['pairHint'])),
            const SizedBox(height: 12),
            primary(t['connect'],
                () => m.command('setupReceiver', {'code': code.text}),
                key: 'setup-receiver')
          ]
        ])),
      ], storage: 'setup');
  Widget home() {
    final s = m.state, now = DateTime.now();
    final phase = dayPhase(now), at = now.millisecondsSinceEpoch;
    final categories = ['Sarapan', 'Makan siang', 'Makan malam'];
    final times = [
      number(s['breakfastAt']),
      number(s['lunchAt']),
      number(s['dinnerAt'])
    ];
    final done = (m.snapshot['mealsToday'] as List? ?? [false, false, false])
        .cast<bool>();
    return page([
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          small(t[['morning', 'afternoon', 'evening', 'night'][phase]]
              .toUpperCase()),
          const SizedBox(height: 4),
          Text(t.fill('hello', m.nickname),
              key: const ValueKey('greeting'),
              style: const TextStyle(
                  fontSize: 29,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -.8))
        ])),
        const SizedBox(width: 12),
        Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: p.tint, borderRadius: BorderRadius.circular(18)),
            child: const PixelIcon('brand', size: 30))
      ]),
      if (m.busy && m.progress == 'locating')
        card(Row(children: [
          const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2)),
          const SizedBox(width: 12),
          Expanded(child: small(t['locating']))
        ])),
      Wrap(spacing: 8, runSpacing: 8, children: [
        Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
                color: p.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: p.border)),
            child: Text(m.time(at),
                key: const ValueKey('local-clock'),
                style: TextStyle(
                    color: p.muted, fontSize: 13, fontWeight: FontWeight.w600)))
      ]),
      ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            SizedBox(height: 144, child: PixelSky(
                action: m.sceneAction,
                together: m.together,
                animate: m.animations && !m.energySaver)),
            Container(
                color: p.card,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Text(t[m.sceneAction == 'idle' ? (m.together ? 'togetherLine' : 'tagline') : 'scene${m.together ? 'Together' : ''}${m.sceneAction == 'outside' ? 'Outside' : m.sceneAction == 'home' ? 'Home' : 'Meal'}'],
                    style: TextStyle(color: p.muted, fontSize: 13)))
          ])),
      if (m.sender) ...[
        Text(t['actions'],
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        LayoutBuilder(builder: (context, constraints) {
          final scale = MediaQuery.textScalerOf(context).scale(1);
          return scale > 1.6
              ? Column(
                  children: ['outside', 'home', 'meal']
                      .map((kind) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: action(kind)))
                      .toList())
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: ['outside', 'home', 'meal']
                      .map((kind) => Expanded(
                          child: Padding(
                              padding: EdgeInsets.only(
                                  right: kind == 'meal' ? 0 : 10),
                              child: action(kind))))
                      .toList());
        })
      ] else
        Text(t.fill('source', s['name'] as String? ?? ''),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        small(t['latest']),
        const SizedBox(height: 10),
        Row(children: [
          PixelIcon(s['location'] == 'outside' ? 'outside' : 'home', size: 38),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(m.locationLabel,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                small(m.stamp(number(s['locationAt'])))
              ]))
        ]),
        if (number(s['locationAt']) > 0 &&
            at - number(s['locationAt']) >= 6 * 3600000) ...[
          const SizedBox(height: 10),
          small(t['placeOld'])
        ],
        const Padding(
            padding: EdgeInsets.symmetric(vertical: 8), child: Divider()),
        summaryRow(t['lastMeal'], m.stamp(number(s['mealAt'])),
            Icons.restaurant_rounded),
        const SizedBox(height: 12),
        summaryRow(t.fill('lastHome', m.actionLabel('home')),
            m.stamp(number(s['homeAt'])), Icons.home_outlined)
      ])),
      card(Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(t['dailyMeals'],
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        small(t.fill('mealCount', '${done.where((x) => x).length}')),
        const SizedBox(height: 4),
        small(t['senderDay']),
        const SizedBox(height: 10),
        ...List.generate(3, (i) {
          final windows = (s['windows'] as List? ?? [5, 10, 10, 15, 17, 22]);
          return ListTile(
              key: ValueKey('meal-$i'),
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                  done[i]
                      ? Icons.check_circle_rounded
                      : Icons.add_circle_outline_rounded,
                  color: done[i] ? p.green : p.accent),
              title: Text(t.label(categories[i]),
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: small(done[i]
                  ? m.stamp(times[i])
                  : '${t['unrecorded']} · ${mealWindow(windows[i * 2] as num, windows[i * 2 + 1] as num)}'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: m.busy
                  ? null
                  : () {
                      if (m.sender)
                        confirmStatus('meal', category: categories[i]);
                      else {
                        final events = m.events
                            .where((e) =>
                                e['kind'] == 'meal' &&
                                e['label'] == categories[i])
                            .toList();
                        if (events.isNotEmpty)
                          eventDetails(events.first);
                        else
                          simpleInfo(t.label(categories[i]), t['unrecorded']);
                      }
                    });
        })
      ])),
      locationCard(),
      if (m.note != null) small(t[m.note!]),
      Row(children: [
        Icon(m.enabled ? Icons.circle : Icons.pause_circle_filled,
            size: 8, color: m.enabled ? p.green : p.muted),
        const SizedBox(width: 8),
        Expanded(child: small(m.connection))
      ]),
    ], storage: 'home');
  }

  Widget action(String kind) => Semantics(
      button: true,
      label: m.actionLabel(kind),
      child: Material(
          color: p.card,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: BorderSide(color: p.border)),
          child: InkWell(
              key: ValueKey('status-$kind'),
              borderRadius: BorderRadius.circular(18),
              onTap: m.busy ? null : () => confirmStatus(kind),
              child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                  child: Column(children: [
                    PixelIcon(kind, size: 38),
                    const SizedBox(height: 10),
                    Text(m.actionLabel(kind),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700))
                  ])))));
  Widget summaryRow(String label, String value, IconData icon) =>
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: p.accent, size: 18),
        const SizedBox(width: 10),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          small(value)
        ]))
      ]);
  String mealWindow(num start, num end) =>
      '${clockDigits(DateTime(2000, 1, 1, start.toInt()), m.clock12)} – ${clockDigits(DateTime(2000, 1, 1, end.toInt()), m.clock12)}';
  Future<void> confirmStatus(String kind, {String? category}) async {
    final selected = kind == 'meal' ? m.mealNow() : category;
    bool share = m.snapshot['shareLocation'] == true;
    final okay = await showDialog<bool>(
        context: context,
        builder: (context) => StatefulBuilder(
            builder: (context, update) => AlertDialog(
                    title: Text(t['confirmStatus']),
                    content: SingleChildScrollView(
                        child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          ClipRRect(borderRadius: BorderRadius.circular(16),child:SizedBox(height:100,width:280,child:PixelSky(action:kind,together:m.together,animate:m.animations && !m.energySaver))),
                          const SizedBox(height:14),
                          Row(children: [
                            PixelIcon(kind, size: 38),
                            const SizedBox(width: 12),
                            Expanded(
                                child: Text(
                                    kind == 'meal' ? t.label(selected!) : m.actionLabel(kind),
                                    style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700)))
                          ]),
                          const SizedBox(height: 12),
                          small(m.time(DateTime.now().millisecondsSinceEpoch)),
                          if (kind == 'meal') ...[
                            const SizedBox(height: 16),
                            small(t.fill('mealScheduled', t.label(selected!))),
                            const SizedBox(height: 6),
                            small(t['mealAutomatic']),
                            const SizedBox(height: 10),
                            small(t['mealKeepsPlace'])
                          ],
                          const SizedBox(height: 16),
                          SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(t['shareLocation']),
                              value: share,
                              onChanged: (value) =>
                                  update(() => share = value)),
                          small(t['locationConsent'])
                        ])),
                    actions: [
                      TextButton(
                          key: const ValueKey('cancel-status'),
                          onPressed: () => Navigator.pop(context, false),
                          child: Text(t['cancel'])),
                      FilledButton(
                          key: const ValueKey('confirm-status'),
                          onPressed: () => Navigator.pop(context, true),
                          child: Text(t['send']))
                    ])));
    if (okay == true) {
      if(share && !await ensureLocationServices())return;
      await m.command('record', {
        'kind': kind,
        'category': null,
        'shareLocation': share
      });
    }
  }

  Future<bool> ensureLocationServices() async {
    final status=await m.backend.invoke('locationServices');
    if(status['enabled']!=false)return true;
    if(!await confirm(t['enableLocation'],t['enableLocationBody']))return false;
    if(!await m.command('locationSettings'))return false;
    final after=await m.backend.invoke('locationServices');
    if(after['enabled']==true)return true;
    if(mounted)await simpleInfo(t['enableLocation'],t['enableLocationBody']);
    return false;
  }
  Widget locationCard() {
    final point = m.state['gps'] as Map?;
    return card(
        Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        Icon(Icons.location_on_outlined, color: p.accent),
        const SizedBox(width: 10),
        Expanded(
            child: Text(t['locationTitle'],
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)))
      ]),
      const SizedBox(height: 10),
      if(point == null) small(t['noLocation']) else ...[
        Text(m.place(point),style:const TextStyle(fontSize:20,fontWeight:FontWeight.w700)),
        const SizedBox(height:6),small('${t['city']} · ${m.city(point)}'),
        const SizedBox(height:6),small('${t['gpsTime']} · ${m.stamp(number(point['at']))}'),
        const SizedBox(height:6),small('${t['timeZone']} · ${point['zone'] ?? ''}'),
      ],
      if (point != null) ...[
        if (DateTime.now().millisecondsSinceEpoch - number(point['at']) >=
            900000) ...[const SizedBox(height: 6), small(t['locationOld'])],
        const SizedBox(height: 12),
        OutlinedButton(
            onPressed: () => gpsDetails(Map<String, dynamic>.from(point)),
            child: Text(t['detail']))
      ],
      if (m.sender) ...[
        const SizedBox(height: 10),
        TextButton.icon(
            onPressed: m.busy
                ? null
                : () async {
                    if (await confirm(
                        t['refreshLocation'], t['locationConsent']) && await ensureLocationServices())
                      await m.command(
                          'record', {'kind': '', 'shareLocation': true});
                  },
            icon: const Icon(Icons.my_location_rounded, size: 18),
            label: Text(t['refreshLocation']))
      ]
    ]));
  }

  Widget history() => page([
        header(t['history'], t['historyBody']),
        if (m.events.isEmpty)
          card(Column(children: [
            const PixelIcon('brand', size: 72),
            const SizedBox(height: 18),
            Text(t['emptyHistory'],
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            small(t['emptyHistoryBody'])
          ])),
        ...m.events.asMap().entries.map((entry) {
          final e = entry.value;
          return card(InkWell(
              key: ValueKey('history-${entry.key}'),
              onTap: () => eventDetails(e),
              child:
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        color: p.tint, borderRadius: BorderRadius.circular(14)),
                    child: PixelIcon(e['kind'] as String, size: 28)),
                const SizedBox(width: 14),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(t.label(e['label'] as String),
                          style: const TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 5),
                      small(m.stamp(number(e['at']))),
                      if (e['gps'] != null) ...[
                        const SizedBox(height: 6),
                        small(t['locationTitle'])
                      ]
                    ])),
                const SizedBox(width: 6),
                TextButton(
                    key: ValueKey('detail-${entry.key}'),
                    onPressed: () => eventDetails(e),
                    child: Text(t['detail']))
              ])));
        }),
      ], storage: 'history');
  Future<void> sheet(String titleKey, List<Widget> Function() contents) =>
      showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          builder: (context) => AnimatedBuilder(animation: m,
              builder: (context, _) => SizedBox(
              height: MediaQuery.sizeOf(context).height * .82,
              child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(children: [
                          Expanded(
                              child: Text(t[titleKey],
                                  style: const TextStyle(
                                      fontSize: 25,
                                      fontWeight: FontWeight.w800))),
                          IconButton(
                              tooltip: t['close'],
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.close_rounded))
                        ]),
                        const SizedBox(height: 16),
                        Expanded(
                            child: SingleChildScrollView(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: contents()
                                        .map((w) => Padding(
                                            padding: const EdgeInsets.only(
                                                bottom: 16),
                                            child: w))
                                        .toList())))
                      ])))));
  Widget detailRow(String name, String value) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        small(name),
        const SizedBox(height: 5),
        SelectableText(value,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600, height: 1.4))
      ]);
  Future<void> eventDetails(Map<String, dynamic> event) {
    final at = number(event['at']),
        origin = Map<String, dynamic>.from(event['originInfo'] as Map? ?? {});
    final point = event['gps'] as Map?;
    return sheet('detailTitle', () => [
      Row(children: [
        PixelIcon(event['kind'] as String, size: 42),
        const SizedBox(width: 14),
        Expanded(
            child: Text(t.label(event['label'] as String),
                style:
                    const TextStyle(fontSize: 23, fontWeight: FontWeight.w700)))
      ]),
      card(Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        detailRow(t['localTime'], m.stamp(at)),
        const Divider(height: 28),
        detailRow(t['senderTime'], m.stamp(at, inZone: origin)),
        const SizedBox(height: 16),
        detailRow(t['timeZone'],
            event['zone'] as String? ?? m.state['zone'] as String? ?? ''),
        const SizedBox(height: 16),
        detailRow(
            t['recorded'],
            m.stamp(at, inZone: const {'offsetMinutes': 0, 'short': 'UTC'}))
      ])),
      if (point != null)
        ...gpsContent(Map<String, dynamic>.from(point))
      else
        card(small(t[
            event['gpsCaptured'] == true ? 'eventGpsExpired' : 'eventNoGps'])),
    ]);
  }

  List<Widget> gpsContent(Map<String, dynamic> point) => [
        card(Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(t['locationTitle'],
              style:
                  const TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
          const SizedBox(height: 18),
          detailRow(t['locationTitle'], m.place(point)),
          const SizedBox(height:16),
          detailRow(t['city'], m.city(point)),
          const SizedBox(height: 16),
          detailRow(t['accuracy'], '±${number(point['accuracy'])} m'),
          const SizedBox(height: 16),
          detailRow(t['gpsTime'], m.stamp(number(point['at']))),
          const SizedBox(height: 16),
          detailRow(t['timeZone'], point['zone'] as String? ?? ''),
          const SizedBox(height: 12),
          small(t['gpsNote']),
          if (DateTime.now().millisecondsSinceEpoch - number(point['at']) >=
              900000) ...[const SizedBox(height: 8), small(t['locationOld'])]
        ])),
        primary(
            t['map'],
            () => m
                .command('openMap', {'lat': point['lat'], 'lon': point['lon']}),
            key: 'open-map'),
      ];
  Future<void> gpsDetails(Map<String, dynamic> point) =>
      sheet('locationTitle', () => gpsContent(point));
  Widget settings() => page([
        header(t['settings'], t['appearanceNote']),
        section(t['profile'], [
          rowSetting(t['editName'], Icons.person_outline_rounded, editNickname,
              subtitle: m.nickname, key: 'edit-nickname'),
          rowSetting(t['language'], Icons.language_rounded, chooseLanguage,
              subtitle: languages[m.language], key: 'language-settings'),
          rowSetting(t['timeFormat'], Icons.schedule_rounded, chooseClock,
              subtitle: t[m.clock12 ? 'clock12' : 'clock24'],
              key: 'time-format'),
        ]),
        section(t['appearance'], [
          Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [themeChoice(false), themeChoice(true)]),
          const SizedBox(height: 16),
          SegmentedButton<bool>(
              segments: [
                ButtonSegment(
                    value: false,
                    icon: const Icon(Icons.light_mode_outlined),
                    label: Text(t['light'])),
                ButtonSegment(
                    value: true,
                    icon: const Icon(Icons.dark_mode_outlined),
                    label: Text(t['dark']))
              ],
              selected: {
                m.dark
              },
              onSelectionChanged:
                  m.busy ? null : (value) => m.prefs({'dark': value.first})),
          const SizedBox(height: 12),
          small(t['daySceneNote']),
          SwitchListTile(
              key: const ValueKey('pixel-animations'),
              contentPadding: EdgeInsets.zero,
              title: Text(t['pixelAnimations']),
              subtitle: Text(t[m.energySaver ? 'motionPowerSave' : 'motionNote']),
              value: m.animations,
              onChanged: m.busy ? null : (value) => m.prefs({'animations': value})),
          const SizedBox(height: 8),
          small(t['zoneNote']),
        ]),
        section(t['family'], [
          if (m.sender) ...[
            rowSetting(t['editLabels'], Icons.edit_outlined, editLabels),
            rowSetting(
                t['schedule'], Icons.restaurant_menu_rounded, editSchedule),
            rowSetting(t['shareCode'], Icons.key_rounded, showCode)
          ],
          if (!m.sender)
            small(t.fill('source', m.state['name'] as String? ?? '')),
        ]),
        section(t['connection'], [
          small(m.connection),
          rowSetting(
              t[m.enabled ? 'pause' : 'resume'],
              m.enabled
                  ? Icons.pause_circle_outline
                  : Icons.play_circle_outline,
              () => m.command('toggleConnection')),
          rowSetting(t['notifications'], Icons.notifications_outlined,
              () => m.command('notifications'), subtitle: t['chimeNote']),
          rowSetting(t['widget'], Icons.widgets_outlined, () {
            if (m.snapshot['platform'] == 'ios')
              simpleInfo(t['widget'], t['iosWidget']);
            else
              m.command('pinWidget');
          }),
          rowSetting(t['battery'], Icons.battery_5_bar_rounded,
              () => m.command('appSettings')),
          small(t['batteryNote']),
          if (m.snapshot['platform'] == 'ios')
            rowSetting(t['pushServer'], Icons.notifications_active_outlined,
                editPushServer,
                subtitle: t['pushNote']),
        ]),
        section(t['privacy'], [
          small(t['privacyBody']),
          if (m.sender) ...[
            rowSetting(t['clearGps'], Icons.location_off_outlined,
                () => dangerAction('clearGps', 'clearGpsBody', 'clearGps'),
                danger: true),
            rowSetting(
                t['clearHistory'],
                Icons.delete_outline_rounded,
                () => dangerAction(
                    'clearHistory', 'clearHistoryBody', 'clearHistory'),
                danger: true),
            rowSetting(t['rotate'], Icons.key_off_outlined,
                () => dangerAction('rotate', 'rotateBody', 'rotate'),
                danger: true)
          ],
          rowSetting(t['disconnect'], Icons.link_off_rounded,
              () => dangerAction('disconnect', 'disconnectBody', 'disconnect'),
              danger: true),
          rowSetting(t['uninstall'], Icons.remove_circle_outline_rounded,
              removeApplication, danger: true, key: 'remove-application'),
        ]),
        small(t['version']),
      ], storage: 'settings');
  Widget section(String title, List<Widget> children) =>
      card(Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        ...children
      ]));
  Widget themeChoice(bool together) {
    final selected = m.together == together;
    return SizedBox(
        width: MediaQuery.sizeOf(context).width < 380
            ? double.infinity
            : MediaQuery.sizeOf(context).width > 620
                ? 250
                : (MediaQuery.sizeOf(context).width - 90) / 2,
        child: Material(
            color: selected ? p.tint : p.bg,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
                key:
                    ValueKey(together ? 'theme-relationship' : 'theme-default'),
                borderRadius: BorderRadius.circular(16),
                onTap:
                    m.busy ? null : () => m.prefs({'relationship': together}),
                child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: SizedBox(
                                  height: 60,
                                  child: PixelSky(together: together))),
                          const SizedBox(height: 8),
                          Text(
                              '${selected ? '✓  ' : ''}${t[together ? 'relationshipTheme' : 'defaultTheme']}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          small(t[together
                              ? 'relationshipDescription'
                              : 'defaultDescription'])
                        ])))));
  }

  Future<void> chooseLanguage() => showModalBottomSheet(
      context: context,
      useSafeArea: true,
      builder: (context) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(t['language'],
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                ...languages.entries.map((entry) => ListTile(
                    key: ValueKey('language-${entry.key}'),
                    title: Text(entry.value),
                    trailing: m.language == entry.key
                        ? Icon(Icons.check_rounded, color: p.accent)
                        : null,
                    onTap: () async {
                      Navigator.pop(context);
                      await m.prefs({'language': entry.key});
                    }))
              ])));
  Future<void> chooseClock() => showModalBottomSheet(
      context: context,
      useSafeArea: true,
      builder: (context) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(t['timeFormat'],
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                ...[false, true].map((value) => ListTile(
                    key: ValueKey(value ? 'clock-12' : 'clock-24'),
                    title: Text(t[value ? 'clock12' : 'clock24']),
                    subtitle: Text(formatClock(
                        DateTime.now().millisecondsSinceEpoch,
                        clock12: value,
                        zone: m.zone)),
                    trailing: m.clock12 == value
                        ? Icon(Icons.check_rounded, color: p.accent)
                        : null,
                    onTap: () async {
                      Navigator.pop(context);
                      await m.prefs({'clock12': value});
                    }))
              ])));
  Future<void> editNickname() async {
    final field = TextEditingController(text: m.nickname);
    String? error;
    final value = await showDialog<String>(
        context: context,
        builder: (context) => StatefulBuilder(
            builder: (context, update) => AlertDialog(
                    title: Text(t['editName']),
                    content: TextField(
                        controller: field,
                        maxLength: 24,
                        decoration: InputDecoration(
                            labelText: t['nickname'], errorText: error)),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(t['cancel'])),
                      FilledButton(
                          onPressed: () {
                            if (!validNickname(field.text)) {
                              update(() => error = t['nameError']);
                              return;
                            }
                            Navigator.pop(context, field.text.trim());
                          },
                          child: Text(t['save']))
                    ])));
    field.dispose();
    if (value != null) await m.prefs({'nickname': value});
  }

  Future<void> showCode() async {
    try {
      final result = await m.backend.invoke('pairCode');
      if (!mounted) return;
      final value = result['code'] as String;
    await sheet('shareCode', () => [
        small(t['secretCode']),
        card(SelectableText(value,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12))),
        primary(t['copy'], () async {
          await Clipboard.setData(ClipboardData(text: value));
          if (mounted)
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(t['copied'])));
        }),
        OutlinedButton(
            onPressed: () => m.command('shareCode'), child: Text(t['share']))
      ]);
    } catch (_) {
      m.error = 'error';
      m.refresh();
    }
  }

  Future<bool> confirm(String title, String body) async =>
      await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
                  title: Text(title),
                  content: SingleChildScrollView(child: Text(body)),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text(t['cancel'])),
                    FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: Text(t['continue']))
                  ])) ??
      false;
  Future<void> simpleInfo(String title, String body) => showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
              title: Text(title),
              content: Text(body),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(t['close']))
              ]));
  Future<void> dangerAction(String title, String body, String command) async {
    if (await confirm(t[title], t[body])) await m.command(command);
  }
  Future<void> removeApplication() async {
    final ios = m.snapshot['platform'] == 'ios';
    final title = t['uninstall'], body = t['iosUninstall'];
    if (!await confirm(title, t['uninstallBody'])) return;
    if (!await m.command('prepareUninstall')) return;
    if (!mounted) return;
    if (ios) {
      await simpleInfo(title, body);
    } else {
      await m.command('uninstall');
    }
  }

  Future<void> editLabels() async {
    final keys = ['name', 'outside', 'home', 'meal'];
    final fields = {
      for (final key in keys)
        key: TextEditingController(text: m.state[key] as String? ?? '')
    };
    String? error;
    final values = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => StatefulBuilder(
            builder: (context, update) => AlertDialog(
                    title: Text(t['editLabels']),
                    content: SingleChildScrollView(
                        child:
                            Column(mainAxisSize: MainAxisSize.min, children: [
                      ...keys.map((key) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: TextField(
                              controller: fields[key],
                              maxLength: 24,
                              decoration: InputDecoration(
                                  labelText: t[key == 'name'
                                      ? 'senderName'
                                      : key == 'home'
                                          ? 'homeStatus'
                                          : key],
                                  errorText: error)))),
                      small(t['sharedChange'])
                    ])),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(t['cancel'])),
                      FilledButton(
                          onPressed: () {
                            if (fields.values
                                .any((f) => !validNickname(f.text))) {
                              update(() => error = t['nameError']);
                              return;
                            }
                            Navigator.pop(context, {
                              for (final key in keys)
                                key: fields[key]!.text.trim()
                            });
                          },
                          child: Text(t['save']))
                    ])));
    for (final field in fields.values) {
      field.dispose();
    }
    if (values != null &&
        await confirm(t['confirmChange'],
            values.values.join(' · ') + '\n\n' + t['sharedChange']))
      await m.command('edit', values);
  }

  Future<void> editSchedule() async {
    final windows =
        (m.state['windows'] as List? ?? [5, 10, 10, 15, 17, 22]).cast<int>();
    final fields =
        windows.map((v) => TextEditingController(text: '$v')).toList();
    String? error;
    final values = await showDialog<List<int>>(
        context: context,
        builder: (context) => StatefulBuilder(
            builder: (context, update) => AlertDialog(
                    title: Text(t['schedule']),
                    content: SingleChildScrollView(
                        child:
                            Column(mainAxisSize: MainAxisSize.min, children: [
                      small(t['scheduleInvalid']),
                      const SizedBox(height: 16),
                      ...List.generate(
                          3,
                          (i) => Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                        t[['breakfast', 'lunch', 'dinner'][i]]),
                                    const SizedBox(height: 8),
                                    Row(children: [
                                      Expanded(
                                          child: TextField(
                                              controller: fields[i * 2],
                                              keyboardType:
                                                  TextInputType.number,
                                              decoration: const InputDecoration(
                                                  hintText: '00'))),
                                      const Padding(
                                          padding: EdgeInsets.all(10),
                                          child: Text('–')),
                                      Expanded(
                                          child: TextField(
                                              controller: fields[i * 2 + 1],
                                              keyboardType:
                                                  TextInputType.number,
                                              decoration: const InputDecoration(
                                                  hintText: '24')))
                                    ])
                                  ]))),
                      if (error != null)
                        Text(error!,
                            style: const TextStyle(color: Colors.redAccent))
                    ])),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(t['cancel'])),
                      FilledButton(
                          onPressed: () {
                            final w = fields
                                .map((f) => int.tryParse(f.text) ?? -1)
                                .toList();
                            bool valid = true;
                            for (int i = 0; i < 3; i++) {
                              if (w[i * 2] < 0 ||
                                  w[i * 2 + 1] > 24 ||
                                  w[i * 2] >= w[i * 2 + 1] ||
                                  (i > 0 && w[i * 2] < w[i * 2 - 1]))
                                valid = false;
                            }
                            if (!valid) {
                              update(() => error = t['scheduleInvalid']);
                              return;
                            }
                            Navigator.pop(context, w);
                          },
                          child: Text(t['save']))
                    ])));
    for (final field in fields) {
      field.dispose();
    }
    if (values != null &&
        await confirm(t['confirmChange'],
            values.join(' · ') + '\n\n' + t['sharedChange']))
      await m.command('edit', {'windows': values});
  }

  Future<void> editPushServer() async {
    final field = TextEditingController(
        text: m.snapshot['pushEndpoint'] as String? ?? '');
    final value = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
                title: Text(t['pushServer']),
                content: Column(mainAxisSize: MainAxisSize.min, children: [
                  small(t['pushNote']),
                  const SizedBox(height: 16),
                  TextField(
                      controller: field,
                      keyboardType: TextInputType.url,
                      decoration:
                          const InputDecoration(hintText: 'https://...'))
                ]),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(t['cancel'])),
                  FilledButton(
                      onPressed: () =>
                          Navigator.pop(context, field.text.trim()),
                      child: Text(t['save']))
                ]));
    field.dispose();
    if (value != null) await m.command('pushServer', {'url': value});
  }
}
