import '../types/committee.dart';
import '../utils/recurrence.dart';

/// One thing the user is expected to confirm.
class CommitteeDueItem {
  const CommitteeDueItem({
    required this.committeeId,
    required this.kind,
    required this.monthIndex,
    required this.dueDate,
    required this.amountMinorUnits,
  });

  final String committeeId;
  final CommitteeEventKind kind;
  final int monthIndex;
  final DateTime dueDate;

  /// Expected amount (the installment or the expected pot).
  final int amountMinorUnits;
}

/// Pure committee maths for ADR-0016. No I/O, deterministic.
class CommitteePlanner {
  const CommitteePlanner._();

  /// Due date of installment [monthIndex] (1-based), month-end safe.
  static DateTime dueDate(Committee committee, int monthIndex) {
    final start = DateTime.parse(committee.startDate);
    final first = DateTime(start.year, start.month, start.day);
    return addMonthsClamped(first, monthIndex - 1, committee.startDay);
  }

  /// Everything due on or before [now] that is not recorded yet, oldest first:
  /// unpaid installments, plus the payout once its month has arrived. Only
  /// active committees produce items.
  static List<CommitteeDueItem> dueItems(
      Iterable<CommitteeProgress> committees, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final items = <CommitteeDueItem>[];
    for (final p in committees) {
      final c = p.committee;
      if (!c.isActive || c.deletedAt != null) continue;
      final paid = p.paidMonths;
      for (var k = 1; k <= c.memberCount; k++) {
        final due = dueDate(c, k);
        if (due.isAfter(today)) break;
        if (!paid.contains(k)) {
          items.add(CommitteeDueItem(
            committeeId: c.id,
            kind: CommitteeEventKind.installment,
            monthIndex: k,
            dueDate: due,
            amountMinorUnits: c.monthlyMinorUnits,
          ));
        }
      }
      final payoutDue = dueDate(c, c.payoutMonth);
      if (!payoutDue.isAfter(today) && !p.payoutReceived) {
        items.add(CommitteeDueItem(
          committeeId: c.id,
          kind: CommitteeEventKind.payout,
          monthIndex: c.payoutMonth,
          dueDate: payoutDue,
          amountMinorUnits: c.payoutMinorUnits,
        ));
      }
    }
    items.sort((a, b) {
      final byDate = a.dueDate.compareTo(b.dueDate);
      if (byDate != 0) return byDate;
      // Installment before payout within the same day.
      return a.kind.index.compareTo(b.kind.index);
    });
    return items;
  }

  /// Expected net over the whole committee: payout minus everything paid in.
  /// Positive means the payout is larger than the installments (for example
  /// when the pot is bigger than `monthly x members`).
  static int expectedNet(Committee committee) =>
      committee.payoutMinorUnits - committee.totalToPayMinorUnits;

  /// Net so far: what has been received minus what has been paid in.
  static int netSoFar(CommitteeProgress progress) =>
      progress.receivedMinorUnits - progress.paidMinorUnits;

  /// Default pot when the user does not enter one.
  static int defaultPayout(int monthlyMinorUnits, int memberCount) =>
      monthlyMinorUnits * memberCount;
}
