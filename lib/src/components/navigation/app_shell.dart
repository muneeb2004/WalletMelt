import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/wallet_melt_theme.dart';

class AppShell extends StatelessWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          Positioned.fill(child: navigationShell),
          Positioned(
            left: 18,
            right: 18,
            bottom: 18,
            child: SafeArea(
              child: LiquidGlass(
                radius: 999,
                blur: 32,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _NavItem(
                        icon: Icons.dashboard_rounded,
                        label: 'Home',
                        index: 0,
                        shell: navigationShell),
                    _NavItem(
                        icon: Icons.receipt_long_rounded,
                        label: 'History',
                        index: 1,
                        shell: navigationShell),
                    _NavItem(
                        icon: Icons.insights_rounded,
                        label: 'Insights',
                        index: 2,
                        shell: navigationShell),
                    _NavItem(
                        icon: Icons.tune_rounded,
                        label: 'Settings',
                        index: 3,
                        shell: navigationShell),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 84),
        child: FloatingActionButton(
          heroTag: 'add-expense',
          tooltip: 'Add expense',
          backgroundColor: WalletMeltColors.brand,
          foregroundColor: WalletMeltColors.textPrimary,
          onPressed: () => context.push('/expense/new'),
          child: const Icon(Icons.add_rounded),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem(
      {required this.icon,
      required this.label,
      required this.index,
      required this.shell});

  final IconData icon;
  final String label;
  final int index;
  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    final active = shell.currentIndex == index;
    return Expanded(
      child: Semantics(
        button: true,
        selected: active,
        label: label,
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: () => shell.goBranch(index,
              initialLocation: index == shell.currentIndex),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              color: active
                  ? WalletMeltColors.brand.withValues(alpha: 0.22)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon,
                    color: active
                        ? WalletMeltColors.brandDeep
                        : Theme.of(context).textTheme.bodyMedium?.color,
                    size: 22),
                const SizedBox(height: 2),
                Text(label,
                    style: Theme.of(context)
                        .textTheme
                        .labelMedium
                        ?.copyWith(fontSize: 11)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
