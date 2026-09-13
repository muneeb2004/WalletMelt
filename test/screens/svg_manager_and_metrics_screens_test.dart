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
    testWidgets('renders preview, quick color palette, and XML editor',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const item = SvgIconItem(
        id: 'electricity',
        label: 'Electricity / Power',
        type: SvgIconType.standard,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SvgEditorDialog(iconItem: item),
          ),
        ),
      );
      await tester.pump();
      // Allow async _loadInitialContent to complete and setState
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Electricity / Power'), findsOneWidget);
      expect(find.text('LIVE PREVIEW (SCALED RENDERING)'), findsOneWidget);
      expect(find.text('QUICK COLOR ACCENT'), findsOneWidget);
      expect(find.text('SVG MARKUP (XML EDITOR)'), findsOneWidget);
      expect(find.text('Save & Reflect Everywhere'), findsOneWidget);
    });
  });
}
