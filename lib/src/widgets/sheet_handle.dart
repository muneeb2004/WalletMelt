import 'package:flutter/material.dart';

import '../theme/wallet_melt_theme.dart';

/// A standard drag handle for bottom sheets. Place as the first child of any
/// sheet's root Column, above the title row.
///
/// When using [showModalBottomSheet], set `showDragHandle: false` and add
/// [SheetHandle] manually so its vertical margin integrates with content
/// padding.
class SheetHandle extends StatelessWidget {
  const SheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 32,
        height: 4,
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        decoration: BoxDecoration(
          color:
              Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.20),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}
