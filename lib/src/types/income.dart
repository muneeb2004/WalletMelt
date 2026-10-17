enum IncomeSource { salary, allowance, scholarship, freelance, gift, other }

IncomeSource incomeSourceFromName(String? name) {
  for (final value in IncomeSource.values) {
    if (value.name == name) return value;
  }
  return IncomeSource.other;
}

enum IncomeScheduleStatus { active, paused }

class Income {
  const Income({
    required this.id,
    required this.title,
    required this.source,
    required this.amountMinorUnits,
    required this.currency,
    required this.date,
    required this.createdAt,
    required this.updatedAt,
    this.accountId,
    this.scheduleId,
    this.notes,
    this.deletedAt,
  });

  final String id;
  final String? accountId;
  final String? scheduleId;
  final String title;
  final IncomeSource source;
  final int amountMinorUnits;
  final String currency;

  /// ISO-8601 date at local midnight (same format as `Expense.date`).
  final String date;
  final String? notes;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;
}

class IncomeSchedule {
  const IncomeSchedule({
    required this.id,
    required this.title,
    required this.source,
    required this.amountMinorUnits,
    required this.currency,
    required this.cycle,
    required this.startDate,
    required this.nextDueDate,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.accountId,
    this.deletedAt,
  });

  final String id;
  final String title;
  final IncomeSource source;
  final int amountMinorUnits;
  final String currency;
  final String? accountId;

  /// Same vocabulary as subscriptions: weekly, monthly, quarterly,
  /// semi_annual, annual or `custom_N`.
  final String cycle;
  final String startDate;
  final String nextDueDate;
  final IncomeScheduleStatus status;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;

  bool get isActive => status == IncomeScheduleStatus.active;

  int get anchorDay => DateTime.tryParse(startDate)?.day ?? 1;
}
