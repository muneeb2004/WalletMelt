import '../types/expense.dart';
import '../utils/date_utils.dart';
import '../utils/merchant_normalizer.dart';
import 'analytics_snapshot.dart';

/// Single-pass mathematical aggregation engine for WalletMelt.
///
/// Operates as a pure-Dart, in-memory aggregation pipeline over loaded expense lists.
class SpendingAnalytics {
  SpendingAnalytics._();

  /// Executes an O(N) single pass over [expenses] to construct an immutable [SpendingAnalyticsSnapshot].
  static SpendingAnalyticsSnapshot buildSnapshot({
    required List<Expense> expenses,
    required DateTime selectedMonth,
    required DateTime now,
    required String currency,
  }) {
    final prevMonth = DateTime(selectedMonth.year, selectedMonth.month - 1);
    final daysInMonth = DateTime(selectedMonth.year, selectedMonth.month + 1, 0).day;

    final bool isFuture = selectedMonth.year > now.year ||
        (selectedMonth.year == now.year && selectedMonth.month > now.month);

    final int daysElapsed;
    if (isFuture) {
      daysElapsed = 0;
    } else if (selectedMonth.year == now.year && selectedMonth.month == now.month) {
      daysElapsed = now.day.clamp(1, daysInMonth);
    } else {
      daysElapsed = daysInMonth;
    }

    double curTotal = 0.0;
    double prevTotal = 0.0;
    double curPosTotal = 0.0;
    double prevPosTotal = 0.0;

    int curPosCount = 0;
    int prevPosCount = 0;
    int curRefundCount = 0;
    int prevRefundCount = 0;

    final curByCategory = <String, double>{};
    final prevByCategory = <String, double>{};
    final curPosCountByCat = <String, int>{};
    final curRefundCountByCat = <String, int>{};
    final merchantMap = <String, _MutableMerchantAggregate>{};

    final curExpenses = <Expense>[];
    final prevExpenses = <Expense>[];

    final endOfNowDay = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);

    for (final exp in expenses) {
      if (exp.deletedAt != null) continue;

      DateTime expDate;
      try {
        expDate = parseIsoDate(exp.date);
      } catch (_) {
        continue;
      }

      // GLOBAL FUTURE-DATE EXCLUSION: Skip transactions dated after current calendar day
      if (expDate.isAfter(endOfNowDay)) continue;

      final inCurrent = isSameMonth(expDate, selectedMonth);
      final inPrevious = isSameMonth(expDate, prevMonth);

      if (inCurrent) {
        curExpenses.add(exp);
        curTotal += exp.amount;
        curByCategory[exp.categoryId] = (curByCategory[exp.categoryId] ?? 0.0) + exp.amount;

        if (exp.amount > 0) {
          curPosTotal += exp.amount;
          curPosCount++;
          curPosCountByCat[exp.categoryId] = (curPosCountByCat[exp.categoryId] ?? 0) + 1;
        } else if (exp.amount < 0) {
          curRefundCount++;
          curRefundCountByCat[exp.categoryId] = (curRefundCountByCat[exp.categoryId] ?? 0) + 1;
        }

        final rawVendor = exp.vendor?.trim();
        final hasVendor = rawVendor != null && rawVendor.isNotEmpty;
        final mKey = merchantKeyForExpense(exp, rawVendor);
        if (mKey != null) {
          final agg = merchantMap.putIfAbsent(
            mKey,
            () => _MutableMerchantAggregate(merchantKey: mKey),
          );
          agg.netAmount += exp.amount;
          if (exp.amount > 0) {
            agg.positiveAmount += exp.amount;
            agg.positiveTransactionCount++;
            agg.categoryIds.add(exp.categoryId);
            if (hasVendor) {
              agg.positiveVendorFrequency[rawVendor] =
                  (agg.positiveVendorFrequency[rawVendor] ?? 0) + 1;
            }
          } else if (exp.amount < 0) {
            agg.refundCount++;
          }
          if (hasVendor) {
            agg.allVendorFrequency[rawVendor] =
                (agg.allVendorFrequency[rawVendor] ?? 0) + 1;
          }
        }
      } else if (inPrevious) {
        prevExpenses.add(exp);
        prevTotal += exp.amount;
        prevByCategory[exp.categoryId] = (prevByCategory[exp.categoryId] ?? 0.0) + exp.amount;
        if (exp.amount > 0) {
          prevPosTotal += exp.amount;
          prevPosCount++;
        } else if (exp.amount < 0) {
          prevRefundCount++;
        }
      }
    }

    return SpendingAnalyticsSnapshot(
      selectedMonth: selectedMonth,
      now: now,
      snapshotGeneratedAt: DateTime.now(),
      currency: currency,
      isFutureMonth: isFuture,
      currentTotal: curTotal,
      previousTotal: prevTotal,
      currentPositiveTotal: curPosTotal,
      previousPositiveTotal: prevPosTotal,
      daysElapsed: daysElapsed,
      daysInMonth: daysInMonth,
      currentByCategory: Map.unmodifiable(curByCategory),
      previousByCategory: Map.unmodifiable(prevByCategory),
      currentPositiveCountByCategory: Map.unmodifiable(curPosCountByCat),
      currentRefundCountByCategory: Map.unmodifiable(curRefundCountByCat),
      currentMerchants: Map.unmodifiable(
        merchantMap.map((k, v) => MapEntry(k, v.toImmutable())),
      ),
      currentPositiveCount: curPosCount,
      previousPositiveCount: prevPosCount,
      currentRefundCount: curRefundCount,
      previousRefundCount: prevRefundCount,
      currentExpenses: List.unmodifiable(curExpenses),
      previousExpenses: List.unmodifiable(prevExpenses),
    );
  }
}

class _MutableMerchantAggregate {
  _MutableMerchantAggregate({required this.merchantKey});

  final String merchantKey;
  double netAmount = 0.0;
  double positiveAmount = 0.0;
  int positiveTransactionCount = 0;
  int refundCount = 0;
  final Set<String> categoryIds = {};
  final Map<String, int> positiveVendorFrequency = {};
  final Map<String, int> allVendorFrequency = {};

  MerchantAggregate toImmutable() {
    String resolvedName = '';
    if (positiveVendorFrequency.isNotEmpty) {
      resolvedName = _resolveMostFrequent(positiveVendorFrequency);
    } else if (allVendorFrequency.isNotEmpty) {
      resolvedName = _resolveMostFrequent(allVendorFrequency);
    }

    return MerchantAggregate(
      merchantKey: merchantKey,
      displayName: resolvedName,
      netAmount: netAmount,
      positiveAmount: positiveAmount,
      positiveTransactionCount: positiveTransactionCount,
      refundCount: refundCount,
      categoryIds: Set.unmodifiable(categoryIds),
    );
  }

  static String _resolveMostFrequent(Map<String, int> frequencyMap) {
    String? bestKey;
    int bestFreq = -1;
    for (final entry in frequencyMap.entries) {
      if (entry.value > bestFreq) {
        bestFreq = entry.value;
        bestKey = entry.key;
      } else if (entry.value == bestFreq) {
        if (bestKey == null || entry.key.compareTo(bestKey) < 0) {
          bestKey = entry.key;
        }
      }
    }
    return bestKey ?? '';
  }
}
