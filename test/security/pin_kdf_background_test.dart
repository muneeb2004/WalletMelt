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
}
