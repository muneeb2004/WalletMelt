import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_melt/src/utils/budget_period.dart';

void main() {
  group('calendar period (start day 1) matches the old month rules', () {
    const p = BudgetPeriod.calendar;
    final jun = DateTime(2026, 6);

    test('range, length and membership', () {
      expect(p.start(jun), DateTime(2026, 6, 1));
      expect(p.endExclusive(jun), DateTime(2026, 7, 1));
      expect(p.lengthInDays(jun), 30);
      expect(p.lengthInDays(DateTime(2026, 2)), 28);
      expect(p.lengthInDays(DateTime(2028, 2)), 29);
      expect(p.contains(jun, DateTime(2026, 6, 30)), isTrue);
      expect(p.contains(jun, DateTime(2026, 7, 1)), isFalse);
      expect(p.periodOf(DateTime(2026, 6, 30, 23, 59)), jun);
    });

    test('elapsed and remaining count today', () {
      final now = DateTime(2026, 6, 13, 15);
      expect(p.daysElapsed(jun, now), 13);
      expect(p.daysRemaining(jun, now), 18); // 30 - 13 + 1
      expect(p.daysRemaining(jun, DateTime(2026, 6, 30)), 1);
      expect(p.daysRemaining(DateTime(2026, 5), now), 0);
      expect(p.daysRemaining(DateTime(2026, 7), now), 31);
      expect(p.daysElapsed(DateTime(2026, 7), now), 0);
      expect(p.daysElapsed(DateTime(2026, 5), now), 31);
      expect(p.isCurrent(jun, now), isTrue);
      expect(p.isFuture(DateTime(2026, 7), now), isTrue);
    });

    test('label keeps the month name', () {
      expect(p.label(jun), 'June 2026');
    });
  });

  group('start day 25', () {
    const p = BudgetPeriod(25);
    final jun = DateTime(2026, 6);

    test('period 2026-06 runs 25 Jun to 24 Jul inclusive', () {
      expect(p.start(jun), DateTime(2026, 6, 25));
      expect(p.lastDay(jun), DateTime(2026, 7, 24));
      expect(p.lengthInDays(jun), 30);
      expect(p.contains(jun, DateTime(2026, 6, 24)), isFalse);
      expect(p.contains(jun, DateTime(2026, 6, 25)), isTrue);
      expect(p.contains(jun, DateTime(2026, 7, 24, 23, 59)), isTrue);
      expect(p.contains(jun, DateTime(2026, 7, 25)), isFalse);
    });

    test('periodOf assigns dates around the boundary', () {
      expect(p.periodOf(DateTime(2026, 6, 24)), DateTime(2026, 5));
      expect(p.periodOf(DateTime(2026, 6, 25)), jun);
      expect(p.periodOf(DateTime(2026, 7, 3)), jun);
      expect(p.periodOf(DateTime(2027, 1, 10)), DateTime(2026, 12));
      expect(p.periodOf(DateTime(2026, 1, 1)), DateTime(2025, 12));
    });

    test('on 3 Jul the current period is still June', () {
      final now = DateTime(2026, 7, 3);
      expect(p.isCurrent(jun, now), isTrue);
      expect(p.isCurrent(DateTime(2026, 7), now), isFalse);
      expect(p.daysElapsed(jun, now), 9); // 25 Jun .. 3 Jul
      expect(p.daysRemaining(jun, now), 22); // 3 Jul .. 24 Jul
      expect(p.daysElapsed(jun, now) + p.daysRemaining(jun, now) - 1,
          p.lengthInDays(jun));
    });

    test('February-spanning period and label', () {
      final jan = DateTime(2026, 1);
      expect(p.lengthInDays(jan), 31); // 25 Jan .. 24 Feb
      expect(p.lengthInDays(DateTime(2026, 2)), 28); // 25 Feb .. 24 Mar
      expect(p.label(jun), '25 Jun - 24 Jul 2026');
    });

    test('daily allowance denominator is never zero in a current period', () {
      for (var d = 25; d <= 30; d++) {
        expect(p.daysRemaining(jun, DateTime(2026, 6, d)), greaterThan(0));
      }
      expect(p.daysRemaining(jun, DateTime(2026, 7, 24)), 1);
      expect(p.daysRemaining(jun, DateTime(2026, 7, 25)), 0);
    });
  });

  test('fromStartDay clamps unsupported values', () {
    expect(BudgetPeriod.fromStartDay(null).startDay, 1);
    expect(BudgetPeriod.fromStartDay(0).startDay, 1);
    expect(BudgetPeriod.fromStartDay(31).startDay, 28);
    expect(BudgetPeriod.fromStartDay(15).startDay, 15);
  });

  test('DST transitions do not change period length', () {
    const p = BudgetPeriod(25);
    // Includes spring and autumn clock changes in many zones.
    expect(p.lengthInDays(DateTime(2026, 3)), 31);
    expect(p.lengthInDays(DateTime(2026, 10)), 31);
    expect(p.lengthInDays(DateTime(2026, 11)), 30);
  });
}
