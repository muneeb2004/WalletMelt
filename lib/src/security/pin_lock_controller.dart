import 'dart:async';
import 'package:flutter/widgets.dart';
import 'biometric_service.dart';
import 'pin_service.dart';

/// State of the authentication session state machine.
enum AuthSessionState {
  unlocked,
  locked,
  verifyingPin,
  verifyingBiometric,
  pinFailed,
  cooldown,
  authenticated,
}

/// Controller handling the application's PIN locking state, biometric authentication, and lifecycle observations.
class PinLockController extends ChangeNotifier with WidgetsBindingObserver {
  final PinService _pinService;
  final BiometricService _biometricService;

  bool _isLocked = false;
  bool _isPinEnabled = false;
  bool _isBiometricsEnabled = false;
  bool _isBiometricHardwareAvailable = false;
  bool _isBiometricsEnrolled = false;
  String _biometricLabel = 'Biometrics';
  bool _isInitialized = false;
  DateTime? _backgroundedAt;
  bool isPinScreenOpen = false;

  bool _isBiometricInProgress = false;
  int _failedAttempts = 0;
  DateTime? _lockoutUntil;

  PinLockController({
    PinService? pinService,
    BiometricService? biometricService,
  })  : _pinService = pinService ?? PinService(),
        _biometricService = biometricService ?? BiometricService() {
    WidgetsBinding.instance.addObserver(this);
  }

  /// Whether the application is currently locked and requires authentication.
  bool get isLocked => _isLocked;

  /// Whether a PIN has been set and enabled.
  bool get isPinEnabled => _isPinEnabled;

  /// Whether biometric unlock is enabled by user and supported.
  bool get isBiometricsEnabled =>
      _isPinEnabled && _isBiometricsEnabled && isBiometricsAvailable;

  /// Whether the device hardware supports biometrics and has enrolled credentials.
  bool get isBiometricsAvailable =>
      _isBiometricHardwareAvailable && _isBiometricsEnrolled;

  /// Platform-adaptive label for biometrics (e.g. "Face ID", "Touch ID", "Fingerprint").
  String get biometricLabel => _biometricLabel;

  /// Whether secure storage and capability loading has completed.
  bool get isInitialized => _isInitialized;

  /// Number of consecutive failed PIN attempts.
  int get failedAttempts => _failedAttempts;

  /// Whether the user is temporarily locked out due to repeated incorrect entries.
  bool get isLockedOut =>
      _lockoutUntil != null && DateTime.now().isBefore(_lockoutUntil!);

  /// Remaining seconds in temporary lockout.
  int get remainingLockoutSeconds {
    if (!isLockedOut) return 0;
    return _lockoutUntil!.difference(DateTime.now()).inSeconds + 1;
  }

  /// Current high-level session authentication state.
  AuthSessionState get sessionState {
    if (!_isPinEnabled || !_isLocked) return AuthSessionState.unlocked;
    if (isLockedOut) return AuthSessionState.cooldown;
    if (_isBiometricInProgress) return AuthSessionState.verifyingBiometric;
    return AuthSessionState.locked;
  }

  /// Underlying biometric service.
  BiometricService get biometricService => _biometricService;

  /// Underlying PIN service.
  PinService get pinService => _pinService;

  /// Asynchronously loads configuration parameters and checks hardware on startup.
  ///
  /// Implements fail-closed behavior: if loading fails, defaults to locked state.
  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      await _loadStatus();
      if (_isPinEnabled) {
        _isLocked = true;
      }
    } catch (_) {
      // Fail closed
      _isPinEnabled = true;
      _isLocked = true;
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<void> _loadStatus() async {
    _isPinEnabled = await _pinService.isPinEnabled();
    _isBiometricsEnabled = await _pinService.isBiometricsEnabled();
    _isBiometricHardwareAvailable =
        await _biometricService.isBiometricHardwareAvailable();
    _isBiometricsEnrolled = await _biometricService.isBiometricsEnrolled();
    _biometricLabel = await _biometricService.getBiometricLabel();
  }

  /// Re-syncs status with secure storage and hardware checks.
  Future<void> refreshPinStatus() async {
    try {
      await _loadStatus();
    } catch (_) {
      // Retain existing state if refresh fails
    }
    if (!_isPinEnabled) {
      _isLocked = false;
      isPinScreenOpen = false;
      _failedAttempts = 0;
      _lockoutUntil = null;
    }
    notifyListeners();
  }

  /// Unlocks the session and clears failure counters.
  void unlock() {
    _isLocked = false;
    isPinScreenOpen = false;
    _failedAttempts = 0;
    _lockoutUntil = null;
    notifyListeners();
  }

  /// Forces the session to lock if PIN protection is active.
  void lock() {
    if (_isPinEnabled) {
      _isLocked = true;
      notifyListeners();
    }
  }

  /// Saves a new PIN and updates status atomically.
  Future<void> enablePin(String rawPin) async {
    await _pinService.setPin(rawPin);
    _isPinEnabled = true;
    _isLocked = false;
    isPinScreenOpen = false;
    _failedAttempts = 0;
    _lockoutUntil = null;
    await _loadStatus();
    notifyListeners();
  }

  /// Removes the PIN from storage, disables biometrics, and unlocks the app.
  Future<void> disablePin() async {
    await _pinService.disablePin();
    _isPinEnabled = false;
    _isBiometricsEnabled = false;
    _isLocked = false;
    isPinScreenOpen = false;
    _failedAttempts = 0;
    _lockoutUntil = null;
    notifyListeners();
  }

  /// Toggles biometric unlock.
  Future<void> setBiometricsEnabled(bool enabled) async {
    await _pinService.setBiometricsEnabled(enabled);
    _isBiometricsEnabled = enabled;
    notifyListeners();
  }

  /// Prompts for native biometric authentication with in-flight guards.
  Future<BiometricAuthResult> authenticateWithBiometrics({
    String reason = 'Unlock WalletMelt to access your financial records',
  }) async {
    if (!isBiometricsEnabled || isLockedOut) {
      return const BiometricAuthResult.notAvailable();
    }

    if (_isBiometricInProgress) {
      return const BiometricAuthResult.error('Authentication already in progress');
    }

    _isBiometricInProgress = true;
    notifyListeners();

    try {
      final result = await _biometricService.authenticate(localizedReason: reason);
      // Verify invariant: session must still be enabled and not locked out
      if (result.isSuccess && _isPinEnabled && !isLockedOut) {
        unlock();
      }
      return result;
    } finally {
      _isBiometricInProgress = false;
      notifyListeners();
    }
  }

  /// Records a failed PIN attempt and triggers temporary throttling if threshold reached.
  void recordFailedAttempt() {
    _failedAttempts++;
    if (_failedAttempts >= 5) {
      _lockoutUntil = DateTime.now().add(const Duration(seconds: 30));
    }
    notifyListeners();
  }

  /// Clears failed attempt counters.
  void resetFailedAttempts() {
    _failedAttempts = 0;
    _lockoutUntil = null;
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

    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      _backgroundedAt = DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      if (_backgroundedAt != null) {
        final elapsed = DateTime.now().difference(_backgroundedAt!);
        if (elapsed >= const Duration(seconds: 30)) {
          _isLocked = true;
          notifyListeners();
        }
        _backgroundedAt = null;
      }
    }
  }
}
