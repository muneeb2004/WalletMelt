import 'package:flutter/material.dart';

import '../../theme/wallet_melt_theme.dart';
import '../../types/category.dart';

class WalletCategoryChip extends StatelessWidget {
  const WalletCategoryChip({
    required this.category,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final Category category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = colorFromHex(category.color);
    final fill = selected
        ? color.withValues(alpha: 0.28)
        : (isDark
            ? const Color(0xFF1E1E24).withValues(alpha: 0.48)
            : Colors.white.withValues(alpha: 0.42));
    final border = selected
        ? color
        : (isDark
            ? const Color.fromRGBO(255, 255, 255, 0.12)
            : Colors.white.withValues(alpha: 0.4));
    return Semantics(
      button: true,
      selected: selected,
      label: category.name,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 160),
        scale: selected ? 1.03 : 1.0,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: border, width: 1.2),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Text(category.name,
                    style: Theme.of(context).textTheme.labelLarge),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
