import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_melt/src/security/pin_hash.dart';
import 'package:wallet_melt/src/security/pin_storage.dart';
import 'package:wallet_melt/src/security/pin_service.dart';
import 'package:wallet_melt/src/security/pin_lock_controller.dart';

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

    setUp(() {
      storage = PinStorage();
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

    test('Disabling PIN clears secure storage data', () async {
      await service.setPin('1234');
      expect(await service.isPinEnabled(), isTrue);

      await service.disablePin();
      expect(await service.isPinEnabled(), isFalse);
      expect(await storage.getPinHash(), isNull);
    });
  });

  group('PinLockController Tests', () {
    late PinStorage storage;
    late PinService service;
    late PinLockController controller;

    setUp(() async {
      storage = PinStorage();
      service = PinService(storage: storage);
      controller = PinLockController(pinService: service);
      await controller.initialize();
    });

    tearDown(() async {
      await storage.clearPinData();
      controller.dispose();
    });

    test('Controller initializes unlocked if PIN is disabled', () {
      expect(controller.isPinEnabled, isFalse);
      expect(controller.isLocked, isFalse);
    });

    test('Controller initializes locked if PIN is enabled', () async {
      await service.setPin('1234');

      final controller2 = PinLockController(pinService: service);
      await controller2.initialize();

      expect(controller2.isPinEnabled, isTrue);
      expect(controller2.isLocked, isTrue);

      controller2.dispose();
    });

    test('Unlocking sets isLocked to false', () async {
      await service.setPin('1234');

      final controller2 = PinLockController(pinService: service);
      await controller2.initialize();
      expect(controller2.isLocked, isTrue);

      controller2.unlock();
      expect(controller2.isLocked, isFalse);

      controller2.dispose();
    });
  });
}
