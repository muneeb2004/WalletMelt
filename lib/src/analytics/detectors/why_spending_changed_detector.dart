import '../analytics_constants.dart';
import '../analytics_helpers.dart';
import '../insight_detector.dart';
import '../insight_engine.dart';
import '../../types/insight_action.dart';
import '../../types/insight_card.dart';
import '../../types/insight_data.dart';

class WhySpendingChangedDetector implements InsightDetector {
  const WhySpendingChangedDetector();

  @override
  InsightCard? detect(InsightContext context) {
    final snapshot = context.snapshot;
    if (snapshot.currentExpenses.isEmpty || snapshot.previousExpenses.isEmpty) {
      return null;
    }

    final totalDelta = snapshot.currentTotal - snapshot.previousTotal;
    final minAmount = AnalyticsConstants.minimumMeaningfulAmount(context.currency);
    if (totalDelta.abs() < minAmount) {
      return null;
    }

    final isIncrease = totalDelta > 0;
    final dominant = findDominantDirectionalChange(
      currentByCategory: snapshot.currentByCategory,
      previousByCategory: snapshot.previousByCategory,
      isIncrease: isIncrease,
    );

    if (dominant == null) return null;

    final topCatId = dominant.categoryId;
    final topCatDelta = dominant.delta;
    final directionalContributionPercent = dominant.contributionPercent;

    final topCatName = context.categoryNameMap[topCatId] ?? 'Uncategorized';
    final deltaPct = snapshot.previousTotal > 0
        ? (totalDelta.abs() / snapshot.previousTotal)
        : 1.0;
    final baseWeight = (0.85 + (0.10 * deltaPct.clamp(0.0, 1.0)));

    final priority = InsightEngine.calculatePriority(
      taxonomy: InsightTaxonomy.behavioral,
      baseWeight: baseWeight,
      confidence: 0.90,
      actionability: 0.85,
    );

    final data = WhyChangedData(
      totalDelta: totalDelta,
      isIncrease: isIncrease,
      topContributorCategoryId: topCatId,
      topContributorName: topCatName,
      topContributorDelta: topCatDelta,
      directionalContributionPercent: directionalContributionPercent,
      currentTotal: snapshot.currentTotal,
      previousTotal: snapshot.previousTotal,
    );

    final title = isIncrease ? 'Spending Increased' : 'Spending Decreased';
    final description = isIncrease
        ? '$topCatName drove ${directionalContributionPercent.toStringAsFixed(0)}% of the gross increase.'
        : '$topCatName drove ${directionalContributionPercent.toStringAsFixed(0)}% of the spending reduction.';

    return InsightCard(
      id: 'insight_why_spending_changed',
      type: InsightType.whySpendingChanged,
      taxonomy: InsightTaxonomy.behavioral,
      severity: isIncrease ? InsightSeverity.warning : InsightSeverity.positive,
      title: title,
      description: description,
      priority: priority,
      data: data,
      metrics: [
        InsightMetric(
          label: 'Total spend',
          value: snapshot.currentTotal,
          previousValue: snapshot.previousTotal,
          unit: InsightMetricUnit.currency,
        ),
      ],
      action: InsightAction.viewCategory(categoryId: topCatId),
    );
  }
}
