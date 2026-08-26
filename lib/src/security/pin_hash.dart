import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Cryptographically secure Key Derivation Function (PBKDF2-HMAC-SHA256) for low-entropy PINs.
class PinKdf {
  PinKdf._();

  /// Default production iteration count (OWASP recommendation: >= 100,000 for PBKDF2-HMAC-SHA256).
  static const int defaultIterations = 100000;

  /// Fast iteration count used strictly during testing to avoid slow test cycles.
  static const int testIterations = 100;

  /// Derives a 256-bit hexadecimal string representation from a raw [pin] and [salt] using PBKDF2-HMAC-SHA256.
  static String hashPin({
    required String pin,
    required List<int> salt,
    int iterations = defaultIterations,
  }) {
    final pinBytes = utf8.encode(pin);
    final keyBytes = pbkdf2HmacSha256(
      password: pinBytes,
      salt: salt,
      iterations: iterations,
      keyLength: 32,
    );
    return keyBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// RFC 2898 / RFC 8018 compliant PBKDF2 implementation using HMAC-SHA256.
  static List<int> pbkdf2HmacSha256({
    required List<int> password,
    required List<int> salt,
    required int iterations,
    int keyLength = 32,
  }) {
    if (iterations <= 0) {
      throw ArgumentError('Iterations must be greater than 0');
    }
    if (keyLength <= 0) {
      throw ArgumentError('Key length must be greater than 0');
    }

    final hmac = Hmac(sha256, password);
    final numBlocks = (keyLength + 31) ~/ 32;
    final derivedKey = <int>[];

    for (var blockIndex = 1; blockIndex <= numBlocks; blockIndex++) {
      final blockIndexBytes = [
        (blockIndex >> 24) & 0xFF,
        (blockIndex >> 16) & 0xFF,
        (blockIndex >> 8) & 0xFF,
        blockIndex & 0xFF,
      ];
      var u = hmac.convert([...salt, ...blockIndexBytes]).bytes;
      final f = List<int>.from(u);

      for (var i = 1; i < iterations; i++) {
        u = hmac.convert(u).bytes;
        for (var k = 0; k < 32; k++) {
          f[k] ^= u[k];
        }
      }
      derivedKey.addAll(f);
    }

    return derivedKey.sublist(0, keyLength);
  }

  /// Constant-time comparison between two hex strings to eliminate timing side-channel attacks.
  static bool fixedTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    var result = 0;
    for (var i = 0; i < a.length; i++) {
      result |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return result == 0;
  }
}

/// Backwards compatibility wrapper for PinHash.
class PinHash {
  PinHash._();

  static String hashPin(String pin, {List<int>? salt, int? iterations}) {
    final effectiveSalt = salt ?? utf8.encode('walletmelt_static_salt_legacy');
    return PinKdf.hashPin(
      pin: pin,
      salt: effectiveSalt,
      iterations: iterations ?? PinKdf.defaultIterations,
    );
  }
}

