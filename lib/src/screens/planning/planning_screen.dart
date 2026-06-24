import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../components/glass/app_background.dart';
import '../../state/app_state.dart';
import '../budget/budget_screen.dart';
import '../subscription/subscription_screen.dart';

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
      length: 2,
      vsync: this,
      initialIndex: widget.initialIndex,
    );
    _tabController.addListener(() {
      setState(() {});
    });
  }

  @override
  void didUpdateWidget(covariant PlanningScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialIndex != oldWidget.initialIndex) {
      _tabController.animateTo(widget.initialIndex);
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
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Planning',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                  // Dynamic Action Button based on active Tab
                  IconButton(
                    tooltip: _tabController.index == 0
                        ? 'Set Budget'
                        : 'Add Subscription',
                    onPressed: () {
                      if (_tabController.index == 0) {
                        final monthlyBudget = state.getMonthlyBudgetAmount();
                        BudgetScreen.showSetBudgetSheet(
                            context, state, monthlyBudget);
                      } else {
                        SubscriptionScreen.showAddSubscriptionSheet(context);
                      }
                    },
                    icon: Icon(
                      _tabController.index == 0
                          ? Icons.edit_calendar_rounded
                          : Icons.add_rounded,
                      size: 28,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),

            // Tab Selector bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.04)
                      : Colors.black.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.06),
                    width: 1.0,
                  ),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  indicator: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.2),
                      width: 1.0,
                    ),
                  ),
                  labelColor: Theme.of(context).colorScheme.primary,
                  unselectedLabelColor:
                      isDark ? Colors.white70 : Colors.black54,
                  labelStyle: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 13),
                  unselectedLabelStyle: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13),
                  tabs: const [
                    Tab(text: 'Budgets'),
                    Tab(text: 'Subscriptions'),
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
