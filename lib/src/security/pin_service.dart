import 'dart:io';
import 'package:flutter/foundation.dart';
import 'pin_hash.dart';
import 'pin_storage.dart';


/// Business logic service for PIN validation, hashing comparison, enabling, and disabling.
class PinService {
  final PinStorage _storage;

  PinService({PinStorage? storage}) : _storage = storage ?? PinStorage();

  PinStorage get storage => _storage;

  int get _defaultIterations =>
      (kIsWeb || Platform.environment.containsKey('FLUTTER_TEST'))
          ? PinKdf.testIterations
          : PinKdf.defaultIterations;

  /// Returns whether the user has enabled PIN lock protection.
  Future<bool> isPinEnabled() async {
    try {
      return await _storage.isPinEnabled();
    } catch (_) {
      // Fail closed: if storage is in an error state, treat as enabled to prevent bypass
      return true;
    }
  }

  /// Verifies a 4-digit raw PIN string using salted PBKDF2 and constant-time comparison.
  ///
  /// Fails closed: invalid format or secure storage read failure always returns false.
  Future<bool> verifyPin(String rawPin, {int? iterations}) async {
    if (rawPin.length != 4 || int.tryParse(rawPin) == null) {
      return false;
    }

    try {
      final storedHash = await _storage.getPinHash();
      if (storedHash == null || storedHash.isEmpty) return false;

      final salt = await _storage.getOrCreateSalt();
      final inputHash = PinKdf.hashPin(
        pin: rawPin,
        salt: salt,
        iterations: iterations ?? _defaultIterations,
      );
      return PinKdf.fixedTimeEquals(storedHash, inputHash);
    } catch (_) {
      // Fail closed: any storage or hashing exception rejects authentication
      return false;
    }
  }

  /// Sets a new PIN: derives the PBKDF2 hash using per-device salt, saves the hash, and sets the enabled status.
  ///
  /// Atomically updates credential data in secure storage.
  Future<void> setPin(String rawPin, {int? iterations}) async {
    if (rawPin.length != 4 || int.tryParse(rawPin) == null) {
      throw ArgumentError('PIN must be exactly 4 numeric digits.');
    }

    final salt = await _storage.getOrCreateSalt();
    final hash = PinKdf.hashPin(
      pin: rawPin,
      salt: salt,
      iterations: iterations ?? _defaultIterations,
    );
    await _storage.savePinHash(hash);
    await _storage.setPinEnabled(true);
  }

  /// Checks if biometric unlock is enabled.
  Future<bool> isBiometricsEnabled() async {
    try {
      return await _storage.isBiometricsEnabled();
    } catch (_) {
      return false;
    }
  }

  /// Sets biometric unlock status.
  Future<void> setBiometricsEnabled(bool enabled) async {
    await _storage.setBiometricsEnabled(enabled);
  }

  /// Disables PIN lock security by clearing PIN status, salt, hash, lockout state, and biometric flag.
  Future<void> disablePin() async {
    await _storage.clearPinData();
  }
}

