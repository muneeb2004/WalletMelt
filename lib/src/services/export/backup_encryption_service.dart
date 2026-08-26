import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import '../../security/pin_hash.dart';

class InvalidBackupPassphraseException implements Exception {
  final String message;
  const InvalidBackupPassphraseException([this.message = 'Incorrect passphrase or corrupted backup file.']);

  @override
  String toString() => 'InvalidBackupPassphraseException: $message';
}

class CorruptedBackupException implements Exception {
  final String message;
  const CorruptedBackupException([this.message = 'Backup file format is invalid or corrupted.']);

  @override
  String toString() => 'CorruptedBackupException: $message';
}

/// Service providing Authenticated Encryption (AES-256-CTR + HMAC-SHA256) for local backup archives.
class BackupEncryptionService {
  const BackupEncryptionService();

  static const List<int> magicHeader = [0x57, 0x4D, 0x45, 0x4E, 0x43, 0x30, 0x31]; // "WMENC01"
  static const int saltLength = 16;
  static const int ivLength = 16;
  static const int hmacLength = 32;
  static const int defaultIterations = 100000;

  /// Checks if the raw [bytes] begin with the WalletMelt encryption header.
  bool isEncrypted(List<int> bytes) {
    if (bytes.length < magicHeader.length + saltLength + ivLength + hmacLength) {
      return false;
    }
    for (var i = 0; i < magicHeader.length; i++) {
      if (bytes[i] != magicHeader[i]) return false;
    }
    return true;
  }

  /// Encrypts [plaintext] bytes using [passphrase] with PBKDF2-HMAC-SHA256 (100k iterations) and AES-256 CTR + HMAC-SHA256.
  Uint8List encrypt({
    required List<int> plaintext,
    required String passphrase,
    int iterations = defaultIterations,
  }) {
    if (passphrase.isEmpty) {
      throw ArgumentError('Passphrase cannot be empty.');
    }

    final random = Random.secure();
    final salt = List<int>.generate(saltLength, (_) => random.nextInt(256));
    final iv = List<int>.generate(ivLength, (_) => random.nextInt(256));

    // Derive 64 bytes: 32 bytes AES key + 32 bytes HMAC key
    final derivedKeys = PinKdf.pbkdf2HmacSha256(
      password: utf8.encode(passphrase),
      salt: salt,
      iterations: iterations,
      keyLength: 64,
    );

    final aesKey = derivedKeys.sublist(0, 32);
    final hmacKey = derivedKeys.sublist(32, 64);

    final ciphertext = _aesCtrTransform(plaintext, aesKey, iv);

    // Compute HMAC-SHA256 tag over (Header || Salt || IV || Ciphertext)
    final authenticatedPayload = [
      ...magicHeader,
      ...salt,
      ...iv,
      ...ciphertext,
    ];

    final hmac = Hmac(sha256, hmacKey);
    final tag = hmac.convert(authenticatedPayload).bytes;

    return Uint8List.fromList([...authenticatedPayload, ...tag]);
  }

  /// Decrypts [encryptedBytes] using [passphrase]. Throws [InvalidBackupPassphraseException] on incorrect passphrase or MAC mismatch.
  Uint8List decrypt({
    required List<int> encryptedBytes,
    required String passphrase,
    int iterations = defaultIterations,
  }) {
    if (!isEncrypted(encryptedBytes)) {
      throw const CorruptedBackupException('Invalid or missing WalletMelt encryption header.');
    }

    final minLength = magicHeader.length + saltLength + ivLength + hmacLength;
    if (encryptedBytes.length < minLength) {
      throw const CorruptedBackupException('Encrypted payload is truncated.');
    }

    var offset = magicHeader.length;
    final salt = encryptedBytes.sublist(offset, offset + saltLength);
    offset += saltLength;

    final iv = encryptedBytes.sublist(offset, offset + ivLength);
    offset += ivLength;

    final ciphertextLength = encryptedBytes.length - offset - hmacLength;
    final ciphertext = encryptedBytes.sublist(offset, offset + ciphertextLength);
    offset += ciphertextLength;

    final storedTag = encryptedBytes.sublist(offset, offset + hmacLength);

    // Derive keys
    final derivedKeys = PinKdf.pbkdf2HmacSha256(
      password: utf8.encode(passphrase),
      salt: salt,
      iterations: iterations,
      keyLength: 64,
    );

    final aesKey = derivedKeys.sublist(0, 32);
    final hmacKey = derivedKeys.sublist(32, 64);

    // Verify HMAC
    final authenticatedPayload = encryptedBytes.sublist(0, encryptedBytes.length - hmacLength);
    final hmac = Hmac(sha256, hmacKey);
    final calculatedTag = hmac.convert(authenticatedPayload).bytes;

    if (!_constantTimeEquals(storedTag, calculatedTag)) {
      throw const InvalidBackupPassphraseException();
    }

    final decrypted = _aesCtrTransform(ciphertext, aesKey, iv);
    return Uint8List.fromList(decrypted);
  }

  bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var result = 0;
    for (var i = 0; i < a.length; i++) {
      result |= a[i] ^ b[i];
    }
    return result == 0;
  }

  /// Pure Dart AES-256 CTR keystream generation and XOR.
  List<int> _aesCtrTransform(List<int> input, List<int> key, List<int> initialIv) {
    final state = _Aes256(key);
    final counter = List<int>.from(initialIv);
    final output = Uint8List(input.length);
    final block = Uint8List(16);

    for (var i = 0; i < input.length; i += 16) {
      state.encryptBlock(counter, block);
      final remaining = min(16, input.length - i);
      for (var j = 0; j < remaining; j++) {
        output[i + j] = input[i + j] ^ block[j];
      }
      _incrementCounter(counter);
    }
    return output;
  }

  void _incrementCounter(List<int> counter) {
    for (var i = counter.length - 1; i >= 0; i--) {
      counter[i] = (counter[i] + 1) & 0xFF;
      if (counter[i] != 0) break;
    }
  }
}

/// Standard AES-256 block encryption implementation.
class _Aes256 {
  final Uint32List _expandedKey = Uint32List(60);

  _Aes256(List<int> key) {
    _keyExpansion(key);
  }

  void encryptBlock(List<int> input, List<int> output) {
    var s0 = (input[0] << 24) | (input[1] << 16) | (input[2] << 8) | input[3];
    var s1 = (input[4] << 24) | (input[5] << 16) | (input[6] << 8) | input[7];
    var s2 = (input[8] << 24) | (input[9] << 16) | (input[10] << 8) | input[11];
    var s3 = (input[12] << 24) | (input[13] << 16) | (input[14] << 8) | input[15];

    s0 ^= _expandedKey[0];
    s1 ^= _expandedKey[1];
    s2 ^= _expandedKey[2];
    s3 ^= _expandedKey[3];

    for (var round = 1; round < 14; round++) {
      final k = round * 4;
      final t0 = _t0(s0) ^ _t1(s1) ^ _t2(s2) ^ _t3(s3) ^ _expandedKey[k];
      final t1 = _t0(s1) ^ _t1(s2) ^ _t2(s3) ^ _t3(s0) ^ _expandedKey[k + 1];
      final t2 = _t0(s2) ^ _t1(s3) ^ _t2(s0) ^ _t3(s1) ^ _expandedKey[k + 2];
      final t3 = _t0(s3) ^ _t1(s0) ^ _t2(s1) ^ _t3(s2) ^ _expandedKey[k + 3];
      s0 = t0;
      s1 = t1;
      s2 = t2;
      s3 = t3;
    }

    final k = 56;
    final t0 = _subWordRot(s0, s1, s2, s3, 0) ^ _expandedKey[k];
    final t1 = _subWordRot(s1, s2, s3, s0, 1) ^ _expandedKey[k + 1];
    final t2 = _subWordRot(s2, s3, s0, s1, 2) ^ _expandedKey[k + 2];
    final t3 = _subWordRot(s3, s0, s1, s2, 3) ^ _expandedKey[k + 3];

    output[0] = (t0 >> 24) & 0xFF;
    output[1] = (t0 >> 16) & 0xFF;
    output[2] = (t0 >> 8) & 0xFF;
    output[3] = t0 & 0xFF;

    output[4] = (t1 >> 24) & 0xFF;
    output[5] = (t1 >> 16) & 0xFF;
    output[6] = (t1 >> 8) & 0xFF;
    output[7] = t1 & 0xFF;

    output[8] = (t2 >> 24) & 0xFF;
    output[9] = (t2 >> 16) & 0xFF;
    output[10] = (t2 >> 8) & 0xFF;
    output[11] = t2 & 0xFF;

    output[12] = (t3 >> 24) & 0xFF;
    output[13] = (t3 >> 16) & 0xFF;
    output[14] = (t3 >> 8) & 0xFF;
    output[15] = t3 & 0xFF;
  }

  void _keyExpansion(List<int> key) {
    for (var i = 0; i < 8; i++) {
      _expandedKey[i] = (key[4 * i] << 24) |
          (key[4 * i + 1] << 16) |
          (key[4 * i + 2] << 8) |
          key[4 * i + 3];
    }
    for (var i = 8; i < 60; i++) {
      var temp = _expandedKey[i - 1];
      if (i % 8 == 0) {
        temp = _subWord(_rotWord(temp)) ^ _rcon[i ~/ 8];
      } else if (i % 8 == 4) {
        temp = _subWord(temp);
      }
      _expandedKey[i] = _expandedKey[i - 8] ^ temp;
    }
  }

  static int _rotWord(int w) => ((w << 8) | (w >>> 24)) & 0xFFFFFFFF;

  static int _subWord(int w) {
    return (_sbox[(w >> 24) & 0xFF] << 24) |
        (_sbox[(w >> 16) & 0xFF] << 16) |
        (_sbox[(w >> 8) & 0xFF] << 8) |
        _sbox[w & 0xFF];
  }

  static int _subWordRot(int a, int b, int c, int d, int offset) {
    final b0 = _sbox[(a >> 24) & 0xFF];
    final b1 = _sbox[(b >> 16) & 0xFF];
    final b2 = _sbox[(c >> 8) & 0xFF];
    final b3 = _sbox[d & 0xFF];
    return (b0 << 24) | (b1 << 16) | (b2 << 8) | b3;
  }

  static int _t0(int s) {
    final b = (s >> 24) & 0xFF;
    final sb = _sbox[b];
    return (_mul2(sb) << 24) | (sb << 16) | (sb << 8) | (_mul3(sb));
  }

  static int _t1(int s) {
    final b = (s >> 16) & 0xFF;
    final sb = _sbox[b];
    return (_mul3(sb) << 24) | (_mul2(sb) << 16) | (sb << 8) | sb;
  }

  static int _t2(int s) {
    final b = (s >> 8) & 0xFF;
    final sb = _sbox[b];
    return (sb << 24) | (_mul3(sb) << 16) | (_mul2(sb) << 8) | sb;
  }

  static int _t3(int s) {
    final b = s & 0xFF;
    final sb = _sbox[b];
    return (sb << 24) | (sb << 16) | (_mul3(sb) << 8) | (_mul2(sb));
  }

  static int _mul2(int b) => ((b << 1) ^ (((b >> 7) & 1) * 0x11B)) & 0xFF;
  static int _mul3(int b) => _mul2(b) ^ b;

  static const List<int> _rcon = [
    0x00000000, 0x01000000, 0x02000000, 0x04000000, 0x08000000,
    0x10000000, 0x20000000, 0x40000000, 0x80000000, 0x1B000000, 0x36000000
  ];

  static const List<int> _sbox = [
    0x63, 0x7c, 0x77, 0x7b, 0xf2, 0x6b, 0x6f, 0xc5, 0x30, 0x01, 0x67, 0x2b, 0xfe, 0xd7, 0xab, 0x76,
    0xca, 0x82, 0xc9, 0x7d, 0xfa, 0x59, 0x47, 0xf0, 0xad, 0xd4, 0xa2, 0xaf, 0x9c, 0xa4, 0x72, 0xc0,
    0xb7, 0xfd, 0x93, 0x26, 0x36, 0x3f, 0xf7, 0xcc, 0x34, 0xa5, 0xe5, 0xf1, 0x71, 0xd8, 0x31, 0x15,
    0x04, 0xc7, 0x23, 0xc3, 0x18, 0x96, 0x05, 0x9a, 0x07, 0x12, 0x80, 0xe2, 0xeb, 0x27, 0xb2, 0x75,
    0x09, 0x83, 0x2c, 0x1a, 0x1b, 0x6e, 0x5a, 0xa0, 0x52, 0x3b, 0xd6, 0xb3, 0x29, 0xe3, 0x2f, 0x84,
    0x53, 0xd1, 0x00, 0xed, 0x20, 0xfc, 0xb1, 0x5b, 0x6a, 0xcb, 0xbe, 0x39, 0x4a, 0x4c, 0x58, 0xcf,
    0xd0, 0xef, 0xaa, 0xfb, 0x43, 0x4d, 0x33, 0x85, 0x45, 0xf9, 0x02, 0x7f, 0x50, 0x3c, 0x9f, 0xa8,
    0x51, 0xa3, 0x40, 0x8f, 0x92, 0x9d, 0x38, 0xf5, 0xbc, 0xb6, 0xda, 0x21, 0x10, 0xff, 0xf3, 0xd2,
    0xcd, 0x0c, 0x13, 0xec, 0x5f, 0x97, 0x44, 0x17, 0xc4, 0xa7, 0x7e, 0x3d, 0x64, 0x5d, 0x19, 0x73,
    0x60, 0x81, 0x4f, 0xdc, 0x22, 0x2a, 0x90, 0x88, 0x46, 0xee, 0xb8, 0x14, 0xde, 0x5e, 0x0b, 0xdb,
    0xe0, 0x32, 0x3a, 0x0a, 0x49, 0x06, 0x24, 0x5c, 0xc2, 0xd3, 0xac, 0x62, 0x91, 0x95, 0xe4, 0x79,
    0xe7, 0xc8, 0x37, 0x6d, 0x8d, 0xd5, 0x4e, 0xa9, 0x6c, 0x56, 0xf4, 0xea, 0x65, 0x7a, 0xae, 0x08,
    0xba, 0x78, 0x25, 0x2e, 0x1c, 0xa6, 0xb4, 0xc6, 0xe8, 0xdd, 0x74, 0x1f, 0x4b, 0xbd, 0x8b, 0x8a,
    0x70, 0x3e, 0xb5, 0x66, 0x48, 0x03, 0xf6, 0x0e, 0x61, 0x35, 0x57, 0xb9, 0x86, 0xc1, 0x1d, 0x9e,
    0xe1, 0xf8, 0x98, 0x11, 0x69, 0xd9, 0x8e, 0x94, 0x9b, 0x1e, 0x87, 0xe9, 0xce, 0x55, 0x28, 0xdf,
    0x8c, 0xa1, 0x89, 0x0d, 0xbf, 0xe6, 0x42, 0x68, 0x41, 0x99, 0x2d, 0x0f, 0xb0, 0x54, 0xbb, 0x16
  ];
}
