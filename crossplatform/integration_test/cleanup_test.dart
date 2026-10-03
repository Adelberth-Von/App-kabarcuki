import 'package:abc/model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('scoped cleanup on the disposable receiver fixture', (tester) async {
    expect(const bool.fromEnvironment('QA_DISPOSABLE'),true);
    final backend=NativeBackend(),before=await NativeBackend().invoke('snapshot');
    expect(before['role'],'receiver');
    expect((before['profile'] as Map)['nickname'],'Mama');
    final seed=await backend.invoke('qaCleanupProbe',{'seed':true});
    expect(seed['filesClear'],false);expect(seed['secretsClear'],false);
    await backend.invoke('prepareUninstall');
    await Future<void>.delayed(const Duration(seconds:1));
    for(final check in (await backend.invoke('qaCleanupProbe')).entries)expect(check.value,true,reason:check.key);
    final empty=await backend.invoke('snapshot');
    expect(empty['role'],'');expect(empty['pending'],0);
    expect((empty['state'] as Map)['events'],isEmpty);
    expect((empty['profile'] as Map)['nickname'],'');
  });
}
