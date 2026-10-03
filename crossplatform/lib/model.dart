import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'strings.dart';

abstract class Backend {
  Future<Map<String, dynamic>> invoke(String method,
      [Map<String, dynamic> arguments = const {}]);
}

class NativeBackend implements Backend {
  static const channel = MethodChannel('abc/native');
  @override
  Future<Map<String, dynamic>> invoke(String method,
      [Map<String, dynamic> arguments = const {}]) async {
    final value = await channel.invokeMethod<String>(method, arguments);
    return Map<String, dynamic>.from(jsonDecode(value ?? '{}') as Map);
  }
}

bool validNickname(String value) {
  final name = value.trim();
  return name.isNotEmpty &&
      name.length <= 24 &&
      !RegExp(r'[\x00-\x1F\x7F]').hasMatch(name);
}

class AppModel extends ChangeNotifier {
  final Backend backend;
  Map<String, dynamic> snapshot = {};
  bool loading = true, busy = false;
  String? error, note;
  String progress = 'saving';
  Timer? _poll;
  AppModel(this.backend);
  Map<String, dynamic> get state =>
      Map<String, dynamic>.from(snapshot['state'] as Map? ?? {});
  Map<String, dynamic> get profile =>
      Map<String, dynamic>.from(snapshot['profile'] as Map? ?? {});
  String get language => languages.containsKey(profile['language'])
      ? profile['language'] as String
      : 'id';
  Copy get copy => Copy(language);
  String get nickname => profile['nickname'] as String? ?? '';
  String get role => snapshot['role'] as String? ?? '';
  bool get dark => profile['dark'] == true;
  bool get together => profile['relationship'] == true;
  bool get clock12 => profile['clock12'] == true;
  bool get sender => role == 'sender';
  bool get enabled => snapshot['enabled'] != false;
  List<Map<String, dynamic>> get events => (state['events'] as List? ?? [])
      .map((e) => Map<String, dynamic>.from(e as Map))
      .toList();
  Future<void> init() async {
    await refresh();
    startPolling();
  }

  void startPolling() {
    _poll?.cancel();
    _poll = Timer.periodic(
        const Duration(seconds: 5), (_) => refresh(silent: true));
  }

  void stopPolling() {
    _poll?.cancel();
    _poll = null;
  }

  Future<void> refresh({bool silent = false}) async {
    if (busy && silent) return;
    try {
      snapshot = await backend.invoke('snapshot');
      if (!silent) error = null;
    } catch (_) {
      if (!silent) error = 'error';
    }
    loading = false;
    notifyListeners();
  }

  Future<bool> command(String name,
      [Map<String, dynamic> arguments = const {}]) async {
    if (busy) return false;
    busy = true;
    progress = name == 'record' && arguments['shareLocation'] == true
        ? 'locating'
        : 'saving';
    error = null;
    note = null;
    notifyListeners();
    try {
      final result = await backend.invoke(name, arguments);
      if (result['snapshot'] is Map)
        snapshot = Map<String, dynamic>.from(result['snapshot'] as Map);
      note = result['note'] as String?;
      return true;
    } on PlatformException catch (e) {
      error = switch (e.code) {
        'invalid_code' => 'invalidCode',
        'queue_full' => 'queueFull',
        'invalid_name' => 'nameError',
        'invalid_schedule' => 'scheduleInvalid',
        _ => 'error'
      };
      return false;
    } catch (_) {
      error = 'error';
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<bool> prefs(Map<String, dynamic> values) =>
      command('preferences', values);
  String actionLabel(String kind) => copy.label((state[kind] ??
      switch (kind) {
        'outside' => 'Keluar',
        'home' => 'Kost',
        _ => 'Makan'
      }) as String);
  String get locationLabel => switch (state['location']) {
        'home' => copy.fill('atPlace', actionLabel('home')),
        'outside' => actionLabel('outside'),
        _ => copy['unknown']
      };
  Map<String, dynamic> get zone =>
      Map<String, dynamic>.from(snapshot['zone'] as Map? ?? {});
  DateTime now() => DateTime.now();
  Map<String, dynamic> localZone(int at) => Map<String, dynamic>.from(
      (snapshot['localTimes'] as Map? ?? {})['$at'] as Map? ?? zone);
  String time(int at, {Map<String, dynamic>? inZone}) =>
      formatClock(at, clock12: clock12, zone: inZone ?? localZone(at));
  String stamp(int at, {Map<String, dynamic>? inZone}) =>
      formatStamp(at, copy, clock12: clock12, zone: inZone ?? localZone(at));
  String get connection {
    final pending = (snapshot['pending'] as num? ?? 0).toInt();
    return pending > 0
        ? copy.fill('queued', '$pending')
        : copy[snapshot['connection'] as String? ?? 'connecting'];
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }
}

int number(dynamic value) => (value as num? ?? 0).toInt();
DateTime zonedDate(int at, Map<String, dynamic> zone) {
  if (zone['offsetMinutes'] is num)
    return DateTime.fromMillisecondsSinceEpoch(at, isUtc: true)
        .add(Duration(minutes: number(zone['offsetMinutes'])));
  return DateTime.fromMillisecondsSinceEpoch(at).toLocal();
}

String clockDigits(DateTime date, bool twelve) {
  final hour = twelve ? (date.hour % 12 == 0 ? 12 : date.hour % 12) : date.hour;
  return '${twelve ? hour.toString() : hour.toString().padLeft(2, '0')}.${date.minute.toString().padLeft(2, '0')}${twelve ? (date.hour < 12 ? ' AM' : ' PM') : ''}';
}

String formatClock(int at,
    {bool clock12 = false, Map<String, dynamic> zone = const {}}) {
  final time = clockDigits(zonedDate(at, zone), clock12);
  final short = zone['short'] as String? ?? '';
  final country = zone['country'] as String? ?? '';
  return '$time${short.isEmpty ? '' : ' $short'}${country.isEmpty ? '' : ' - $country'}';
}

String dateLabel(DateTime d, Copy copy) =>
    '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
String formatStamp(int at, Copy copy,
    {bool clock12 = false, Map<String, dynamic> zone = const {}, int? now}) {
  if (at <= 0) return copy['unrecorded'];
  final d = zonedDate(at, zone),
      today = zonedDate(now ?? DateTime.now().millisecondsSinceEpoch, zone);
  final yesterday = DateTime(today.year, today.month, today.day - 1);
  bool same(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
  final label = same(d, today)
      ? copy['today']
      : same(d, yesterday)
          ? copy['yesterday']
          : dateLabel(d, copy);
  return '$label · ${formatClock(at, clock12: clock12, zone: zone)}';
}

int dayPhase(DateTime d) => d.hour >= 5 && d.hour < 11
    ? 0
    : d.hour >= 11 && d.hour < 15
        ? 1
        : d.hour >= 15 && d.hour < 18
            ? 2
            : 3;
