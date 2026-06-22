enum DebtType { owedToMe, iOwe, loanGiven, loanTaken }

enum DebtStatus { active, partiallyPaid, settled, overdue }

class DebtRecord {
  const DebtRecord({
    required this.id,
    required this.personName,
    required this.type,
    required this.principalAmount,
    required this.remainingAmount,
    required this.currency,
    required this.createdAt,
    required this.status,
    this.description,
    this.dueDate,
    this.settledAt,
    this.notes,
  });

  final String id;
  final String personName;
  final DebtType type;
  final double principalAmount;
  final double remainingAmount;
  final String currency;
  final String? description;
  final String createdAt;
  final String? dueDate;
  final String? settledAt;
  final DebtStatus status;
  final String? notes;

  bool get isSettled => status == DebtStatus.settled || remainingAmount <= 0;

  DebtRecord copyWith({
    String? id,
    String? personName,
    DebtType? type,
    double? principalAmount,
    double? remainingAmount,
    String? currency,
    String? description,
    String? createdAt,
    String? dueDate,
    String? settledAt,
    bool clearDueDate = false,
    bool clearSettledAt = false,
    DebtStatus? status,
    String? notes,
  }) {
    return DebtRecord(
      id: id ?? this.id,
      personName: personName ?? this.personName,
      type: type ?? this.type,
      principalAmount: principalAmount ?? this.principalAmount,
      remainingAmount: remainingAmount ?? this.remainingAmount,
      currency: currency ?? this.currency,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      dueDate: clearDueDate ? null : dueDate ?? this.dueDate,
      settledAt: clearSettledAt ? null : settledAt ?? this.settledAt,
      status: status ?? this.status,
      notes: notes ?? this.notes,
    );
  }
}

class DebtRepayment {
  const DebtRepayment({
    required this.id,
    required this.debtId,
    required this.amount,
    required this.createdAt,
    this.notes,
  });

  final String id;
  final String debtId;
  final double amount;
  final String createdAt;
  final String? notes;

  DebtRepayment copyWith({
    String? id,
    String? debtId,
    double? amount,
    String? createdAt,
    String? notes,
  }) {
    return DebtRepayment(
      id: id ?? this.id,
      debtId: debtId ?? this.debtId,
      amount: amount ?? this.amount,
      createdAt: createdAt ?? this.createdAt,
      notes: notes ?? this.notes,
    );
  }
}
