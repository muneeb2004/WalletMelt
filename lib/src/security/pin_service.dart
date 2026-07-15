import 'pin_hash.dart';
import 'pin_storage.dart';

/// Business logic service for PIN validation, hashing comparison, enabling, and disabling.
class PinService {
  final PinStorage _storage;

  PinService({PinStorage? storage}) : _storage = storage ?? PinStorage();

  /// Returns whether the user has enabled PIN lock protection.
  Future<bool> isPinEnabled() async {
    return await _storage.isPinEnabled();
  }

  /// Verifies a 4-digit raw PIN string by hashing it and comparing to the stored hash.
  Future<bool> verifyPin(String rawPin) async {
    final storedHash = await _storage.getPinHash();
    if (storedHash == null) return false;
    final inputHash = PinHash.hashPin(rawPin);
    return storedHash == inputHash;
  }

  /// Sets a new PIN: hashes the raw PIN, saves the hash, and sets the enabled status.
  Future<void> setPin(String rawPin) async {
    final hash = PinHash.hashPin(rawPin);
    await _storage.savePinHash(hash);
    await _storage.setPinEnabled(true);
  }

  /// Disables PIN lock security by clearing both PIN status and PIN hash.
  Future<void> disablePin() async {
    await _storage.clearPinData();
  }
}
