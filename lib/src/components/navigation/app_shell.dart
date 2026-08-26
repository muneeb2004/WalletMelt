import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/wallet_melt_theme.dart';
import '../../types/debt.dart';
import '../../screens/debt/debt_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _transitionController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _transitionController = AnimationController(
      vsync: this,
      duration: AppMotion.medium,
    )..value = 1.0;

    _fadeAnimation = CurvedAnimation(
      parent: _transitionController,
      curve: AppMotion.standard,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.015),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _transitionController,
      curve: AppMotion.standard,
    ));
  }

  @override
  void didUpdateWidget(AppShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.navigationShell.currentIndex !=
        widget.navigationShell.currentIndex) {
      _transitionController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _transitionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeIndex = widget.navigationShell.currentIndex;
    final action = ScreenActionResolver.resolve(context, activeIndex);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final isKeyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;

    return Scaffold(
      extendBody: true,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Positioned.fill(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: widget.navigationShell,
              ),
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 18,
            child: SafeArea(
              child: AnimatedSlide(
                offset: isKeyboardOpen ? const Offset(0.0, 1.4) : Offset.zero,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOutCubic,
                child: AnimatedOpacity(
                  opacity: isKeyboardOpen ? 0.0 : 1.0,
                  duration: const Duration(milliseconds: 180),
                  child: IgnorePointer(
                    ignoring: isKeyboardOpen,
                    child: Container(
                      height: 70,
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0C0E14) : Colors.white,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                        border: Border.all(
                          color: isDark
                              ? WalletMeltColors.darkBorder
                              : WalletMeltColors.lightBorder,
                          width: 1.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.40 : 0.08),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: _FluidBlobNavBar(shell: widget.navigationShell),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _AppFloatingActionButton(action: action),
    );
  }
}


class ScreenAction {
  final IconData icon;
  final String label;
  final VoidCallback action;

  const ScreenAction({
    required this.icon,
    required this.label,
    required this.action,
  });
}

class ScreenActionResolver {
  static ScreenAction? resolve(BuildContext context, int currentIndex) {
    switch (currentIndex) {
      case 0:
        return null; // Dashboard has prominent Quick Actions bar
      case 1:
        return ScreenAction(
          icon: Icons.add_rounded,
          label: 'Add Expense',
          action: () => context.push('/expense/new'),
        );
      case 2:
        return null; // PlanningScreen renders its own contextual header add/edit button
      case 3:
        return ScreenAction(
          icon: Icons.add_rounded,
          label: 'Add Obligation',
          action: () => _showDebtActionsSheet(context),
        );
      default:
        return null;
    }
  }

  static void _showDebtActionsSheet(BuildContext context) {
    showAppBottomSheet<void>(
      context,
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add Obligation',
                style: Theme.of(sheetContext).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 16),
              _buildDebtActionTile(
                sheetContext,
                icon: Icons.arrow_outward_rounded,
                color: WalletMeltColors.positive,
                title: 'Money Owed To Me',
                subtitle: 'A person owes you money',
                onTap: () {
                  WMHaptics.light();
                  Navigator.pop(sheetContext);
                  DebtScreen.showAddDebtSheet(context,
                      initialType: DebtType.owedToMe);
                },
              ),
              const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
              _buildDebtActionTile(
                sheetContext,
                icon: Icons.call_received_rounded,
                color: WalletMeltColors.danger,
                title: 'Money I Owe',
                subtitle: 'You owe someone money',
                onTap: () {
                  WMHaptics.light();
                  Navigator.pop(sheetContext);
                  DebtScreen.showAddDebtSheet(context,
                      initialType: DebtType.iOwe);
                },
              ),
              const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
              _buildDebtActionTile(
                sheetContext,
                icon: Icons.arrow_outward_rounded,
                color: WalletMeltColors.positive,
                title: 'Loan Given',
                subtitle: 'You lent money to someone',
                onTap: () {
                  WMHaptics.light();
                  Navigator.pop(sheetContext);
                  DebtScreen.showAddDebtSheet(context,
                      initialType: DebtType.loanGiven);
                },
              ),
              const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
              _buildDebtActionTile(
                sheetContext,
                icon: Icons.call_received_rounded,
                color: WalletMeltColors.danger,
                title: 'Loan Taken',
                subtitle: 'You borrowed money from someone',
                onTap: () {
                  WMHaptics.light();
                  Navigator.pop(sheetContext);
                  DebtScreen.showAddDebtSheet(context,
                      initialType: DebtType.loanTaken);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  static Widget _buildDebtActionTile(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return WMGlassSurface.tier2(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: AppSpacing.md - 2.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 14.0,
                  ),
                ),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: WalletMeltColors.textMuted,
                    fontSize: 11.0,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded,
              color: WalletMeltColors.textMuted),
        ],
      ),
    );
  }
}

class _AppFloatingActionButton extends StatefulWidget {
  const _AppFloatingActionButton({required this.action});

  final ScreenAction? action;

  @override
  State<_AppFloatingActionButton> createState() =>
      _AppFloatingActionButtonState();
}

class _AppFloatingActionButtonState extends State<_AppFloatingActionButton> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    final isKeyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    final isVisible = widget.action != null && !isKeyboardOpen;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedOpacity(
      opacity: isVisible ? 1.0 : 0.0,
      duration: AppMotion.medium,
      child: AnimatedScale(
        scale: isVisible ? _scale : 0.0,
        duration: AppMotion.medium,
        curve: AppMotion.entrance,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 84),
          child: IgnorePointer(
            ignoring: !isVisible,
            child: GestureDetector(

              onTapDown: (_) => setState(() => _scale = 0.94),
              onTapUp: (_) => setState(() => _scale = 1.0),
              onTapCancel: () => setState(() => _scale = 1.0),
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark
                      ? WalletMeltColors.brand
                      : WalletMeltColors.textPrimary,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.16),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: RawMaterialButton(
                  shape: const CircleBorder(),
                  elevation: 0,
                  fillColor: Colors.transparent,
                  splashColor: Colors.white.withValues(alpha: 0.15),
                  highlightColor: Colors.white.withValues(alpha: 0.08),
                  onPressed: widget.action == null
                      ? null
                      : () {
                          WMHaptics.light();
                          widget.action!.action();
                        },
                  child: Icon(
                    widget.action?.icon ?? Icons.add_rounded,
                    size: 28,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FluidBlobNavBar extends StatelessWidget {
  const _FluidBlobNavBar({
    required this.shell,
  });

  final StatefulNavigationShell shell;

  static const _items = [
    (icon: Icons.home_filled, label: 'Home'),
    (icon: Icons.receipt_long_rounded, label: 'History'),
    (icon: Icons.account_balance_wallet_rounded, label: 'Planning'),
    (icon: Icons.handshake_rounded, label: 'Debts'),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentIndex = shell.currentIndex;
    final activeBgColor = isDark ? WalletMeltColors.brand : WalletMeltColors.textPrimary;
    final activeTextColor = isDark ? Colors.black : Colors.white;
    final inactiveColor = isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8);

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final activeWidth = (totalWidth * 0.36).clamp(90.0, 130.0);
        final inactiveWidth = (totalWidth - activeWidth) / (_items.length - 1);
        final pillLeft = currentIndex * inactiveWidth;

        return Stack(
          alignment: Alignment.centerLeft,
          children: [
            // ── Single Fluid Sliding Blob Pill ────────────────────────────
            AnimatedPositioned(
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOutCubic,
              left: pillLeft,
              top: 2,
              bottom: 2,
              width: activeWidth,
              child: Container(
                decoration: BoxDecoration(
                  color: activeBgColor,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                  boxShadow: [
                    BoxShadow(
                      color: activeBgColor.withValues(alpha: isDark ? 0.35 : 0.22),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
              ),
            ),

            // ── Interactive Tab Slots ─────────────────────────────────────
            Row(
              children: List.generate(_items.length, (index) {
                final active = index == currentIndex;
                final item = _items[index];

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 320),
                  curve: Curves.easeOutCubic,
                  width: active ? activeWidth : inactiveWidth,
                  height: double.infinity,
                  child: Semantics(
                    button: true,
                    selected: active,
                    label: item.label,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        WMHaptics.selection();
                        shell.goBranch(index, initialLocation: index == shell.currentIndex);
                      },
                      child: Container(
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              item.icon,
                              color: active ? activeTextColor : inactiveColor,
                              size: 20,
                            ),
                            if (active) ...[
                              const SizedBox(width: 6),
                              Flexible(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    item.label,
                                    maxLines: 1,
                                    softWrap: false,
                                    style: TextStyle(
                                      fontFamily: 'PlusJakartaSans',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: activeTextColor,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        );
      },
    );
  }
}
