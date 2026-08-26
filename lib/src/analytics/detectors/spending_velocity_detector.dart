import '../analytics_constants.dart';
import '../insight_detector.dart';
import '../insight_engine.dart';
import '../../types/insight_action.dart';
import '../../types/insight_card.dart';
import '../../types/insight_data.dart';

class SpendingVelocityDetector implements InsightDetector {
  const SpendingVelocityDetector();

  @override
  InsightCard? detect(InsightContext context) {
    final snapshot = context.snapshot;

    // Velocity is strictly evaluated for the active current month
    final isCurrentMonth = snapshot.selectedMonth.year == snapshot.now.year &&
        snapshot.selectedMonth.month == snapshot.now.month;
    if (!isCurrentMonth) return null;

    if (snapshot.daysElapsed < AnalyticsConstants.minDaysForVelocity) {
      return null;
    }
    if (snapshot.currentPositiveCount < AnalyticsConstants.minExpensesForVelocity) {
      return null;
    }
    if (snapshot.currentPositiveTotal <= 0 || snapshot.previousPositiveTotal <= 0) {
      return null;
    }

    // Daily linear positive pace projection
    final dailyPace = snapshot.currentPositiveTotal / snapshot.daysElapsed;
    final projectedTotal = dailyPace * snapshot.daysInMonth;
    final projectedChangePercent =
        ((projectedTotal - snapshot.previousPositiveTotal) /
                snapshot.previousPositiveTotal) *
            100;

    final baseWeight = 0.80 +
        (0.10 * (projectedChangePercent.abs() / 100.0).clamp(0.0, 1.0));

    final priority = InsightEngine.calculatePriority(
      taxonomy: InsightTaxonomy.behavioral,
      baseWeight: baseWeight,
      confidence: 0.85,
      actionability: 0.80,
    );

    final severity = projectedChangePercent > 10.0
        ? InsightSeverity.warning
        : (projectedChangePercent < -10.0
            ? InsightSeverity.positive
            : InsightSeverity.info);

    final isHigher = projectedChangePercent > 0;
    final title = 'Spending Pace';
    final description = isHigher
        ? 'At your current daily pace, positive spend is projected to be ${projectedChangePercent.abs().toStringAsFixed(0)}% higher than last month.'
        : 'At your current daily pace, positive spend is projected to be ${projectedChangePercent.abs().toStringAsFixed(0)}% lower than last month.';

    final data = VelocityData(
      amountSpent: snapshot.currentPositiveTotal,
      daysElapsed: snapshot.daysElapsed,
      daysInMonth: snapshot.daysInMonth,
      projectedTotal: projectedTotal,
      previousMonthTotal: snapshot.previousPositiveTotal,
      projectedChangePercent: projectedChangePercent,
    );

    return InsightCard(
      id: 'insight_spending_velocity',
      type: InsightType.spendingVelocity,
      taxonomy: InsightTaxonomy.behavioral,
      severity: severity,
      title: title,
      description: description,
      priority: priority,
      data: data,
      metrics: [
        InsightMetric(
          label: 'Projected spend',
          value: projectedTotal,
          previousValue: snapshot.previousPositiveTotal,
          unit: InsightMetricUnit.currency,
        ),
      ],
      action: const InsightAction.viewHistory(),
    );
  }
}
