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
                child: FlatNavBar(
                  radius: 999,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final totalWidth = constraints.maxWidth;
                      final tabWidth = totalWidth / 6;
                      final activeIndex = navigationShell.currentIndex;

                      return Stack(
                        children: [
                          // Smoothly sliding active indicator tab background
                          AnimatedPositioned(
                            duration: const Duration(milliseconds: 320),
                            curve: Curves.easeOutBack,
                            left: activeIndex * tabWidth,
                            width: tabWidth,
                            top: 0,
                            bottom: 0,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withValues(alpha: 0.18),
                                    width: 1.0,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Tab Items Row
                          Row(
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
                                  icon: Icons.account_balance_wallet_rounded,
                                  label: 'Budget',
                                  index: 2,
                                  shell: navigationShell),
                              _NavItem(
                                  icon: Icons.handshake_rounded,
                                  label: 'Debts',
                                  index: 3,
                                  shell: navigationShell),
                              _NavItem(
                                  icon: Icons.insights_rounded,
                                  label: 'Insights',
                                  index: 4,
                                  shell: navigationShell),
                              _NavItem(
                                  icon: Icons.tune_rounded,
                                  label: 'Settings',
                                  index: 5,
                                  shell: navigationShell),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      floatingActionButton: const _AppFloatingActionButton(),
    );
  }
}

class _AppFloatingActionButton extends StatefulWidget {
  const _AppFloatingActionButton();

  @override
  State<_AppFloatingActionButton> createState() => _AppFloatingActionButtonState();
}

class _AppFloatingActionButtonState extends State<_AppFloatingActionButton> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 84),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _scale = 0.90),
        onTapUp: (_) => setState(() => _scale = 1.0),
        onTapCancel: () => setState(() => _scale = 1.0),
        child: AnimatedScale(
          scale: _scale,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeInOut,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFCD34D), // Soft golden brand highlight
                  Color(0xFFF59E0B), // Premium amber brand shade
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.36),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: const Color(0xFFB87912).withValues(alpha: 0.20),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: RawMaterialButton(
              shape: const CircleBorder(),
              elevation: 0,
              fillColor: Colors.transparent,
              onPressed: () => context.push('/expense/new'),
              child: const Icon(
                Icons.add_rounded,
                size: 28,
                color: WalletMeltColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.shell,
  });

  final IconData icon;
  final String label;
  final int index;
  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    final active = shell.currentIndex == index;
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final activeColor = colorScheme.primary;
    final inactiveColor = theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.54) ?? Colors.grey;

    return Expanded(
      child: Semantics(
        button: true,
        selected: active,
        label: label,
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: () => shell.goBranch(index,
              initialLocation: index == shell.currentIndex),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            decoration: const BoxDecoration(
              color: Colors.transparent,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: active ? activeColor : inactiveColor,
                  size: 20,
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.clip,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontSize: 10,
                      fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                      color: active ? activeColor : inactiveColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
