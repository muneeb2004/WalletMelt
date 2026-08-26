import '../analytics_constants.dart';
import '../insight_detector.dart';
import '../insight_engine.dart';
import '../../types/insight_action.dart';
import '../../types/insight_card.dart';
import '../../types/insight_data.dart';

class MerchantCategoryInconsistencyDetector implements InsightDetector {
  const MerchantCategoryInconsistencyDetector();

  @override
  InsightCard? detect(InsightContext context) {
    final snapshot = context.snapshot;
    final catNameMap = context.categoryNameMap;

    final inconsistencies = <MerchantInconsistency>[];

    // Evaluated strictly within the selected month
    for (final merchant in snapshot.currentMerchants.values) {
      if (merchant.categoryIds.length >= 2 &&
          merchant.positiveTransactionCount >=
              AnalyticsConstants.minPositiveTransactionsForInconsistency) {
        final categoryNames = merchant.categoryIds
            .map((id) => catNameMap[id] ?? 'Uncategorized')
            .toList()
          ..sort();

        inconsistencies.add(MerchantInconsistency(
          merchantKey: merchant.merchantKey,
          displayName: merchant.displayName.isEmpty
              ? 'Unknown Merchant'
              : merchant.displayName,
          categoryNames: categoryNames,
          positiveTransactionCount: merchant.positiveTransactionCount,
        ));
      }
    }

    if (inconsistencies.isEmpty) return null;

    // Sort by positiveTransactionCount descending
    inconsistencies.sort((a, b) =>
        b.positiveTransactionCount.compareTo(a.positiveTransactionCount));

    final top = inconsistencies.first;
    final priority = InsightEngine.calculatePriority(
      taxonomy: InsightTaxonomy.risk,
      baseWeight: 0.60,
      confidence: 0.85,
      actionability: 0.70,
    );

    final title = 'Merchant Category Inconsistency';
    final description =
        '${top.displayName} was categorized across ${top.categoryNames.length} categories (${top.categoryNames.join(', ')}).';

    final data = MerchantInconsistencyData(inconsistencies: inconsistencies);

    return InsightCard(
      id: 'insight_merchant_inconsistency',
      type: InsightType.merchantCategoryInconsistency,
      taxonomy: InsightTaxonomy.risk,
      severity: InsightSeverity.info,
      title: title,
      description: description,
      priority: priority,
      data: data,
      metrics: [
        InsightMetric(
          label: 'Categories',
          value: top.categoryNames.length.toDouble(),
          unit: InsightMetricUnit.count,
        ),
      ],
      action: const InsightAction.viewHistory(),
    );
  }
}
