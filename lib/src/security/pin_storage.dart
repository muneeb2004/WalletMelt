import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure storage layer for storing PIN, cryptographic salt, lockout state, and biometric configuration.
///
/// Implements fail-closed semantics: storage failures never result in an unauthenticated unlock.
class PinStorage {
  static const _pinHashKey = 'security.pin_hash';
  static const _pinSaltKey = 'security.pin_salt';
  static const _pinEnabledKey = 'security.pin_enabled';
  static const _biometricsEnabledKey = 'security.biometrics_enabled';
  static const _failedAttemptsKey = 'security.failed_attempts';
  static const _lockoutUntilKey = 'security.lockout_until';

  final FlutterSecureStorage _secureStorage;

  // In-memory fallback for testing/web
  static final Map<String, String> _testStorage = {};

  PinStorage({FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  Future<void> _write(String key, String value) async {
    if (kIsWeb || Platform.environment.containsKey('FLUTTER_TEST')) {
      _testStorage[key] = value;
      return;
    }
    try {
      await _secureStorage.write(
        key: key,
        value: value,
      );
    } on PlatformException catch (e) {
      throw PinStorageException('Failed to write secure key: ${e.code}');
    } catch (e) {
      throw PinStorageException('Failed to write to secure storage: $e');
    }
  }

  Future<String?> _read(String key) async {
    if (kIsWeb || Platform.environment.containsKey('FLUTTER_TEST')) {
      return _testStorage[key];
    }
    try {
      return await _secureStorage.read(
        key: key,
      );
    } on PlatformException catch (e) {
      throw PinStorageException('Failed to read secure key: ${e.code}');
    } catch (e) {
      throw PinStorageException('Failed to read from secure storage: $e');
    }
  }

  Future<void> _delete(String key) async {
    if (kIsWeb || Platform.environment.containsKey('FLUTTER_TEST')) {
      _testStorage.remove(key);
      return;
    }
    try {
      await _secureStorage.delete(
        key: key,
      );
    } on PlatformException catch (e) {
      throw PinStorageException('Failed to delete secure key: ${e.code}');
    } catch (e) {
      throw PinStorageException('Failed to delete from secure storage: $e');
    }
  }

  /// Checks if the PIN lock feature is enabled.
  Future<bool> isPinEnabled() async {
    final enabled = await _read(_pinEnabledKey);
    return enabled == 'true';
  }

  /// Sets the PIN lock feature status.
  Future<void> setPinEnabled(bool enabled) async {
    await _write(_pinEnabledKey, enabled.toString());
  }

  /// Retrieves the saved PBKDF2 PIN hash.
  Future<String?> getPinHash() async {
    return await _read(_pinHashKey);
  }

  /// Saves the PBKDF2 PIN hash.
  Future<void> savePinHash(String hash) async {
    await _write(_pinHashKey, hash);
  }

  /// Retrieves or generates a 32-byte cryptographically secure random salt for PIN KDF.
  Future<List<int>> getOrCreateSalt() async {
    final existingHex = await _read(_pinSaltKey);
    if (existingHex != null && existingHex.isNotEmpty) {
      return _hexToBytes(existingHex);
    }

    final random = Random.secure();
    final saltBytes = List<int>.generate(32, (_) => random.nextInt(256));
    final hexString = saltBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    await _write(_pinSaltKey, hexString);
    return saltBytes;
  }

  /// Retrieves the saved hex salt or null.
  Future<String?> getPinSalt() async {
    return await _read(_pinSaltKey);
  }

  /// Saves an explicit hex salt string.
  Future<void> savePinSalt(String hexSalt) async {
    await _write(_pinSaltKey, hexSalt);
  }

  /// Checks if biometric unlock is enabled.
  Future<bool> isBiometricsEnabled() async {
    final enabled = await _read(_biometricsEnabledKey);
    return enabled == 'true';
  }

  /// Sets the biometric unlock status.
  Future<void> setBiometricsEnabled(bool enabled) async {
    await _write(_biometricsEnabledKey, enabled.toString());
  }

  /// Retrieves the persisted failed attempt count (survives app restart).
  Future<int> getFailedAttempts() async {
    final raw = await _read(_failedAttemptsKey);
    return raw != null ? (int.tryParse(raw) ?? 0) : 0;
  }

  /// Persists failed attempts in secure storage.
  Future<void> setFailedAttempts(int count) async {
    await _write(_failedAttemptsKey, count.toString());
  }

  /// Retrieves the persisted lockout expiration timestamp (survives app restart).
  Future<DateTime?> getLockoutUntil() async {
    final raw = await _read(_lockoutUntilKey);
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  /// Persists the lockout expiration timestamp in secure storage.
  Future<void> setLockoutUntil(DateTime? until) async {
    if (until == null) {
      await _delete(_lockoutUntilKey);
    } else {
      await _write(_lockoutUntilKey, until.toIso8601String());
    }
  }

  /// Clears all PIN, salt, lockout, and biometric-related keys from secure storage.
  Future<void> clearPinData() async {
    await _delete(_pinHashKey);
    await _delete(_pinSaltKey);
    await _delete(_pinEnabledKey);
    await _delete(_biometricsEnabledKey);
    await _delete(_failedAttemptsKey);
    await _delete(_lockoutUntilKey);
  }

  List<int> _hexToBytes(String hex) {
    final bytes = <int>[];
    for (var i = 0; i < hex.length; i += 2) {
      final byteString = hex.substring(i, min(i + 2, hex.length));
      final byte = int.tryParse(byteString, radix: 16);
      if (byte != null) bytes.add(byte);
    }
    return bytes;
  }
}

/// Custom exception thrown on secure storage failures.
class PinStorageException implements Exception {
  final String message;
  const PinStorageException(this.message);

  @override
  String toString() => 'PinStorageException: $message';
}

