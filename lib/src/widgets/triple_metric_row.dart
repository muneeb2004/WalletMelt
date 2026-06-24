import 'package:flutter/material.dart';
import '../theme/wallet_melt_theme.dart';

class TripleMetricRow extends StatelessWidget {
  const TripleMetricRow({
    required this.label1,
    required this.value1,
    required this.color1,
    required this.label2,
    required this.value2,
    required this.color2,
    required this.label3,
    required this.value3,
    required this.color3,
    super.key,
  });

  final String label1;
  final String value1;
  final Color color1;
  final String label2;
  final String value2;
  final Color color2;
  final String label3;
  final String value3;
  final Color color3;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final separatorColor =
        isDark ? WalletMeltColors.darkBorder : WalletMeltColors.lightBorder;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label1,
                style: const TextStyle(
                  fontSize: 9.0,
                  color: WalletMeltColors.textMuted,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2.0 /* AppSpacing.xs / 2 */),
              Text(
                value1,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14.0,
                  color: color1,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8.0 /* AppSpacing.sm */),
        Container(
          width: 1.0,
          height: 24.0,
          color: separatorColor,
        ),
        const SizedBox(width: 8.0 /* AppSpacing.sm */),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label2,
                style: const TextStyle(
                  fontSize: 9.0,
                  color: WalletMeltColors.textMuted,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2.0),
              Text(
                value2,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14.0,
                  color: color2,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8.0 /* AppSpacing.sm */),
        Container(
          width: 1.0,
          height: 24.0,
          color: separatorColor,
        ),
        const SizedBox(width: 8.0 /* AppSpacing.sm */),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label3,
                style: const TextStyle(
                  fontSize: 9.0,
                  color: WalletMeltColors.textMuted,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2.0),
              Text(
                value3,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14.0,
                  color: color3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
