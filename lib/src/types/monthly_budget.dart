class MonthlyBudget {
  const MonthlyBudget({
    required this.id,
    required this.month,
    required this.amount,
    required this.currency,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String month; // e.g., '2026-03'
  final double amount;
  final String currency;
  final String createdAt;
  final String updatedAt;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'month': month,
      'amount': amount,
      'currency': currency,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory MonthlyBudget.fromMap(Map<String, Object?> map) {
    return MonthlyBudget(
      id: map['id']! as String,
      month: map['month']! as String,
      amount: (map['amount']! as num).toDouble(),
      currency: map['currency']! as String,
      createdAt: map['createdAt']! as String,
      updatedAt: map['updatedAt']! as String,
    );
  }

  MonthlyBudget copyWith({
    String? id,
    String? month,
    double? amount,
    String? currency,
    String? createdAt,
    String? updatedAt,
  }) {
    return MonthlyBudget(
      id: id ?? this.id,
      month: month ?? this.month,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MonthlyBudget &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          month == other.month &&
          amount == other.amount &&
          currency == other.currency &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(
        id,
        month,
        amount,
        currency,
        createdAt,
        updatedAt,
      );
}
