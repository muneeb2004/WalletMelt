import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wallet_melt/src/screens/debt/debt_screen.dart';
import 'package:wallet_melt/src/state/app_state.dart';
import 'package:wallet_melt/src/types/debt.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget buildDebtScreen(AppState appState) {
    return MaterialApp(
      home: ChangeNotifierProvider<AppState>.value(
        value: appState,
        child: const DebtScreen(),
      ),
    );
  }

  group('DebtScreen Search Functionality & Keyboard Integration', () {
    testWidgets('Search query filters debts and clear button clears field text and reset results', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      const debt1 = DebtRecord(
        id: 'debt-1',
        personName: 'Alexander Graham',
        type: DebtType.owedToMe,
        principalAmount: 100.0,
        remainingAmount: 100.0,
        currency: 'USD',
        createdAt: '2026-08-01T10:00:00Z',
        status: DebtStatus.active,
        description: 'Dinner split',
      );

      const debt2 = DebtRecord(
        id: 'debt-2',
        personName: 'Beatrix Potter',
        type: DebtType.iOwe,
        principalAmount: 50.0,
        remainingAmount: 50.0,
        currency: 'USD',
        createdAt: '2026-08-02T10:00:00Z',
        status: DebtStatus.active,
        description: 'Book purchase',
      );

      final appState = AppState.test();
      appState.debts = [debt1, debt2];

      await tester.pumpWidget(buildDebtScreen(appState));
      await tester.pumpAndSettle();

      // Both debts are visible on screen
      expect(find.text('Alexander Graham'), findsOneWidget);
      expect(find.text('Beatrix Potter'), findsOneWidget);

      // Type Alexander in search
      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'Alexander');
      await tester.pumpAndSettle();

      // Only Alexander is visible
      expect(find.text('Alexander Graham'), findsOneWidget);
      expect(find.text('Beatrix Potter'), findsNothing);

      // Verify clear button is present
      final clearButton = find.byIcon(Icons.clear_rounded);
      expect(clearButton, findsOneWidget);

      // Tap clear button
      await tester.tap(clearButton);
      await tester.pumpAndSettle();

      // Verify TextField text is cleared
      final TextField fieldWidget = tester.widget(searchField);
      expect(fieldWidget.controller?.text, '');

      // Verify both debts are visible again
      expect(find.text('Alexander Graham'), findsOneWidget);
      expect(find.text('Beatrix Potter'), findsOneWidget);
    });
  });
}
