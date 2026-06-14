enum RecurrenceFrequency { weekly, monthly, quarterly, yearly }

class Expense {
  const Expense({
    required this.id,
    required this.amount,
    required this.currency,
    required this.categoryId,
    required this.title,
    required this.date,
    required this.isRecurring,
    required this.createdAt,
    required this.updatedAt,
    this.vendor,
    this.notes,
    this.receiptImageUri,
    this.recurrenceFrequency,
    this.deletedAt,
  });

  final String id;
  final double amount;
  final String currency;
  final String categoryId;
  final String title;
  final String? vendor;
  final String date;
  final String? notes;
  final String? receiptImageUri;
  final bool isRecurring;
  final RecurrenceFrequency? recurrenceFrequency;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;

  bool get isDeleted => deletedAt != null;

  Expense copyWith({
    String? id,
    double? amount,
    String? currency,
    String? categoryId,
    String? title,
    String? vendor,
    String? date,
    String? notes,
    String? receiptImageUri,
    bool clearReceipt = false,
    bool? isRecurring,
    RecurrenceFrequency? recurrenceFrequency,
    String? createdAt,
    String? updatedAt,
    String? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Expense(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      categoryId: categoryId ?? this.categoryId,
      title: title ?? this.title,
      vendor: vendor ?? this.vendor,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      receiptImageUri: clearReceipt ? null : receiptImageUri ?? this.receiptImageUri,
      isRecurring: isRecurring ?? this.isRecurring,
      recurrenceFrequency: recurrenceFrequency ?? this.recurrenceFrequency,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: clearDeletedAt ? null : deletedAt ?? this.deletedAt,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'amount': amount,
      'currency': currency,
      'categoryId': categoryId,
      'title': title,
      'vendor': vendor,
      'date': date,
      'notes': notes,
      'receiptImageUri': receiptImageUri,
      'isRecurring': isRecurring ? 1 : 0,
      'recurrenceFrequency': recurrenceFrequency?.name,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'deletedAt': deletedAt,
    };
  }

  factory Expense.fromMap(Map<String, Object?> map) {
    return Expense(
      id: map['id']! as String,
      amount: (map['amount']! as num).toDouble(),
      currency: map['currency']! as String,
      categoryId: map['categoryId']! as String,
      title: map['title']! as String,
      vendor: map['vendor'] as String?,
      date: map['date']! as String,
      notes: map['notes'] as String?,
      receiptImageUri: map['receiptImageUri'] as String?,
      isRecurring: (map['isRecurring']! as int) == 1,
      recurrenceFrequency: _frequencyFromName(map['recurrenceFrequency'] as String?),
      createdAt: map['createdAt']! as String,
      updatedAt: map['updatedAt']! as String,
      deletedAt: map['deletedAt'] as String?,
    );
  }

  static RecurrenceFrequency? _frequencyFromName(String? name) {
    if (name == null) return null;
    for (final value in RecurrenceFrequency.values) {
      if (value.name == name) return value;
    }
    return null;
  }
}
