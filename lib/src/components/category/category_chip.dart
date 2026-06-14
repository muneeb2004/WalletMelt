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
    final color = colorFromHex(category.color);
    return Semantics(
      button: true,
      selected: selected,
      label: category.name,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 160),
        scale: selected ? 1.03 : 1,
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: selected ? color.withValues(alpha: 0.28) : Colors.white.withValues(alpha: 0.42),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: selected ? color : Colors.white.withValues(alpha: 0.4)),
            ),
            child: Text(category.name, style: Theme.of(context).textTheme.labelLarge),
          ),
        ),
      ),
    );
  }
}
