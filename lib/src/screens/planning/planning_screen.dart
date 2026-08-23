import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../components/glass/app_background.dart';
import '../../state/app_state.dart';
import '../../theme/wallet_melt_theme.dart';
import '../budget/budget_screen.dart';
import '../subscription/subscription_screen.dart';
import '../essentials/essential_expenses_screen.dart';

class PlanningScreen extends StatefulWidget {
  final int initialIndex;
  const PlanningScreen({this.initialIndex = 0, super.key});

  @override
  State<PlanningScreen> createState() => _PlanningScreenState();
}

class _PlanningScreenState extends State<PlanningScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialIndex.clamp(0, 2),
    );
    _tabController.addListener(() {
      setState(() {});
    });
  }

  @override
  void didUpdateWidget(covariant PlanningScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialIndex != oldWidget.initialIndex) {
      _tabController.animateTo(widget.initialIndex.clamp(0, 2));
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: AppBackground(
        child: Column(
          children: [
            // Top Header & Action Row
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Financial Planning',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Budgets, renewals & predictable expenses',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: WalletMeltColors.textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Dynamic Action Button based on active Tab
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isDark ? WalletMeltColors.darkSurface : Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? WalletMeltColors.darkBorder : WalletMeltColors.lightBorder,
                        width: 1.0,
                      ),
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      tooltip: _tabController.index == 0
                          ? 'Set Budget'
                          : (_tabController.index == 1
                              ? 'Add Subscription'
                              : 'Add Essential'),
                      onPressed: () {
                        if (_tabController.index == 0) {
                          final monthlyBudget = state.getMonthlyBudgetAmount();
                          final totalSpent = state.getCurrentMonthTotalSpent();
                          BudgetScreen.showSetBudgetSheet(
                              context, state, monthlyBudget, totalSpent);
                        } else if (_tabController.index == 1) {
                          SubscriptionScreen.showAddSubscriptionSheet(context);
                        } else {
                          EssentialExpensesScreen.showAddEssentialSheet(context);
                        }
                      },
                      icon: Icon(
                        _tabController.index == 0
                            ? Icons.edit_rounded
                            : Icons.add_rounded,
                        size: 20,
                        color: isDark ? Colors.white : WalletMeltColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Segmented Tab Selector bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF161922) : const Color(0xFFECEFF3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  indicator: BoxDecoration(
                    color: isDark ? WalletMeltColors.brand : WalletMeltColors.textPrimary,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.06),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  labelColor: isDark ? Colors.black : Colors.white,
                  unselectedLabelColor:
                      isDark ? WalletMeltColors.darkTextSecondary : WalletMeltColors.textSecondary,
                  labelStyle: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 11.5),
                  unselectedLabelStyle: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 11.5),
                  tabs: const [
                    Tab(child: FittedBox(fit: BoxFit.scaleDown, child: Text('Budgets'))),
                    Tab(child: FittedBox(fit: BoxFit.scaleDown, child: Text('Subscriptions'))),
                    Tab(child: FittedBox(fit: BoxFit.scaleDown, child: Text('Essentials'))),
                  ],
                ),
              ),
            ),

            // Tab View Body
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [
                  BudgetScreen(isEmbedded: true),
                  SubscriptionScreen(isEmbedded: true),
                  EssentialExpensesScreen(isEmbedded: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
