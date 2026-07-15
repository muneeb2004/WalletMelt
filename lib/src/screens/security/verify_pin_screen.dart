import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../components/glass/app_background.dart';
import '../../security/pin_service.dart';
import '../../utils/haptics.dart';
import '../../widgets/security/number_pad.dart';
import '../../widgets/security/pin_indicator.dart';
import '../../widgets/security/shake_animation.dart';

/// Screen prompting user for current PIN, returning true on successful verification.
class VerifyPinScreen extends StatefulWidget {
  final String title;
  final String instruction;

  const VerifyPinScreen({
    this.title = 'Verify PIN',
    this.instruction = 'Enter your current 4-digit PIN to proceed',
    super.key,
  });

  @override
  State<VerifyPinScreen> createState() => _VerifyPinScreenState();
}

class _VerifyPinScreenState extends State<VerifyPinScreen> {
  final GlobalKey<ShakeAnimationState> _shakeKey = GlobalKey<ShakeAnimationState>();
  final PinService _pinService = PinService();

  String _enteredPin = '';
  String? _errorMessage;

  void _onKeyPress(String value) {
    if (_enteredPin.length >= 4) return;

    setState(() {
      _enteredPin += value;
      _errorMessage = null;
    });

    if (_enteredPin.length == 4) {
      // Small delay for natural animation completion
      Future.delayed(const Duration(milliseconds: 150), () {
        if (!mounted) return;
        _verifyPin();
      });
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
      await WMHaptics.success();
      if (!mounted) return;
      context.pop(true);
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

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
          onPressed: () => context.pop(false),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: AppBackground(
        child: Column(
          children: [
            const Spacer(),
            Icon(
              Icons.security_rounded,
              size: 64,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              widget.title,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.instruction,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 32),

            // PIN Dots with Shake
            ShakeAnimation(
              key: _shakeKey,
              child: PinIndicator(length: _enteredPin.length),
            ),

            const SizedBox(height: 16),

            // Error Message
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

            // Pad
            NumberPad(
              onKeyPress: _onKeyPress,
              onDelete: _onDelete,
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
