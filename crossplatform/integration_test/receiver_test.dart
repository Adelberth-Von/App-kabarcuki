import 'package:abc/main.dart';
import 'package:abc/model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
      'receiver reads encrypted updates in its own language and time zone',
      (tester) async {
    const code = String.fromEnvironment('PAIRING_CODE');
    expect(code.isNotEmpty, true,
        reason: 'Provide a private pairing fixture on a fresh test device.');
    final backend = NativeBackend();
    final before = await backend.invoke('snapshot');
    expect(before['role'], '', reason: 'Use a fresh receiver simulator.');
    await backend.invoke('preferences', {
      'nickname': 'Mama',
      'language': 'en',
      'clock12': true,
      'relationship': false,
      'dark': false
    });
    await backend.invoke('setupReceiver', {'code': code});
    final model = AppModel(backend);
    await tester.pumpWidget(AbcApp(model: model));
    await tester.pumpAndSettle();
    for (var i = 0; number(model.state['revision']) == 0 && i < 90; i++) {
      await Future<void>.delayed(const Duration(seconds: 1));
      await tester.pumpAndSettle();
    }
    expect(model.role, 'receiver');
    expect(number(model.state['revision']), greaterThan(0));
    expect(find.byKey(const ValueKey('status-home')), findsNothing);
    expect(find.text('Hi, Mama'), findsOneWidget);
    expect(model.clock12, true);
    expect(model.zone['country'], 'Germany');
    await expectLater(
        backend.invoke('record', {'kind': 'outside', 'shareLocation': false}),
        throwsA(isA<PlatformException>()));
    if (model.snapshot['platform'] == 'android') {
      await binding.convertFlutterSurfaceToImage();
      await tester.pump();
    }
    await binding.takeScreenshot('abc-receiver-home');
    final initial = number(model.state['revision']);
    await tester.tap(find.text('History').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('detail-0')));
    await tester.pumpAndSettle();
    await binding.takeScreenshot('abc-receiver-detail');
    expect(find.text(model.copy['senderTime']), findsOneWidget);
    // Leave the native receiving service active; a later status is checked independently.
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    expect(initial, greaterThan(0));
    // AbcApp owns and disposes the model.
  });
}
