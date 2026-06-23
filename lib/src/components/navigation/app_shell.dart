import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../theme/wallet_melt_theme.dart';
import '../../state/app_state.dart';
import '../../types/debt.dart';
import '../../screens/budget/budget_screen.dart';
import '../../screens/debt/debt_screen.dart';

class AppShell extends StatelessWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final activeIndex = navigationShell.currentIndex;
    final action = ScreenActionResolver.resolve(context, activeIndex);

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          Positioned.fill(child: navigationShell),
          Positioned(
            left: AppSpacing.md,
            right: AppSpacing.md,
            bottom: AppSpacing.md,
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
                            duration: const Duration(milliseconds: 260),
                            curve: Curves.easeOutCubic,
                            left: activeIndex * tabWidth,
                            width: tabWidth,
                            top: 0,
                            bottom: 0,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(16),
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
      case 1:
        return ScreenAction(
          icon: Icons.add_rounded,
          label: 'Add Expense',
          action: () => context.push('/expense/new'),
        );
      case 2:
        final state = context.watch<AppState>();
        final monthlyBudget = state.getMonthlyBudgetAmount();
        final hasBudget = monthlyBudget != null;
        return ScreenAction(
          icon: hasBudget ? Icons.edit_rounded : Icons.add_rounded,
          label: hasBudget ? 'Edit Budget' : 'Set Budget',
          action: () {
            BudgetScreen.showSetBudgetSheet(context, state, monthlyBudget);
          },
        );
      case 3:
        return ScreenAction(
          icon: Icons.add_rounded,
          label: 'Add Obligation',
          action: () => _showDebtActionsSheet(context),
        );
      case 4:
      case 5:
      default:
        return null;
    }
  }

  static void _showDebtActionsSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      constraints: const BoxConstraints(maxWidth: 600),
      builder: (sheetContext) {
        return SafeArea(
          child: AnimatedPadding(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.lg,
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
                      HapticFeedback.lightImpact();
                      Navigator.pop(sheetContext);
                      DebtScreen.showAddDebtSheet(context, initialType: DebtType.owedToMe);
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
                      HapticFeedback.lightImpact();
                      Navigator.pop(sheetContext);
                      DebtScreen.showAddDebtSheet(context, initialType: DebtType.iOwe);
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
                      HapticFeedback.lightImpact();
                      Navigator.pop(sheetContext);
                      DebtScreen.showAddDebtSheet(context, initialType: DebtType.loanGiven);
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
                      HapticFeedback.lightImpact();
                      Navigator.pop(sheetContext);
                      DebtScreen.showAddDebtSheet(context, initialType: DebtType.loanTaken);
                    },
                  ),
                ],
              ),
            ),
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
          const Icon(Icons.chevron_right_rounded, color: WalletMeltColors.textMuted),
        ],
      ),
    );
  }
}

class _AppFloatingActionButton extends StatefulWidget {
  const _AppFloatingActionButton({required this.action});

  final ScreenAction? action;

  @override
  State<_AppFloatingActionButton> createState() => _AppFloatingActionButtonState();
}

class _AppFloatingActionButtonState extends State<_AppFloatingActionButton> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    final hasAction = widget.action != null;

    return AnimatedOpacity(
      opacity: hasAction ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 220),
      child: AnimatedScale(
        scale: hasAction ? _scale : 0.0,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 84),
          child: IgnorePointer(
            ignoring: !hasAction,
            child: GestureDetector(
              onTapDown: (_) => setState(() => _scale = 0.94),
              onTapUp: (_) => setState(() => _scale = 1.0),
              onTapCancel: () => setState(() => _scale = 1.0),
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
                  splashColor: Colors.white.withValues(alpha: 0.15),
                  highlightColor: Colors.white.withValues(alpha: 0.08),
                  onPressed: widget.action == null
                      ? null
                      : () {
                          HapticFeedback.lightImpact();
                          widget.action!.action();
                        },
                  child: Icon(
                    widget.action?.icon ?? Icons.add_rounded,
                    size: 28,
                    color: WalletMeltColors.textPrimary,
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
    final inactiveColor =
        theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.54) ??
            Colors.grey;

    return Expanded(
      child: Semantics(
        button: true,
        selected: active,
        label: label,
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: () {
            HapticFeedback.lightImpact();
            shell.goBranch(index,
                initialLocation: index == shell.currentIndex);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 10),
            decoration: const BoxDecoration(
              color: Colors.transparent,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedScale(
                  scale: active ? 1.12 : 1.0,
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeOutCubic,
                  child: TweenAnimationBuilder<Color?>(
                    duration: const Duration(milliseconds: 240),
                    tween: ColorTween(
                      end: active ? activeColor : inactiveColor,
                    ),
                    builder: (context, color, child) {
                      return Icon(
                        icon,
                        color: color ?? (active ? activeColor : inactiveColor),
                        size: 20,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 3),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeOutCubic,
                    style: theme.textTheme.labelMedium!.copyWith(
                      fontSize: 9.5,
                      fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                      color: active ? activeColor : inactiveColor,
                    ),
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.clip,
                    child: Text(label),
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
