import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_melt/src/analytics/spending_analytics.dart';
import 'package:wallet_melt/src/types/expense.dart';
import 'package:wallet_melt/src/utils/merchant_normalizer.dart';

void main() {
  group('SpendingAnalytics & SpendingAnalyticsSnapshot', () {
    final nowTime = DateTime(2026, 8, 24, 14, 30);
    final selectedMonth = DateTime(2026, 8);

    Expense createExp({
      required String id,
      required double amount,
      required String categoryId,
      required String date,
      String? vendor,
      String? storeId,
      String? deletedAt,
    }) {
      return Expense(
        id: id,
        amount: amount,
        currency: 'PKR',
        categoryId: categoryId,
        title: 'Expense $id',
        date: date,
        vendor: vendor,
        storeId: storeId,
        isRecurring: false,
        createdAt: '2026-08-01T10:00:00Z',
        updatedAt: '2026-08-01T10:00:00Z',
        deletedAt: deletedAt,
      );
    }

    test('Snapshot mathematical invariant: sum(currentByCategory.values) == currentTotal', () {
      final expenses = [
        createExp(id: '1', amount: 5000, categoryId: 'food', date: '2026-08-10'),
        createExp(id: '2', amount: 3500, categoryId: 'transport', date: '2026-08-12'),
        createExp(id: '3', amount: -500, categoryId: 'food', date: '2026-08-15'), // Refund
      ];

      final snapshot = SpendingAnalytics.buildSnapshot(
        expenses: expenses,
        selectedMonth: selectedMonth,
        now: nowTime,
        currency: 'PKR',
      );

      final categorySum = snapshot.currentByCategory.values.fold(0.0, (sum, val) => sum + val);
      expect(snapshot.currentTotal, 8000.0);
      expect(categorySum, snapshot.currentTotal);
      expect(snapshot.currentByCategory['food'], 4500.0);
      expect(snapshot.currentByCategory['transport'], 3500.0);
    });

    test('Snapshot positive average invariant: currentAvgTransaction == currentPositiveTotal / currentPositiveCount', () {
      final expenses = [
        createExp(id: '1', amount: 1000, categoryId: 'food', date: '2026-08-05'),
        createExp(id: '2', amount: 3000, categoryId: 'food', date: '2026-08-06'),
        createExp(id: '3', amount: -500, categoryId: 'food', date: '2026-08-07'), // Refund
      ];

      final snapshot = SpendingAnalytics.buildSnapshot(
        expenses: expenses,
        selectedMonth: selectedMonth,
        now: nowTime,
        currency: 'PKR',
      );

      expect(snapshot.currentPositiveTotal, 4000.0);
      expect(snapshot.currentPositiveCount, 2);
      expect(snapshot.currentRefundCount, 1);
      expect(snapshot.currentAvgTransaction, 2000.0);
      expect(snapshot.currentAvgTransaction, snapshot.currentPositiveTotal / snapshot.currentPositiveCount);
    });

    test('Snapshot excludes deleted transactions', () {
      final expenses = [
        createExp(id: '1', amount: 5000, categoryId: 'food', date: '2026-08-10'),
        createExp(id: '2', amount: 9999, categoryId: 'food', date: '2026-08-11', deletedAt: '2026-08-12T00:00:00Z'),
      ];

      final snapshot = SpendingAnalytics.buildSnapshot(
        expenses: expenses,
        selectedMonth: selectedMonth,
        now: nowTime,
        currency: 'PKR',
      );

      expect(snapshot.currentTotal, 5000.0);
      expect(snapshot.currentExpenses.length, 1);
      expect(snapshot.currentExpenses.first.id, '1');
    });

    test('Global future-dated transaction exclusion: expenses with date > now excluded from all totals', () {
      final expenses = [
        createExp(id: '1', amount: 4000, categoryId: 'food', date: '2026-08-20'),
        createExp(id: '2', amount: 2000, categoryId: 'food', date: '2026-08-24'), // Today (included)
        createExp(id: '3', amount: 10000, categoryId: 'food', date: '2026-08-28'), // Future (excluded)
      ];

      final snapshot = SpendingAnalytics.buildSnapshot(
        expenses: expenses,
        selectedMonth: selectedMonth,
        now: nowTime, // August 24, 2026
        currency: 'PKR',
      );

      expect(snapshot.currentTotal, 6000.0);
      expect(snapshot.currentPositiveTotal, 6000.0);
      expect(snapshot.currentExpenses.map((e) => e.id).toList(), ['1', '2']);
    });

    test('Past month sets daysElapsed = daysInMonth', () {
      final pastMonth = DateTime(2026, 7);
      final expenses = [
        createExp(id: '1', amount: 3000, categoryId: 'rent', date: '2026-07-10'),
      ];

      final snapshot = SpendingAnalytics.buildSnapshot(
        expenses: expenses,
        selectedMonth: pastMonth,
        now: nowTime, // August 2026
        currency: 'PKR',
      );

      expect(snapshot.isFutureMonth, isFalse);
      expect(snapshot.daysInMonth, 31);
      expect(snapshot.daysElapsed, 31);
      expect(snapshot.currentTotal, 3000.0);
    });

    test('Future month sets daysElapsed = 0 and isFutureMonth = true', () {
      final futureMonth = DateTime(2026, 9);
      final expenses = [
        createExp(id: '1', amount: 3000, categoryId: 'rent', date: '2026-09-10'),
      ];

      final snapshot = SpendingAnalytics.buildSnapshot(
        expenses: expenses,
        selectedMonth: futureMonth,
        now: nowTime, // August 2026
        currency: 'PKR',
      );

      expect(snapshot.isFutureMonth, isTrue);
      expect(snapshot.daysInMonth, 30);
      expect(snapshot.daysElapsed, 0);
      expect(snapshot.currentTotal, 0.0); // Future expenses excluded globally
    });

    test('Leap year February daysInMonth equals 29 (2028)', () {
      final feb2028 = DateTime(2028, 2);
      final snapshot = SpendingAnalytics.buildSnapshot(
        expenses: const [],
        selectedMonth: feb2028,
        now: DateTime(2028, 2, 15),
        currency: 'PKR',
      );

      expect(snapshot.daysInMonth, 29);
      expect(snapshot.daysElapsed, 15);
    });

    test('Non-leap year February daysInMonth equals 28 (2027)', () {
      final feb2027 = DateTime(2027, 2);
      final snapshot = SpendingAnalytics.buildSnapshot(
        expenses: const [],
        selectedMonth: feb2027,
        now: DateTime(2027, 2, 10),
        currency: 'PKR',
      );

      expect(snapshot.daysInMonth, 28);
      expect(snapshot.daysElapsed, 10);
    });

    test('January previous month correctly maps to December of prior year', () {
      final jan2026 = DateTime(2026, 1);
      final expenses = [
        createExp(id: '1', amount: 5000, categoryId: 'food', date: '2026-01-10'),
        createExp(id: '2', amount: 4000, categoryId: 'food', date: '2025-12-15'), // Previous month
      ];

      final snapshot = SpendingAnalytics.buildSnapshot(
        expenses: expenses,
        selectedMonth: jan2026,
        now: DateTime(2026, 1, 20),
        currency: 'PKR',
      );

      expect(snapshot.currentTotal, 5000.0);
      expect(snapshot.previousTotal, 4000.0);
      expect(snapshot.previousExpenses.length, 1);
      expect(snapshot.previousExpenses.first.id, '2');
    });

    test('Canonical merchant key groups storeId and normalized vendor with correct prefixes', () {
      final expWithStore = createExp(
        id: '1',
        amount: 1000,
        categoryId: 'food',
        date: '2026-08-01',
        vendor: 'Subway Clifton',
        storeId: 'store-123',
      );
      final expWithVendor = createExp(
        id: '2',
        amount: 2000,
        categoryId: 'food',
        date: '2026-08-02',
        vendor: '  Subway Clifton  ',
      );

      expect(merchantKeyForExpense(expWithStore), 'store:store-123');
      expect(merchantKeyForExpense(expWithVendor), 'vendor:subway clifton');
    });

    test('Blank and null vendors return null merchant key and are excluded from merchantMap', () {
      final expenses = [
        createExp(id: '1', amount: 1000, categoryId: 'food', date: '2026-08-01', vendor: null),
        createExp(id: '2', amount: 2000, categoryId: 'food', date: '2026-08-02', vendor: '   '),
      ];

      final snapshot = SpendingAnalytics.buildSnapshot(
        expenses: expenses,
        selectedMonth: selectedMonth,
        now: nowTime,
        currency: 'PKR',
      );

      expect(snapshot.currentMerchants.isEmpty, isTrue);
    });

    test('Refunds reduce net category totals, increment refundCount, and do not increment positiveCount', () {
      final expenses = [
        createExp(id: '1', amount: 3000, categoryId: 'electronics', date: '2026-08-05', vendor: 'Daraz'),
        createExp(id: '2', amount: -1000, categoryId: 'electronics', date: '2026-08-06', vendor: 'Daraz'),
      ];

      final snapshot = SpendingAnalytics.buildSnapshot(
        expenses: expenses,
        selectedMonth: selectedMonth,
        now: nowTime,
        currency: 'PKR',
      );

      expect(snapshot.currentTotal, 2000.0);
      expect(snapshot.currentPositiveTotal, 3000.0);
      expect(snapshot.currentPositiveCount, 1);
      expect(snapshot.currentRefundCount, 1);
      expect(snapshot.currentPositiveCountByCategory['electronics'], 1);
      expect(snapshot.currentRefundCountByCategory['electronics'], 1);

      final daraz = snapshot.currentMerchants['vendor:daraz']!;
      expect(daraz.netAmount, 2000.0);
      expect(daraz.positiveAmount, 3000.0);
      expect(daraz.positiveTransactionCount, 1);
      expect(daraz.refundCount, 1);
    });

    test('Merchant display name selects most frequent positive-purchase vendor string with alphabetical tie-breaker', () {
      final expenses = [
        createExp(id: '1', amount: 100, categoryId: 'food', date: '2026-08-01', vendor: 'Subway Clifton'),
        createExp(id: '2', amount: 100, categoryId: 'food', date: '2026-08-02', vendor: 'Subway Clifton'),
        createExp(id: '3', amount: 100, categoryId: 'food', date: '2026-08-03', vendor: 'subway clifton'),
        createExp(id: '4', amount: -50, categoryId: 'food', date: '2026-08-04', vendor: 'SUBWAY REFUND'), // Refund ignored for positive freq
      ];

      final snapshot = SpendingAnalytics.buildSnapshot(
        expenses: expenses,
        selectedMonth: selectedMonth,
        now: nowTime,
        currency: 'PKR',
      );

      final subway = snapshot.currentMerchants['vendor:subway clifton']!;
      expect(subway.displayName, 'Subway Clifton');
    });
  });
}
