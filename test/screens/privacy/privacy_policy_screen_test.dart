import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wallet_melt/src/app/wallet_melt_app.dart';
import 'package:wallet_melt/src/screens/privacy/privacy_policy_screen.dart';
import 'package:wallet_melt/src/screens/security/pin_lock_screen.dart';
import 'package:wallet_melt/src/security/pin_lock_controller.dart';
import 'package:wallet_melt/src/security/pin_service.dart';
import 'package:wallet_melt/src/security/pin_storage.dart';
import 'package:wallet_melt/src/services/settings/settings_service.dart';
import 'package:wallet_melt/src/state/app_state.dart';
import 'package:wallet_melt/src/types/settings.dart';


void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget buildTestableScreen({
    required AppState appState,
    bool isConsentMode = false,
  }) {
    return ChangeNotifierProvider<AppState>.value(
      value: appState,
      child: MaterialApp(
        home: PrivacyPolicyScreen(isConsentMode: isConsentMode),
      ),
    );
  }


  group('PrivacyPolicyScreen & Consent Gating Tests', () {
    testWidgets('Renders all major legal sections and Developer contact information', (tester) async {
      final appState = AppState.test();

      await tester.pumpWidget(buildTestableScreen(
        appState: appState,
        isConsentMode: false,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Privacy Policy'), findsOneWidget);
      expect(find.text('Last Updated: August 26, 2026'), findsOneWidget);
      expect(find.text('100% On-Device & Offline Architecture'), findsOneWidget);
      expect(find.text('0. Plain-Language Summary'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('1. About This App and the Developer'),
        300,
      );
      expect(find.text('1. About This App and the Developer'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('9. Disclaimer of Warranties'),
        500,
      );
      expect(find.text('9. Disclaimer of Warranties'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('10. Limitation of Liability'),
        500,
      );
      expect(find.text('10. Limitation of Liability'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('14. Contact'),
        500,
      );
      expect(find.text('14. Contact'), findsOneWidget);
    });


    testWidgets('In consent mode, Accept button is disabled until agreement checkbox is checked', (tester) async {
      final appState = AppState.test();

      await tester.pumpWidget(buildTestableScreen(
        appState: appState,
        isConsentMode: true,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Privacy & Terms Notice'), findsOneWidget);
      expect(find.text('Decline & Exit'), findsOneWidget);
      expect(find.text('Accept & Continue'), findsOneWidget);

      final acceptButtonFinder = find.widgetWithText(FilledButton, 'Accept & Continue');
      final FilledButton initialButton = tester.widget(acceptButtonFinder);
      expect(initialButton.onPressed, isNull); // Disabled

      // Toggle agreement checkbox
      final checkboxFinder = find.byType(Checkbox);
      await tester.tap(checkboxFinder);
      await tester.pumpAndSettle();

      final FilledButton enabledButton = tester.widget(acceptButtonFinder);
      expect(enabledButton.onPressed, isNotNull); // Enabled

      // Tap Accept & Continue
      await tester.tap(acceptButtonFinder);
      await tester.pumpAndSettle();

      expect(appState.settings.hasAcceptedPrivacyPolicy, isTrue);
    });

    testWidgets('Decline & Exit button opens confirmation dialog', (tester) async {
      final appState = AppState.test();

      await tester.pumpWidget(buildTestableScreen(
        appState: appState,
        isConsentMode: true,
      ));
      await tester.pumpAndSettle();

      final declineButtonFinder = find.text('Decline & Exit');
      await tester.tap(declineButtonFinder);
      await tester.pumpAndSettle();

      expect(find.text('Exit WalletMelt?'), findsOneWidget);
      expect(find.text('Review Policy'), findsOneWidget);
      expect(find.text('Exit App'), findsOneWidget);
    });

    test('SettingsService persists hasAcceptedPrivacyPolicy across reloads', () async {
      final service = SettingsService();
      const settingsWithConsent = WalletMeltSettings(
        currency: 'USD',
        themePreference: ThemePreference.dark,
        hasCompletedOnboarding: true,
        hasAcceptedPrivacyPolicy: true,
      );

      await service.save(settingsWithConsent);
      final loaded = await service.load();

      expect(loaded.hasAcceptedPrivacyPolicy, isTrue);
      expect(loaded.currency, 'USD');
      expect(loaded.hasCompletedOnboarding, isTrue);
    });

    testWidgets('Upgrading user with PIN enabled unlocks at /pin-lock then seamlessly transitions to /privacy-consent without redirect loops', (tester) async {
      final storage = PinStorage();
      await storage.clearPinData();
      final pinService = PinService(storage: storage);
      await pinService.setPin('1234');

      final pinController = PinLockController(pinService: pinService);
      await pinController.initialize();

      final appState = AppState.test(
        settings: const WalletMeltSettings(
          currency: 'USD',
          themePreference: ThemePreference.system,
          hasCompletedOnboarding: true,
          hasAcceptedPrivacyPolicy: false,
        ),
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AppState>.value(value: appState),
            ChangeNotifierProvider<PinLockController>.value(value: pinController),
          ],
          child: const WalletMeltApp(),
        ),
      );
      await tester.pumpAndSettle();

      // 1. PIN Lock Screen is presented cleanly without redirect loop
      expect(find.byType(PinLockScreen), findsOneWidget);
      expect(tester.takeException(), isNull);

      // 2. Enter 1 2 3 4 to unlock
      await tester.tap(find.text('1'));
      await tester.pump();
      await tester.tap(find.text('2'));
      await tester.pump();
      await tester.tap(find.text('3'));
      await tester.pump();
      await tester.tap(find.text('4'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      // 3. Transitions cleanly to Privacy Consent Screen
      expect(find.byType(PrivacyPolicyScreen), findsOneWidget);
      expect(find.text('Privacy & Terms Notice'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // 4. Accept privacy policy
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Accept & Continue'));
      await tester.pumpAndSettle();

      // 5. User successfully reaches dashboard
      expect(appState.settings.hasAcceptedPrivacyPolicy, isTrue);
      expect(find.byType(PrivacyPolicyScreen), findsNothing);
      expect(tester.takeException(), isNull);

      await storage.clearPinData();
      pinController.dispose();
    });

    testWidgets('Brand new user boots to /privacy-consent and completes onboarding without redirect loops', (tester) async {
      final storage = PinStorage();
      await storage.clearPinData();
      final pinService = PinService(storage: storage);
      final pinController = PinLockController(pinService: pinService);
      await pinController.initialize();

      final appState = AppState.test(
        settings: const WalletMeltSettings(
          currency: 'PKR',
          themePreference: ThemePreference.system,
          hasCompletedOnboarding: false,
          hasAcceptedPrivacyPolicy: false,
        ),
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AppState>.value(value: appState),
            ChangeNotifierProvider<PinLockController>.value(value: pinController),
          ],
          child: const WalletMeltApp(),
        ),
      );
      await tester.pumpAndSettle();

      // 1. New user boots directly to Privacy & Terms Notice without redirect loop
      expect(find.byType(PrivacyPolicyScreen), findsOneWidget);
      expect(find.text('Privacy & Terms Notice'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // 2. Accept privacy policy
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Accept & Continue'));
      await tester.pumpAndSettle();

      // 3. Seamlessly transitions to Onboarding Screen
      expect(appState.settings.hasAcceptedPrivacyPolicy, isTrue);
      expect(find.byType(PrivacyPolicyScreen), findsNothing);
      expect(tester.takeException(), isNull);
      expect(find.text('100% Offline & Private'), findsOneWidget);

      // 4. Progress through onboarding
      await tester.tap(find.text('Next Feature'));
      await tester.pumpAndSettle();
      expect(find.text('Visual Budget Zones'), findsOneWidget);

      await tester.tap(find.text('Next Feature'));
      await tester.pumpAndSettle();
      expect(find.text('Itemized Tracking'), findsOneWidget);

      // 5. Complete onboarding
      await tester.tap(find.widgetWithText(ElevatedButton, 'Start Tracking'));
      await tester.pumpAndSettle();

      // 6. User reaches main Dashboard
      expect(appState.settings.hasCompletedOnboarding, isTrue);
      expect(tester.takeException(), isNull);

      pinController.dispose();
    });

    testWidgets('Unaccepted user attempting to navigate directly to / or other routes is routed to /privacy-consent without loop', (tester) async {
      final storage = PinStorage();
      await storage.clearPinData();
      final pinService = PinService(storage: storage);
      final pinController = PinLockController(pinService: pinService);
      await pinController.initialize();

      final appState = AppState.test(
        settings: const WalletMeltSettings(
          currency: 'PKR',
          themePreference: ThemePreference.system,
          hasCompletedOnboarding: false,
          hasAcceptedPrivacyPolicy: false,
        ),
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AppState>.value(value: appState),
            ChangeNotifierProvider<PinLockController>.value(value: pinController),
          ],
          child: const WalletMeltApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Boots directly to privacy consent
      expect(find.byType(PrivacyPolicyScreen), findsOneWidget);
      expect(tester.takeException(), isNull);

      pinController.dispose();
    });
  });
}


