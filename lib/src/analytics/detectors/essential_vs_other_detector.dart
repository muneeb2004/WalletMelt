import '../insight_detector.dart';
import '../insight_engine.dart';
import '../../types/insight_action.dart';
import '../../types/insight_card.dart';
import '../../types/insight_data.dart';
import '../../types/subscription.dart';

class EssentialVsOtherDetector implements InsightDetector {
  const EssentialVsOtherDetector();

  @override
  InsightCard? detect(InsightContext context) {
    final snapshot = context.snapshot;
    if (snapshot.currentExpenses.isEmpty) return null;

    // Collect active essential categories via set union
    final essentialCatIds = <String>{
      for (final t in context.essentialTemplates)
        if (t.isActive && !t.isDeleted) t.categoryId,
      for (final s in context.subscriptions)
        if (s.status == SubscriptionStatus.active && !s.isDeleted) s.categoryId,
    };

    if (essentialCatIds.isEmpty) return null;

    // Calculate net essential spend from current active expenses
    final essentialTotal = snapshot.currentExpenses
        .where((e) => essentialCatIds.contains(e.categoryId))
        .fold(0.0, (sum, e) => sum + e.amount);

    // Guaranteed reconciliation invariant: essentialTotal + otherTotal == currentTotal
    final otherTotal = snapshot.currentTotal - essentialTotal;

    final essentialPercent = snapshot.currentTotal > 0
        ? ((essentialTotal / snapshot.currentTotal) * 100).clamp(0.0, 100.0)
        : 0.0;

    final priority = InsightEngine.calculatePriority(
      taxonomy: InsightTaxonomy.structure,
      baseWeight: 0.55,
      confidence: 1.00,
      actionability: 0.50,
    );

    final title = 'Essential vs Other Spending';
    final description =
        'Essential expenses accounted for ${essentialPercent.toStringAsFixed(0)}% of net spending this month.';

    final data = EssentialSplitData(
      essentialTotal: essentialTotal,
      otherTotal: otherTotal,
      essentialPercent: essentialPercent,
      basis: EssentialClassificationBasis
          .configuredEssentialCategoriesAndSubscriptions,
    );

    return InsightCard(
      id: 'insight_essential_vs_other',
      type: InsightType.essentialVsOther,
      taxonomy: InsightTaxonomy.structure,
      severity: InsightSeverity.info,
      title: title,
      description: description,
      priority: priority,
      data: data,
      metrics: [
        InsightMetric(
          label: 'Essential share',
          value: essentialPercent,
          unit: InsightMetricUnit.percent,
        ),
        InsightMetric(
          label: 'Essential spend',
          value: essentialTotal,
          unit: InsightMetricUnit.currency,
        ),
      ],
      action: const InsightAction.viewHistory(),
    );
  }
}
