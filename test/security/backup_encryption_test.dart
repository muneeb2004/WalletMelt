import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_melt/src/services/export/backup_encryption_service.dart';

void main() {
  group('BackupEncryptionService Tests', () {
    const service = BackupEncryptionService();
    const testPassphrase = 'CorrectHorseBatteryStaple123!';
    final sampleData = utf8.encode('{"app": "WalletMelt", "expenses": [{"amount": 1050}]}');

    test('isEncrypted identifies encrypted vs plain bytes', () {
      final encrypted = service.encrypt(
        plaintext: sampleData,
        passphrase: testPassphrase,
        iterations: 100,
      );

      expect(service.isEncrypted(encrypted), isTrue);
      expect(service.isEncrypted(sampleData), isFalse);
      expect(service.isEncrypted([1, 2, 3]), isFalse);
    });

    test('Encrypt and decrypt roundtrip preserves exact plaintext', () {
      final encrypted = service.encrypt(
        plaintext: sampleData,
        passphrase: testPassphrase,
        iterations: 100,
      );

      final decrypted = service.decrypt(
        encryptedBytes: encrypted,
        passphrase: testPassphrase,
        iterations: 100,
      );

      expect(utf8.decode(decrypted), utf8.decode(sampleData));
    });

    test('Decryption with wrong passphrase throws InvalidBackupPassphraseException', () {
      final encrypted = service.encrypt(
        plaintext: sampleData,
        passphrase: testPassphrase,
        iterations: 100,
      );

      expect(
        () => service.decrypt(
          encryptedBytes: encrypted,
          passphrase: 'WrongPassphrase',
          iterations: 100,
        ),
        throwsA(isA<InvalidBackupPassphraseException>()),
      );
    });

    test('Decryption of tampered ciphertext fails HMAC check and throws', () {
      final encrypted = service.encrypt(
        plaintext: sampleData,
        passphrase: testPassphrase,
        iterations: 100,
      );

      final tampered = Uint8List.fromList(encrypted);
      tampered[tampered.length - 35] ^= 0xFF; // Flip byte in ciphertext payload

      expect(
        () => service.decrypt(
          encryptedBytes: tampered,
          passphrase: testPassphrase,
          iterations: 100,
        ),
        throwsA(isA<InvalidBackupPassphraseException>()),
      );
    });

    test('Decryption of corrupted header throws CorruptedBackupException', () {
      final corrupted = Uint8List.fromList([0x00, 0x01, 0x02, ...sampleData]);
      expect(
        () => service.decrypt(
          encryptedBytes: corrupted,
          passphrase: testPassphrase,
          iterations: 100,
        ),
        throwsA(isA<CorruptedBackupException>()),
      );
    });
  });
}
