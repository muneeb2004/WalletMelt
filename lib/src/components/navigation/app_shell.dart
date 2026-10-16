import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../../theme/wallet_melt_theme.dart';
import '../../constants/app_version.dart';
import '../../types/debt.dart';
import '../../screens/debt/debt_screen.dart';
import '../../widgets/whats_new_dialog.dart';

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkWhatsNewPrompt();
    });
  }

  void _checkWhatsNewPrompt() {
    if (!mounted) return;
    final state = context.read<AppState>();
    if (state.settings.hasCompletedOnboarding &&
        state.settings.hasAcceptedPrivacyPolicy &&
        state.settings.lastSeenWhatsNewVersion != AppVersion.version) {
      state.updateLastSeenWhatsNewVersion(AppVersion.version);
      showWhatsNewModal(context);
    }
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
    final isKeyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: widget.navigationShell,
        ),
      ),
      floatingActionButton: isKeyboardOpen || action == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () {
                WMHaptics.light();
                action.action();
              },
              icon: Icon(action.icon),
              label: Text(action.label),
            ),
      bottomNavigationBar: isKeyboardOpen
          ? null
          : NavigationBar(
              selectedIndex: activeIndex,
              onDestinationSelected: (index) {
                WMHaptics.selection();
                widget.navigationShell.goBranch(
                  index,
                  initialLocation: index == activeIndex,
                );
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home_rounded),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: Icon(Icons.receipt_long_outlined),
                  selectedIcon: Icon(Icons.receipt_long_rounded),
                  label: 'History',
                ),
                NavigationDestination(
                  icon: Icon(Icons.calendar_month_outlined),
                  selectedIcon: Icon(Icons.calendar_month_rounded),
                  label: 'Planning',
                ),
                NavigationDestination(
                  icon: Icon(Icons.handshake_outlined),
                  selectedIcon: Icon(Icons.handshake_rounded),
                  label: 'Debts',
                ),
              ],
            ),
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
                  ),
                ),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: WMType.captionSize,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded,
              color: Theme.of(context).colorScheme.onSurfaceVariant),
        ],
      ),
    );
  }
}
