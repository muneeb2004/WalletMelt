import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:wallet_melt/src/data/local/wallet_melt_database.dart';
import 'package:wallet_melt/src/data/repositories/drift/drift_store_repository.dart';
import 'package:wallet_melt/src/screens/merchant/merchants_screen.dart';
import 'package:wallet_melt/src/state/app_state.dart';

void main() {
  late WalletMeltDatabase db;
  late DriftStoreRepository storeRepository;
  late AppState appState;

  setUp(() async {
    db = WalletMeltDatabase(NativeDatabase.memory());
    storeRepository = DriftStoreRepository(db);
    appState = AppState.test(
      driftStoreRepository: storeRepository,
    );
    await storeRepository.saveMerchant(
      name: 'Subway Clifton',
      defaultCategoryId: 'grocery',
      isFavorite: true,
      notes: 'Lunch place',
    );
    await storeRepository.saveMerchant(
      name: 'AutoCare Garage',
      defaultCategoryId: 'fuel',
      isFavorite: false,
      notes: 'Car workshop',
    );
    // Discovered history should NOT appear in saved merchants list
    await storeRepository.recordMerchantHistory('Random Corner Mart');
    await appState.refresh();
  });

  tearDown(() async {
    await db.close();
  });

  Widget buildHarness() {
    return ChangeNotifierProvider<AppState>.value(
      value: appState,
      child: const MaterialApp(
        home: MerchantsScreen(),
      ),
    );
  }

  group('MerchantsScreen Widget Tests', () {
    testWidgets('renders saved merchants and excludes history-only merchants', (tester) async {
      await tester.pumpWidget(buildHarness());
      await tester.pumpAndSettle();

      expect(find.text('Saved Merchants'), findsOneWidget);
      expect(find.text('Subway Clifton'), findsOneWidget);
      expect(find.text('AutoCare Garage'), findsOneWidget);
      // History-only entry must NOT be displayed
      expect(find.text('Random Corner Mart'), findsNothing);
    });

    testWidgets('search bar filters saved merchants list in real-time', (tester) async {
      await tester.pumpWidget(buildHarness());
      await tester.pumpAndSettle();

      // Enter search query
      await tester.enterText(find.byType(TextField).first, 'auto');
      await tester.pumpAndSettle();

      expect(find.text('AutoCare Garage'), findsOneWidget);
      expect(find.text('Subway Clifton'), findsNothing);
    });

    testWidgets('toggling favorite star updates merchant state', (tester) async {
      await tester.pumpWidget(buildHarness());
      await tester.pumpAndSettle();

      // AutoCare is not favorite initially
      final autoCare = appState.savedMerchants.firstWhere((m) => m.name == 'AutoCare Garage');
      expect(autoCare.isFavorite, isFalse);

      // Tap favorite star on AutoCare
      final starIcons = find.byIcon(Icons.star_outline_rounded);
      expect(starIcons, findsOneWidget);
      await tester.tap(starIcons);
      await tester.pumpAndSettle();

      final updatedAutoCare = appState.savedMerchants.firstWhere((m) => m.name == 'AutoCare Garage');
      expect(updatedAutoCare.isFavorite, isTrue);
    });
  });
}
