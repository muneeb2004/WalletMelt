import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_melt/src/theme/wallet_melt_theme.dart';

void main() {
  group('WalletMelt Theme Modal Branding & Tokens', () {
    test('Dark theme provides proper BottomSheetThemeData tokens', () {
      final darkTheme = WalletMeltTheme.dark();
      final sheetTheme = darkTheme.bottomSheetTheme;

      expect(sheetTheme.backgroundColor, equals(WalletMeltColors.darkSurface));
      expect(sheetTheme.modalBackgroundColor, equals(WalletMeltColors.darkSurface));
      expect(sheetTheme.surfaceTintColor, equals(Colors.transparent));
      expect(sheetTheme.elevation, equals(0));
      expect(sheetTheme.modalElevation, equals(0));
      expect(sheetTheme.showDragHandle, isTrue);
      expect(sheetTheme.dragHandleSize, equals(const Size(32, 4)));
      expect(sheetTheme.clipBehavior, equals(Clip.antiAlias));

      final shape = sheetTheme.shape as RoundedRectangleBorder?;
      expect(shape, isNotNull);
      final radius = shape!.borderRadius as BorderRadius;
      expect(radius.topLeft.x, equals(AppSpacing.radiusLg));
      expect(radius.topRight.x, equals(AppSpacing.radiusLg));
      expect(radius.bottomLeft.x, equals(0));
      expect(radius.bottomRight.x, equals(0));
      expect(shape.side.color, equals(WalletMeltColors.darkBorder));
      expect(shape.side.width, equals(1.0));
    });

    test('Light theme provides proper BottomSheetThemeData tokens', () {
      final lightTheme = WalletMeltTheme.light();
      final sheetTheme = lightTheme.bottomSheetTheme;

      expect(sheetTheme.backgroundColor, equals(Colors.white));
      expect(sheetTheme.modalBackgroundColor, equals(Colors.white));
      expect(sheetTheme.surfaceTintColor, equals(Colors.transparent));
      expect(sheetTheme.elevation, equals(0));
      expect(sheetTheme.showDragHandle, isTrue);
      expect(sheetTheme.dragHandleSize, equals(const Size(32, 4)));

      final shape = sheetTheme.shape as RoundedRectangleBorder?;
      expect(shape, isNotNull);
      final radius = shape!.borderRadius as BorderRadius;
      expect(radius.topLeft.x, equals(AppSpacing.radiusLg));
      expect(radius.topRight.x, equals(AppSpacing.radiusLg));
      expect(shape.side.color, equals(WalletMeltColors.lightBorder));
      expect(shape.side.width, equals(1.0));
    });

    test('Dark theme provides proper DialogThemeData tokens', () {
      final darkTheme = WalletMeltTheme.dark();
      final dialogTheme = darkTheme.dialogTheme;

      expect(dialogTheme.backgroundColor, equals(WalletMeltColors.darkSurface));
      expect(dialogTheme.surfaceTintColor, equals(Colors.transparent));
      expect(dialogTheme.elevation, equals(0));

      final shape = dialogTheme.shape as RoundedRectangleBorder?;
      expect(shape, isNotNull);
      final radius = shape!.borderRadius as BorderRadius;
      expect(radius.topLeft.x, equals(AppSpacing.radiusLg));
      expect(radius.bottomRight.x, equals(AppSpacing.radiusLg));
      expect(shape.side.color, equals(WalletMeltColors.darkBorder));
      expect(shape.side.width, equals(1.0));
    });
  });

  group('Modal Z-Order and Scrim Barrier Tests', () {
    testWidgets('showAppBottomSheet defaults useRootNavigator to true and renders on root Navigator', (tester) async {
      int navBarTapCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          theme: WalletMeltTheme.dark(),
          home: Scaffold(
            body: Stack(
              children: [
                // Simulating nested tab Navigator
                Positioned.fill(
                  child: Navigator(
                    onGenerateRoute: (settings) => MaterialPageRoute(
                      builder: (nestedContext) => Center(
                        child: ElevatedButton(
                          key: const ValueKey('open_sheet_button'),
                          onPressed: () {
                            showAppBottomSheet<void>(
                              nestedContext,
                              builder: (sheetContext) => const SizedBox(
                                height: 200,
                                child: Center(child: Text('Modal Bottom Sheet Content')),
                              ),
                            );
                          },
                          child: const Text('Open Sheet'),
                        ),
                      ),
                    ),
                  ),
                ),
                // Simulating Floating Nav Bar in parent stack
                Positioned(
                  left: 24,
                  right: 24,
                  bottom: 18,
                  child: GestureDetector(
                    key: const ValueKey('floating_nav_bar'),
                    onTap: () {
                      navBarTapCount++;
                    },
                    child: Container(
                      height: 64,
                      color: Colors.blue,
                      child: const Center(child: Text('Floating Nav Bar')),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      // Verify floating nav is tappable initially
      await tester.tap(find.byKey(const ValueKey('floating_nav_bar')));
      await tester.pumpAndSettle();
      expect(navBarTapCount, equals(1));

      // Open the sheet
      await tester.tap(find.byKey(const ValueKey('open_sheet_button')));
      await tester.pumpAndSettle();

      // Verify sheet is open
      expect(find.byType(BottomSheet), findsOneWidget);

      // Verify the sheet rendered on root Navigator above the nested Navigator
      final rootNav = tester.state<NavigatorState>(find.byType(Navigator).first);
      final nestedNav = tester.state<NavigatorState>(find.byType(Navigator).last);
      expect(rootNav, isNot(equals(nestedNav)));

      // Tap on the floating nav bar area (covered by the bottom sheet on root overlay)
      await tester.tapAt(tester.getCenter(find.byKey(const ValueKey('floating_nav_bar'))));
      await tester.pumpAndSettle();

      // Nav bar tap count should NOT have incremented because the sheet / root overlay absorbs it
      expect(navBarTapCount, equals(1));

      // Tap on the scrim/barrier above the sheet to dismiss
      await tester.tapAt(const Offset(50, 50));
      await tester.pumpAndSettle();

      // Modal should now be dismissed
      expect(find.byType(BottomSheet), findsNothing);
    });

    testWidgets('showConfirmDialog defaults useRootNavigator to true and renders on root Navigator', (tester) async {
      bool? confirmResult;

      await tester.pumpWidget(
        MaterialApp(
          theme: WalletMeltTheme.dark(),
          home: Scaffold(
            body: Navigator(
              onGenerateRoute: (settings) => MaterialPageRoute(
                builder: (nestedContext) => Center(
                  child: ElevatedButton(
                    key: const ValueKey('open_dialog_button'),
                    onPressed: () async {
                      confirmResult = await showConfirmDialog(
                        nestedContext,
                        title: 'Confirm Delete',
                        body: 'Are you sure?',
                        confirmLabel: 'Delete',
                        isDestructive: true,
                      );
                    },
                    child: const Text('Open Dialog'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      // Open confirm dialog
      await tester.tap(find.byKey(const ValueKey('open_dialog_button')));
      await tester.pumpAndSettle();

      expect(find.text('Confirm Delete'), findsOneWidget);
      expect(find.text('Are you sure?'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);

      // Tap Confirm
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(confirmResult, isTrue);
      expect(find.text('Confirm Delete'), findsNothing);
    });

    testWidgets('Raw showDialog with useRootNavigator: true renders on root Navigator overlay and absorbs nav bar taps', (tester) async {
      int navBarTapCount = 0;
      String? enteredValue;

      await tester.pumpWidget(
        MaterialApp(
          theme: WalletMeltTheme.dark(),
          home: Scaffold(
            body: Stack(
              children: [
                // Simulating nested branch Navigator
                Positioned.fill(
                  child: Navigator(
                    onGenerateRoute: (settings) => MaterialPageRoute(
                      builder: (nestedContext) => Center(
                        child: ElevatedButton(
                          key: const ValueKey('open_raw_dialog_button'),
                          onPressed: () async {
                            final controller = TextEditingController(text: 'Initial Value');
                            final res = await showDialog<String>(
                              context: nestedContext,
                              useRootNavigator: true,
                              barrierDismissible: false,
                              builder: (dialogCtx) => AlertDialog(
                                title: const Text('Raw Template Dialog'),
                                content: TextField(controller: controller),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(dialogCtx, controller.text),
                                    child: const Text('Save'),
                                  ),
                                ],
                              ),
                            );
                            enteredValue = res;
                          },
                          child: const Text('Open Raw Dialog'),
                        ),
                      ),
                    ),
                  ),
                ),
                // Simulating Floating Nav Bar in parent stack
                Positioned(
                  left: 24,
                  right: 24,
                  bottom: 18,
                  child: GestureDetector(
                    key: const ValueKey('floating_nav_bar_dialog_test'),
                    onTap: () {
                      navBarTapCount++;
                    },
                    child: Container(
                      height: 64,
                      color: Colors.red,
                      child: const Center(child: Text('Floating Nav Bar')),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      // Verify floating nav is tappable initially
      await tester.tap(find.byKey(const ValueKey('floating_nav_bar_dialog_test')));
      await tester.pumpAndSettle();
      expect(navBarTapCount, equals(1));

      // Open the raw dialog
      await tester.tap(find.byKey(const ValueKey('open_raw_dialog_button')));
      await tester.pumpAndSettle();

      // Verify dialog is visible
      expect(find.text('Raw Template Dialog'), findsOneWidget);

      // Verify root vs nested navigator
      final navigators = tester.widgetList<Navigator>(find.byType(Navigator)).toList();
      expect(navigators.length, greaterThanOrEqualTo(2));

      // Tap on the floating nav bar area beneath the modal scrim
      await tester.tapAt(tester.getCenter(find.byKey(const ValueKey('floating_nav_bar_dialog_test'))));
      await tester.pumpAndSettle();

      // Nav bar tap count should NOT have incremented
      expect(navBarTapCount, equals(1));

      // Tap Save in dialog
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(enteredValue, equals('Initial Value'));
      expect(find.text('Raw Template Dialog'), findsNothing);
    });

    testWidgets('Raw showModalBottomSheet with useRootNavigator: true renders on root Navigator overlay and absorbs nav bar taps', (tester) async {
      int navBarTapCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          theme: WalletMeltTheme.dark(),
          home: Scaffold(
            body: Stack(
              children: [
                Positioned.fill(
                  child: Navigator(
                    onGenerateRoute: (settings) => MaterialPageRoute(
                      builder: (nestedContext) => Center(
                        child: ElevatedButton(
                          key: const ValueKey('open_raw_sheet_button'),
                          onPressed: () {
                            showModalBottomSheet<void>(
                              context: nestedContext,
                              useRootNavigator: true,
                              builder: (sheetCtx) => const SizedBox(
                                height: 180,
                                child: Center(child: Text('Raw Sheet Content')),
                              ),
                            );
                          },
                          child: const Text('Open Raw Sheet'),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 24,
                  right: 24,
                  bottom: 18,
                  child: GestureDetector(
                    key: const ValueKey('floating_nav_bar_sheet_test'),
                    onTap: () {
                      navBarTapCount++;
                    },
                    child: Container(
                      height: 64,
                      color: Colors.green,
                      child: const Center(child: Text('Floating Nav Bar')),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      // Verify floating nav is tappable initially
      await tester.tap(find.byKey(const ValueKey('floating_nav_bar_sheet_test')));
      await tester.pumpAndSettle();
      expect(navBarTapCount, equals(1));

      // Open the raw sheet
      await tester.tap(find.byKey(const ValueKey('open_raw_sheet_button')));
      await tester.pumpAndSettle();

      expect(find.text('Raw Sheet Content'), findsOneWidget);

      // Tap on the floating nav bar area beneath the sheet
      await tester.tapAt(tester.getCenter(find.byKey(const ValueKey('floating_nav_bar_sheet_test'))));
      await tester.pumpAndSettle();

      // Nav bar tap count should NOT have incremented
      expect(navBarTapCount, equals(1));

      // Tap barrier to dismiss
      await tester.tapAt(const Offset(20, 20));
      await tester.pumpAndSettle();

      expect(find.text('Raw Sheet Content'), findsNothing);
    });
  });
}
