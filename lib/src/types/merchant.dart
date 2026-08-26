class Merchant {
  const Merchant({
    required this.id,
    required this.name,
    required this.normalizedName,
    required this.createdAt,
    required this.updatedAt,
    this.defaultCategoryId,
    this.notes,
    this.isSaved = false,
    this.isFavorite = false,
    this.lastUsedAt,
    this.archivedAt,
  });

  final String id;
  final String name;
  final String normalizedName;
  final String? defaultCategoryId;
  final String? notes;
  final bool isSaved;
  final bool isFavorite;
  final String? lastUsedAt;
  final String createdAt;
  final String updatedAt;
  final String? archivedAt;

  bool get isArchived => archivedAt != null;
  bool get isActive => archivedAt == null;

  Merchant copyWith({
    String? id,
    String? name,
    String? normalizedName,
    String? defaultCategoryId,
    bool clearDefaultCategory = false,
    String? notes,
    bool clearNotes = false,
    bool? isSaved,
    bool? isFavorite,
    String? lastUsedAt,
    String? createdAt,
    String? updatedAt,
    String? archivedAt,
    bool clearArchivedAt = false,
  }) {
    final nextFavorite = isFavorite ?? this.isFavorite;
    final nextSaved = isSaved ?? (nextFavorite ? true : this.isSaved);

    return Merchant(
      id: id ?? this.id,
      name: name ?? this.name,
      normalizedName: normalizedName ?? this.normalizedName,
      defaultCategoryId: clearDefaultCategory
          ? null
          : (defaultCategoryId ?? this.defaultCategoryId),
      notes: clearNotes ? null : (notes ?? this.notes),
      isSaved: nextSaved,
      isFavorite: nextSaved ? nextFavorite : false,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      archivedAt: clearArchivedAt ? null : (archivedAt ?? this.archivedAt),
    );
  }
}
