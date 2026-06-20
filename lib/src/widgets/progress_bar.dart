import 'package:flutter/material.dart';

/// A reusable linear budget progress bar.
///
/// Wraps [LinearProgressIndicator] in a pill-shaped [ClipRRect] so widget
/// tests can still locate the indicator by type. Pass a [fraction] in the
/// range 0.0–1.0+ (values above 1.0 are clamped visually to 1.0 but do not
/// affect [color] selection — that is the caller's responsibility).
class ProgressBar extends StatelessWidget {
  const ProgressBar({
    required this.fraction,
    required this.color,
    super.key,
    this.height = 8.0,
  });

  /// Spend ratio — unclamped (caller decides color, we clamp display only).
  final double fraction;

  /// Fill color of the indicator track.
  final Color color;

  /// Height of the bar in logical pixels. Defaults to 8.
  final double height;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final targetValue = fraction.clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: height,
        child: TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutCubic,
          tween: Tween<double>(end: targetValue),
          builder: (context, animValue, _) {
            return TweenAnimationBuilder<Color?>(
              duration: const Duration(milliseconds: 350),
              tween: ColorTween(end: color),
              builder: (context, animColor, _) {
                return LinearProgressIndicator(
                  value: animValue,
                  backgroundColor: isDark
                      ? const Color.fromRGBO(255, 255, 255, 0.08)
                      : const Color.fromRGBO(0, 0, 0, 0.06),
                  valueColor: AlwaysStoppedAnimation<Color>(animColor ?? color),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
