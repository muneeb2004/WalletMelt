import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure storage layer for storing PIN configuration.
class PinStorage {
  static const _pinHashKey = 'security.pin_hash';
  static const _pinEnabledKey = 'security.pin_enabled';

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
    await _secureStorage.write(
      key: key,
      value: value,
    );
  }

  Future<String?> _read(String key) async {
    if (kIsWeb || Platform.environment.containsKey('FLUTTER_TEST')) {
      return _testStorage[key];
    }
    return await _secureStorage.read(
      key: key,
    );
  }

  Future<void> _delete(String key) async {
    if (kIsWeb || Platform.environment.containsKey('FLUTTER_TEST')) {
      _testStorage.remove(key);
      return;
    }
    await _secureStorage.delete(
      key: key,
    );
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

  /// Clears all PIN-related keys from secure storage.
  Future<void> clearPinData() async {
    await _delete(_pinHashKey);
    await _delete(_pinEnabledKey);
  }
}
