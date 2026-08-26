import '../types/category.dart';
import '../types/spending_summaries.dart';
import 'analytics_snapshot.dart';

/// Pure transformation builder that produces dedicated analytical summaries
/// from a [SpendingAnalyticsSnapshot].
class SummaryBuilder {
  SummaryBuilder._();

  /// Builds [SpendingSummaries] including Top Categories, Top Merchants, and Largest Expenses.
  static SpendingSummaries build({
    required SpendingAnalyticsSnapshot snapshot,
    required List<Category> categories,
    int topCategoriesLimit = 5,
    int topMerchantsLimit = 5,
    int largestExpensesLimit = 5,
  }) {
    final catMap = {for (final c in categories) c.id: c.name};
    final denominator = snapshot.currentTotal > 0
        ? snapshot.currentTotal
        : snapshot.currentPositiveTotal;

    // 1. Top Categories (Filtered for positive net spend, sorted by netAmount DESC with categoryName ASC tie-break)
    final catList = <CategorySummaryItem>[];
    for (final entry in snapshot.currentByCategory.entries) {
      if (entry.value <= 0) continue;
      final name = catMap[entry.key] ?? 'Uncategorized';
      final netAmt = entry.value;
      final pct = denominator > 0
          ? ((netAmt / denominator) * 100).clamp(0.0, 100.0)
          : 0.0;
      catList.add(CategorySummaryItem(
        categoryId: entry.key,
        categoryName: name,
        netAmount: netAmt,
        percentOfTotal: pct,
        positiveTransactionCount:
            snapshot.currentPositiveCountByCategory[entry.key] ?? 0,
        refundCount: snapshot.currentRefundCountByCategory[entry.key] ?? 0,
      ));
    }
    catList.sort((a, b) {
      final amtCmp = b.netAmount.compareTo(a.netAmount);
      if (amtCmp != 0) return amtCmp;
      return a.categoryName.compareTo(b.categoryName);
    });

    // 2. Top Merchants (Filtered for positive net spend, sorted by netAmount DESC with displayName ASC tie-break)
    final merchantList = <MerchantSummaryItem>[];
    for (final m in snapshot.currentMerchants.values) {
      if (m.netAmount <= 0) continue;
      final pct = denominator > 0
          ? ((m.netAmount / denominator) * 100).clamp(0.0, 100.0)
          : 0.0;
      merchantList.add(MerchantSummaryItem(
        merchantKey: m.merchantKey,
        displayName: m.displayName.isEmpty ? 'Unknown Merchant' : m.displayName,
        netAmount: m.netAmount,
        positiveTransactionCount: m.positiveTransactionCount,
        refundCount: m.refundCount,
        percentOfTotal: pct,
      ));
    }
    merchantList.sort((a, b) {
      final amtCmp = b.netAmount.compareTo(a.netAmount);
      if (amtCmp != 0) return amtCmp;
      return a.displayName.compareTo(b.displayName);
    });

    // 3. Largest Positive Transactions (Sorted by amount DESC with ID ASC tie-break)
    final posExpenses = <TransactionSummaryItem>[];
    for (final e in snapshot.currentExpenses) {
      if (e.amount > 0) {
        posExpenses.add(TransactionSummaryItem(
          id: e.id,
          title: e.title,
          amount: e.amount,
          date: e.date,
          categoryId: e.categoryId,
          categoryName: catMap[e.categoryId] ?? 'Uncategorized',
          vendor: e.vendor,
        ));
      }
    }
    posExpenses.sort((a, b) {
      final amtCmp = b.amount.compareTo(a.amount);
      if (amtCmp != 0) return amtCmp;
      return a.id.compareTo(b.id);
    });

    return SpendingSummaries(
      topCategories: catList.take(topCategoriesLimit).toList(),
      topMerchants: merchantList.take(topMerchantsLimit).toList(),
      largestExpenses: posExpenses.take(largestExpensesLimit).toList(),
    );
  }
}
