import 'package:flutter/widgets.dart';
import 'package:abc/main.dart';
import 'package:abc/model.dart';

/// Local UI preview only: no pairing capabilities, GPS or network backend.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(AbcApp(model: AppModel(ThemePreviewBackend())));
}

class ThemePreviewBackend extends Backend {
  final Map<String, dynamic> data;

  ThemePreviewBackend()
    : data = {
        'profile': {
          'nickname': '',
          'language': 'id',
          'dark': false,
          'relationship': false,
          'clock12': false,
          'animations': false,
        },
        'role': '',
        'mode': 'oneWay',
        'reciprocity': 'none',
        'platform': 'android',
        'connection': 'sent',
        'enabled': true,
        'pending': 0,
        'energySaver': false,
        'mealsToday': [true, false, false],
        'zone': {'id': 'Asia/Jakarta', 'short': 'WIB', 'country': 'Indonesia'},
        'state': _state('Nara'),
      };

  static Map<String, dynamic> _state(String name) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final point = {
      'lat': -7.7956,
      'lon': 110.3695,
      'accuracy': 12,
      'at': now - 600000,
      'zone': 'Asia/Jakarta',
      'city': 'Yogyakarta',
      'place': 'Gondomanan',
    };
    const origin = {
      'short': 'WIB',
      'country': 'Indonesia',
      'offsetMinutes': 420,
    };
    return {
      'name': name,
      'outside': 'Keluar',
      'home': 'Kost',
      'meal': 'Makan',
      'zone': 'Asia/Jakarta',
      'windows': [5, 10, 10, 15, 17, 22],
      'location': 'home',
      'locationAt': now - 600000,
      'homeAt': now - 600000,
      'breakfastAt': now - 7200000,
      'mealAt': now - 7200000,
      'gps': point,
      'events': [
        {
          'kind': 'home',
          'label': 'Di kost',
          'at': now - 600000,
          'zone': 'Asia/Jakarta',
          'originInfo': origin,
          'gps': point,
        },
        {
          'kind': 'meal',
          'label': 'Sarapan',
          'at': now - 7200000,
          'zone': 'Asia/Jakarta',
          'originInfo': origin,
        },
        {
          'kind': 'outside',
          'label': 'Keluar',
          'at': now - 10800000,
          'zone': 'Asia/Jakarta',
          'originInfo': origin,
        },
      ],
    };
  }

  @override
  Future<Map<String, dynamic>> invoke(
    String method, [
    Map<String, dynamic> arguments = const {},
  ]) async {
    if (method == 'snapshot') return data;
    if (method == 'preferences') {
      final profile = Map<String, dynamic>.from(data['profile'] as Map);
      profile.addAll(arguments);
      data['profile'] = profile;
    } else if (method == 'setupSender') {
      data['role'] = 'sender';
      (data['state'] as Map)['name'] = (data['profile'] as Map)['nickname'];
    } else if (method == 'enableSeirama') {
      data['role'] = 'duplex';
      data['mode'] = 'seirama';
      data['reciprocity'] = 'active';
      data['peerState'] = _state('Mama');
      data['peerMealsToday'] = [true, false, false];
      data['peerZone'] = data['zone'];
    } else if (method == 'pairCode') {
      return {'code': 'PREVIEW-ONLY-NOT-A-PAIRING-CODE'};
    } else if (method == 'record') {
      final state = data['state'] as Map;
      final kind = arguments['kind'];
      final now = DateTime.now().millisecondsSinceEpoch;
      state['events'] = [
        {
          'kind': kind,
          'label': kind == 'meal'
              ? 'Makan'
              : kind == 'home'
              ? 'Di kost'
              : 'Keluar',
          'at': now,
          'zone': 'Asia/Jakarta',
        },
        ...state['events'] as List,
      ];
    }
    return {'snapshot': data};
  }
}
