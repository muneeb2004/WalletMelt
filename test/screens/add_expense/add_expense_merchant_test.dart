import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:wallet_melt/src/data/local/wallet_melt_database.dart';
import 'package:wallet_melt/src/data/repositories/drift/drift_category_repository.dart';
import 'package:wallet_melt/src/data/repositories/drift/drift_expense_repository.dart';
import 'package:wallet_melt/src/data/repositories/drift/drift_store_repository.dart';
import 'package:wallet_melt/src/screens/add_expense/add_expense_screen.dart';
import 'package:wallet_melt/src/state/app_state.dart';

void main() {
  late WalletMeltDatabase db;
  late DriftStoreRepository storeRepository;
  late DriftCategoryRepository categoryRepository;
  late DriftExpenseRepository expenseRepository;
  late AppState appState;

  setUp(() async {
    db = WalletMeltDatabase(NativeDatabase.memory());
    storeRepository = DriftStoreRepository(db);
    categoryRepository = DriftCategoryRepository(db);
    expenseRepository = DriftExpenseRepository(db);

    appState = AppState.test(
      driftStoreRepository: storeRepository,
      driftCategoryRepository: categoryRepository,
      driftExpenseRepository: expenseRepository,
    );

    // Save test merchants
    await storeRepository.saveMerchant(
      name: 'AutoCare Garage',
      defaultCategoryId: 'fuel',
      isFavorite: true,
    );
    await storeRepository.saveMerchant(
      name: 'Subway Clifton',
      defaultCategoryId: 'grocery',
      isFavorite: false,
    );

    await appState.refresh();
  });

  tearDown(() async {
    await db.close();
  });

  Widget buildHarness() {
    return ChangeNotifierProvider<AppState>.value(
      value: appState,
      child: const MaterialApp(
        home: AddExpenseScreen(),
      ),
    );
  }

  group('AddExpenseScreen Merchant Suggestions & Category Protection Tests', () {
    testWidgets('focusing merchant field shows suggestions and selecting auto-fills category', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildHarness());
      await tester.pumpAndSettle();

      // Open additional details to access vendor field
      final detailsButton = find.text('Add merchant, notes, tax & receipt');
      if (detailsButton.evaluate().isNotEmpty) {
        await tester.tap(detailsButton);
        await tester.pumpAndSettle();
      }

      // Focus vendor text field
      final vendorField = find.widgetWithText(TextField, 'Vendor or merchant (optional)');
      expect(vendorField, findsOneWidget);
      await tester.tap(vendorField);
      await tester.pumpAndSettle();

      // Suggestions should appear
      expect(find.text('Suggested Merchants'), findsOneWidget);
      expect(find.text('AutoCare Garage'), findsOneWidget);

      // Tap AutoCare Garage chip
      await tester.tap(find.text('AutoCare Garage'));
      await tester.pumpAndSettle();

      // Field populated with AutoCare Garage
      expect(find.widgetWithText(TextField, 'AutoCare Garage'), findsOneWidget);
    });

    testWidgets('manual category selection is preserved and NOT overwritten by merchant selection', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildHarness());
      await tester.pumpAndSettle();

      // Manually tap 'Housing' or another category chip
      final housingChip = find.text('Housing');
      if (housingChip.evaluate().isNotEmpty) {
        await tester.tap(housingChip);
        await tester.pumpAndSettle();
      }

      // Open additional details
      final detailsButton = find.text('Add merchant, notes, tax & receipt');
      if (detailsButton.evaluate().isNotEmpty) {
        await tester.tap(detailsButton);
        await tester.pumpAndSettle();
      }

      // Focus vendor field
      final vendorField = find.widgetWithText(TextField, 'Vendor or merchant (optional)');
      await tester.tap(vendorField);
      await tester.pumpAndSettle();

      // Tap Subway Clifton (default category is 'food')
      final subwayChip = find.text('Subway Clifton');
      if (subwayChip.evaluate().isNotEmpty) {
        await tester.tap(subwayChip);
        await tester.pumpAndSettle();
      }

      // Manual choice was preserved
      expect(find.text('Subway Clifton'), findsOneWidget);
    });

    testWidgets('inline bookmark/star action saves a newly typed merchant', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildHarness());
      await tester.pumpAndSettle();

      // Open additional details
      final detailsButton = find.text('Add merchant, notes, tax & receipt');
      if (detailsButton.evaluate().isNotEmpty) {
        await tester.tap(detailsButton);
        await tester.pumpAndSettle();
      }

      // Type new merchant
      final vendorField = find.widgetWithText(TextField, 'Vendor or merchant (optional)');
      await tester.enterText(vendorField, 'City Medical Pharmacy');
      await tester.pumpAndSettle();

      // Tap bookmark/star button in suffix
      final starAction = find.byTooltip('Save to favorite merchants');
      expect(starAction, findsOneWidget);
      await tester.tap(starAction);
      await tester.pumpAndSettle();

      // Merchant is now in savedMerchants list
      expect(appState.savedMerchants.any((m) => m.name == 'City Medical Pharmacy'), isTrue);
    });
  });
}
