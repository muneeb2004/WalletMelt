import '../types/budget.dart';
import '../types/category.dart';
import '../types/essential_expense.dart';
import '../types/insight_card.dart';
import '../types/subscription.dart';
import 'analytics_snapshot.dart';

/// Context provided to each insight detector containing current domain state
/// and the precomputed analytical snapshot.
class InsightContext {
  InsightContext({
    required this.snapshot,
    required this.categories,
    required this.budgets,
    required this.essentialTemplates,
    required this.subscriptions,
    required this.monthlyBudgetAmount,
  }) : categoryNameMap = {for (final c in categories) c.id: c.name};

  final SpendingAnalyticsSnapshot snapshot;
  final List<Category> categories;
  final List<CategoryBudget> budgets;
  final List<EssentialExpenseTemplate> essentialTemplates;
  final List<Subscription> subscriptions;
  final double? monthlyBudgetAmount;
  final Map<String, String> categoryNameMap;

  String get currency => snapshot.currency;
}

/// Abstract contract for an isolated insight detector.
abstract interface class InsightDetector {
  /// Analyzes [context] and returns an [InsightCard], or `null` if thresholds
  /// or data sufficiency criteria are not met.
  InsightCard? detect(InsightContext context);
}
