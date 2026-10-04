import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:pixelify_flutter/pixelify_flutter.dart';
import 'package:pixelarticons/pixelarticons.dart';
import 'app_theme.dart';
import 'cozy_ui.dart';
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
        WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed)
      return;
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
      return PixelTheme(
        accentColor: p.accent,
        pixelScale: 1,
        enableShaders: false,
        child: ShadApp(
          title: 'abc',
          debugShowCheckedModeBanner: false,
          locale: Locale(model.language),
          supportedLocales: const [Locale('id'), Locale('en'), Locale('de')],
          theme: AbcThemes.shad(dark: false, together: model.together),
          darkTheme: AbcThemes.shad(dark: true, together: model.together),
          themeMode: model.dark ? ThemeMode.dark : ThemeMode.light,
          materialThemeBuilder: (context, theme) =>
              AbcThemes.material(dark: model.dark, together: model.together),
          home: AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle(
              statusBarColor: p.bg,
              statusBarIconBrightness: model.dark
                  ? Brightness.light
                  : Brightness.dark,
              statusBarBrightness: model.dark
                  ? Brightness.dark
                  : Brightness.light,
              systemNavigationBarColor: p.card,
              systemNavigationBarIconBrightness: model.dark
                  ? Brightness.light
                  : Brightness.dark,
            ),
            child: Shell(model: model),
          ),
        ),
      );
    },
  );
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
  bool receiving = false, peerHistory = false;
  bool _migrationPrompted = false,
      _modeSheetOpen = false,
      _statusDialogOpen = false;
  bool get twoWay => m.snapshot['mode'] == 'seirama' || m.role == 'duplex';
  Map<String, dynamic> get peer =>
      Map<String, dynamic>.from(m.snapshot['peerState'] as Map? ?? {});
  bool get peerActive => m.snapshot['reciprocity'] == 'active';
  String get peerName => (peer['name'] as String? ?? '').isNotEmpty
      ? peer['name'] as String
      : t['yourPartner'];
  List<Map<String, dynamic>> get peerEvents => (peer['events'] as List? ?? [])
      .map((e) => Map<String, dynamic>.from(e as Map))
      .toList();
  final nickname = TextEditingController(), code = TextEditingController();
  String? nameError;
  @override
  void initState() {
    super.initState();
    m.addListener(_quickAction);
    // Localization delegates may finish after the first native snapshot.
    _quickAction();
  }

  void _quickAction() {
    final action = m.snapshot.remove('quickAction');
    final openPeer = m.snapshot.remove('quickPeer') == true;
    if (m.sender &&
        m.nickname.isNotEmpty &&
        ['outside', 'home', 'meal'].contains(action)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => tab = 0);
          confirmStatus(action as String);
        }
      });
    } else if (openPeer && twoWay) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) showPeer();
      });
    }
    if (!_migrationPrompted &&
        !m.loading &&
        m.role.isNotEmpty &&
        m.nickname.isNotEmpty &&
        !twoWay &&
        (m.modeUpgradeSuggested || m.profile['relationship'] == true)) {
      _migrationPrompted = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) enableSeirama(migration: true);
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
  bool get motion => m.animations && !m.energySaver;
  Widget card(
    Widget child, {
    EdgeInsets padding = const EdgeInsets.all(18),
    Color? color,
  }) => CozyCard(palette: p, padding: padding, color: color, child: child);
  Widget badge(String label, {IconData? icon, Color? color}) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: (color ?? p.accent).withValues(alpha: .10),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 14, color: color ?? p.accent),
          const SizedBox(width: 5),
        ],
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color ?? p.accent,
            ),
          ),
        ),
      ],
    ),
  );
  Widget page(List<Widget> children, {String storage = 'page'}) => SafeArea(
    bottom: false,
    child: SingleChildScrollView(
      key: PageStorageKey(storage),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(18, 24, 18, 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children
                .map(
                  (child) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: child,
                  ),
                )
                .toList(),
          ),
        ),
      ),
    ),
  );
  Widget header(String title, String subtitle) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      PixelifyText(title, size: 25),
      const SizedBox(height: 8),
      small(subtitle),
    ],
  );
  Widget primary(String label, VoidCallback? tap, {String? key}) => CozyButton(
    key: key == null ? null : ValueKey(key),
    palette: p,
    label: label,
    onPressed: tap,
    animate: motion,
    busy: m.busy,
    icon: Pixel.arrowright,
  );
  Widget rowSetting(
    String title,
    IconData icon,
    VoidCallback tap, {
    String? subtitle,
    bool danger = false,
    String? key,
  }) => CozyPress(
    enabled: !m.busy,
    animate: motion,
    child: InkWell(
      key: key == null ? null : ValueKey(key),
      borderRadius: BorderRadius.circular(10),
      onTap: m.busy ? null : tap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CozyIconTile(
              icon,
              palette: p,
              tone: danger ? p.danger : p.accent,
              size: 21,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: danger ? p.danger : p.ink,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    small(subtitle),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Pixel.chevronright, size: 18, color: p.muted),
          ],
        ),
      ),
    ),
  );
  @override
  Widget build(BuildContext context) {
    if (m.loading)
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const PixelIcon('brand', size: 72),
              const SizedBox(height: 16),
              const PixelText(
                text: 'abc',
                flickerEnabled: false,
                style: TextStyle(
                  fontFamily: 'Silkscreen',
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 20),
              CircularProgressIndicator(color: p.accent),
            ],
          ),
        ),
      );
    final needsName = m.nickname.isEmpty;
    return Scaffold(
      body: CozyBackdrop(
        palette: p,
        child: Column(
          children: [
            if (m.error != null)
              SafeArea(
                bottom: false,
                child: MaterialBanner(
                  content: Text(t[m.error!]),
                  actions: [
                    TextButton(
                      onPressed: () {
                        m.error = null;
                        m.refresh();
                      },
                      child: Text(t['retry']),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: needsName
                  ? onboarding()
                  : m.role.isEmpty
                  ? setup()
                  : tab == 0
                  ? home()
                  : tab == 1
                  ? history()
                  : settings(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: needsName || m.role.isEmpty
          ? null
          : CozyNavigation(
              palette: p,
              labels: [t['home'], t['history'], t['settings']],
              selected: tab,
              animate: motion,
              onSelected: (value) => setState(() => tab = value),
            ),
    );
  }

  Widget brandHeader() => LayoutBuilder(
    builder: (context, constraints) {
      final brand = [
        CozyIconTile(Pixel.home, palette: p, size: 23),
        const SizedBox(width: 10),
        const PixelifyText('abc', size: 26),
      ];
      if (MediaQuery.textScalerOf(context).scale(1) > 1.4) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: brand),
            const SizedBox(height: 8),
            Align(alignment: Alignment.centerRight, child: languageButton()),
          ],
        );
      }
      return Row(children: [...brand, const Spacer(), languageButton()]);
    },
  );
  Widget onboarding() => page([
    brandHeader(),
    CozyScene(
      palette: p,
      title: t['yourLittleWorld'],
      caption: t['cozyWelcome'],
      animate: motion,
    ),
    header(t['welcome'], t['welcomeBody']),
    Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PixelifyText(t['nickname'], size: 12),
        const SizedBox(height: 10),
        ShadInput(
          key: const ValueKey('nickname-input'),
          controller: nickname,
          maxLength: 24,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.done,
          leading: Icon(Pixel.user, size: 21, color: p.accent),
          placeholder: Text(t['nameHint']),
          padding: const EdgeInsets.all(16),
          decoration: cozyInputDecoration(p, error: nameError != null),
          onChanged: (_) {
            if (nameError != null) setState(() => nameError = null);
          },
          onSubmitted: (_) => saveWelcome(),
        ),
        if (nameError != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              nameError!,
              style: TextStyle(color: p.danger, fontSize: 13),
            ),
          ),
      ],
    ),
    primary(t['continue'], saveWelcome, key: 'onboarding-continue'),
    Center(child: small(t['tagline'])),
    CozyFooter(palette: p),
  ], storage: 'welcome');
  Future<void> saveWelcome() async {
    if (!validNickname(nickname.text)) {
      setState(() => nameError = t['nameError']);
      return;
    }
    FocusScope.of(context).unfocus();
    await m.prefs({'nickname': nickname.text.trim()});
  }

  Widget languageButton() => ShadButton.ghost(
    height: 0,
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
    onPressed: chooseLanguage,
    leading: Icon(Pixel.message, size: 18, color: p.accent),
    child: Text(
      languages[m.language]!,
      style: TextStyle(fontSize: 12, color: p.accent),
    ),
  );
  Widget setup() => page([
    brandHeader(),
    header(t['hello'].replaceAll('{x}', m.nickname), t['setupBody']),
    sectionTitle(t['chooseRole']),
    card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CozyIconTile(
                Pixel.messagearrowright,
                palette: p,
                tone: p.green,
                size: 30,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PixelifyText(t['sender'], size: 16),
                    const SizedBox(height: 8),
                    small(t['senderBody']),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          primary(
            t['sender'],
            () => m.command('setupSender'),
            key: 'setup-sender',
          ),
        ],
      ),
    ),
    card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CozyIconTile(Pixel.mail, palette: p, size: 30),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PixelifyText(t['receiver'], size: 16),
                    const SizedBox(height: 8),
                    small(t['receiverBody']),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (!receiving)
            CozyButton(
              palette: p,
              label: t['receiver'],
              secondary: true,
              animate: motion,
              onPressed: () => setState(() => receiving = true),
              icon: Pixel.link,
            )
          else ...[
            Text(
              t['pairCode'],
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            ShadInput(
              key: const ValueKey('pair-code-input'),
              controller: code,
              minLines: 2,
              maxLines: 4,
              autocorrect: false,
              enableSuggestions: false,
              placeholder: Text(t['pairCode']),
              decoration: cozyInputDecoration(p),
              padding: const EdgeInsets.all(14),
            ),
            const SizedBox(height: 8),
            small(t['pairHint']),
            const SizedBox(height: 14),
            primary(
              t['connect'],
              () => m.command('setupReceiver', {'code': code.text}),
              key: 'setup-receiver',
            ),
          ],
        ],
      ),
    ),
    modeSetupCard(),
    CozyFooter(palette: p),
  ], storage: 'setup');
  Widget home() {
    final now = DateTime.now(), phase = dayPhase(DateTime.now());
    return page([
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t[['morning', 'afternoon', 'evening', 'night'][phase]]
                      .toUpperCase(),
                  style: TextStyle(
                    color: p.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.25,
                  ),
                ),
                const SizedBox(height: 6),
                PixelifyText(
                  t.fill('hello', m.nickname),
                  size: 25,
                  key: const ValueKey('greeting'),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Semantics(
            button: true,
            label: t['settings'],
            child: InkWell(
              onTap: () => setState(() => tab = 2),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: p.tint,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: p.border),
                ),
                child: const PixelIcon('brand', size: 29),
              ),
            ),
          ),
        ],
      ),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: p.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: p.border),
            ),
            child: Text(
              m.time(now.millisecondsSinceEpoch),
              key: const ValueKey('local-clock'),
              style: TextStyle(
                color: p.muted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (twoWay) badge(t['seirama'], icon: Pixel.heart),
        ],
      ),
      if (twoWay && !peerActive) partnerConnectionCard(),
      CozyScene(
        palette: p,
        title: t[['morning', 'afternoon', 'evening', 'night'][phase]],
        action: m.sceneAction,
        animate: motion,
        at: now,
        caption:
            t[m.sceneAction == 'idle'
                ? (m.together ? 'togetherLine' : 'cozyWelcome')
                : 'scene${m.together ? 'Together' : ''}${m.sceneAction == 'outside'
                      ? 'Outside'
                      : m.sceneAction == 'home'
                      ? 'Home'
                      : 'Meal'}'],
      ),
      if (m.busy && m.progress == 'locating')
        card(
          Row(
            children: [
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 12),
              Expanded(child: small(t['locating'])),
            ],
          ),
        ),
      if (m.sender) ...[
        sectionTitle(
          t['actions'],
          subtitle: twoWay ? t.fill('sharingWith', peerName) : t['shareMoment'],
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final scale = MediaQuery.textScalerOf(context).scale(1);
            return scale > 1.6
                ? Column(
                    children: ['outside', 'home', 'meal']
                        .map(
                          (kind) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: action(kind, wide: true),
                          ),
                        )
                        .toList(),
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: ['outside', 'home', 'meal']
                        .map(
                          (kind) => Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(
                                right: kind == 'meal' ? 0 : 9,
                              ),
                              child: action(kind),
                            ),
                          ),
                        )
                        .toList(),
                  );
          },
        ),
      ] else
        sectionTitle(t.fill('source', m.state['name'] as String? ?? '')),
      if (twoWay) ...[
        sectionTitle(t['ourUpdates']),
        personCard(m.state, isPeer: false),
        personCard(peer, isPeer: true),
      ] else
        statusSummary(m.state),
      mealsCard(),
      locationCard(),
      if (m.note != null)
        card(
          Row(
            children: [
              Icon(Pixel.check, color: p.green, size: 18),
              const SizedBox(width: 8),
              Expanded(child: small(t[m.note!])),
            ],
          ),
          padding: const EdgeInsets.all(12),
        ),
      InkWell(
        onTap: () => setState(() => tab = 2),
        child: Row(
          children: [
            Icon(
              m.enabled ? Pixel.check : Pixel.pause,
              size: 7,
              color: m.enabled ? p.green : p.muted,
            ),
            const SizedBox(width: 8),
            Expanded(child: small(m.connection)),
            Icon(Pixel.chevronright, size: 16, color: p.muted),
          ],
        ),
      ),
    ], storage: 'home');
  }

  Widget sectionTitle(String title, {String? subtitle}) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      PixelifyText(title, size: 16),
      if (subtitle != null) ...[const SizedBox(height: 5), small(subtitle)],
    ],
  );
  String stateLabel(Map data) => switch (data['location']) {
    'home' => t.fill('atPlace', t.label(data['home'] as String? ?? 'Kost')),
    'outside' => t.label(data['outside'] as String? ?? 'Keluar'),
    _ => t['unknown'],
  };
  Map latestEvent(Map data) {
    final entries = data['events'] as List? ?? [];
    return entries.isEmpty ? const {} : entries.first as Map;
  }

  String latestLabel(Map data) => latestEvent(data)['kind'] == 'meal'
      ? t.label(latestEvent(data)['label'] as String? ?? 'Makan')
      : stateLabel(data);
  int latestAt(Map data) => latestEvent(data)['kind'] == 'meal'
      ? number(latestEvent(data)['at'])
      : number(data['locationAt']);
  String shownStamp(int at, {bool remote = false}) =>
      remote ? m.peerStamp(at) : m.stamp(at);
  Widget statusSummary(Map data) => card(
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        small(t['latest']),
        const SizedBox(height: 12),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: p.tint,
                borderRadius: BorderRadius.circular(17),
              ),
              child: PixelIcon(
                latestEvent(data)['kind'] == 'meal'
                    ? 'meal'
                    : data['location'] == 'outside'
                    ? 'outside'
                    : 'home',
                size: 34,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PixelifyText(latestLabel(data), size: 19),
                  const SizedBox(height: 5),
                  small(shownStamp(latestAt(data))),
                ],
              ),
            ),
          ],
        ),
        if (number(data['locationAt']) > 0 &&
            DateTime.now().millisecondsSinceEpoch -
                    number(data['locationAt']) >=
                6 * 3600000)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: small(t['placeOld']),
          ),
        Divider(height: 30, color: p.border),
        if (latestEvent(data)['kind'] == 'meal') ...[
          summaryRow(t['latestPlace'], stateLabel(data), Pixel.pin),
          const SizedBox(height: 14),
        ],
        summaryRow(
          t['lastMeal'],
          m.stamp(number(data['mealAt'])),
          Pixel.coffee,
        ),
        const SizedBox(height: 14),
        summaryRow(
          t.fill('lastHome', t.label(data['home'] as String? ?? 'Kost')),
          m.stamp(number(data['homeAt'])),
          Pixel.home,
        ),
      ],
    ),
  );
  Widget personCard(Map data, {required bool isPeer, bool detailed = false}) {
    final name = isPeer ? peerName : (data['name'] as String? ?? m.nickname);
    return card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: p.tint,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  isPeer ? Pixel.heart : Pixel.user,
                  color: p.accent,
                  size: 23,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    small(t[isPeer ? 'partnerUpdates' : 'myUpdates']),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Flexible(child: badge(t[isPeer ? 'readOnly' : 'fromThisPhone'])),
            ],
          ),
          const SizedBox(height: 16),
          if (isPeer && (!peerActive || data.isEmpty))
            small(t['peerNoUpdate'])
          else ...[
            Text(
              latestLabel(data),
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 5),
            small(shownStamp(latestAt(data), remote: isPeer)),
            const SizedBox(height: 14),
            if (latestEvent(data)['kind'] == 'meal') ...[
              small('${t['latestPlace']} · ${stateLabel(data)}'),
              const SizedBox(height: 10),
            ],
            summaryRow(
              t['lastMeal'],
              shownStamp(number(data['mealAt']), remote: isPeer),
              Pixel.coffee,
            ),
            if (data['gps'] is Map) ...[
              const SizedBox(height: 10),
              summaryRow(t['city'], m.city(data['gps'] as Map), Pixel.pin),
            ],
          ],
          if (isPeer && peerActive && !detailed) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                key: const ValueKey('peer-details'),
                onPressed: showPeer,
                icon: const Icon(Pixel.arrowright, size: 16),
                label: Text(t['viewPartner']),
              ),
            ),
          ],
        ],
      ),
      color: isPeer ? p.card : p.tint.withValues(alpha: m.dark ? .65 : .35),
    );
  }

  Widget mealsCard() {
    final s = m.state;
    final done = (m.snapshot['mealsToday'] as List? ?? [false, false, false])
        .cast<bool>();
    final times = [
      number(s['breakfastAt']),
      number(s['lunchAt']),
      number(s['dinnerAt']),
    ];
    final windows = s['windows'] as List? ?? [5, 10, 10, 15, 17, 22];
    final categories = ['Sarapan', 'Makan siang', 'Makan malam'];
    return card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: sectionTitle(
                  t['dailyMeals'],
                  subtitle: t.fill(
                    'mealCount',
                    '${done.where((x) => x).length}',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              CozyIconTile(Pixel.coffee, palette: p, tone: p.green, size: 22),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: List.generate(
              3,
              (i) => Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: i == 2 ? 0 : 6),
                  height: 6,
                  decoration: BoxDecoration(
                    color: done[i] ? p.green : p.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          small(t['senderDay']),
          const SizedBox(height: 12),
          ...List.generate(
            3,
            (i) => Padding(
              padding: EdgeInsets.only(bottom: i == 2 ? 0 : 9),
              child: CozyPress(
                animate: motion,
                enabled: !m.busy,
                child: ShadCard(
                  padding: EdgeInsets.zero,
                  radius: BorderRadius.circular(10),
                  backgroundColor: done[i]
                      ? Color.alphaBlend(p.green.withValues(alpha: .08), p.card)
                      : p.bg,
                  border: ShadBorder.all(
                    color: done[i] ? p.green.withValues(alpha: .3) : p.border,
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      key: ValueKey('meal-$i'),
                      borderRadius: BorderRadius.circular(10),
                      onTap: m.busy
                          ? null
                          : () {
                              if (m.sender) {
                                confirmStatus('meal', category: categories[i]);
                              } else {
                                final events = m.events
                                    .where(
                                      (e) =>
                                          e['kind'] == 'meal' &&
                                          e['label'] == categories[i],
                                    )
                                    .toList();
                                if (events.isNotEmpty) {
                                  eventDetails(events.first);
                                } else {
                                  simpleInfo(
                                    t.label(categories[i]),
                                    t['unrecorded'],
                                  );
                                }
                              }
                            },
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              done[i]
                                  ? Pixel.check
                                  : [
                                      Pixel.sun,
                                      Pixel.sunalt,
                                      Pixel.moonstar,
                                    ][i],
                              color: done[i] ? p.green : p.amber,
                              size: 23,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  PixelifyText(
                                    t.label(categories[i]),
                                    size: 11,
                                  ),
                                  const SizedBox(height: 6),
                                  small(
                                    done[i]
                                        ? m.stamp(times[i])
                                        : '${t['unrecorded']} · ${mealWindow(windows[i * 2] as num, windows[i * 2 + 1] as num)}',
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(Pixel.chevronright, color: p.muted, size: 16),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget action(String kind, {bool wide = false}) => CozyActionCard(
    key: ValueKey('status-$kind'),
    palette: p,
    kind: kind,
    label: m.actionLabel(kind),
    wide: wide,
    animate: motion,
    onPressed: m.busy ? null : () => confirmStatus(kind),
  );

  Widget summaryRow(String label, String value, IconData icon) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, color: p.accent, size: 18),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            small(value),
          ],
        ),
      ),
    ],
  );
  String mealWindow(num start, num end) =>
      '${clockDigits(DateTime(2000, 1, 1, start.toInt()), m.clock12)} – ${clockDigits(DateTime(2000, 1, 1, end.toInt()), m.clock12)}';
  Future<void> confirmStatus(String kind, {String? category}) async {
    if (_statusDialogOpen || m.busy || !m.sender) return;
    _statusDialogOpen = true;
    try {
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
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: SizedBox(
                      height: 100,
                      width: 280,
                      child: PixelSky(
                        action: kind,
                        together: m.together,
                        animate: m.animations && !m.energySaver,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (twoWay) ...[
                    badge(t.fill('sharingWith', peerName), icon: Pixel.heart),
                    const SizedBox(height: 12),
                  ],
                  Row(
                    children: [
                      PixelIcon(kind, size: 38),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          kind == 'meal'
                              ? t.label(selected!)
                              : m.actionLabel(kind),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  small(m.time(DateTime.now().millisecondsSinceEpoch)),
                  if (kind == 'meal') ...[
                    const SizedBox(height: 16),
                    small(t.fill('mealScheduled', t.label(selected!))),
                    const SizedBox(height: 6),
                    small(t['mealAutomatic']),
                    const SizedBox(height: 10),
                    small(t['mealKeepsPlace']),
                  ],
                  const SizedBox(height: 16),
                  cozyToggle(
                    t['shareLocation'],
                    share,
                    (value) => update(() => share = value),
                  ),
                  small(t['locationConsent']),
                ],
              ),
            ),
            actions: [
              TextButton(
                key: const ValueKey('cancel-status'),
                onPressed: () => Navigator.pop(context, false),
                child: Text(t['cancel']),
              ),
              FilledButton(
                key: const ValueKey('confirm-status'),
                onPressed: () => Navigator.pop(context, true),
                child: Text(t['send']),
              ),
            ],
          ),
        ),
      );
      if (okay == true) {
        if (share && !await ensureLocationServices()) return;
        await m.command('record', {
          'kind': kind,
          'category': null,
          'shareLocation': share,
        });
      }
    } finally {
      _statusDialogOpen = false;
    }
  }

  Future<bool> ensureLocationServices() async {
    final status = await m.backend.invoke('locationServices');
    if (status['enabled'] != false) return true;
    if (!await confirm(t['enableLocation'], t['enableLocationBody']))
      return false;
    if (!await m.command('locationSettings')) return false;
    final after = await m.backend.invoke('locationServices');
    if (after['enabled'] == true) return true;
    if (mounted) await simpleInfo(t['enableLocation'], t['enableLocationBody']);
    return false;
  }

  Widget locationCard() {
    final point = m.state['gps'] as Map?;
    return card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Pixel.pin, color: p.accent),
              const SizedBox(width: 10),
              Expanded(child: PixelifyText(t['locationTitle'], size: 16)),
            ],
          ),
          const SizedBox(height: 10),
          if (point == null)
            small(t['noLocation'])
          else ...[
            Text(
              m.place(point),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            small('${t['city']} · ${m.city(point)}'),
            const SizedBox(height: 6),
            small('${t['gpsTime']} · ${m.stamp(number(point['at']))}'),
            const SizedBox(height: 6),
            small('${t['timeZone']} · ${point['zone'] ?? ''}'),
          ],
          if (point != null) ...[
            if (DateTime.now().millisecondsSinceEpoch - number(point['at']) >=
                900000) ...[
              const SizedBox(height: 6),
              small(t['locationOld']),
            ],
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => gpsDetails(Map<String, dynamic>.from(point)),
              child: Text(t['detail']),
            ),
          ],
          if (m.sender) ...[
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: m.busy
                  ? null
                  : () async {
                      if (await confirm(
                            t['refreshLocation'],
                            t['locationConsent'],
                          ) &&
                          await ensureLocationServices())
                        await m.command('record', {
                          'kind': '',
                          'shareLocation': true,
                        });
                    },
              icon: const Icon(Pixel.gps, size: 18),
              label: Text(t['refreshLocation']),
            ),
          ],
        ],
      ),
    );
  }

  Widget historyTabs() => LayoutBuilder(
    builder: (context, constraints) {
      final buttons = [false, true]
          .map(
            (isPeer) => ShadButton.raw(
              key: ValueKey(isPeer ? 'history-peer' : 'history-self'),
              variant: peerHistory == isPeer
                  ? ShadButtonVariant.primary
                  : ShadButtonVariant.outline,
              width: double.infinity,
              expands: true,
              height: 0,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
              onPressed: () => setState(() => peerHistory = isPeer),
              child: Text(
                t[isPeer ? 'partnerUpdates' : 'myUpdates'],
                textAlign: TextAlign.center,
              ),
            ),
          )
          .toList();
      if (MediaQuery.textScalerOf(context).scale(1) > 1.3) {
        return Column(
          children: [buttons[0], const SizedBox(height: 8), buttons[1]],
        );
      }
      return Row(
        children: [
          Expanded(child: buttons[0]),
          const SizedBox(width: 8),
          Expanded(child: buttons[1]),
        ],
      );
    },
  );

  Widget history() {
    final entries = twoWay && peerHistory ? peerEvents : m.events;
    return page([
      header(t['history'], t['journal']),
      card(
        Row(
          children: [
            CozyIconTile(Pixel.book, palette: p, size: 26),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PixelifyText(
                    twoWay && peerHistory
                        ? t['partnerUpdates']
                        : t['myUpdates'],
                    size: 14,
                  ),
                  const SizedBox(height: 5),
                  small(t['historyBody']),
                ],
              ),
            ),
            const SizedBox(width: 8),
            PixelifyText('${entries.length}', size: 26, color: p.accent),
          ],
        ),
        color: p.tint,
      ),
      if (twoWay) historyTabs(),
      if (entries.isEmpty) ...[
        CozyScene(
          palette: p,
          title: t['yourLittleWorld'],
          caption: t['emptyHistoryBody'],
          animate: motion,
        ),
        PixelifyText(t['emptyHistory'], size: 19, align: TextAlign.center),
      ],
      ...entries.asMap().entries.map((entry) {
        final e = entry.value;
        final kind = e['kind'] as String;
        final tone = kind == 'meal'
            ? p.green
            : kind == 'outside'
            ? p.amber
            : p.accent;
        void detail() =>
            eventDetails(e, owner: peerHistory && twoWay ? peerName : null);
        return CozyPress(
          animate: motion,
          child: card(
            InkWell(
              key: ValueKey('history-${entry.key}'),
              onTap: detail,
              borderRadius: BorderRadius.circular(13),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        CozyIconTile(
                          actionIcon(kind),
                          palette: p,
                          tone: tone,
                          size: 24,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: 2,
                          height: 20,
                          color: tone.withValues(alpha: .25),
                        ),
                        Container(
                          width: 5,
                          height: 5,
                          color: tone.withValues(alpha: .55),
                        ),
                      ],
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          PixelifyText(t.label(e['label'] as String), size: 14),
                          const SizedBox(height: 7),
                          small(
                            shownStamp(
                              number(e['at']),
                              remote: twoWay && peerHistory,
                            ),
                          ),
                          if (e['gps'] != null) ...[
                            const SizedBox(height: 10),
                            badge(
                              (e['gps'] as Map)['city'] as String? ??
                                  t['locationTitle'],
                              icon: Pixel.pin,
                              color: tone,
                            ),
                          ],
                          const SizedBox(height: 8),
                          ShadButton.ghost(
                            key: ValueKey('detail-${entry.key}'),
                            height: 0,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 0,
                              vertical: 10,
                            ),
                            foregroundColor: p.accent,
                            trailing: Icon(
                              Pixel.arrowright,
                              size: 16,
                              color: p.accent,
                            ),
                            onPressed: detail,
                            child: Text(
                              t['detail'],
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            padding: EdgeInsets.zero,
          ),
        );
      }),
    ], storage: 'history-${twoWay && peerHistory ? 'peer' : 'self'}');
  }

  Future<void> sheet(String titleKey, List<Widget> Function() contents) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (context) => AnimatedBuilder(
          animation: m,
          builder: (context, _) => AnimatedPadding(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.only(
              bottom: MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: SizedBox(
              height:
                  (MediaQuery.sizeOf(context).height -
                      MediaQuery.viewInsetsOf(context).bottom) *
                  .82,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(child: PixelifyText(t[titleKey], size: 21)),
                        IconButton(
                          tooltip: t['close'],
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Pixel.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: contents()
                              .map(
                                (w) => Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: w,
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
  Widget detailRow(String name, String value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      small(name),
      const SizedBox(height: 5),
      SelectableText(
        value,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          height: 1.4,
        ),
      ),
    ],
  );
  Future<void> eventDetails(Map<String, dynamic> event, {String? owner}) {
    final at = number(event['at']),
        origin = Map<String, dynamic>.from(event['originInfo'] as Map? ?? {});
    final point = event['gps'] as Map?;
    return sheet(
      'detailTitle',
      () => [
        if (owner != null) badge(t.fill('source', owner), icon: Pixel.heart),
        Row(
          children: [
            PixelIcon(event['kind'] as String, size: 42),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                t.label(event['label'] as String),
                style: const TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        card(
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              detailRow(t['localTime'], shownStamp(at, remote: owner != null)),
              const Divider(height: 28),
              detailRow(t['senderTime'], m.stamp(at, inZone: origin)),
              const SizedBox(height: 16),
              detailRow(
                t['timeZone'],
                event['zone'] as String? ?? m.state['zone'] as String? ?? '',
              ),
              const SizedBox(height: 16),
              detailRow(
                t['recorded'],
                m.stamp(at, inZone: const {'offsetMinutes': 0, 'short': 'UTC'}),
              ),
            ],
          ),
        ),
        if (point != null)
          ...gpsContent(Map<String, dynamic>.from(point), remote: owner != null)
        else
          card(
            small(
              t[event['gpsCaptured'] == true
                  ? 'eventGpsExpired'
                  : 'eventNoGps'],
            ),
          ),
      ],
    );
  }

  List<Widget> gpsContent(
    Map<String, dynamic> point, {
    bool remote = false,
  }) => [
    card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            t['locationTitle'],
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 18),
          detailRow(t['locationTitle'], m.place(point)),
          const SizedBox(height: 16),
          detailRow(t['city'], m.city(point)),
          const SizedBox(height: 16),
          detailRow(t['accuracy'], '±${number(point['accuracy'])} m'),
          const SizedBox(height: 16),
          detailRow(
            t['gpsTime'],
            shownStamp(number(point['at']), remote: remote),
          ),
          const SizedBox(height: 16),
          detailRow(t['timeZone'], point['zone'] as String? ?? ''),
          const SizedBox(height: 12),
          small(t['gpsNote']),
          if (DateTime.now().millisecondsSinceEpoch - number(point['at']) >=
              900000) ...[
            const SizedBox(height: 8),
            small(t['locationOld']),
          ],
        ],
      ),
    ),
    primary(
      t['map'],
      () => m.command('openMap', {'lat': point['lat'], 'lon': point['lon']}),
      key: 'open-map',
    ),
  ];
  Future<void> gpsDetails(Map<String, dynamic> point) =>
      sheet('locationTitle', () => gpsContent(point));
  Widget settings() => page([
    header(t['settings'], t['personalSpace']),
    section(t['mode'], [
      modeChoice(false),
      const SizedBox(height: 10),
      modeChoice(true),
      if (twoWay) ...[const SizedBox(height: 12), partnerConnectionCard()],
    ]),
    section(t['profile'], [
      rowSetting(
        t['editName'],
        Pixel.user,
        editNickname,
        subtitle: m.nickname,
        key: 'edit-nickname',
      ),
      rowSetting(
        t['language'],
        Pixel.message,
        chooseLanguage,
        subtitle: languages[m.language],
        key: 'language-settings',
      ),
      rowSetting(
        t['timeFormat'],
        Pixel.clock,
        chooseClock,
        subtitle: t[m.clock12 ? 'clock12' : 'clock24'],
        key: 'time-format',
      ),
    ]),
    section(t['appearance'], [
      AspectRatio(
        aspectRatio: 160 / 64,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: PixelSky(together: m.together, action: 'home'),
        ),
      ),
      const SizedBox(height: 14),
      small(t['modeVisualNote']),
      const SizedBox(height: 16),
      LayoutBuilder(
        builder: (context, constraints) {
          final wideText = MediaQuery.textScalerOf(context).scale(1) > 1.6;
          final options = [
            false,
            true,
          ].map((dark) => appearanceOption(dark)).toList();
          return wideText
              ? Column(
                  children: [
                    options[0],
                    const SizedBox(height: 10),
                    options[1],
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: options[0]),
                    const SizedBox(width: 10),
                    Expanded(child: options[1]),
                  ],
                );
        },
      ),
      const SizedBox(height: 12),
      small(t['daySceneNote']),
      cozyToggle(
        t['pixelAnimations'],
        m.animations,
        m.busy ? null : (value) => m.prefs({'animations': value}),
        key: 'pixel-animations',
        subtitle: t[m.energySaver ? 'motionPowerSave' : 'motionNote'],
      ),
      const SizedBox(height: 8),
      small(t['zoneNote']),
    ]),
    section(t['family'], [
      if (m.sender) ...[
        rowSetting(t['editLabels'], Pixel.edit, editLabels),
        rowSetting(t['schedule'], Pixel.coffee, editSchedule),
        rowSetting(t['shareCode'], Pixel.lock, showCode),
      ],
      if (!m.sender) small(t.fill('source', m.state['name'] as String? ?? '')),
    ]),
    section(t['connection'], [
      small(m.connection),
      rowSetting(
        t[m.enabled ? 'pause' : 'resume'],
        m.enabled ? Pixel.pause : Pixel.play,
        () => m.command('toggleConnection'),
      ),
      rowSetting(
        t['notifications'],
        Pixel.notification,
        () => m.command('notifications'),
        subtitle: t['chimeNote'],
      ),
      rowSetting(t['widget'], Pixel.grid, () {
        if (m.snapshot['platform'] == 'ios')
          simpleInfo(t['widget'], t['iosWidget']);
        else
          m.command('pinWidget');
      }),
      rowSetting(
        t['battery'],
        Pixel.batteryfull,
        () => m.command('appSettings'),
      ),
      small(t['batteryNote']),
      if (m.snapshot['platform'] == 'ios')
        rowSetting(
          t['pushServer'],
          Pixel.notification,
          editPushServer,
          subtitle: t['pushNote'],
        ),
    ]),
    section(t['privacy'], [
      small(t['privacyBody']),
      if (m.sender) ...[
        rowSetting(
          t['clearGps'],
          Pixel.gps,
          () => dangerAction('clearGps', 'clearGpsBody', 'clearGps'),
          danger: true,
        ),
        rowSetting(
          t['clearHistory'],
          Pixel.trash,
          () =>
              dangerAction('clearHistory', 'clearHistoryBody', 'clearHistory'),
          danger: true,
        ),
        rowSetting(
          t['rotate'],
          Pixel.lock,
          () => dangerAction('rotate', 'rotateBody', 'rotate'),
          danger: true,
        ),
      ],
      rowSetting(
        t['disconnect'],
        Pixel.link,
        () => dangerAction('disconnect', 'disconnectBody', 'disconnect'),
        danger: true,
      ),
      rowSetting(
        t['uninstall'],
        Pixel.closebox,
        removeApplication,
        danger: true,
        key: 'remove-application',
      ),
    ]),
    small(t['version']),
    CozyFooter(key: const ValueKey('developer-credit'), palette: p),
  ], storage: 'settings');
  Widget cozyToggle(
    String title,
    bool value,
    ValueChanged<bool>? onChanged, {
    String? key,
    String? subtitle,
  }) => InkWell(
    key: key == null ? null : ValueKey(key),
    borderRadius: BorderRadius.circular(10),
    onTap: onChanged == null ? null : () => onChanged(!value),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 5),
                  small(subtitle),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Semantics(
            label: title,
            child: ShadSwitch(
              value: value,
              enabled: onChanged != null,
              onChanged: onChanged,
              width: 44,
              height: 24,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 2),
              duration: motion && !MediaQuery.disableAnimationsOf(context)
                  ? const Duration(milliseconds: 150)
                  // ShadAnimate needs a nonzero interval; settle in one frame.
                  : const Duration(milliseconds: 1),
              checkedTrackColor: p.accent,
              uncheckedTrackColor: p.border,
              thumbColor: p.card,
            ),
          ),
        ],
      ),
    ),
  );
  Widget appearanceOption(bool dark) => CozyPress(
    animate: motion,
    enabled: !m.busy,
    child: ShadCard(
      backgroundColor: dark == m.dark ? p.tint : p.bg,
      padding: EdgeInsets.zero,
      radius: BorderRadius.circular(10),
      border: ShadBorder.all(
        color: dark == m.dark ? p.accent : p.border,
        width: 1.5,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: ValueKey(dark ? 'appearance-dark' : 'appearance-light'),
          borderRadius: BorderRadius.circular(10),
          onTap: m.busy ? null : () => m.prefs({'dark': dark}),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      dark ? Pixel.moonstars : Pixel.sun,
                      color: p.accent,
                      size: 23,
                    ),
                    const Spacer(),
                    if (dark == m.dark)
                      Icon(Pixel.check, size: 18, color: p.accent),
                  ],
                ),
                const SizedBox(height: 12),
                PixelifyText(t[dark ? 'dark' : 'light'], size: 12),
                const SizedBox(height: 4),
                small(t[dark ? 'darkPreview' : 'lightPreview']),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  Widget section(String title, List<Widget> children) => card(
    Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PixelifyText(title, size: 15, color: p.accent),
        const SizedBox(height: 10),
        ...children,
      ],
    ),
  );
  Widget modeSetupCard() => card(
    Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            CozyIconTile(Pixel.heart, palette: p, size: 26),
            const SizedBox(width: 12),
            Expanded(child: PixelifyText(t['seirama'], size: 20)),
          ],
        ),
        const SizedBox(height: 16),
        AspectRatio(
          aspectRatio: 160 / 64,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: PixelSky(together: true, action: 'home', animate: motion),
          ),
        ),
        const SizedBox(height: 14),
        small(t['seiramaDescription']),
        const SizedBox(height: 18),
        primary(t['activateSeirama'], enableSeirama, key: 'setup-seirama'),
      ],
    ),
    color: p.tint,
  );
  Widget modeChoice(bool seirama) {
    final selected = twoWay == seirama;
    return Material(
      color: selected ? p.tint : p.bg,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        key: ValueKey(seirama ? 'mode-seirama' : 'mode-oneway'),
        borderRadius: BorderRadius.circular(18),
        onTap: m.busy
            ? null
            : () {
                if (seirama) {
                  if (twoWay) {
                    linkPartner();
                  } else {
                    enableSeirama();
                  }
                } else if (twoWay) {
                  leaveSeirama();
                }
              },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: p.card,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  seirama ? Pixel.heart : Pixel.arrowright,
                  size: 22,
                  color: p.accent,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t[seirama ? 'seirama' : 'oneWay'],
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    small(
                      t[seirama ? 'seiramaDescription' : 'oneWayDescription'],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Semantics(
                selected: selected,
                label: t[seirama ? 'seirama' : 'oneWay'],
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: selected ? p.accent : Colors.transparent,
                    border: Border.all(
                      color: selected ? p.accent : p.border,
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: selected
                      ? Icon(
                          Pixel.check,
                          size: 16,
                          color: m.dark ? p.bg : Colors.white,
                        )
                      : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget partnerConnectionCard() => card(
    Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(
              peerActive ? Pixel.heart : Pixel.link,
              color: p.accent,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                t[peerActive
                    ? 'seiramaActive'
                    : m.snapshot['reciprocity'] == 'inactive'
                    ? 'seiramaInactive'
                    : m.snapshot['reciprocity'] == 'waiting'
                    ? 'seiramaWaiting'
                    : 'seiramaUnlinked'],
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
        if (!peerActive) ...[
          const SizedBox(height: 10),
          OutlinedButton.icon(
            key: const ValueKey('link-partner'),
            onPressed: m.busy ? null : linkPartner,
            icon: const Icon(Pixel.link, size: 17),
            label: Text(t['linkPartner']),
          ),
        ],
      ],
    ),
    padding: const EdgeInsets.all(14),
    color: p.tint.withValues(alpha: m.dark ? .65 : .45),
  );
  Future<void> enableSeirama({bool migration = false}) async {
    final consent = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t['seiramaConsentTitle']),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: const SizedBox(
                  height: 120,
                  width: 280,
                  child: PixelSky(together: true, action: 'home'),
                ),
              ),
              const SizedBox(height: 16),
              if (migration) ...[
                small(t['modeUpgrade']),
                const SizedBox(height: 12),
              ],
              Text(
                t['seiramaConsentBody'],
                style: const TextStyle(height: 1.55),
              ),
              if (m.role == 'sender') ...[
                const SizedBox(height: 12),
                small(t['existingRecipients']),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            key: const ValueKey('cancel-mode'),
            onPressed: () => Navigator.pop(context, false),
            child: Text(t['cancel']),
          ),
          FilledButton(
            key: const ValueKey('confirm-mode'),
            onPressed: () => Navigator.pop(context, true),
            child: Text(t['activateSeirama']),
          ),
        ],
      ),
    );
    if (consent != true) {
      if (migration) await m.prefs({'relationship': false});
      return;
    }
    if (await m.command('enableSeirama', {'confirmed': true}) && mounted) {
      setState(() => tab = 0);
      await linkPartner();
    }
  }

  Future<void> leaveSeirama() async {
    if (!await confirm(t['leaveSeirama'], t['leaveSeiramaBody'])) return;
    if (await m.command('disableSeirama', {'confirmed': true}) && mounted)
      setState(() => peerHistory = false);
  }

  Future<void> linkPartner() async {
    if (_modeSheetOpen || !twoWay) return;
    _modeSheetOpen = true;
    final input = TextEditingController();
    try {
      final result = await m.backend.invoke('pairCode');
      if (!mounted) return;
      final invite = result['code'] as String;
      await sheet(
        'exchangeCodes',
        () => [
          small(t['exchangeBody']),
          card(
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  t['yourCode'],
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                small(t['secretCode']),
                const SizedBox(height: 12),
                SelectableText(
                  invite,
                  key: const ValueKey('seirama-own-code'),
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: invite));
                    if (mounted)
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(t['copied'])));
                  },
                  icon: const Icon(Pixel.copy, size: 17),
                  label: Text(t['copy']),
                ),
              ],
            ),
          ),
          TextField(
            key: const ValueKey('seirama-peer-code'),
            controller: input,
            minLines: 2,
            maxLines: 4,
            autocorrect: false,
            enableSuggestions: false,
            decoration: InputDecoration(labelText: t['partnerCode']),
          ),
          if (m.error != null)
            Text(t[m.error!], style: const TextStyle(color: Colors.redAccent)),
          primary(t['connect'], () async {
            FocusScope.of(context).unfocus();
            if (!await confirm(t['joinSeiramaTitle'], t['joinSeiramaBody']))
              return;
            if (await m.command('joinSeirama', {
                  'confirmed': true,
                  'code': input.text.trim(),
                }) &&
                mounted)
              Navigator.pop(context);
          }, key: 'join-seirama'),
        ],
      );
    } catch (_) {
      if (mounted) await simpleInfo(t['linkPartner'], t['error']);
    } finally {
      input.dispose();
      _modeSheetOpen = false;
    }
  }

  Future<void> showPeer() => sheet(
    'partnerUpdates',
    () => [
      personCard(peer, isPeer: true, detailed: true),
      if (peerActive) ...[
        if (peer['gps'] is Map)
          ...gpsContent(
            Map<String, dynamic>.from(peer['gps'] as Map),
            remote: true,
          )
        else
          card(small(t['noLocation'])),
        OutlinedButton.icon(
          onPressed: () {
            Navigator.pop(context);
            setState(() {
              peerHistory = true;
              tab = 1;
            });
          },
          icon: const Icon(Pixel.book, size: 17),
          label: Text(t['history']),
        ),
      ],
    ],
  );

  Future<void> chooseLanguage() => showModalBottomSheet(
    context: context,
    useSafeArea: true,
    builder: (context) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            t['language'],
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          ...languages.entries.map(
            (entry) => ListTile(
              key: ValueKey('language-${entry.key}'),
              title: Text(entry.value),
              trailing: m.language == entry.key
                  ? Icon(Pixel.check, color: p.accent)
                  : null,
              onTap: () async {
                Navigator.pop(context);
                await m.prefs({'language': entry.key});
              },
            ),
          ),
        ],
      ),
    ),
  );
  Future<void> chooseClock() => showModalBottomSheet(
    context: context,
    useSafeArea: true,
    builder: (context) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            t['timeFormat'],
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          ...[false, true].map(
            (value) => ListTile(
              key: ValueKey(value ? 'clock-12' : 'clock-24'),
              title: Text(t[value ? 'clock12' : 'clock24']),
              subtitle: Text(
                formatClock(
                  DateTime.now().millisecondsSinceEpoch,
                  clock12: value,
                  zone: m.zone,
                ),
              ),
              trailing: m.clock12 == value
                  ? Icon(Pixel.check, color: p.accent)
                  : null,
              onTap: () async {
                Navigator.pop(context);
                await m.prefs({'clock12': value});
              },
            ),
          ),
        ],
      ),
    ),
  );
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
              labelText: t['nickname'],
              errorText: error,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(t['cancel']),
            ),
            FilledButton(
              onPressed: () {
                if (!validNickname(field.text)) {
                  update(() => error = t['nameError']);
                  return;
                }
                Navigator.pop(context, field.text.trim());
              },
              child: Text(t['save']),
            ),
          ],
        ),
      ),
    );
    field.dispose();
    if (value != null) await m.prefs({'nickname': value});
  }

  Future<void> showCode() async {
    try {
      final result = await m.backend.invoke('pairCode');
      if (!mounted) return;
      final value = result['code'] as String;
      await sheet(
        'shareCode',
        () => [
          small(t['secretCode']),
          card(
            SelectableText(
              value,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
          primary(t['copy'], () async {
            await Clipboard.setData(ClipboardData(text: value));
            if (mounted)
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(t['copied'])));
          }),
          OutlinedButton(
            onPressed: () => m.command('shareCode'),
            child: Text(t['share']),
          ),
        ],
      );
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
              child: Text(t['cancel']),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(t['continue']),
            ),
          ],
        ),
      ) ??
      false;
  Future<void> simpleInfo(String title, String body) => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(t['close']),
        ),
      ],
    ),
  );
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
        key: TextEditingController(text: m.state[key] as String? ?? ''),
    };
    String? error;
    final values = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, update) => AlertDialog(
          title: Text(t['editLabels']),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ...keys.map(
                  (key) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TextField(
                      controller: fields[key],
                      maxLength: 24,
                      decoration: InputDecoration(
                        labelText:
                            t[key == 'name'
                                ? 'senderName'
                                : key == 'home'
                                ? 'homeStatus'
                                : key],
                        errorText: error,
                      ),
                    ),
                  ),
                ),
                small(t['sharedChange']),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(t['cancel']),
            ),
            FilledButton(
              onPressed: () {
                if (fields.values.any((f) => !validNickname(f.text))) {
                  update(() => error = t['nameError']);
                  return;
                }
                Navigator.pop(context, {
                  for (final key in keys) key: fields[key]!.text.trim(),
                });
              },
              child: Text(t['save']),
            ),
          ],
        ),
      ),
    );
    for (final field in fields.values) {
      field.dispose();
    }
    if (values != null &&
        await confirm(
          t['confirmChange'],
          values.values.join(' · ') + '\n\n' + t['sharedChange'],
        ))
      await m.command('edit', values);
  }

  Future<void> editSchedule() async {
    final windows = (m.state['windows'] as List? ?? [5, 10, 10, 15, 17, 22])
        .cast<int>();
    final fields = windows
        .map((v) => TextEditingController(text: '$v'))
        .toList();
    String? error;
    final values = await showDialog<List<int>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, update) => AlertDialog(
          title: Text(t['schedule']),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                small(t['scheduleInvalid']),
                const SizedBox(height: 16),
                ...List.generate(
                  3,
                  (i) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t[['breakfast', 'lunch', 'dinner'][i]]),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: fields[i * 2],
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  hintText: '00',
                                ),
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.all(10),
                              child: Text('–'),
                            ),
                            Expanded(
                              child: TextField(
                                controller: fields[i * 2 + 1],
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  hintText: '24',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                if (error != null)
                  Text(error!, style: const TextStyle(color: Colors.redAccent)),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(t['cancel']),
            ),
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
              child: Text(t['save']),
            ),
          ],
        ),
      ),
    );
    for (final field in fields) {
      field.dispose();
    }
    if (values != null &&
        await confirm(
          t['confirmChange'],
          values.join(' · ') + '\n\n' + t['sharedChange'],
        ))
      await m.command('edit', {'windows': values});
  }

  Future<void> editPushServer() async {
    final field = TextEditingController(
      text: m.snapshot['pushEndpoint'] as String? ?? '',
    );
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t['pushServer']),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            small(t['pushNote']),
            const SizedBox(height: 16),
            TextField(
              controller: field,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(hintText: 'https://...'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t['cancel']),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, field.text.trim()),
            child: Text(t['save']),
          ),
        ],
      ),
    );
    field.dispose();
    if (value != null) await m.command('pushServer', {'url': value});
  }
}
