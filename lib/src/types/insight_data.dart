/// Sealed payload hierarchy representing type-safe data for each insight detector.
sealed class InsightData {
  const InsightData();
}

/// Payload for Why Spending Changed insight.
class WhyChangedData extends InsightData {
  const WhyChangedData({
    required this.totalDelta,
    required this.isIncrease,
    required this.topContributorCategoryId,
    required this.topContributorName,
    required this.topContributorDelta,
    required this.directionalContributionPercent,
    required this.currentTotal,
    required this.previousTotal,
  });

  final double totalDelta;
  final bool isIncrease;
  final String topContributorCategoryId;
  final String topContributorName;
  final double topContributorDelta;

  /// Percentage of total gross movement in the direction of the net change [0.0, 100.0].
  final double directionalContributionPercent;
  final double currentTotal;
  final double previousTotal;
}

/// Abstract representation of a budget at risk.
sealed class BudgetRiskItem {
  const BudgetRiskItem({
    required this.spent,
    required this.budgetAmount,
    required this.daysElapsed,
    required this.daysInMonth,
    this.projectedTotal,
  });

  /// Net spend after refunds.
  final double spent;
  final double budgetAmount;
  final int daysElapsed;
  final int daysInMonth;
  final double? projectedTotal;

  double get usagePercent =>
      budgetAmount > 0 ? ((spent > 0 ? spent : 0.0) / budgetAmount) * 100 : 0.0;

  double get remainingBudget => budgetAmount - spent;

  double? get projectedOverage =>
      projectedTotal != null && projectedTotal! > budgetAmount
          ? projectedTotal! - budgetAmount
          : null;
}

/// Specific category budget at risk.
class CategoryBudgetRisk extends BudgetRiskItem {
  const CategoryBudgetRisk({
    required this.categoryId,
    required this.categoryName,
    required super.spent,
    required super.budgetAmount,
    required super.daysElapsed,
    required super.daysInMonth,
    super.projectedTotal,
  });

  final String categoryId;
  final String categoryName;
}

/// Overall monthly budget at risk.
class OverallBudgetRisk extends BudgetRiskItem {
  const OverallBudgetRisk({
    required super.spent,
    required super.budgetAmount,
    required super.daysElapsed,
    required super.daysInMonth,
    super.projectedTotal,
  });
}

/// Payload for Budget Risk insight aggregating multiple active budgets.
class BudgetRiskData extends InsightData {
  const BudgetRiskData({
    required this.risks,
    required this.highestRiskItem,
  });

  final List<BudgetRiskItem> risks;
  final BudgetRiskItem highestRiskItem;
}

/// Payload for Spending Velocity insight.
class VelocityData extends InsightData {
  const VelocityData({
    required this.amountSpent,
    required this.daysElapsed,
    required this.daysInMonth,
    required this.projectedTotal,
    required this.previousMonthTotal,
    required this.projectedChangePercent,
  });

  /// Positive elapsed spending amount.
  final double amountSpent;
  final int daysElapsed;
  final int daysInMonth;
  final double projectedTotal;
  final double previousMonthTotal;
  final double projectedChangePercent;
}

/// Payload for Category Spending Changes insight.
class CategoryChangesData extends InsightData {
  const CategoryChangesData({required this.changes});

  final List<CategoryChange> changes;
}

/// Represents spending change in a single category between periods.
class CategoryChange {
  const CategoryChange({
    required this.categoryId,
    required this.categoryName,
    required this.currentAmount,
    required this.previousAmount,
  });

  final String categoryId;
  final String categoryName;
  final double currentAmount;
  final double previousAmount;

  /// Signed directional change (`current - previous`).
  double get absoluteChange => currentAmount - previousAmount;

  /// Absolute magnitude of change.
  double get magnitude => absoluteChange.abs();

  /// Magnitude percentage change relative to previous amount.
  double? get percentChange =>
      previousAmount != 0 ? (magnitude / previousAmount.abs()) * 100 : null;
}

/// Payload for Spending Frequency insight.
class FrequencyData extends InsightData {
  const FrequencyData({
    required this.currentCount,
    required this.previousCount,
    required this.currentAvgValue,
    required this.previousAvgValue,
    required this.countDeltaPercent,
    required this.avgValueDeltaPercent,
  });

  final int currentCount;
  final int previousCount;
  final double currentAvgValue;
  final double previousAvgValue;
  final double countDeltaPercent;
  final double avgValueDeltaPercent;
}

/// Payload for Merchant Category Inconsistency insight.
class MerchantInconsistencyData extends InsightData {
  const MerchantInconsistencyData({required this.inconsistencies});

  final List<MerchantInconsistency> inconsistencies;
}

/// Represents a merchant recorded under multiple distinct categories.
class MerchantInconsistency {
  const MerchantInconsistency({
    required this.merchantKey,
    required this.displayName,
    required this.categoryNames,
    required this.positiveTransactionCount,
  });

  final String merchantKey;
  final String displayName;
  final List<String> categoryNames;
  final int positiveTransactionCount;
}

enum EssentialClassificationBasis {
  configuredEssentialCategoriesAndSubscriptions,
}

/// Payload for Essential vs Other Spending insight.
class EssentialSplitData extends InsightData {
  const EssentialSplitData({
    required this.essentialTotal,
    required this.otherTotal,
    required this.essentialPercent,
    required this.basis,
  });

  final double essentialTotal;
  final double otherTotal;
  final double essentialPercent;
  final EssentialClassificationBasis basis;
}
