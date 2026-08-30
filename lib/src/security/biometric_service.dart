import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

import '../utils/platform_info.dart';

/// Status of a biometric authentication attempt.
enum BiometricAuthStatus {
  success,
  failure,
  canceled,
  notAvailable,
  notEnrolled,
  lockedOut,
  permanentlyLockedOut,
  otherError,
}

/// Result returned from a biometric authentication attempt.
class BiometricAuthResult {
  final BiometricAuthStatus status;
  final String? errorMessage;

  const BiometricAuthResult(this.status, [this.errorMessage]);

  const BiometricAuthResult.success()
      : status = BiometricAuthStatus.success,
        errorMessage = null;

  const BiometricAuthResult.failure([String? message])
      : status = BiometricAuthStatus.failure,
        errorMessage = message;

  const BiometricAuthResult.canceled()
      : status = BiometricAuthStatus.canceled,
        errorMessage = null;

  const BiometricAuthResult.notAvailable([String? message])
      : status = BiometricAuthStatus.notAvailable,
        errorMessage = message;

  const BiometricAuthResult.notEnrolled([String? message])
      : status = BiometricAuthStatus.notEnrolled,
        errorMessage = message;

  const BiometricAuthResult.lockedOut([String? message])
      : status = BiometricAuthStatus.lockedOut,
        errorMessage = message;

  const BiometricAuthResult.permanentlyLockedOut([String? message])
      : status = BiometricAuthStatus.permanentlyLockedOut,
        errorMessage = message;

  const BiometricAuthResult.error([String? message])
      : status = BiometricAuthStatus.otherError,
        errorMessage = message;

  bool get isSuccess => status == BiometricAuthStatus.success;
  bool get isCanceled => status == BiometricAuthStatus.canceled;
}

/// Service managing biometric hardware detection, enrollment status, and biometric prompt execution.
class BiometricService {
  final LocalAuthentication _localAuth;
  bool _isAuthenticating = false;

  // In-memory test override
  static bool? testHardwareAvailable;
  static bool? testEnrolled;
  static List<BiometricType>? testBiometrics;
  static BiometricAuthResult? testAuthResult;
  static Duration? testAuthDelay;

  BiometricService({LocalAuthentication? localAuth})
      : _localAuth = localAuth ?? LocalAuthentication();

  /// Whether biometric authentication is currently in-flight.
  bool get isAuthenticating => _isAuthenticating;

  /// Determines if the device hardware supports biometric authentication.
  Future<bool> isBiometricHardwareAvailable() async {
    if (PlatformInfo.isWeb) return false;
    if (PlatformInfo.isFlutterTest) {
      return testHardwareAvailable ?? false;
    }

    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isSupported = await _localAuth.isDeviceSupported();
      return canCheck || isSupported;
    } on PlatformException catch (_) {
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Retrieves list of enrolled and available biometric sensor types on the device.
  Future<List<BiometricType>> getAvailableBiometrics() async {
    if (PlatformInfo.isWeb) return const [];
    if (PlatformInfo.isFlutterTest) {
      return testBiometrics ?? const [];
    }

    try {
      return await _localAuth.getAvailableBiometrics();
    } on PlatformException catch (_) {
      return const [];
    } catch (_) {
      return const [];
    }
  }

  /// Checks if any biometrics are enrolled on the device.
  Future<bool> isBiometricsEnrolled() async {
    if (PlatformInfo.isWeb) return false;
    if (PlatformInfo.isFlutterTest) {
      return testEnrolled ?? false;
    }

    try {
      final biometrics = await getAvailableBiometrics();
      return biometrics.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Returns a platform-adaptive user-facing label for biometrics (e.g. "Face ID", "Touch ID", "Fingerprint", "Face Unlock", "Biometrics").
  Future<String> getBiometricLabel() async {
    if (PlatformInfo.isWeb) return 'Biometrics';

    try {
      final biometrics = await getAvailableBiometrics();
      if (PlatformInfo.isIOS || PlatformInfo.isMacOS) {
        if (biometrics.contains(BiometricType.face)) {
          return 'Face ID';
        } else if (biometrics.contains(BiometricType.fingerprint)) {
          return 'Touch ID';
        }
      } else if (PlatformInfo.isAndroid) {
        if (biometrics.contains(BiometricType.fingerprint)) {
          return 'Fingerprint';
        } else if (biometrics.contains(BiometricType.face)) {
          return 'Face Unlock';
        } else if (biometrics.contains(BiometricType.iris)) {
          return 'Iris';
        }
      }
    } catch (_) {}

    return 'Biometrics';
  }

  /// Prompts the user with native biometric authentication with in-flight concurrency guards.
  Future<BiometricAuthResult> authenticate({
    String localizedReason = 'Unlock WalletMelt to access your financial records',
  }) async {
    if (PlatformInfo.isWeb) {
      return const BiometricAuthResult.notAvailable('Biometrics not supported on Web');
    }

    if (_isAuthenticating) {
      return const BiometricAuthResult.error('Authentication already in progress');
    }

    _isAuthenticating = true;

    try {
      if (PlatformInfo.isFlutterTest) {
        if (testAuthDelay != null) {
          await Future.delayed(testAuthDelay!);
        }
        return testAuthResult ?? const BiometricAuthResult.success();
      }

      final isAvailable = await isBiometricHardwareAvailable();
      if (!isAvailable) {
        return const BiometricAuthResult.notAvailable('Biometric hardware is not available on this device');
      }

      final isEnrolled = await isBiometricsEnrolled();
      if (!isEnrolled) {
        return const BiometricAuthResult.notEnrolled('No biometrics enrolled on this device');
      }

      final authenticated = await _localAuth.authenticate(
        localizedReason: localizedReason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          useErrorDialogs: false,
          sensitiveTransaction: true,
        ),
      );

      if (authenticated) {
        return const BiometricAuthResult.success();
      } else {
        return const BiometricAuthResult.canceled();
      }
    } on PlatformException catch (e) {
      switch (e.code) {
        case 'NotAvailable':
        case 'PasscodeNotSet':
        case 'no_biometrics_available':
          return const BiometricAuthResult.notAvailable('Biometrics not available on this device');
        case 'NotEnrolled':
        case 'no_fingerprint_enrolled':
        case 'no_face_enrolled':
          return const BiometricAuthResult.notEnrolled('No biometrics enrolled');
        case 'LockedOut':
          return const BiometricAuthResult.lockedOut('Too many failed attempts. Try again later.');
        case 'PermanentlyLockedOut':
          return const BiometricAuthResult.permanentlyLockedOut('Biometrics locked. Enter PIN to unlock.');
        case 'auth_in_progress':
          return const BiometricAuthResult.error('Authentication already in progress');
        case 'UserCancel':
        case 'SystemCancel':
        case 'AppCancel':
          return const BiometricAuthResult.canceled();
        default:
          return const BiometricAuthResult.failure('Biometric authentication failed');
      }
    } catch (_) {
      return const BiometricAuthResult.failure('Biometric authentication failed');
    } finally {
      _isAuthenticating = false;
    }
  }

  /// Cancels any active authentication prompt.
  Future<void> stopAuthentication() async {
    if (PlatformInfo.isWeb || PlatformInfo.isFlutterTest) {
      _isAuthenticating = false;
      return;
    }
    try {
      await _localAuth.stopAuthentication();
    } catch (_) {
    } finally {
      _isAuthenticating = false;
    }
  }
}
