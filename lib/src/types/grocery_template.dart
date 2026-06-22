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
}
