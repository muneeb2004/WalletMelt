import 'insight_action.dart';
import 'insight_data.dart';

enum InsightTaxonomy {
  risk,
  behavioral,
  structure,
}

enum InsightType {
  whySpendingChanged,
  budgetRisk,
  spendingVelocity,
  categoryChanges,
  spendingFrequency,
  merchantCategoryInconsistency,
  essentialVsOther,
}

enum InsightSeverity {
  info,
  positive,
  warning,
  alert,
}

enum InsightMetricUnit {
  currency,
  percent,
  count,
  days,
}

/// Explicit ranking used as a deterministic tie-breaker when priorities are equal.
int severityRank(InsightSeverity severity) => switch (severity) {
  InsightSeverity.alert => 0,
  InsightSeverity.warning => 1,
  InsightSeverity.positive => 2,
  InsightSeverity.info => 3,
};

int taxonomyRank(InsightTaxonomy taxonomy) => switch (taxonomy) {
  InsightTaxonomy.risk => 0,
  InsightTaxonomy.behavioral => 1,
  InsightTaxonomy.structure => 2,
};

class InsightMetric {
  const InsightMetric({
    required this.label,
    required this.value,
    this.previousValue,
    this.unit = InsightMetricUnit.currency,
  });

  final String label;
  final double value;
  final double? previousValue;
  final InsightMetricUnit unit;

  double? get delta => previousValue != null ? value - previousValue! : null;

  double? get deltaPercent =>
      previousValue != null && previousValue! != 0
          ? ((value - previousValue!) / previousValue!) * 100
          : null;
}

class InsightCard {
  const InsightCard({
    required this.id,
    required this.type,
    required this.taxonomy,
    required this.severity,
    required this.title,
    required this.description,
    required this.priority,
    required this.data,
    this.metrics = const [],
    this.period,
    this.action,
  });

  final String id;
  final InsightType type;
  final InsightTaxonomy taxonomy;
  final InsightSeverity severity;
  final String title;
  final String description;
  final double priority;
  final InsightData data;
  final List<InsightMetric> metrics;
  final String? period;
  final InsightAction? action;
}
