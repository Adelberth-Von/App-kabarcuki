// Explicitly run this file to render local previews; no emulator or native API.
import 'dart:io';
import 'dart:ui' as ui;
import 'package:abc/main.dart';
import 'package:abc/cozy_ui.dart';
import 'package:abc/model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'theme_preview.dart' show ThemePreviewBackend;

Future<void> loadPreviewFonts() async {
  for (final entry in {
    'Silkscreen': [
      'assets/fonts/silkscreen/Silkscreen-Regular.ttf',
      'assets/fonts/silkscreen/Silkscreen-Bold.ttf',
    ],
    'packages/pixelarticons/Pixel Art Icons': [
      'packages/pixelarticons/fonts/pixelarticons.otf',
    ],
  }.entries) {
    final loader = FontLoader(entry.key);
    for (final path in entry.value) {
      loader.addFont(rootBundle.load(path));
    }
    await loader.load();
  }
  final sdk =
      Platform.environment['FLUTTER_ROOT'] ?? '../../../work/tools/flutter';
  final material = Directory('$sdk/bin/cache/artifacts/material_fonts');
  final body = FontLoader('sans-serif');
  for (final name in [
    'roboto-regular.ttf',
    'roboto-medium.ttf',
    'roboto-bold.ttf',
  ]) {
    final bytes = await File('${material.path}/$name').readAsBytes();
    body.addFont(Future.value(ByteData.sublistView(bytes)));
  }
  await body.load();
  final icons = FontLoader('MaterialIcons');
  icons.addFont(
    Future.value(
      ByteData.sublistView(
        await File('${material.path}/materialicons-regular.otf').readAsBytes(),
      ),
    ),
  );
  await icons.load();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadPreviewFonts);
  testWidgets('render the actual cozy pages with an offline fixture', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final boundary = GlobalKey();
    final backend = ThemePreviewBackend();
    final model = AppModel(backend);
    final directory = Directory('qa-screenshots/cozy-redesign');
    directory.createSync(recursive: true);
    await tester.pumpWidget(
      RepaintBoundary(
        key: boundary,
        child: AbcApp(model: model),
      ),
    );
    await tester.pumpAndSettle();

    Future<void> capture(String name) async {
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.runAsync(() async {
        final render =
            boundary.currentContext!.findRenderObject()
                as RenderRepaintBoundary;
        final image = await render.toImage(pixelRatio: 2);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        await File(
          '${directory.path}/$name.png',
        ).writeAsBytes(data!.buffer.asUint8List());
        image.dispose();
      });
    }

    Future<void> tap(String key) async {
      final finder = find.byKey(ValueKey(key));
      await tester.ensureVisible(finder);
      await tester.pumpAndSettle();
      await tester.tap(finder);
      await tester.pumpAndSettle();
    }

    Future<void> top() async {
      final scroll = find.byType(SingleChildScrollView).first;
      await tester.drag(scroll, const Offset(0, 2500));
      await tester.pumpAndSettle();
    }

    await capture('01-welcome');
    await tester.enterText(
      find.byKey(const ValueKey('nickname-input')),
      'Nara',
    );
    await tap('onboarding-continue');
    await top();
    await capture('02-roles');
    await tester.ensureVisible(find.text('Seirama'));
    await tester.pumpAndSettle();
    await capture('03-roles-seirama');
    await tap('setup-sender');
    await capture('04-home-light');
    await model.prefs({'dark': true});
    await capture('05-home-dark');
    await model.prefs({'dark': false});
    await tap('status-outside');
    await capture('14-status-confirmation');
    await tap('cancel-status');
    await tester.ensureVisible(
      find
          .ancestor(
            of: find.byKey(const ValueKey('meal-0')),
            matching: find.byType(CozyCard),
          )
          .first,
    );
    await tester.pumpAndSettle();
    await capture('06-meals');
    await tap('tab-1');
    await capture('07-history');
    await tap('detail-0');
    await capture('08-detail');
    await tester.tap(find.byTooltip('Tutup'));
    await tester.pumpAndSettle();
    await tap('tab-2');
    await capture('09-settings');
    final appearanceCard = find
        .ancestor(
          of: find.byKey(const ValueKey('appearance-dark')),
          matching: find.byType(CozyCard),
        )
        .first;
    await tester.ensureVisible(appearanceCard);
    await tester.pumpAndSettle();
    await capture('10-appearance-light');
    await tap('appearance-dark');
    await tester.ensureVisible(appearanceCard);
    await tester.pumpAndSettle();
    await capture('11-appearance-dark');
    await tester.ensureVisible(find.byKey(const ValueKey('developer-credit')));
    await tester.pumpAndSettle();
    await capture('12-settings-footer');
    await model.command('enableSeirama');
    await tap('tab-0');
    await top();
    await capture('13-seirama-dark');
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
}
