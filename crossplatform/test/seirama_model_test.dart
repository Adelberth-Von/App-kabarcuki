import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:abc/model.dart';

class ModeBackend extends Backend {
  final data = <String, dynamic>{
    'role': 'receiver',
    'mode': 'oneWay',
    'modeUpgradeSuggested': true,
    'profile': {'relationship': true, 'language': 'id', 'nickname': 'B'},
    'state': {'name': 'A', 'revision': 40, 'events': []},
  };
  Map<String, dynamic> arguments = {};
  @override
  Future<Map<String, dynamic>> invoke(String method,
      [Map<String, dynamic> values = const {}]) async {
    if (method == 'snapshot') return data;
    arguments = values;
    if (values['confirmed'] != true) {
      throw PlatformException(code: 'confirmation_required');
    }
    data.addAll({
      'role': 'duplex',
      'mode': 'seirama',
      'modeUpgradeSuggested': false,
      'reciprocity': 'waiting',
      'state': {'name': 'B', 'revision': 1, 'events': []},
      'peerState': {'name': 'A', 'revision': 40, 'events': []},
    });
    return {'snapshot': data};
  }
}
class OwnCodeBackend extends ModeBackend {
  @override
  Future<Map<String, dynamic>> invoke(String method,
      [Map<String, dynamic> arguments = const {}]) async {
    if (method == 'joinSeirama') throw PlatformException(code: 'own_code');
    return super.invoke(method, arguments);
  }
}

void main() {
  test('self-link error uses the specific translated partner-code guidance', () async {
    final model = AppModel(OwnCodeBackend());
    await model.refresh();
    expect(await model.joinSeirama('KB2.self', confirmed: true), isFalse);
    expect(model.error, 'ownCodeError');
    expect(model.role, 'receiver');
    model.dispose();
  });
  test('legacy appearance requests consent without creating reciprocal sharing',
      () async {
    final backend = ModeBackend(), model = AppModel(backend);
    await model.refresh();
    expect(model.together, isFalse);
    expect(model.modeUpgradeSuggested, isTrue);
    expect(model.sender, isFalse);
    expect(await model.enableSeirama(confirmed: false), isFalse);
    expect(model.role, 'receiver');
    expect(model.state['revision'], 40);
    expect(await model.enableSeirama(confirmed: true), isTrue);
    expect(backend.arguments['confirmed'], isTrue);
    expect(model.together, isTrue);
    expect(model.sender, isTrue);
    expect(model.state['name'], 'B');
    expect(model.peerName, 'A');
    expect(model.peerState?['revision'], 40);
    expect(model.reciprocity, 'waiting');
    model.dispose();
  });
  test('peer history and displayed clocks use independent snapshot slots', () {
    final model = AppModel(ModeBackend());
    const at = 1790931600000;
    model.snapshot = {
      'role': 'duplex', 'mode': 'seirama',
      'profile': {'language': 'id', 'clock12': true},
      'state': {'name': 'A', 'events': [{'kind': 'home'}]},
      'peerState': {'name': 'B', 'events': [{'kind': 'meal'}]},
      'peerMealsToday': [false, false, true],
      'localTimes': {'$at': {'offsetMinutes': 420, 'short': 'WIB'}},
      'peerLocalTimes': {'$at': {'offsetMinutes': 120, 'short': 'CEST'}},
    };
    expect(model.events.single['kind'], 'home');
    expect(model.peerEvents.single['kind'], 'meal');
    expect(model.peerMealsToday, [false, false, true]);
    expect(model.time(at), contains('WIB'));
    expect(model.peerTime(at), contains('CEST'));
    model.snapshot['profile'] = {'clock12': false};
    expect(model.time(at), isNot(contains(' AM')));
    expect(model.peerTime(at), isNot(contains(' PM')));
    model.dispose();
  });
}
