import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../components/glass/app_background.dart';
import '../../security/biometric_service.dart';
import '../../security/pin_lock_controller.dart';
import '../../security/pin_service.dart';
import '../../theme/wallet_melt_theme.dart';
import '../../widgets/security/number_pad.dart';
import '../../widgets/security/pin_indicator.dart';
import '../../widgets/security/shake_animation.dart';


/// Premium PIN & Biometric Lock Screen for WalletMelt.
class PinLockScreen extends StatefulWidget {
  final String? from;
  final PinService? pinService;

  const PinLockScreen({this.from, this.pinService, super.key});

  @override
  State<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends State<PinLockScreen> {
  final GlobalKey<ShakeAnimationState> _shakeKey =
      GlobalKey<ShakeAnimationState>();
  late final PinService _pinService;

  String _enteredPin = '';
  String? _errorMessage;
  bool _hasError = false;
  bool _isSuccess = false;
  bool _isVerifying = false;
  bool _hasAutoPrompted = false;

  Timer? _lockoutTimer;
  int _lockoutSecondsLeft = 0;

  @override
  void initState() {
    super.initState();
    _pinService = widget.pinService ?? PinService();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _checkLockoutStatus();
      _attemptAutoBiometrics();
    });
  }

  @override
  void dispose() {
    _lockoutTimer?.cancel();
    super.dispose();
  }


  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  void _checkLockoutStatus() {
    final controller = context.read<PinLockController>();
    if (controller.isLockedOut) {
      _startLockoutCountdown(controller.remainingLockoutSeconds);
    }
  }

  void _startLockoutCountdown(int seconds) {
    _lockoutTimer?.cancel();
    setState(() {
      _lockoutSecondsLeft = seconds;
      _errorMessage = 'Too many failed attempts. Try again in ${_lockoutSecondsLeft}s';
    });

    _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final controller = context.read<PinLockController>();
      if (!controller.isLockedOut || _lockoutSecondsLeft <= 1) {
        timer.cancel();
        controller.resetFailedAttempts();
        setState(() {
          _lockoutSecondsLeft = 0;
          _errorMessage = null;
          _hasError = false;
        });
      } else {
        setState(() {
          _lockoutSecondsLeft--;
          _errorMessage =
              'Too many failed attempts. Try again in ${_lockoutSecondsLeft}s';
        });
      }
    });
  }

  Future<void> _attemptAutoBiometrics() async {
    if (_hasAutoPrompted) return;
    _hasAutoPrompted = true;

    final controller = context.read<PinLockController>();
    if (controller.isBiometricsEnabled && !controller.isLockedOut) {
      // Small pause so UI renders cleanly before the native system prompt overlays
      await Future.delayed(const Duration(milliseconds: 250));
      if (!mounted) return;
      await _triggerBiometrics(silentCancel: true);
    }
  }

  Future<void> _triggerBiometrics({bool silentCancel = false}) async {
    final controller = context.read<PinLockController>();
    if (!controller.isBiometricsEnabled || controller.isLockedOut || _isVerifying) {
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
      _hasError = false;
    });

    try {
      final result = await controller.authenticateWithBiometrics(
        reason: 'Unlock WalletMelt to access your financial records',
      );

      if (!mounted) return;

      if (result.isSuccess) {
        _handleSuccessfulUnlock();
      } else if (result.status == BiometricAuthStatus.canceled) {
        if (!silentCancel) {
          setState(() {
            _errorMessage = 'Biometric authentication was canceled';
          });
        }
      } else if (result.status == BiometricAuthStatus.lockedOut ||
          result.status == BiometricAuthStatus.permanentlyLockedOut) {
        setState(() {
          _errorMessage = result.errorMessage ??
              'Biometrics temporarily locked. Enter PIN to unlock.';
          _hasError = true;
        });
      } else if (result.errorMessage != null && !silentCancel) {
        setState(() {
          _errorMessage = result.errorMessage;
          _hasError = true;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isVerifying = false);
      }
    }
  }

  void _onKeyPress(String value) {
    final controller = context.read<PinLockController>();
    if (controller.isLockedOut || _isVerifying) return;
    if (_enteredPin.length >= 4) return;

    setState(() {
      _enteredPin += value;
      _errorMessage = null;
      _hasError = false;
    });

    if (_enteredPin.length == 4) {
      _verifyPin();
    }
  }

  void _onDelete() {
    final controller = context.read<PinLockController>();
    if (controller.isLockedOut || _isVerifying || _enteredPin.isEmpty) return;

    setState(() {
      _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
      _errorMessage = null;
      _hasError = false;
    });
  }

  Future<void> _verifyPin() async {
    if (_isVerifying) return;
    setState(() => _isVerifying = true);

    final isValid = await _pinService.verifyPin(_enteredPin);
    if (!mounted) return;

    if (isValid) {
      _handleSuccessfulUnlock();
    } else {
      final controller = context.read<PinLockController>();
      controller.recordFailedAttempt();

      WMHaptics.error();
      if (!mounted) return;

      _shakeKey.currentState?.shake();
      setState(() {
        _enteredPin = '';
        _hasError = true;
        _isVerifying = false;
        if (controller.isLockedOut) {
          _startLockoutCountdown(controller.remainingLockoutSeconds);
        } else {
          final attemptsLeft = 5 - controller.failedAttempts;
          _errorMessage = attemptsLeft <= 2
              ? 'Incorrect PIN. $attemptsLeft attempts remaining.'
              : 'Incorrect PIN. Please try again.';
        }
      });
    }
  }

  void _handleSuccessfulUnlock() {
    setState(() {
      _isSuccess = true;
      _hasError = false;
      _errorMessage = null;
    });

    WMHaptics.success();
    final controller = context.read<PinLockController>();
    controller.unlock();

    // Smooth navigation into destination
    if (widget.from != null && widget.from != '/pin-lock') {
      try {
        context.go(widget.from!);
      } catch (_) {
        Navigator.of(context).maybePop();
      }
    } else if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      try {
        context.go('/');
      } catch (_) {
        Navigator.of(context).maybePop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final pinController = context.watch<PinLockController>();
    final isLockedOut = pinController.isLockedOut;
    final isBiometricsEnabled = pinController.isBiometricsEnabled;

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: AppBackground(
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxHeight < 720;

                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Top Header Section
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(height: isCompact ? 16 : 32),
                              // App Name Header
                              Text(
                                'WalletMelt',
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  fontSize: isCompact ? 26 : 30,
                                  letterSpacing: -0.8,
                                  color: isDark
                                      ? WalletMeltColors.darkTextPrimary
                                      : WalletMeltColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              // Greeting & Status Subtitle
                              Text(
                                '${_getGreeting()} • Enter your PIN',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: isDark
                                      ? WalletMeltColors.darkTextSecondary
                                      : WalletMeltColors.textSecondary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),

                          // Center Authentication & Indicator Section
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(height: isCompact ? 10 : 18),
                              // PIN Dots with Shake
                              ShakeAnimation(
                                key: _shakeKey,
                                child: PinIndicator(
                                  length: _enteredPin.length,
                                  hasError: _hasError,
                                  isSuccess: _isSuccess,
                                ),
                              ),
                              const SizedBox(height: 10),
                              // Instruction / Error Area (Fixed height to avoid jumps)
                              SizedBox(
                                height: 26,
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 200),
                                  child: _errorMessage != null
                                      ? Text(
                                          _errorMessage!,
                                          key: ValueKey(_errorMessage),
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 12.0,
                                            fontWeight: FontWeight.w600,
                                            color: _hasError || isLockedOut
                                                ? theme.colorScheme.error
                                                : (isDark
                                                    ? WalletMeltColors.darkTextSecondary
                                                    : WalletMeltColors.textSecondary),
                                          ),
                                        )
                                      : Text(
                                          isBiometricsEnabled
                                              ? 'Enter PIN or use ${pinController.biometricLabel}'
                                              : 'Enter 4-digit PIN',
                                          key: const ValueKey('instruction'),
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 12.0,
                                            fontWeight: FontWeight.w500,
                                            color: isDark
                                                ? WalletMeltColors.darkTextSecondary
                                                : WalletMeltColors.textSecondary,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),

                          // Keypad Section
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              NumberPad(
                                onKeyPress: _onKeyPress,
                                onDelete: _onDelete,
                                onBiometricPressed: isBiometricsEnabled
                                    ? () => _triggerBiometrics()
                                    : null,
                                biometricLabel: pinController.biometricLabel,
                                disabled: isLockedOut || _isVerifying,
                              ),
                            ],
                          ),


                          // Minimal Footer Note
                          Padding(
                            padding: EdgeInsets.only(
                              top: 6.0,
                              bottom: isCompact ? 10.0 : 16.0,
                            ),
                            child: Text(
                              'Forgot PIN? Uninstalling and reinstalling clears local access.',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: 10.5,
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.3)
                                    : Colors.black.withValues(alpha: 0.35),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
