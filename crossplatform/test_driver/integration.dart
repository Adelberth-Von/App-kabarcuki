import 'dart:io';
import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() =>
    integrationDriver(onScreenshot: (name, bytes, [args]) async {
      final dir = Directory('qa-screenshots');
      await dir.create(recursive: true);
      await File('${dir.path}/$name.png').writeAsBytes(bytes);
      return true;
    }, responseDataCallback: (data) async {
      final screenshots=(data?['screenshots'] as List? ?? []).map((item)=>(item as Map)['screenshotName']).toSet();
      const required={'abc-home','abc-confirm','abc-history','abc-detail','abc-appearance-dark','abc-appearance-light','abc-relationship-home','abc-relationship-dark-home','abc-settings'};
      if(data?['nativeCompleted']!=true || !screenshots.containsAll(required)) {
        throw StateError('Native UI QA did not complete all assertions and required screenshots.');
      }
      await writeResponseData(data);
    });
