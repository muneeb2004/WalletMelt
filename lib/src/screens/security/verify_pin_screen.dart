import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../components/glass/app_background.dart';
import '../../security/pin_service.dart';
import '../../theme/wallet_melt_theme.dart';
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
  final GlobalKey<ShakeAnimationState> _shakeKey =
      GlobalKey<ShakeAnimationState>();
  final PinService _pinService = PinService();

  String _enteredPin = '';
  String? _errorMessage;
  bool _hasError = false;

  void _onKeyPress(String value) {
    if (_enteredPin.length >= 4) return;

    setState(() {
      _enteredPin += value;
      _errorMessage = null;
      _hasError = false;
    });

    if (_enteredPin.length == 4) {
      // Small delay for natural animation completion
      Future.delayed(const Duration(milliseconds: 120), () {
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
      _hasError = false;
    });
  }

  Future<void> _verifyPin() async {
    final isValid = await _pinService.verifyPin(_enteredPin);
    if (!mounted) return;

    if (isValid) {
      await WMHaptics.success();
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } else {
      await WMHaptics.error();
      if (!mounted) return;
      _shakeKey.currentState?.shake();
      setState(() {
        _enteredPin = '';
        _hasError = true;
        _errorMessage = 'Incorrect PIN. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Back',
          onPressed: () => context.pop(false),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: AppBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxHeight < 680;

              return SingleChildScrollView(
                physics: constraints.maxHeight < 580
                    ? const ClampingScrollPhysics()
                    : const NeverScrollableScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Top icon & title
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(height: isCompact ? 16 : 28),
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isDark
                                    ? WalletMeltColors.brand.withValues(alpha: 0.12)
                                    : WalletMeltColors.brand.withValues(alpha: 0.15),
                              ),
                              child: Icon(
                                Icons.security_rounded,
                                size: 28,
                                color: isDark
                                    ? WalletMeltColors.brand
                                    : WalletMeltColors.brandDeep,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              widget.title,
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                fontSize: isCompact ? 22 : 24,
                                letterSpacing: -0.5,
                                color: isDark
                                    ? WalletMeltColors.darkTextPrimary
                                    : WalletMeltColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              widget.instruction,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: isDark
                                    ? WalletMeltColors.darkTextSecondary
                                    : WalletMeltColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),

                        // Center PIN Dots with Shake
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(height: isCompact ? 16 : 24),
                            ShakeAnimation(
                              key: _shakeKey,
                              child: PinIndicator(
                                length: _enteredPin.length,
                                hasError: _hasError,
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 24,
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                child: _errorMessage != null
                                    ? Text(
                                        _errorMessage!,
                                        key: ValueKey(_errorMessage),
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w600,
                                          color: theme.colorScheme.error,
                                        ),
                                      )
                                    : const SizedBox.shrink(
                                        key: ValueKey('empty'),
                                      ),
                              ),
                            ),
                          ],
                        ),

                        // Keypad
                        Padding(
                          padding: EdgeInsets.only(
                            bottom: isCompact ? 16.0 : 28.0,
                          ),
                          child: NumberPad(
                            onKeyPress: _onKeyPress,
                            onDelete: _onDelete,
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
    );
  }
}
