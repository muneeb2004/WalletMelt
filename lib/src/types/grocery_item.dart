class GroceryItem {
  const GroceryItem({
    required this.id,
    required this.expenseId,
    required this.name,
    required this.amount,
    required this.createdAt,
  });

  final String id;
  final String expenseId;
  final String name;
  final double amount;
  final String createdAt;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'expenseId': expenseId,
      'name': name,
      'amount': amount,
      'createdAt': createdAt,
    };
  }

  factory GroceryItem.fromMap(Map<String, Object?> map) {
    return GroceryItem(
      id: map['id']! as String,
      expenseId: map['expenseId']! as String,
      name: map['name']! as String,
      amount: (map['amount']! as num).toDouble(),
      createdAt: map['createdAt']! as String,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GroceryItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          expenseId == other.expenseId &&
          name == other.name &&
          amount == other.amount &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(
        id,
        expenseId,
        name,
        amount,
        createdAt,
      );
}

class GroceryItemDraft {
  const GroceryItemDraft({
    required this.name,
    required this.amount,
    this.quantity,
    this.unitPrice,
  });

  final String name;
  final double amount;
  final double? quantity;
  final double? unitPrice;
}
