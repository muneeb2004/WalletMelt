enum CommitteeStatus { active, completed, archived }

CommitteeStatus committeeStatusFromName(String? name) {
  for (final value in CommitteeStatus.values) {
    if (value.name == name) return value;
  }
  return CommitteeStatus.active;
}

enum CommitteeEventKind { installment, payout }

CommitteeEventKind committeeEventKindFromName(String? name) =>
    name == 'payout' ? CommitteeEventKind.payout : CommitteeEventKind.installment;

class Committee {
  const Committee({
    required this.id,
    required this.name,
    required this.monthlyMinorUnits,
    required this.memberCount,
    required this.payoutMonth,
    required this.payoutMinorUnits,
    required this.currency,
    required this.startDate,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.accountId,
    this.deletedAt,
  });

  final String id;
  final String name;

  /// The user's installment, paid every month including the payout month.
  final int monthlyMinorUnits;
  final int memberCount;

  /// 1-based month in which the user receives the pot.
  final int payoutMonth;
  final int payoutMinorUnits;
  final String currency;

  /// Account installments are paid from and the payout is deposited into.
  final String? accountId;

  /// ISO date of the first installment; its day is the monthly due day.
  final String startDate;
  final CommitteeStatus status;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;

  bool get isActive => status == CommitteeStatus.active;

  int get startDay => DateTime.tryParse(startDate)?.day ?? 1;

  int get totalToPayMinorUnits => monthlyMinorUnits * memberCount;
}

class CommitteeEvent {
  const CommitteeEvent({
    required this.id,
    required this.committeeId,
    required this.kind,
    required this.monthIndex,
    required this.amountMinorUnits,
    required this.date,
    required this.createdAt,
    required this.updatedAt,
    this.notes,
    this.deletedAt,
  });

  final String id;
  final String committeeId;
  final CommitteeEventKind kind;
  final int monthIndex;
  final int amountMinorUnits;
  final String date;
  final String? notes;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;
}

/// A committee with its confirmed events and everything derived from them.
class CommitteeProgress {
  const CommitteeProgress({required this.committee, required this.events});

  final Committee committee;
  final List<CommitteeEvent> events;

  Iterable<CommitteeEvent> get _live =>
      events.where((e) => e.deletedAt == null);

  Set<int> get paidMonths => {
        for (final e in _live)
          if (e.kind == CommitteeEventKind.installment) e.monthIndex,
      };

  int get paidCount => paidMonths.length;

  int get paidMinorUnits => _live
      .where((e) => e.kind == CommitteeEventKind.installment)
      .fold(0, (sum, e) => sum + e.amountMinorUnits);

  CommitteeEvent? get payoutEvent => _live
      .where((e) => e.kind == CommitteeEventKind.payout)
      .firstOrNull;

  bool get payoutReceived => payoutEvent != null;

  int get receivedMinorUnits => payoutEvent?.amountMinorUnits ?? 0;

  int get remainingInstallments => committee.memberCount - paidCount;

  bool get isFullyRecorded =>
      paidCount >= committee.memberCount && payoutReceived;

  /// Lowest month without a recorded installment, or null when all are paid.
  int? get nextInstallmentMonth {
    final paid = paidMonths;
    for (var k = 1; k <= committee.memberCount; k++) {
      if (!paid.contains(k)) return k;
    }
    return null;
  }
}
