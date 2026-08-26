import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_melt/src/security/biometric_service.dart';
import 'package:wallet_melt/src/security/pin_lock_controller.dart';
import 'package:wallet_melt/src/security/pin_service.dart';
import 'package:wallet_melt/src/security/pin_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Persistent Lockout Tests Across App Restarts', () {
    late PinStorage storage;
    late PinService pinService;
    late BiometricService biometricService;

    setUp(() async {
      storage = PinStorage();
      await storage.clearPinData();
      pinService = PinService(storage: storage);
      biometricService = BiometricService();
    });

    tearDown(() async {
      await storage.clearPinData();
    });

    test('Failed attempts and lockout state persist when controller is re-instantiated', () async {
      // 1. Controller Instance 1 (Initial session)
      final controller1 = PinLockController(
        pinService: pinService,
        biometricService: biometricService,
      );
      await controller1.initialize();
      await controller1.enablePin('1234');

      expect(controller1.failedAttempts, 0);
      expect(controller1.isLockedOut, isFalse);

      // Record 5 failed attempts to trigger 30s lockout
      for (var i = 0; i < 5; i++) {
        controller1.recordFailedAttempt();
      }

      expect(controller1.failedAttempts, 5);
      expect(controller1.isLockedOut, isTrue);
      expect(controller1.remainingLockoutSeconds, greaterThan(0));

      // Simulate app kill and controller teardown
      controller1.dispose();

      // 2. Controller Instance 2 (Simulating fresh app restart)
      final controller2 = PinLockController(
        pinService: pinService,
        biometricService: biometricService,
      );
      await controller2.initialize();

      // Verify that lockout state survived app restart
      expect(controller2.failedAttempts, 5);
      expect(controller2.isLockedOut, isTrue);
      expect(controller2.remainingLockoutSeconds, greaterThan(0));
      expect(controller2.isLocked, isTrue);

      // Unlocking clears the persistent state
      controller2.unlock();
      expect(controller2.failedAttempts, 0);
      expect(controller2.isLockedOut, isFalse);

      // 3. Controller Instance 3 (Simulating next launch after clean unlock)
      controller2.dispose();
      final controller3 = PinLockController(
        pinService: pinService,
        biometricService: biometricService,
      );
      await controller3.initialize();
      expect(controller3.failedAttempts, 0);
      expect(controller3.isLockedOut, isFalse);

      controller3.dispose();
    });
  });
}
