import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_melt/src/types/expense.dart';
import 'package:wallet_melt/src/utils/insights.dart';

Expense _e(String id, String date, String createdAt) => Expense(
      id: id,
      title: id,
      amount: 10,
      currency: 'PKR',
      categoryId: 'c',
      date: date,
      isRecurring: false,
      createdAt: createdAt,
      updatedAt: createdAt,
    );

void main() {
  test('newest first: date, then createdAt, then id', () {
    final list = [
      _e('a', '2026-11-01', '2026-11-01T08:00:00'),
      _e('b', '2026-11-02', '2026-11-02T08:00:00'),
      _e('c', '2026-11-02', '2026-11-02T09:00:00'),
      _e('d', '2026-11-02', '2026-11-02T09:00:00'),
    ]..sort(compareExpensesNewestFirst);
    expect(list.map((e) => e.id), ['c', 'd', 'b', 'a']);
  });

  test('order is independent of input order', () {
    final base = [
      _e('a', '2026-11-02', '2026-11-02T08:00:00'),
      _e('b', '2026-11-02', '2026-11-02T09:00:00'),
      _e('c', '2026-11-01', '2026-11-01T09:00:00'),
    ];
    final x = [...base]..sort(compareExpensesNewestFirst);
    final y = base.reversed.toList()..sort(compareExpensesNewestFirst);
    expect(x.map((e) => e.id), y.map((e) => e.id));
  });
}
