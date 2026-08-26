import '../types/budget.dart';
import '../types/category.dart';
import '../types/essential_expense.dart';
import '../types/insight_card.dart';
import '../types/subscription.dart';
import 'analytics_constants.dart';
import 'analytics_snapshot.dart';
import 'detectors/budget_risk_detector.dart';
import 'detectors/category_changes_detector.dart';
import 'detectors/essential_vs_other_detector.dart';
import 'detectors/merchant_inconsistency_detector.dart';
import 'detectors/spending_frequency_detector.dart';
import 'detectors/spending_velocity_detector.dart';
import 'detectors/why_spending_changed_detector.dart';
import 'insight_detector.dart';

/// Orchestrator for evaluating insight detectors and deterministically ranking results.
class InsightEngine {
  InsightEngine._();

  static const List<InsightDetector> _detectors = [
    BudgetRiskDetector(),
    WhySpendingChangedDetector(),
    SpendingVelocityDetector(),
    CategoryChangesDetector(),
    SpendingFrequencyDetector(),
    MerchantCategoryInconsistencyDetector(),
    EssentialVsOtherDetector(),
  ];

  /// Calculates bounded priority score using proportional taxonomy multipliers.
  static double calculatePriority({
    required InsightTaxonomy taxonomy,
    required double baseWeight,
    required double confidence,
    required double actionability,
  }) {
    final taxonomyMultiplier = switch (taxonomy) {
      InsightTaxonomy.risk => AnalyticsConstants.riskTaxonomyMultiplier,
      InsightTaxonomy.behavioral => AnalyticsConstants.behavioralTaxonomyMultiplier,
      InsightTaxonomy.structure => AnalyticsConstants.structureTaxonomyMultiplier,
    };
    return (baseWeight * confidence * actionability * taxonomyMultiplier)
        .clamp(0.0, 2.0);
  }

  /// Generates and returns a deterministically ranked list of actionable [InsightCard]s.
  static List<InsightCard> generate({
    required SpendingAnalyticsSnapshot snapshot,
    required List<Category> categories,
    required List<CategoryBudget> budgets,
    required List<EssentialExpenseTemplate> essentialTemplates,
    required List<Subscription> subscriptions,
    required double? monthlyBudgetAmount,
    int maxInsights = AnalyticsConstants.maxRankedInsights,
  }) {
    // Strict future-month suppression: return empty feed for future months
    if (snapshot.isFutureMonth) return const [];

    final context = InsightContext(
      snapshot: snapshot,
      categories: categories,
      budgets: budgets,
      essentialTemplates: essentialTemplates,
      subscriptions: subscriptions,
      monthlyBudgetAmount: monthlyBudgetAmount,
    );

    final cards = <InsightCard>[];
    for (final detector in _detectors) {
      final card = detector.detect(context);
      if (card != null) {
        cards.add(card);
      }
    }

    // 5-tier deterministic tie-breaking:
    cards.sort((a, b) {
      // Tier 1: Priority DESC
      final pCmp = b.priority.compareTo(a.priority);
      if (pCmp != 0) return pCmp;

      // Tier 2: Severity rank ASC (alert=0 < warning=1 < positive=2 < info=3)
      final sCmp =
          severityRank(a.severity).compareTo(severityRank(b.severity));
      if (sCmp != 0) return sCmp;

      // Tier 3: Taxonomy rank ASC (risk=0 < behavioral=1 < structure=2)
      final tCmp =
          taxonomyRank(a.taxonomy).compareTo(taxonomyRank(b.taxonomy));
      if (tCmp != 0) return tCmp;

      // Tier 4: Stable enum index ASC
      final eCmp = a.type.index.compareTo(b.type.index);
      if (eCmp != 0) return eCmp;

      // Tier 5: Deterministic ID ASC
      return a.id.compareTo(b.id);
    });

    return cards.take(maxInsights).toList();
  }
}
