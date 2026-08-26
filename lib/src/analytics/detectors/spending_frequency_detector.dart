import '../insight_detector.dart';
import '../insight_engine.dart';
import '../../types/insight_action.dart';
import '../../types/insight_card.dart';
import '../../types/insight_data.dart';

class SpendingFrequencyDetector implements InsightDetector {
  const SpendingFrequencyDetector();

  @override
  InsightCard? detect(InsightContext context) {
    final snapshot = context.snapshot;

    // Strict positive-transaction count gating
    if (snapshot.currentPositiveCount == 0 ||
        snapshot.previousPositiveCount == 0) {
      return null;
    }

    final curCount = snapshot.currentPositiveCount;
    final prevCount = snapshot.previousPositiveCount;
    final curAvg = snapshot.currentAvgTransaction;
    final prevAvg = snapshot.previousAvgTransaction;

    final countDeltaPercent =
        ((curCount - prevCount) / prevCount) * 100;
    final avgValueDeltaPercent =
        prevAvg > 0 ? ((curAvg - prevAvg) / prevAvg) * 100 : 0.0;

    final priority = InsightEngine.calculatePriority(
      taxonomy: InsightTaxonomy.behavioral,
      baseWeight: 0.65,
      confidence: 0.80,
      actionability: 0.65,
    );

    final String title;
    final String description;

    if (countDeltaPercent > 10.0 && avgValueDeltaPercent < -10.0) {
      title = 'Spending Frequency';
      description =
          'You are purchasing more frequently with smaller average amounts.';
    } else if (countDeltaPercent < -10.0 && avgValueDeltaPercent > 10.0) {
      title = 'Spending Frequency';
      description =
          'You are making fewer transactions with higher average purchase amounts.';
    } else if (countDeltaPercent > 10.0) {
      title = 'Spending Frequency';
      description =
          'Transaction count increased by ${countDeltaPercent.toStringAsFixed(0)}% compared to last month.';
    } else if (countDeltaPercent < -10.0) {
      title = 'Spending Frequency';
      description =
          'Transaction count decreased by ${countDeltaPercent.abs().toStringAsFixed(0)}% compared to last month.';
    } else {
      title = 'Spending Frequency';
      description =
          'Purchase frequency and average transaction sizes remained stable.';
    }

    final data = FrequencyData(
      currentCount: curCount,
      previousCount: prevCount,
      currentAvgValue: curAvg,
      previousAvgValue: prevAvg,
      countDeltaPercent: countDeltaPercent,
      avgValueDeltaPercent: avgValueDeltaPercent,
    );

    return InsightCard(
      id: 'insight_spending_frequency',
      type: InsightType.spendingFrequency,
      taxonomy: InsightTaxonomy.behavioral,
      severity: InsightSeverity.info,
      title: title,
      description: description,
      priority: priority,
      data: data,
      metrics: [
        InsightMetric(
          label: 'Transactions',
          value: curCount.toDouble(),
          previousValue: prevCount.toDouble(),
          unit: InsightMetricUnit.count,
        ),
        InsightMetric(
          label: 'Avg purchase',
          value: curAvg,
          previousValue: prevAvg,
          unit: InsightMetricUnit.currency,
        ),
      ],
      action: const InsightAction.viewHistory(),
    );
  }
}
