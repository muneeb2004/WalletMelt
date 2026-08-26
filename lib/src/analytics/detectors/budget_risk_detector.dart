import '../insight_detector.dart';
import '../insight_engine.dart';
import '../../types/insight_action.dart';
import '../../types/insight_card.dart';
import '../../types/insight_data.dart';

class BudgetRiskDetector implements InsightDetector {
  const BudgetRiskDetector();

  @override
  InsightCard? detect(InsightContext context) {
    final snapshot = context.snapshot;
    final catNameMap = context.categoryNameMap;
    final risks = <BudgetRiskItem>[];

    // 1. Evaluate Category Budgets
    for (final budget in context.budgets) {
      if (budget.amount <= 0) continue;
      final spent = snapshot.currentByCategory[budget.categoryId] ?? 0.0;
      final projected = snapshot.daysElapsed > 0
          ? (spent / snapshot.daysElapsed) * snapshot.daysInMonth
          : spent;

      final item = CategoryBudgetRisk(
        categoryId: budget.categoryId,
        categoryName: catNameMap[budget.categoryId] ?? 'Uncategorized',
        spent: spent,
        budgetAmount: budget.amount,
        daysElapsed: snapshot.daysElapsed,
        daysInMonth: snapshot.daysInMonth,
        projectedTotal: projected,
      );

      if (item.usagePercent >= 60.0) {
        risks.add(item);
      }
    }

    // 2. Evaluate Overall Monthly Budget
    if (context.monthlyBudgetAmount != null && context.monthlyBudgetAmount! > 0) {
      final overallAmount = context.monthlyBudgetAmount!;
      final spent = snapshot.currentTotal;
      final projected = snapshot.daysElapsed > 0
          ? (spent / snapshot.daysElapsed) * snapshot.daysInMonth
          : spent;

      final overallItem = OverallBudgetRisk(
        spent: spent,
        budgetAmount: overallAmount,
        daysElapsed: snapshot.daysElapsed,
        daysInMonth: snapshot.daysInMonth,
        projectedTotal: projected,
      );

      if (overallItem.usagePercent >= 60.0) {
        risks.add(overallItem);
      }
    }

    if (risks.isEmpty) return null;

    // Identify highest risk item
    double scoreFor(BudgetRiskItem item) {
      double score = item.usagePercent / 100.0;
      if (item.projectedOverage != null && item.projectedOverage! > 0) {
        score += (item.projectedOverage! / item.budgetAmount).clamp(0.0, 0.5);
      }
      return score;
    }

    final highestRisk =
        risks.reduce((a, b) => scoreFor(a) >= scoreFor(b) ? a : b);

    // rawRisk is unbounded above; normalizedRisk is clamped to [0.0, 1.0]
    final rawRisk = scoreFor(highestRisk);
    final normalizedRisk = ((rawRisk - 0.60) / (1.50 - 0.60)).clamp(0.0, 1.0);
    final baseWeight = 0.90 + (0.10 * normalizedRisk);

    final priority = InsightEngine.calculatePriority(
      taxonomy: InsightTaxonomy.risk,
      baseWeight: baseWeight,
      confidence: 1.00,
      actionability: 1.00,
    );

    // Severity mapping: >=95% alert, >=80% warning, >=60% info
    final severity = highestRisk.usagePercent >= 95.0
        ? InsightSeverity.alert
        : (highestRisk.usagePercent >= 80.0
            ? InsightSeverity.warning
            : InsightSeverity.info);

    final String title;
    final String description;

    if (highestRisk is CategoryBudgetRisk) {
      title = 'Budget Risk: ${highestRisk.categoryName}';
      description =
          '${highestRisk.categoryName} is at ${highestRisk.usagePercent.toStringAsFixed(0)}% of its budget limit.';
    } else {
      title = 'Monthly Budget Risk';
      description =
          'Overall spending is at ${highestRisk.usagePercent.toStringAsFixed(0)}% of your monthly budget.';
    }

    final data = BudgetRiskData(
      risks: risks,
      highestRiskItem: highestRisk,
    );

    return InsightCard(
      id: 'insight_budget_risk',
      type: InsightType.budgetRisk,
      taxonomy: InsightTaxonomy.risk,
      severity: severity,
      title: title,
      description: description,
      priority: priority,
      data: data,
      metrics: [
        InsightMetric(
          label: 'Budget usage',
          value: highestRisk.usagePercent,
          unit: InsightMetricUnit.percent,
        ),
      ],
      action: const InsightAction.viewBudgets(),
    );
  }
}
