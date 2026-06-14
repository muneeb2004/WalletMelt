import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../types/category.dart';
import 'repository_providers.dart';

final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  final repository = await ref.watch(driftCategoryRepositoryProvider.future);
  return repository.listCategories();
});

final categoryByIdProvider = FutureProvider.family<Category?, String>((ref, id) async {
  final categories = await ref.watch(categoriesProvider.future);
  for (final category in categories) {
    if (category.id == id) return category;
  }
  return null;
});
