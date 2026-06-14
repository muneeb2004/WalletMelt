import 'package:flutter/material.dart';

import '../../theme/wallet_melt_theme.dart';

class AppBackground extends StatelessWidget {
  const AppBackground({required this.child, super.key, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: dark ? WalletMeltColors.darkBackground : null,
        gradient: dark
            ? null
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  WalletMeltColors.backgroundGradientStart,
                  WalletMeltColors.background,
                  WalletMeltColors.backgroundGradientEnd,
                ],
              ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: padding ?? const EdgeInsets.fromLTRB(20, 18, 20, 120),
          child: child,
        ),
      ),
    );
  }
}
