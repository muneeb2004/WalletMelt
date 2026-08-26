/// Decoupled action and navigation intent models for WalletMelt Insights.
///
/// Keeps domain and analytics completely independent of UI routing frameworks.
enum InsightActionType {
  viewHistory,
  viewCategory,
  viewExpense,
  viewBudgets,
}

class InsightAction {
  const InsightAction({
    required this.type,
    required this.label,
    this.targetId,
  });

  final InsightActionType type;
  final String label;
  final String? targetId;

  const InsightAction.viewCategory({
    required String categoryId,
    String label = 'View breakdown →',
  }) : this(type: InsightActionType.viewCategory, label: label, targetId: categoryId);

  const InsightAction.viewExpense({
    required String expenseId,
    String label = 'View expense →',
  }) : this(type: InsightActionType.viewExpense, label: label, targetId: expenseId);

  const InsightAction.viewBudgets({
    String label = 'Manage budgets →',
  }) : this(type: InsightActionType.viewBudgets, label: label);

  const InsightAction.viewHistory({
    String label = 'View transactions →',
  }) : this(type: InsightActionType.viewHistory, label: label);
}
