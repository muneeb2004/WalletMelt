class Payee {
  const Payee({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.phone,
    this.notes,
    this.deletedAt,
    this.isActive = true,
  });

  final String id;
  final String name;
  final String? phone;
  final String? notes;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;
  final bool isActive;

  Payee copyWith({
    String? id,
    String? name,
    String? phone,
    String? notes,
    String? createdAt,
    String? updatedAt,
    String? deletedAt,
    bool clearDeletedAt = false,
    bool? isActive,
  }) {
    return Payee(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: clearDeletedAt ? null : deletedAt ?? this.deletedAt,
      isActive: isActive ?? this.isActive,
    );
  }
}
