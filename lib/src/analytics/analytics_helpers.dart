/// Pure analytical helper model representing the dominant directional spending contributor.
class DirectionalContributor {
  const DirectionalContributor({
    required this.categoryId,
    required this.delta,
    required this.contributionPercent,
  });

  final String categoryId;
  final double delta;
  final double contributionPercent;
}

/// Identifies the category that contributed most to a gross spending increase or decrease.
///
/// Operates in a single O(C) pass across both category maps without intermediate allocations.
DirectionalContributor? findDominantDirectionalChange({
  required Map<String, double> currentByCategory,
  required Map<String, double> previousByCategory,
  required bool isIncrease,
}) {
  final allCategoryIds = {
    ...currentByCategory.keys,
    ...previousByCategory.keys,
  };

  String? topCatId;
  double topCatDelta = 0.0;
  double sumDirectional = 0.0;

  for (final catId in allCategoryIds) {
    final cur = currentByCategory[catId] ?? 0.0;
    final prev = previousByCategory[catId] ?? 0.0;
    final delta = isIncrease ? (cur - prev) : (prev - cur);
    if (delta > 0) {
      sumDirectional += delta;
      if (delta > topCatDelta) {
        topCatDelta = delta;
        topCatId = catId;
      }
    }
  }

  if (topCatId == null || sumDirectional <= 0) return null;

  final contributionPercent =
      ((topCatDelta / sumDirectional) * 100).clamp(0.0, 100.0);

  return DirectionalContributor(
    categoryId: topCatId,
    delta: topCatDelta,
    contributionPercent: contributionPercent,
  );
}
