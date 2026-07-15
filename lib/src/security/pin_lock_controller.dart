import 'dart:async';
import 'package:flutter/widgets.dart';
import 'pin_service.dart';

/// Controller handling the application's PIN locking state and lifecycle observations.
class PinLockController extends ChangeNotifier with WidgetsBindingObserver {
  final PinService _pinService;

  bool _isLocked = false;
  bool _isPinEnabled = false;
  bool _isInitialized = false;
  DateTime? _backgroundedAt;
  bool isPinScreenOpen = false;

  PinLockController({PinService? pinService})
      : _pinService = pinService ?? PinService() {
    WidgetsBinding.instance.addObserver(this);
  }

  /// Whether the application is currently locked and requires a PIN screen.
  bool get isLocked => _isLocked;

  /// Whether a PIN has been set and enabled.
  bool get isPinEnabled => _isPinEnabled;

  /// Whether secure storage data loading has completed.
  bool get isInitialized => _isInitialized;

  /// Asynchronously loads configuration parameters on startup.
  Future<void> initialize() async {
    if (_isInitialized) return;
    _isPinEnabled = await _pinService.isPinEnabled();
    if (_isPinEnabled) {
      _isLocked = true;
    }
    _isInitialized = true;
    notifyListeners();
  }
  /// Re-syncs the enabled status with the storage (e.g. after changing settings).
  Future<void> refreshPinStatus() async {
    _isPinEnabled = await _pinService.isPinEnabled();
    if (!_isPinEnabled) {
      _isLocked = false;
      isPinScreenOpen = false;
    }
    notifyListeners();
  }

  /// Unlocks the session.
  void unlock() {
    _isLocked = false;
    isPinScreenOpen = false;
    notifyListeners();
  }

  /// Forces the session to lock.
  void lock() {
    if (_isPinEnabled) {
      _isLocked = true;
      notifyListeners();
    }
  }

  /// Saves the new PIN and updates status.
  Future<void> enablePin(String rawPin) async {
    await _pinService.setPin(rawPin);
    _isPinEnabled = true;
    _isLocked = false;
    isPinScreenOpen = false;
    notifyListeners();
  }

  /// Removes the PIN from storage and updates status.
  Future<void> disablePin() async {
    await _pinService.disablePin();
    _isPinEnabled = false;
    _isLocked = false;
    isPinScreenOpen = false;
    notifyListeners();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_isInitialized || !_isPinEnabled) return;

    if (state == AppLifecycleState.paused) {
      _backgroundedAt = DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      if (_backgroundedAt != null) {
        final elapsed = DateTime.now().difference(_backgroundedAt!);
        if (elapsed.inSeconds > 30) {
          _isLocked = true;
          notifyListeners();
        }
        _backgroundedAt = null;
      }
    }
  }
}
