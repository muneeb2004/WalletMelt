import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:wallet_melt/src/screens/settings/metric_calculations_screen.dart';
import 'package:wallet_melt/src/screens/settings/svg_editor_dialog.dart';
import 'package:wallet_melt/src/screens/settings/svg_manager_screen.dart';
import 'package:wallet_melt/src/services/svg/svg_customization_service.dart';
import 'package:wallet_melt/src/state/app_state.dart';
import 'package:wallet_melt/src/types/debt.dart';
import 'package:wallet_melt/src/types/settings.dart';

class _FakeAppState extends ChangeNotifier implements AppState {
  @override
  final WalletMeltSettings settings = WalletMeltSettings.defaults;

  @override
  DateTime get selectedMonth => DateTime(2026, 9, 1);

  @override
  double getCurrentMonthTotalSpent() => 15000.0;

  @override
  double? getMonthlyBudgetAmount([String? month]) => 30000.0;

  @override
  List<DebtRecord> get debts => const [];

  @override
  set debts(List<DebtRecord> value) {}

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('walletmelt_screens_test_');
    SvgCustomizationService.instance.setBaseDirForTesting(tempDir.path);
  });

  tearDown(() async {
    SvgCustomizationService.instance.resetForTesting();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('MetricCalculationsScreen - Widget Tests', () {
    testWidgets('renders all metric breakdown sections including Daily Allowance hero',
        (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ChangeNotifierProvider<AppState>.value(
          value: _FakeAppState(),
          child: const MaterialApp(
            home: MetricCalculationsScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Metric Calculations'), findsOneWidget);
      expect(find.text('Daily Spend Allowance Formula'), findsOneWidget);
      expect(find.textContaining('FEATURED: PER DAY ALLOWANCE'), findsOneWidget);
      expect(find.textContaining('BUDGET PROGRESS & UTILIZATION'), findsOneWidget);
      expect(find.textContaining('SPENDING VELOCITY & PROJECTED TOTAL'), findsOneWidget);
      expect(find.textContaining('FINANCIAL OBLIGATIONS (DEBT)'), findsOneWidget);
      expect(find.textContaining('SUBSCRIPTION BILLING NORMALIZATION'), findsOneWidget);

      // Verify formula details before scrolling to bottom
      expect(find.textContaining('where Remaining Budget = Total Monthly Budget'), findsOneWidget);
      expect(find.textContaining('Why is "+ 1" added to remaining days?'), findsOneWidget);

      final taxSectionFinder = find.textContaining('TAX CALCULATIONS');
      await tester.scrollUntilVisible(taxSectionFinder, 300.0);
      expect(taxSectionFinder, findsOneWidget);
    });
  });

  group('SvgManagerScreen - Widget Tests', () {
    testWidgets('renders icon list, search box, and filter chips', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: SvgManagerScreen(),
        ),
      );
      await tester.pump();
      // Allow async _loadIcons to complete and setState
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Icon & SVG Manager'), findsOneWidget);
      expect(find.text('Across-the-Board SVG Reflection'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget); // Search box
      expect(find.textContaining('All Icons'), findsOneWidget);
      expect(find.text('Preset SVGs'), findsOneWidget);
      expect(find.text('Standard Categories'), findsOneWidget);

      // Verify standard icons are displayed
      expect(find.text('Electricity / Power'), findsOneWidget);
      expect(find.text('Grocery / Mart'), findsOneWidget);
    });
  });

  group('SvgEditorDialog - Widget Tests', () {
    const item = SvgIconItem(
      id: 'electricity',
      label: 'Electricity / Power',
      type: SvgIconType.standard,
    );

    void phone(WidgetTester tester) {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    }

    const strokeSvg =
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">'
        '<path d="M4 4h16v16H4z" fill="none" stroke="currentColor" stroke-width="2"/></svg>';

    // Seeding an override keeps the editor off the asset bundle, which is
    // unreliable under fake async across tests.
    Future<void> seed(WidgetTester tester) => tester.runAsync(() =>
        SvgCustomizationService.instance
            .saveOverride(rawId: 'electricity', svgContent: strokeSvg));

    Future<void> openEditor(WidgetTester tester, {String? usedBy}) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () =>
                      SvgEditorDialog.show(context, item, usedBy: usedBy),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pump();
      // Let the real asset/file load finish, then rebuild.
      for (var i = 0; i < 40 && find.text('Edit icon').evaluate().isEmpty; i++) {
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 100)));
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tester.pump(const Duration(milliseconds: 500));
    }

    testWidgets('shows header actions, preview and style tools', (tester) async {
      phone(tester);
      await seed(tester);
      await openEditor(tester);

      expect(find.text('Electricity / Power'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);
      expect(find.byTooltip('Undo'), findsOneWidget);
      expect(find.byTooltip('Redo'), findsOneWidget);
      expect(find.text('Theme colour'), findsOneWidget);
      expect(find.text('Used by: Food'), findsNothing);
      expect(find.text('Edited'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows the used-by line when opened from a category',
        (tester) async {
      phone(tester);
      await seed(tester);
      await openEditor(tester, usedBy: 'Food');

      expect(find.text('Used by: Food'), findsOneWidget);
      expect(find.text('Electricity / Power'), findsOneWidget);
    });

    testWidgets('edited icon stays editable and Save is reachable at 360px',
        (tester) async {
      phone(tester);
      await seed(tester);
      await openEditor(tester);

      expect(find.text('Edited'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Make a change: Save becomes enabled and sits fully on screen.
      await tester.tap(find.text('Transform'));
      await tester.pump();
      await tester.tap(find.text('Rotate right'));
      await tester.pump();

      final save = find.widgetWithText(FilledButton, 'Save');
      expect(tester.widget<FilledButton>(save).onPressed, isNotNull);
      final rect = tester.getRect(save);
      expect(rect.right, lessThanOrEqualTo(360));
      expect(rect.height, greaterThanOrEqualTo(40));
      expect(tester.takeException(), isNull);
    });

    testWidgets('asks before discarding unsaved changes', (tester) async {
      phone(tester);
      await seed(tester);
      await openEditor(tester);

      await tester.tap(find.text('Transform'));
      await tester.pump();
      await tester.tap(find.text('Rotate right'));
      await tester.pump();

      await tester.tap(find.byTooltip('Close'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Discard changes?'), findsOneWidget);

      await tester.tap(find.text('Keep editing'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Discard changes?'), findsNothing);
      expect(find.text('Edit icon'), findsOneWidget);

      await tester.tap(find.byTooltip('Close'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Discard'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Edit icon'), findsNothing);
    });
  });
}
