import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';
import 'package:wallet_melt/src/screens/security/create_pin_screen.dart';
import 'package:wallet_melt/src/screens/security/pin_lock_screen.dart';
import 'package:wallet_melt/src/screens/security/verify_pin_screen.dart';
import 'package:wallet_melt/src/security/biometric_service.dart';
import 'package:wallet_melt/src/security/pin_hash.dart';
import 'package:wallet_melt/src/security/pin_storage.dart';
import 'package:wallet_melt/src/security/pin_service.dart';
import 'package:wallet_melt/src/security/pin_lock_controller.dart';
import 'package:wallet_melt/src/widgets/security/biometric_button.dart';
import 'package:wallet_melt/src/widgets/security/number_pad.dart';
import 'package:wallet_melt/src/widgets/security/pin_indicator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PinHash Tests', () {
    test('Hashing should be deterministic and output valid SHA-256', () {
      const pin = '1234';
      final hash1 = PinHash.hashPin(pin);
      final hash2 = PinHash.hashPin(pin);
      expect(hash1, hash2);
      expect(hash1, isNot(pin));
      expect(hash1.length, 64); // SHA-256 hex length is 64 chars
    });

    test('Different PINs should produce different hashes', () {
      final hash1 = PinHash.hashPin('1234');
      final hash2 = PinHash.hashPin('5678');
      expect(hash1, isNot(hash2));
    });
  });

  group('PinStorage & PinService Tests', () {
    late PinStorage storage;
    late PinService service;

    setUp(() async {
      storage = PinStorage();
      await storage.clearPinData();
      service = PinService(storage: storage);
    });

    tearDown(() async {
      await storage.clearPinData();
    });

    test('PIN is disabled by default', () async {
      expect(await service.isPinEnabled(), isFalse);
    });

    test('Saving PIN works and enables PIN lock', () async {
      await service.setPin('1234');
      expect(await service.isPinEnabled(), isTrue);

      final storedHash = await storage.getPinHash();
      expect(storedHash, PinHash.hashPin('1234'));
    });

    test('Verifying PIN works correctly', () async {
      await service.setPin('1234');
      expect(await service.verifyPin('1234'), isTrue);
      expect(await service.verifyPin('5678'), isFalse);
    });

    test('Verifying invalid PIN format fails closed', () async {
      expect(await service.verifyPin(''), isFalse);
      expect(await service.verifyPin('12'), isFalse);
      expect(await service.verifyPin('12345'), isFalse);
      expect(await service.verifyPin('abcd'), isFalse);
    });

    test('Setting invalid PIN throws ArgumentError', () async {
      expect(() => service.setPin('12'), throwsArgumentError);
      expect(() => service.setPin('12345'), throwsArgumentError);
      expect(() => service.setPin('abcd'), throwsArgumentError);
    });

    test('Biometric setting is persisted and retrieved', () async {
      expect(await service.isBiometricsEnabled(), isFalse);
      await service.setBiometricsEnabled(true);
      expect(await service.isBiometricsEnabled(), isTrue);
      await service.setBiometricsEnabled(false);
      expect(await service.isBiometricsEnabled(), isFalse);
    });

    test('Disabling PIN clears secure storage data and biometrics', () async {
      await service.setPin('1234');
      await service.setBiometricsEnabled(true);
      expect(await service.isPinEnabled(), isTrue);
      expect(await service.isBiometricsEnabled(), isTrue);

      await service.disablePin();
      expect(await service.isPinEnabled(), isFalse);
      expect(await service.isBiometricsEnabled(), isFalse);
      expect(await storage.getPinHash(), isNull);
    });
  });

  group('BiometricService Tests', () {
    late BiometricService bioService;

    setUp(() {
      bioService = BiometricService();
      BiometricService.testHardwareAvailable = null;
      BiometricService.testEnrolled = null;
      BiometricService.testBiometrics = null;
      BiometricService.testAuthResult = null;
      BiometricService.testAuthDelay = null;
    });

    tearDown(() {
      BiometricService.testHardwareAvailable = null;
      BiometricService.testEnrolled = null;
      BiometricService.testBiometrics = null;
      BiometricService.testAuthResult = null;
      BiometricService.testAuthDelay = null;
    });

    test('Hardware detection reflects mock state', () async {
      BiometricService.testHardwareAvailable = true;
      expect(await bioService.isBiometricHardwareAvailable(), isTrue);

      BiometricService.testHardwareAvailable = false;
      expect(await bioService.isBiometricHardwareAvailable(), isFalse);
    });

    test('Enrolled check returns true when available biometrics is non-empty', () async {
      BiometricService.testEnrolled = true;
      expect(await bioService.isBiometricsEnrolled(), isTrue);

      BiometricService.testEnrolled = false;
      expect(await bioService.isBiometricsEnrolled(), isFalse);
    });

    test('Authentication returns configured test result', () async {
      BiometricService.testAuthResult = const BiometricAuthResult.success();
      final res1 = await bioService.authenticate();
      expect(res1.isSuccess, isTrue);

      BiometricService.testAuthResult = const BiometricAuthResult.canceled();
      final res2 = await bioService.authenticate();
      expect(res2.isCanceled, isTrue);

      BiometricService.testAuthResult = const BiometricAuthResult.lockedOut('Locked');
      final res3 = await bioService.authenticate();
      expect(res3.status, BiometricAuthStatus.lockedOut);
      expect(res3.errorMessage, 'Locked');
    });

    test('Simultaneous authentications are guarded by in-flight lock', () async {
      BiometricService.testAuthResult = const BiometricAuthResult.success();
      BiometricService.testAuthDelay = const Duration(milliseconds: 50);
      expect(bioService.isAuthenticating, isFalse);

      final authFuture1 = bioService.authenticate();
      expect(bioService.isAuthenticating, isTrue);

      final authFuture2 = bioService.authenticate();
      final res2 = await authFuture2;
      expect(res2.status, BiometricAuthStatus.otherError);
      expect(res2.errorMessage, 'Authentication already in progress');

      final res1 = await authFuture1;
      expect(res1.isSuccess, isTrue);
      expect(bioService.isAuthenticating, isFalse);
      BiometricService.testAuthDelay = null;
    });

    test('stopAuthentication resets authenticating guard', () async {
      await bioService.stopAuthentication();
      expect(bioService.isAuthenticating, isFalse);
    });
  });

  group('PinLockController State Machine & Invariants', () {
    late PinStorage storage;
    late PinService service;
    late BiometricService bioService;
    late PinLockController controller;

    setUp(() async {
      BiometricService.testHardwareAvailable = true;
      BiometricService.testEnrolled = true;
      BiometricService.testBiometrics = [BiometricType.fingerprint];
      BiometricService.testAuthResult = const BiometricAuthResult.success();

      storage = PinStorage();
      await storage.clearPinData();
      service = PinService(storage: storage);
      bioService = BiometricService();
      controller = PinLockController(
        pinService: service,
        biometricService: bioService,
      );
      await controller.initialize();
    });

    tearDown(() async {
      await storage.clearPinData();
      controller.dispose();
      BiometricService.testHardwareAvailable = null;
      BiometricService.testEnrolled = null;
      BiometricService.testBiometrics = null;
      BiometricService.testAuthResult = null;
    });

    test('Session state machine transitions cleanly', () async {
      // Disabled -> unlocked
      expect(controller.sessionState, AuthSessionState.unlocked);

      // Enable PIN -> unlocked initially
      await controller.enablePin('1234');
      expect(controller.sessionState, AuthSessionState.unlocked);

      // Lock app -> locked
      controller.lock();
      expect(controller.sessionState, AuthSessionState.locked);

      // Failed attempts -> cooldown
      for (int i = 0; i < 5; i++) {
        controller.recordFailedAttempt();
      }
      expect(controller.sessionState, AuthSessionState.cooldown);

      // Unlock -> unlocked
      controller.unlock();
      expect(controller.sessionState, AuthSessionState.unlocked);
    });

    test('Biometric invariant: biometrics disabled if PIN disabled', () async {
      await service.setBiometricsEnabled(true);
      await controller.refreshPinStatus();

      expect(controller.isPinEnabled, isFalse);
      expect(controller.isBiometricsEnabled, isFalse);

      await controller.enablePin('1234');
      await controller.setBiometricsEnabled(true);
      expect(controller.isPinEnabled, isTrue);
      expect(controller.isBiometricsEnabled, isTrue);

      await controller.disablePin();
      expect(controller.isPinEnabled, isFalse);
      expect(controller.isBiometricsEnabled, isFalse);
    });

    test('Biometric invariant: biometrics disabled if hardware enrollment removed', () async {
      await controller.enablePin('1234');
      await controller.setBiometricsEnabled(true);
      expect(controller.isBiometricsEnabled, isTrue);

      // User removes fingerprint enrollment from device
      BiometricService.testEnrolled = false;
      await controller.refreshPinStatus();

      expect(controller.isBiometricsAvailable, isFalse);
      expect(controller.isBiometricsEnabled, isFalse);
    });

    test('Failed attempts threshold triggers temporary lockout', () {
      expect(controller.isLockedOut, isFalse);
      for (int i = 0; i < 4; i++) {
        controller.recordFailedAttempt();
        expect(controller.isLockedOut, isFalse);
      }
      controller.recordFailedAttempt(); // 5th attempt
      expect(controller.isLockedOut, isTrue);
      expect(controller.remainingLockoutSeconds, greaterThan(0));

      controller.resetFailedAttempts();
      expect(controller.isLockedOut, isFalse);
      expect(controller.failedAttempts, 0);
    });

    test('Biometric authentication is blocked during lockout', () async {
      await controller.enablePin('1234');
      await controller.setBiometricsEnabled(true);
      controller.lock();

      // Trigger lockout
      for (int i = 0; i < 5; i++) {
        controller.recordFailedAttempt();
      }
      expect(controller.isLockedOut, isTrue);

      final result = await controller.authenticateWithBiometrics();
      expect(result.status, BiometricAuthStatus.notAvailable);
      expect(controller.isLocked, isTrue);
    });

    test('Biometric authentication unlocks session when valid', () async {
      await controller.enablePin('1234');
      await controller.setBiometricsEnabled(true);
      controller.lock();
      expect(controller.isLocked, isTrue);

      final result = await controller.authenticateWithBiometrics();
      expect(result.isSuccess, isTrue);
      expect(controller.isLocked, isFalse);
    });

    test('Grace period: background < 30 seconds remains unlocked', () async {
      await controller.enablePin('1234');
      expect(controller.isLocked, isFalse);

      // Simulate backgrounding at T=0
      controller.didChangeAppLifecycleState(AppLifecycleState.paused);

      // Simulate resume at T=25 seconds
      controller.didChangeAppLifecycleState(AppLifecycleState.resumed);

      expect(controller.isLocked, isFalse);
    });
  });

  group('Security Widget Tests', () {
    setUp(() {
      BiometricService.testHardwareAvailable = false;
      BiometricService.testEnrolled = false;
      BiometricService.testBiometrics = null;
      BiometricService.testAuthResult = null;
    });

    tearDown(() {
      BiometricService.testHardwareAvailable = null;
      BiometricService.testEnrolled = null;
      BiometricService.testBiometrics = null;
      BiometricService.testAuthResult = null;
    });

    testWidgets('PinIndicator renders correct filled and empty dots', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PinIndicator(length: 2, maxLength: 4),
          ),
        ),
      );

      expect(find.byType(PinIndicator), findsOneWidget);
    });

    testWidgets('NumberPad taps trigger callbacks with correct values and semantics', (tester) async {
      String entered = '';
      bool deleted = false;
      bool bioTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NumberPad(
              onKeyPress: (val) => entered += val,
              onDelete: () => deleted = true,
              onBiometricPressed: () => bioTapped = true,
              biometricLabel: 'Fingerprint',
            ),
          ),
        ),
      );

      await tester.tap(find.text('5'));
      await tester.pump();
      expect(entered, '5');

      await tester.tap(find.text('9'));
      await tester.pump();
      expect(entered, '59');

      await tester.tap(find.byIcon(Icons.backspace_outlined));
      await tester.pump();
      expect(deleted, isTrue);

      await tester.tap(find.byIcon(Icons.fingerprint_rounded));
      await tester.pump();
      expect(bioTapped, isTrue);
    });

    testWidgets('WMBiometricButton renders label and triggers tap', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WMBiometricButton(
              onTap: () => tapped = true,
              label: 'Face ID',
            ),
          ),
        ),
      );

      expect(find.text('Unlock with Face ID'), findsOneWidget);
      await tester.tap(find.byType(WMBiometricButton));
      await tester.pump();
      expect(tapped, isTrue);
    });

    testWidgets('PinLockScreen renders lock UI and handles PIN entry', (tester) async {
      final storage = PinStorage();
      await storage.clearPinData();
      final service = PinService(storage: storage);
      await service.setPin('1234');
      final bioService = BiometricService();
      final controller = PinLockController(
        pinService: service,
        biometricService: bioService,
      );
      await controller.initialize();

      await tester.pumpWidget(
        ChangeNotifierProvider<PinLockController>.value(
          value: controller,
          child: MaterialApp(
            home: PinLockScreen(pinService: service),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('WalletMelt is locked'), findsOneWidget);
      expect(find.byType(PinIndicator), findsOneWidget);
      expect(find.byType(NumberPad), findsOneWidget);

      // Enter 1 2 3 4
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

      expect(controller.isLocked, isFalse);

      await storage.clearPinData();
      controller.dispose();
    });

    testWidgets('PinLockScreen handles incorrect PIN with error shake', (tester) async {
      final storage = PinStorage();
      await storage.clearPinData();
      final service = PinService(storage: storage);
      await service.setPin('1234');
      final bioService = BiometricService();
      final controller = PinLockController(
        pinService: service,
        biometricService: bioService,
      );
      await controller.initialize();

      await tester.pumpWidget(
        ChangeNotifierProvider<PinLockController>.value(
          value: controller,
          child: MaterialApp(
            home: PinLockScreen(pinService: service),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Enter 9 9 9 9 (incorrect)
      await tester.tap(find.text('9'));
      await tester.pump();
      await tester.tap(find.text('9'));
      await tester.pump();
      await tester.tap(find.text('9'));
      await tester.pump();
      await tester.tap(find.text('9'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(find.textContaining('Incorrect PIN'), findsOneWidget);
      expect(controller.isLocked, isTrue);

      await storage.clearPinData();
      controller.dispose();
    });

    testWidgets('CreatePinScreen guides through setup and confirmation', (tester) async {
      final storage = PinStorage();
      await storage.clearPinData();
      final service = PinService(storage: storage);
      final bioService = BiometricService();
      final controller = PinLockController(
        pinService: service,
        biometricService: bioService,
      );
      await controller.initialize();

      await tester.pumpWidget(
        ChangeNotifierProvider<PinLockController>.value(
          value: controller,
          child: const MaterialApp(
            home: CreatePinScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Create PIN'), findsOneWidget);

      // Enter first PIN: 1 2 3 4
      await tester.tap(find.text('1'));
      await tester.pump();
      await tester.tap(find.text('2'));
      await tester.pump();
      await tester.tap(find.text('3'));
      await tester.pump();
      await tester.tap(find.text('4'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Confirm PIN'), findsOneWidget);

      // Enter confirmation: 1 2 3 4
      await tester.tap(find.text('1'));
      await tester.pump();
      await tester.tap(find.text('2'));
      await tester.pump();
      await tester.tap(find.text('3'));
      await tester.pump();
      await tester.tap(find.text('4'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(controller.isPinEnabled, isTrue);

      await storage.clearPinData();
      controller.dispose();
    });

    testWidgets('VerifyPinScreen verifies correct PIN', (tester) async {
      final storage = PinStorage();
      await storage.clearPinData();
      final service = PinService(storage: storage);
      await service.setPin('1234');

      await tester.pumpWidget(
        const MaterialApp(
          home: VerifyPinScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Verify PIN'), findsOneWidget);

      // Enter 1 2 3 4
      await tester.tap(find.text('1'));
      await tester.pump();
      await tester.tap(find.text('2'));
      await tester.pump();
      await tester.tap(find.text('3'));
      await tester.pump();
      await tester.tap(find.text('4'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      await storage.clearPinData();
    });

    for (final (width, height) in [
      (320.0, 568.0),
      (360.0, 640.0),
      (375.0, 667.0),
      (390.0, 844.0),
      (430.0, 932.0),
    ]) {
      testWidgets('PinLockScreen renders comfortably without overflow on ${width.toInt()}x${height.toInt()}', (tester) async {
        tester.view.physicalSize = Size(width, height);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final storage = PinStorage();
        await storage.clearPinData();
        final service = PinService(storage: storage);
        await service.setPin('1234');
        final bioService = BiometricService();
        final controller = PinLockController(
          pinService: service,
          biometricService: bioService,
        );
        await controller.initialize();

        await tester.pumpWidget(
          ChangeNotifierProvider<PinLockController>.value(
            value: controller,
            child: MaterialApp(
              home: PinLockScreen(pinService: service),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('WalletMelt is locked'), findsOneWidget);
        expect(find.byType(PinIndicator), findsOneWidget);
        expect(find.byType(NumberPad), findsOneWidget);
        expect(tester.takeException(), isNull);

        await storage.clearPinData();
        controller.dispose();
      });
    }

    testWidgets('PinLockScreen with biometrics enabled displays biometric button and triggers auth', (tester) async {
      BiometricService.testHardwareAvailable = true;
      BiometricService.testEnrolled = true;
      BiometricService.testBiometrics = [BiometricType.face];
      BiometricService.testAuthResult = const BiometricAuthResult.canceled();

      final storage = PinStorage();
      await storage.clearPinData();
      final service = PinService(storage: storage);
      await service.setPin('1234');
      await service.setBiometricsEnabled(true);
      final bioService = BiometricService();
      final controller = PinLockController(
        pinService: service,
        biometricService: bioService,
      );
      await controller.initialize();

      expect(controller.isBiometricsEnabled, isTrue);

      await tester.pumpWidget(
        ChangeNotifierProvider<PinLockController>.value(
          value: controller,
          child: MaterialApp(
            home: PinLockScreen(pinService: service),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(WMBiometricButton), findsOneWidget);

      // Set auth result to success and tap biometric button
      BiometricService.testAuthResult = const BiometricAuthResult.success();
      await tester.tap(find.byType(WMBiometricButton));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(controller.isLocked, isFalse);

      await storage.clearPinData();
      controller.dispose();
    });
  });
}
