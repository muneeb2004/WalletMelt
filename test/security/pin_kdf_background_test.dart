import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_melt/src/security/pin_hash.dart';
import 'package:wallet_melt/src/services/export/backup_encryption_service.dart';

void main() {
  test('background PIN hash matches the synchronous hash (format unchanged)',
      () async {
    final salt = List<int>.generate(32, (i) => i);
    final sync = PinKdf.hashPin(pin: '1234', salt: salt, iterations: 50);
    final bg = await PinKdf.hashPinInBackground(
        pin: '1234', salt: salt, iterations: 50);
    expect(bg, sync);
  });

  test('background encrypt and decrypt round-trip', () async {
    const service = BackupEncryptionService();
    final cipher = await service.encryptInBackground(
        plaintext: [1, 2, 3], passphrase: 'pw', iterations: 10);
    // The synchronous path can read what the background path wrote.
    expect(service.decrypt(encryptedBytes: cipher, passphrase: 'pw', iterations: 10),
        [1, 2, 3]);
    expect(
        await service.decryptInBackground(
            encryptedBytes: cipher, passphrase: 'pw', iterations: 10),
        [1, 2, 3]);
  });

  test('background decrypt still reports a wrong passphrase', () async {
    const service = BackupEncryptionService();
    final cipher = service.encrypt(
        plaintext: [9], passphrase: 'right', iterations: 10);
    await expectLater(
      service.decryptInBackground(
          encryptedBytes: cipher, passphrase: 'wrong', iterations: 10),
      throwsA(isA<InvalidBackupPassphraseException>()),
    );
  });

  // Under flutter test runInBackground runs inline, so exercise the real
  // isolate path directly: arguments must be sendable and errors must keep
  // their type, or PIN checks would fail closed on devices.
  group('real isolate (compute)', () {
    // Built the way PinStorage._hexToBytes builds salts: a growable List<int>.
    final salt = <int>[];
    for (var i = 0; i < 32; i++) {
      salt.add((i * 7) & 0xFF);
    }

    test('PIN hash in an isolate equals the sync hash', () async {
      final viaIsolate = await compute(hashPinTask, ('4821', salt, 50));
      expect(viaIsolate, PinKdf.hashPin(pin: '4821', salt: salt, iterations: 50));
    });

    test('encrypt and decrypt round-trip in isolates', () async {
      final cipher = await compute(encryptTask, (<int>[5, 6, 7], 'pw', 10));
      final plain = await compute(decryptTask, (cipher.toList(), 'pw', 10));
      expect(plain, [5, 6, 7]);
    });

    test('wrong passphrase keeps its exception type across the isolate', () async {
      final cipher = const BackupEncryptionService()
          .encrypt(plaintext: [1], passphrase: 'right', iterations: 10);
      await expectLater(
        compute(decryptTask, (cipher.toList(), 'wrong', 10)),
        throwsA(isA<InvalidBackupPassphraseException>()),
      );
    });
  });
}
