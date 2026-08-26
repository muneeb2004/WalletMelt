/// Presentation view models for dedicated Spending Summary sections.
class CategorySummaryItem {
  const CategorySummaryItem({
    required this.categoryId,
    required this.categoryName,
    required this.netAmount,
    required this.percentOfTotal,
    required this.positiveTransactionCount,
    required this.refundCount,
  });

  final String categoryId;
  final String categoryName;
  final double netAmount;
  final double percentOfTotal;
  final int positiveTransactionCount;
  final int refundCount;
}

class MerchantSummaryItem {
  const MerchantSummaryItem({
    required this.merchantKey,
    required this.displayName,
    required this.netAmount,
    required this.positiveTransactionCount,
    required this.refundCount,
    required this.percentOfTotal,
  });

  final String merchantKey;
  final String displayName;
  final double netAmount;
  final int positiveTransactionCount;
  final int refundCount;
  final double percentOfTotal;
}

class TransactionSummaryItem {
  const TransactionSummaryItem({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.categoryId,
    required this.categoryName,
    this.vendor,
  });

  final String id;
  final String title;
  final double amount;
  final String date;
  final String categoryId;
  final String categoryName;
  final String? vendor;
}

class SpendingSummaries {
  const SpendingSummaries({
    required this.topCategories,
    required this.topMerchants,
    required this.largestExpenses,
  });

  final List<CategorySummaryItem> topCategories;
  final List<MerchantSummaryItem> topMerchants;
  final List<TransactionSummaryItem> largestExpenses;
}
