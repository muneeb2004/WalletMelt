import 'dart:math';

import '../analytics_constants.dart';
import '../analytics_helpers.dart';
import '../insight_detector.dart';
import '../insight_engine.dart';
import '../../types/insight_action.dart';
import '../../types/insight_card.dart';
import '../../types/insight_data.dart';

class CategoryChangesDetector implements InsightDetector {
  const CategoryChangesDetector();

  @override
  InsightCard? detect(InsightContext context) {
    final snapshot = context.snapshot;
    if (snapshot.currentExpenses.isEmpty || snapshot.previousExpenses.isEmpty) {
      return null;
    }

    final catNameMap = context.categoryNameMap;
    final allCategoryIds = {
      ...snapshot.currentByCategory.keys,
      ...snapshot.previousByCategory.keys,
    };

    // Determine dominant category from Why Spending Changed to avoid feed duplication
    String? dominantCatId;
    final totalDelta = snapshot.currentTotal - snapshot.previousTotal;
    final minAmount =
        AnalyticsConstants.minimumMeaningfulAmount(context.currency);
    if (totalDelta.abs() >= minAmount) {
      final dominant = findDominantDirectionalChange(
        currentByCategory: snapshot.currentByCategory,
        previousByCategory: snapshot.previousByCategory,
        isIncrease: totalDelta > 0,
      );
      dominantCatId = dominant?.categoryId;
    }

    final comparisonBase =
        max(snapshot.currentPositiveTotal, snapshot.previousPositiveTotal);
    final absoluteThreshold =
        max(comparisonBase * 0.02, minAmount);

    final significantChanges = <CategoryChange>[];
    double maxMagnitude = 0.0;

    for (final catId in allCategoryIds) {
      if (catId == dominantCatId) continue; // Deduplicate

      final cur = snapshot.currentByCategory[catId] ?? 0.0;
      final prev = snapshot.previousByCategory[catId] ?? 0.0;
      final absoluteChange = cur - prev;
      final magnitude = absoluteChange.abs();
      final percentChange = prev != 0
          ? (magnitude / prev.abs()) * 100
          : 100.0;

      final isSignificant = magnitude >= absoluteThreshold &&
          percentChange >= AnalyticsConstants.minCategoryChangePercent;

      if (isSignificant) {
        significantChanges.add(CategoryChange(
          categoryId: catId,
          categoryName: catNameMap[catId] ?? 'Uncategorized',
          currentAmount: cur,
          previousAmount: prev,
        ));
        if (magnitude > maxMagnitude) {
          maxMagnitude = magnitude;
        }
      }
    }

    if (significantChanges.isEmpty) return null;

    // Sort by magnitude descending
    significantChanges.sort((a, b) => b.magnitude.compareTo(a.magnitude));

    final baseWeight = 0.70 +
        (0.10 * (maxMagnitude / (comparisonBase > 0 ? comparisonBase : 1.0)).clamp(0.0, 1.0));

    final priority = InsightEngine.calculatePriority(
      taxonomy: InsightTaxonomy.behavioral,
      baseWeight: baseWeight,
      confidence: 0.80,
      actionability: 0.75,
    );

    final topChange = significantChanges.first;
    final isIncrease = topChange.absoluteChange > 0;
    final title = 'Category Spending Changes';
    final description = isIncrease
        ? '${topChange.categoryName} increased by ${topChange.percentChange?.toStringAsFixed(0) ?? '100'}%.'
        : '${topChange.categoryName} decreased by ${topChange.percentChange?.toStringAsFixed(0) ?? '100'}%.';

    final data = CategoryChangesData(changes: significantChanges);

    return InsightCard(
      id: 'insight_category_changes',
      type: InsightType.categoryChanges,
      taxonomy: InsightTaxonomy.behavioral,
      severity: InsightSeverity.info,
      title: title,
      description: description,
      priority: priority,
      data: data,
      metrics: [
        InsightMetric(
          label: topChange.categoryName,
          value: topChange.currentAmount,
          previousValue: topChange.previousAmount,
          unit: InsightMetricUnit.currency,
        ),
      ],
      action: InsightAction.viewCategory(categoryId: topChange.categoryId),
    );
  }
}
