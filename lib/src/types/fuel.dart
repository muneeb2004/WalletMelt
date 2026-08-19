import 'package:flutter/material.dart';

enum FuelType {
  regular,
  premium,
  diesel;

  String get displayName => switch (this) {
        FuelType.regular => 'Regular',
        FuelType.premium => 'Premium',
        FuelType.diesel => 'Diesel',
      };

  IconData get icon => switch (this) {
        FuelType.regular => Icons.local_gas_station_rounded,
        FuelType.premium => Icons.speed_rounded,
        FuelType.diesel => Icons.local_shipping_rounded,
      };

  static FuelType fromName(String? name) {
    if (name == null) return FuelType.regular;
    final normalized = name.toLowerCase().trim();
    for (final type in FuelType.values) {
      if (type.name == normalized || type.displayName.toLowerCase() == normalized) {
        return type;
      }
    }
    return FuelType.regular;
  }
}

/// Helper function to perform deterministic decimal rounding for monetary and fuel values.
double roundToTwoDecimals(double value) {
  if (value.isNaN || value.isInfinite) return 0.0;
  return (value * 100).roundToDouble() / 100.0;
}

class FuelComponent {
  const FuelComponent({
    required this.id,
    required this.fuelTransactionId,
    required this.fuelType,
    required this.quantityLitres,
    required this.pricePerLitre,
    required this.subtotal,
    required this.createdAt,
  });

  final String id;
  final String fuelTransactionId;
  final FuelType fuelType;
  final double quantityLitres;
  final double pricePerLitre;
  final double subtotal;
  final String createdAt;

  double get computedSubtotal => roundToTwoDecimals(quantityLitres * pricePerLitre);

  FuelComponent copyWith({
    String? id,
    String? fuelTransactionId,
    FuelType? fuelType,
    double? quantityLitres,
    double? pricePerLitre,
    double? subtotal,
    String? createdAt,
  }) {
    return FuelComponent(
      id: id ?? this.id,
      fuelTransactionId: fuelTransactionId ?? this.fuelTransactionId,
      fuelType: fuelType ?? this.fuelType,
      quantityLitres: quantityLitres ?? this.quantityLitres,
      pricePerLitre: pricePerLitre ?? this.pricePerLitre,
      subtotal: subtotal ?? this.subtotal,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'fuelTransactionId': fuelTransactionId,
      'fuelType': fuelType.name,
      'quantityLitres': quantityLitres,
      'pricePerLitre': pricePerLitre,
      'subtotal': subtotal,
      'createdAt': createdAt,
    };
  }

  factory FuelComponent.fromMap(Map<String, Object?> map) {
    return FuelComponent(
      id: map['id']! as String,
      fuelTransactionId: map['fuelTransactionId']! as String,
      fuelType: FuelType.fromName(map['fuelType'] as String?),
      quantityLitres: (map['quantityLitres']! as num).toDouble(),
      pricePerLitre: (map['pricePerLitre']! as num).toDouble(),
      subtotal: (map['subtotal']! as num).toDouble(),
      createdAt: map['createdAt']! as String,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FuelComponent &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          fuelTransactionId == other.fuelTransactionId &&
          fuelType == other.fuelType &&
          (quantityLitres - other.quantityLitres).abs() < 0.0001 &&
          (pricePerLitre - other.pricePerLitre).abs() < 0.0001 &&
          (subtotal - other.subtotal).abs() < 0.0001;

  @override
  int get hashCode =>
      id.hashCode ^
      fuelTransactionId.hashCode ^
      fuelType.hashCode ^
      quantityLitres.hashCode ^
      pricePerLitre.hashCode ^
      subtotal.hashCode;
}

class FuelComponentDraft {
  const FuelComponentDraft({
    this.id,
    required this.fuelType,
    required this.quantityLitres,
    required this.pricePerLitre,
  });

  final String? id;
  final FuelType fuelType;
  final double quantityLitres;
  final double pricePerLitre;

  double get subtotal => roundToTwoDecimals(quantityLitres * pricePerLitre);

  bool get isValid =>
      !quantityLitres.isNaN &&
      !quantityLitres.isInfinite &&
      quantityLitres > 0 &&
      !pricePerLitre.isNaN &&
      !pricePerLitre.isInfinite &&
      pricePerLitre > 0;

  FuelComponentDraft copyWith({
    String? id,
    FuelType? fuelType,
    double? quantityLitres,
    double? pricePerLitre,
  }) {
    return FuelComponentDraft(
      id: id ?? this.id,
      fuelType: fuelType ?? this.fuelType,
      quantityLitres: quantityLitres ?? this.quantityLitres,
      pricePerLitre: pricePerLitre ?? this.pricePerLitre,
    );
  }
}

class FuelTransaction {
  const FuelTransaction({
    required this.id,
    required this.expenseId,
    required this.createdAt,
    this.odometerReading,
    this.components = const [],
  });

  final String id;
  final String expenseId;
  final double? odometerReading;
  final String createdAt;
  final List<FuelComponent> components;

  double get totalLitres =>
      components.fold(0.0, (sum, item) => sum + item.quantityLitres);

  double get totalAmount =>
      roundToTwoDecimals(components.fold(0.0, (sum, item) => sum + item.subtotal));

  FuelTransaction copyWith({
    String? id,
    String? expenseId,
    double? odometerReading,
    bool clearOdometer = false,
    String? createdAt,
    List<FuelComponent>? components,
  }) {
    return FuelTransaction(
      id: id ?? this.id,
      expenseId: expenseId ?? this.expenseId,
      odometerReading:
          clearOdometer ? null : (odometerReading ?? this.odometerReading),
      createdAt: createdAt ?? this.createdAt,
      components: components ?? this.components,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'expenseId': expenseId,
      'odometerReading': odometerReading,
      'createdAt': createdAt,
      'components': components.map((c) => c.toMap()).toList(),
    };
  }

  factory FuelTransaction.fromMap(Map<String, Object?> map) {
    final rawComponents = map['components'] as List<dynamic>? ?? [];
    return FuelTransaction(
      id: map['id']! as String,
      expenseId: map['expenseId']! as String,
      odometerReading: map['odometerReading'] != null
          ? (map['odometerReading'] as num).toDouble()
          : null,
      createdAt: map['createdAt']! as String,
      components: rawComponents
          .map((c) => FuelComponent.fromMap(Map<String, Object?>.from(c as Map)))
          .toList(),
    );
  }
}

class FuelTransactionDraft {
  const FuelTransactionDraft({
    this.id,
    this.odometerReading,
    this.components = const [],
  });

  final String? id;
  final double? odometerReading;
  final List<FuelComponentDraft> components;

  double get totalLitres =>
      components.fold(0.0, (sum, item) => sum + item.quantityLitres);

  double get totalAmount =>
      roundToTwoDecimals(components.fold(0.0, (sum, item) => sum + item.subtotal));

  bool get isValid =>
      components.isNotEmpty && components.every((item) => item.isValid);

  FuelTransactionDraft copyWith({
    String? id,
    double? odometerReading,
    bool clearOdometer = false,
    List<FuelComponentDraft>? components,
  }) {
    return FuelTransactionDraft(
      id: id ?? this.id,
      odometerReading:
          clearOdometer ? null : (odometerReading ?? this.odometerReading),
      components: components ?? this.components,
    );
  }
}
