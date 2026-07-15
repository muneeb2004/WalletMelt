import 'package:flutter/material.dart';

/// Animated indicator showing 4 dots representing entered digits.
class PinIndicator extends StatelessWidget {
  final int length;
  final int maxLength;

  const PinIndicator({
    required this.length,
    this.maxLength = 4,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(maxLength, (index) {
        final isFilled = index < length;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 12),
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isFilled
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface.withValues(alpha: 0.12),
            border: Border.all(
              color: isFilled
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface.withValues(alpha: 0.24),
              width: 2,
            ),
          ),
          transform: Matrix4.diagonal3Values(
            isFilled ? 1.15 : 1.0,
            isFilled ? 1.15 : 1.0,
            1.0,
          ),
          transformAlignment: Alignment.center,
        );
      }),
    );
  }
}
