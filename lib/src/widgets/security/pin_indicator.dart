import 'package:flutter/material.dart';
import '../../theme/wallet_melt_theme.dart';

/// Animated indicator displaying PIN entry progress with smooth scale and color transitions.
class PinIndicator extends StatelessWidget {
  final int length;
  final int maxLength;
  final bool hasError;
  final bool isSuccess;

  const PinIndicator({
    required this.length,
    this.maxLength = 4,
    this.hasError = false,
    this.isSuccess = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final dotColor = hasError
        ? theme.colorScheme.error
        : (isSuccess
            ? (isDark ? WalletMeltColors.brand : WalletMeltColors.textPrimary)
            : (isDark ? WalletMeltColors.brand : WalletMeltColors.textPrimary));

    final emptyBorderColor = hasError
        ? theme.colorScheme.error.withValues(alpha: 0.5)
        : (isDark
            ? Colors.white.withValues(alpha: 0.22)
            : Colors.black.withValues(alpha: 0.20));

    final emptyFillColor = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.black.withValues(alpha: 0.04);

    return Semantics(
      label: hasError
          ? 'Incorrect PIN entered. 0 of $maxLength digits entered.'
          : '$length of $maxLength digits entered.',
      readOnly: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(maxLength, (index) {
          final isFilled = index < length;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.symmetric(horizontal: 10),
            width: isFilled ? 16 : 14,
            height: isFilled ? 16 : 14,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isFilled ? dotColor : emptyFillColor,
              border: Border.all(
                color: isFilled ? dotColor : emptyBorderColor,
                width: isFilled ? 2.0 : 1.5,
              ),
              boxShadow: isFilled
                  ? [
                      BoxShadow(
                        color: dotColor.withValues(alpha: isDark ? 0.25 : 0.15),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
          );
        }),
      ),
    );
  }
}

/// Convenience alias adhering to WalletMelt design token naming.
typedef WMPinIndicator = PinIndicator;
