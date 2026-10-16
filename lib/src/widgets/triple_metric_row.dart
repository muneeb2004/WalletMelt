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
    final separatorColor =
        context.scheme.outlineVariant;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label1,
                style: TextStyle(
                  fontSize: 11,
                  color: context.scheme.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2.0 /* AppSpacing.xs / 2 */),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value1,
                  maxLines: 1,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: color1,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
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
                style: TextStyle(
                  fontSize: 11,
                  color: context.scheme.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2.0),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value2,
                  maxLines: 1,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: color2,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
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
                style: TextStyle(
                  fontSize: 11,
                  color: context.scheme.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2.0),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value3,
                  maxLines: 1,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: color3,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
