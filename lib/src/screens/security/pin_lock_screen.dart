import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../components/glass/app_background.dart';
import '../../security/pin_lock_controller.dart';
import '../../security/pin_service.dart';
import '../../utils/haptics.dart';
import '../../widgets/security/number_pad.dart';
import '../../widgets/security/pin_indicator.dart';
import '../../widgets/security/shake_animation.dart';

/// Screen displayed when the app is locked, prompting for PIN entry.
class PinLockScreen extends StatefulWidget {
  final String? from;

  const PinLockScreen({this.from, super.key});

  @override
  State<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends State<PinLockScreen> {
  final GlobalKey<ShakeAnimationState> _shakeKey = GlobalKey<ShakeAnimationState>();
  final PinService _pinService = PinService();

  String _enteredPin = '';
  String? _errorMessage;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(
      const AssetImage('assets/brand/optimized/walletmelt_icon_transparent.webp'),
      context,
    );
  }

  void _onKeyPress(String value) {
    if (_enteredPin.length >= 4) return;

    setState(() {
      _enteredPin += value;
      _errorMessage = null;
    });

    if (_enteredPin.length == 4) {
      _verifyPin();
    }
  }

  void _onDelete() {
    if (_enteredPin.isEmpty) return;
    setState(() {
      _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
      _errorMessage = null;
    });
  }

  Future<void> _verifyPin() async {
    final isValid = await _pinService.verifyPin(_enteredPin);
    if (!mounted) return;

    if (isValid) {
      final controller = context.read<PinLockController>();
      await WMHaptics.success();
      if (!mounted) return;
      controller.unlock();

      if (widget.from != null && widget.from != '/pin-lock') {
        context.go(widget.from!);
      } else {
        context.pop();
      }
    } else {
      await WMHaptics.error();
      if (!mounted) return;
      _shakeKey.currentState?.shake();
      setState(() {
        _enteredPin = '';
        _errorMessage = 'Incorrect PIN. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: AppBackground(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              // Logo (Transparent background, non-redundant, good scale & alignment)
              Image.asset(
                'assets/brand/optimized/walletmelt_icon_transparent.webp',
                height: 72,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
                semanticLabel: 'WalletMelt logo',
              ),
              const SizedBox(height: 16),
              Text(
                'Enter PIN to unlock',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 32),

              // PIN Dots with Shake Animation
              ShakeAnimation(
                key: _shakeKey,
                child: PinIndicator(length: _enteredPin.length),
              ),

              const SizedBox(height: 16),

              // Error text container (constant height to prevent layout jumps)
              SizedBox(
                height: 24,
                child: _errorMessage != null
                    ? Text(
                        _errorMessage!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.error,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    : null,
              ),

              const Spacer(),

              // Keyboard
              NumberPad(
                onKeyPress: _onKeyPress,
                onDelete: _onDelete,
              ),

              const SizedBox(height: 24),

              // Forgot PIN helper text
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Text(
                  'Forgot PIN? Uninstalling and reinstalling the app will erase access to the stored PIN.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
