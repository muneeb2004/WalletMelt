class GroceryTemplate {
  const GroceryTemplate({
    required this.id,
    required this.name,
    required this.items,
    required this.createdAt,
  });

  final String id;
  final String name;
  final List<String> items;
  final String createdAt;

  GroceryTemplate copyWith({
    String? id,
    String? name,
    List<String>? items,
    String? createdAt,
  }) {
    return GroceryTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      items: items ?? this.items,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

