import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../components/glass/app_background.dart';
import '../../security/pin_lock_controller.dart';
import '../../utils/haptics.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/security/number_pad.dart';
import '../../widgets/security/pin_indicator.dart';
import '../../widgets/security/shake_animation.dart';

/// Screen guiding the user through creating and confirming a new PIN.
class CreatePinScreen extends StatefulWidget {
  const CreatePinScreen({super.key});

  @override
  State<CreatePinScreen> createState() => _CreatePinScreenState();
}

class _CreatePinScreenState extends State<CreatePinScreen> {
  final GlobalKey<ShakeAnimationState> _shakeKey = GlobalKey<ShakeAnimationState>();

  String _firstPin = '';
  String _enteredPin = '';
  bool _isConfirming = false;
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
        _handleCompletedPin();
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

  Future<void> _handleCompletedPin() async {
    if (!_isConfirming) {
      setState(() {
        _firstPin = _enteredPin;
        _enteredPin = '';
        _isConfirming = true;
      });
    } else {
      if (_enteredPin == _firstPin) {
        final controller = context.read<PinLockController>();
        await controller.enablePin(_enteredPin);
        if (!mounted) return;

        showSuccessSnackbar(context, 'PIN Lock enabled successfully.');
        context.pop(true);
      } else {
        await WMHaptics.error();
        _shakeKey.currentState?.shake();
        setState(() {
          _enteredPin = '';
          _errorMessage = 'PINs do not match. Please try again.';
        });
      }
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
          icon: const Icon(Icons.close),
          tooltip: 'Cancel',
          onPressed: () => context.pop(false),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: AppBackground(
        child: Column(
          children: [
            const Spacer(),
            Icon(
              _isConfirming ? Icons.lock_outline : Icons.lock_open_outlined,
              size: 64,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              _isConfirming ? 'Confirm PIN' : 'Create PIN',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _isConfirming
                  ? 'Re-enter your 4-digit PIN to confirm'
                  : 'Enter a 4-digit PIN to secure WalletMelt',
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
