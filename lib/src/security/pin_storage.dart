import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure storage layer for storing PIN and biometric authentication configuration.
///
/// Implements fail-closed semantics: storage failures never result in an unauthenticated unlock.
class PinStorage {
  static const _pinHashKey = 'security.pin_hash';
  static const _pinEnabledKey = 'security.pin_enabled';
  static const _biometricsEnabledKey = 'security.biometrics_enabled';

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

  /// Retrieves the saved SHA-256 PIN hash.
  Future<String?> getPinHash() async {
    return await _read(_pinHashKey);
  }

  /// Saves the SHA-256 PIN hash.
  Future<void> savePinHash(String hash) async {
    await _write(_pinHashKey, hash);
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

  /// Clears all PIN and biometric-related keys from secure storage.
  Future<void> clearPinData() async {
    await _delete(_pinHashKey);
    await _delete(_pinEnabledKey);
    await _delete(_biometricsEnabledKey);
  }
}

/// Custom exception thrown on secure storage failures.
class PinStorageException implements Exception {
  final String message;
  const PinStorageException(this.message);

  @override
  String toString() => 'PinStorageException: $message';
}
