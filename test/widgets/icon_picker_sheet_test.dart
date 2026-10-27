import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_melt/src/services/svg/svg_customization_service.dart';
import 'package:wallet_melt/src/widgets/icon_picker_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('walletmelt_picker_');
    SvgCustomizationService.instance.setBaseDirForTesting(tempDir.path);
  });

  tearDown(() async {
    SvgCustomizationService.instance.resetForTesting();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  Future<ValueNotifier<String?>> open(
    WidgetTester tester, {
    String? current,
    String? suggestFor,
  }) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final result = ValueNotifier<String?>(null);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                result.value = await showIconPicker(context,
                    current: current, suggestFor: suggestFor);
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return result;
  }

  testWidgets('offers icons, emoji and uploads without any code field',
      (tester) async {
    await open(tester);

    expect(find.text('Choose an icon'), findsOneWidget);
    expect(find.text('Icons'), findsOneWidget);
    expect(find.text('Emoji'), findsOneWidget);
    expect(find.text('Yours'), findsOneWidget);
    expect(find.text('Upload your own SVG'), findsOneWidget);
    expect(find.textContaining('<svg'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('suggests icons that match the category name', (tester) async {
    await open(tester, suggestFor: 'Food');
    expect(find.text('Suggested for you'), findsOneWidget);
  });

  testWidgets('search finds an icon by keyword and returns its id',
      (tester) async {
    final result = await open(tester);

    await tester.enterText(find.byType(TextField), 'petrol');
    await tester.pumpAndSettle();
    expect(find.text('Results'), findsOneWidget);

    await tester.tap(find.byTooltip('Fuel'));
    await tester.pumpAndSettle();
    expect(result.value, 'fuel');
  });

  testWidgets('emoji tab returns an emoji id', (tester) async {
    final result = await open(tester);

    await tester.tap(find.text('Emoji'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Pizza').first);
    await tester.pumpAndSettle();
    expect(result.value, 'emoji:🍕');
  });

  testWidgets('shows a friendly empty state for no matches', (tester) async {
    await open(tester);
    await tester.enterText(find.byType(TextField), 'zzzzqq');
    await tester.pumpAndSettle();
    expect(find.textContaining('No icons match'), findsOneWidget);
  });

  testWidgets('fits above the keyboard without overflowing', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.view.resetViewInsets();
    });
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showIconPicker(context),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Choose an icon'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
