import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Helper class to hash the PIN using SHA-256.
class PinHash {
  PinHash._();

  /// Hashes the raw [pin] using SHA-256 and returns its hexadecimal string representation.
  static String hashPin(String pin) {
    final bytes = utf8.encode(pin);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
