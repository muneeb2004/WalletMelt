import 'fuel.dart';

enum EssentialFrequency {
  monthly,
  weekly,
  quarterly,
  yearly,
  custom;

  String get displayName => switch (this) {
        EssentialFrequency.monthly => 'Monthly',
        EssentialFrequency.weekly => 'Weekly',
        EssentialFrequency.quarterly => 'Quarterly',
        EssentialFrequency.yearly => 'Yearly',
        EssentialFrequency.custom => 'Custom',
      };

  static EssentialFrequency fromString(String? val) {
    if (val == null) return EssentialFrequency.monthly;
    final normalized = val.toLowerCase().trim();
    if (normalized.startsWith('custom')) return EssentialFrequency.custom;
    for (final f in EssentialFrequency.values) {
      if (f.name == normalized) return f;
    }
    return EssentialFrequency.monthly;
  }
}

class FuelTemplateComponent {
  const FuelTemplateComponent({
    required this.id,
    required this.templateId,
    required this.fuelType,
    required this.expectedLitres,
    required this.expectedPricePerLitre,
    required this.createdAt,
  });

  final String id;
  final String templateId;
  final FuelType fuelType;
  final double expectedLitres;
  final double expectedPricePerLitre;
  final String createdAt;

  double get estimatedAmount =>
      roundToTwoDecimals(expectedLitres * expectedPricePerLitre);

  FuelTemplateComponent copyWith({
    String? id,
    String? templateId,
    FuelType? fuelType,
    double? expectedLitres,
    double? expectedPricePerLitre,
    String? createdAt,
  }) {
    return FuelTemplateComponent(
      id: id ?? this.id,
      templateId: templateId ?? this.templateId,
      fuelType: fuelType ?? this.fuelType,
      expectedLitres: expectedLitres ?? this.expectedLitres,
      expectedPricePerLitre:
          expectedPricePerLitre ?? this.expectedPricePerLitre,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'templateId': templateId,
      'fuelType': fuelType.name,
      'expectedLitres': expectedLitres,
      'expectedPricePerLitre': expectedPricePerLitre,
      'createdAt': createdAt,
    };
  }

  factory FuelTemplateComponent.fromMap(Map<String, Object?> map) {
    return FuelTemplateComponent(
      id: map['id']! as String,
      templateId: map['templateId']! as String,
      fuelType: FuelType.fromName(map['fuelType'] as String?),
      expectedLitres: (map['expectedLitres']! as num).toDouble(),
      expectedPricePerLitre: (map['expectedPricePerLitre']! as num).toDouble(),
      createdAt: map['createdAt']! as String,
    );
  }
}

class EssentialExpenseTemplate {
  const EssentialExpenseTemplate({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.frequency,
    required this.expectedAmount,
    required this.isActive,
    required this.isFuel,
    required this.createdAt,
    required this.updatedAt,
    this.expectedDay,
    this.dueDate,
    this.notes,
    this.deletedAt,
    this.fuelComponents = const [],
  });

  final String id;
  final String name;
  final String categoryId;
  final String frequency; // 'monthly', 'weekly', 'quarterly', 'yearly', 'custom_X'
  final double expectedAmount;
  final int? expectedDay; // 1-31 (day of month)
  final String? dueDate; // ISO date string
  final bool isActive;
  final bool isFuel;
  final String? notes;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;
  final List<FuelTemplateComponent> fuelComponents;

  bool get isDeleted => deletedAt != null;

  double get computedExpectedAmount {
    if (isFuel && fuelComponents.isNotEmpty) {
      return roundToTwoDecimals(
          fuelComponents.fold(0.0, (sum, c) => sum + c.estimatedAmount));
    }
    return roundToTwoDecimals(expectedAmount);
  }

  double get totalExpectedLitres {
    if (!isFuel) return 0.0;
    return fuelComponents.fold(0.0, (sum, c) => sum + c.expectedLitres);
  }

  EssentialExpenseTemplate copyWith({
    String? id,
    String? name,
    String? categoryId,
    String? frequency,
    double? expectedAmount,
    int? expectedDay,
    bool clearExpectedDay = false,
    String? dueDate,
    bool clearDueDate = false,
    bool? isActive,
    bool? isFuel,
    String? notes,
    bool clearNotes = false,
    String? createdAt,
    String? updatedAt,
    String? deletedAt,
    bool clearDeletedAt = false,
    List<FuelTemplateComponent>? fuelComponents,
  }) {
    return EssentialExpenseTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      categoryId: categoryId ?? this.categoryId,
      frequency: frequency ?? this.frequency,
      expectedAmount: expectedAmount ?? this.expectedAmount,
      expectedDay: clearExpectedDay ? null : (expectedDay ?? this.expectedDay),
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      isActive: isActive ?? this.isActive,
      isFuel: isFuel ?? this.isFuel,
      notes: clearNotes ? null : (notes ?? this.notes),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
      fuelComponents: fuelComponents ?? this.fuelComponents,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'categoryId': categoryId,
      'frequency': frequency,
      'expectedAmount': expectedAmount,
      'expectedDay': expectedDay,
      'dueDate': dueDate,
      'isActive': isActive ? 1 : 0,
      'isFuel': isFuel ? 1 : 0,
      'notes': notes,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'deletedAt': deletedAt,
      'fuelComponents': fuelComponents.map((c) => c.toMap()).toList(),
    };
  }

  factory EssentialExpenseTemplate.fromMap(Map<String, Object?> map) {
    final rawFuel = map['fuelComponents'] as List<dynamic>? ?? [];
    return EssentialExpenseTemplate(
      id: map['id']! as String,
      name: map['name']! as String,
      categoryId: map['categoryId']! as String,
      frequency: map['frequency']! as String,
      expectedAmount: (map['expectedAmount']! as num).toDouble(),
      expectedDay: map['expectedDay'] as int?,
      dueDate: map['dueDate'] as String?,
      isActive: map['isActive'] == 1 || map['isActive'] == true,
      isFuel: map['isFuel'] == 1 || map['isFuel'] == true,
      notes: map['notes'] as String?,
      createdAt: map['createdAt']! as String,
      updatedAt: map['updatedAt']! as String,
      deletedAt: map['deletedAt'] as String?,
      fuelComponents: rawFuel
          .map((c) =>
              FuelTemplateComponent.fromMap(Map<String, Object?>.from(c as Map)))
          .toList(),
    );
  }
}
