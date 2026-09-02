class CategoryBudget {
  const CategoryBudget({
    required this.id,
    required this.categoryId,
    required this.amount,
    required this.currency,
    required this.month,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String categoryId;
  final double amount;
  final String currency;
  final String month;
  final String createdAt;
  final String updatedAt;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'categoryId': categoryId,
      'amount': amount,
      'currency': currency,
      'month': month,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory CategoryBudget.fromMap(Map<String, Object?> map) {
    return CategoryBudget(
      id: map['id']! as String,
      categoryId: map['categoryId']! as String,
      amount: (map['amount']! as num).toDouble(),
      currency: map['currency']! as String,
      month: map['month']! as String,
      createdAt: map['createdAt']! as String,
      updatedAt: map['updatedAt']! as String,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategoryBudget &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          categoryId == other.categoryId &&
          amount == other.amount &&
          currency == other.currency &&
          month == other.month &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(
        id,
        categoryId,
        amount,
        currency,
        month,
        createdAt,
        updatedAt,
      );
}
