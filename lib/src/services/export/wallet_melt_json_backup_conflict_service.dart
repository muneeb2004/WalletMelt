import 'dart:convert';

import '../../types/budget.dart';
import '../../types/category.dart';
import '../../types/expense.dart';
import '../../types/grocery_item.dart';
import '../../types/settings.dart';

// ---------------------------------------------------------------------------
// Local snapshot passed in by the caller (read-only current app data).
// ---------------------------------------------------------------------------

/// A read-only snapshot of the current local app data used for conflict
/// detection. This is passed in by the caller from AppState — the conflict
/// service never accesses repositories directly.
class LocalAppSnapshot {
  const LocalAppSnapshot({
    required this.expenses,
    required this.deletedExpenses,
    required this.categories,
    required this.budgets,
    required this.groceryItems,
    this.settings,
  });

  /// Active (non-deleted) expenses currently in the local database.
  final List<Expense> expenses;

  /// Soft-deleted expenses currently in the local database.
  final List<Expense> deletedExpenses;

  /// All categories currently in the local database.
  final List<Category> categories;

  /// All budgets currently in the local database.
  final List<CategoryBudget> budgets;

  /// All grocery items currently in the local database.
  final List<GroceryItem> groceryItems;

  /// Current app settings (optional; may be null if not available).
  final WalletMeltSettings? settings;

  /// All expenses (active + deleted) in a single combined list.
  List<Expense> get allExpenses => [...expenses, ...deletedExpenses];
}

// ---------------------------------------------------------------------------
// Conflict summary model.
// ---------------------------------------------------------------------------

/// A structured, read-only summary of detected conflicts and warnings between
/// a backup file and the current local app data.
///
/// This model never triggers any database writes. It is a pure analysis result.
class BackupConflictSummary {
  const BackupConflictSummary({
    this.duplicateExpenseIdCount = 0,
    this.softDeletedBackupExpenseCount = 0,
    this.receiptReferenceCount = 0,
    this.groceryOrphanCount = 0,
    this.duplicateCategoryIdCount = 0,
    this.categoryNameIdMismatchCount = 0,
    this.duplicateBudgetMonthCategoryCount = 0,
    this.budgetMissingCategoryCount = 0,
    this.appVersionWarning,
    this.settingsWarning,
    this.hasAnyConflict = false,
  });

  // — Expense conflicts —

  /// Count of backup expense IDs already present in local data (active or deleted).
  final int duplicateExpenseIdCount;

  /// Count of backup expenses that are soft-deleted (have a non-null deleted_at).
  final int softDeletedBackupExpenseCount;

  /// Count of backup expenses that include a receipt_image_uri reference.
  /// These paths may not be valid on this device.
  final int receiptReferenceCount;

  /// Count of grocery items in the backup that reference an expense_id not
  /// present anywhere in the backup's own expense list.
  final int groceryOrphanCount;

  // — Category conflicts —

  /// Count of backup category IDs already present locally.
  final int duplicateCategoryIdCount;

  /// Count of backup categories whose name matches a local category but
  /// whose ID does not (or vice-versa — same ID, different name).
  final int categoryNameIdMismatchCount;

  // — Budget conflicts —

  /// Count of backup budgets whose month + category_id pair already exists
  /// locally (i.e., would collide).
  final int duplicateBudgetMonthCategoryCount;

  /// Count of backup budgets that reference a category_id not found
  /// anywhere in the backup's own category list.
  final int budgetMissingCategoryCount;

  // — Metadata / settings —

  /// Non-null when the backup's app_version is null, empty, or not
  /// recognised (informational warning only; does not block preview).
  final String? appVersionWarning;

  /// Non-null when the backup's settings block differs from the current
  /// app settings or is missing entirely.
  final String? settingsWarning;

  /// True if any count is non-zero or any warning is non-null.
  final bool hasAnyConflict;

  /// Convenience list of all human-readable conflict lines (empty when clean).
  List<String> get summaryLines {
    final lines = <String>[];

    if (duplicateExpenseIdCount > 0) {
      lines.add(
        '$duplicateExpenseIdCount expense ID(s) already exist locally '
        'and would conflict on restore.',
      );
    }
    if (softDeletedBackupExpenseCount > 0) {
      lines.add(
        '$softDeletedBackupExpenseCount soft-deleted expense(s) present '
        'in backup.',
      );
    }
    if (receiptReferenceCount > 0) {
      lines.add(
        '$receiptReferenceCount expense(s) reference receipt image path(s) '
        'that may not exist on this device.',
      );
    }
    if (groceryOrphanCount > 0) {
      lines.add(
        '$groceryOrphanCount grocery item(s) reference an expense_id not '
        'found in the backup — these items would become orphaned.',
      );
    }
    if (duplicateCategoryIdCount > 0) {
      lines.add(
        '$duplicateCategoryIdCount category ID(s) already exist locally '
        'and would conflict on restore.',
      );
    }
    if (categoryNameIdMismatchCount > 0) {
      lines.add(
        '$categoryNameIdMismatchCount category name/ID mismatch(es) '
        'detected — same name with different ID or same ID with different name.',
      );
    }
    if (duplicateBudgetMonthCategoryCount > 0) {
      lines.add(
        '$duplicateBudgetMonthCategoryCount budget(s) for the same '
        'month + category already exist locally.',
      );
    }
    if (budgetMissingCategoryCount > 0) {
      lines.add(
        '$budgetMissingCategoryCount budget(s) reference a category_id '
        'not present in the backup.',
      );
    }
    if (appVersionWarning != null) {
      lines.add(appVersionWarning!);
    }
    if (settingsWarning != null) {
      lines.add(settingsWarning!);
    }
    return lines;
  }
}

// ---------------------------------------------------------------------------
// Service.
// ---------------------------------------------------------------------------

/// A read-only service that compares decoded backup content against a
/// [LocalAppSnapshot] and returns a [BackupConflictSummary].
///
/// **Invariants:**
/// - Never writes to any repository.
/// - Never mutates any AppState field.
/// - Never calls any database write API.
/// - Never makes restore decisions automatically.
/// - All detection is purely in-memory comparison.
class WalletMeltJsonBackupConflictService {
  const WalletMeltJsonBackupConflictService();

  /// Runs conflict detection on the raw [jsonText] backup against the supplied
  /// [localSnapshot] of the current in-app data.
  ///
  /// Returns a [BackupConflictSummary] regardless of outcome. If [jsonText]
  /// cannot be decoded, a summary with a general warning is returned.
  ///
  /// This method is synchronous and pure — it only reads from the inputs.
  BackupConflictSummary detect({
    required String jsonText,
    required LocalAppSnapshot localSnapshot,
  }) {
    final Map<String, Object?> backupMap;
    try {
      final decoded = jsonDecode(jsonText);
      if (decoded is! Map) {
        return const BackupConflictSummary(hasAnyConflict: true);
      }
      backupMap = decoded.cast<String, Object?>();
    } catch (_) {
      return const BackupConflictSummary(hasAnyConflict: true);
    }

    final backupExpenses = _asMaps(backupMap['expenses']);
    final backupGroceryItems = _asMaps(backupMap['grocery_items']);
    final backupCategories = _asMaps(backupMap['categories']);
    final backupBudgets = _asMaps(backupMap['budgets']);
    final backupSettings = backupMap['settings'] as Map?;
    final backupMetadata = backupMap['metadata'] as Map?;

    final results = _ConflictCounts();

    _detectExpenseConflicts(
      backupExpenses: backupExpenses,
      localSnapshot: localSnapshot,
      out: results,
    );

    _detectGroceryOrphans(
      backupGroceryItems: backupGroceryItems,
      backupExpenseIds:
          backupExpenses.map((e) => e['id']?.toString() ?? '').toSet(),
      localSnapshot: localSnapshot,
      out: results,
    );

    _detectCategoryConflicts(
      backupCategories: backupCategories,
      localSnapshot: localSnapshot,
      out: results,
    );

    _detectBudgetConflicts(
      backupBudgets: backupBudgets,
      backupCategoryIds:
          backupCategories.map((c) => c['id']?.toString() ?? '').toSet(),
      localSnapshot: localSnapshot,
      out: results,
    );

    _detectMetadataWarnings(
      backupMetadata: backupMetadata,
      out: results,
    );

    _detectSettingsWarning(
      backupSettings: backupSettings,
      localSnapshot: localSnapshot,
      out: results,
    );

    final hasAny = results.duplicateExpenseIdCount > 0 ||
        results.softDeletedBackupExpenseCount > 0 ||
        results.receiptReferenceCount > 0 ||
        results.groceryOrphanCount > 0 ||
        results.duplicateCategoryIdCount > 0 ||
        results.categoryNameIdMismatchCount > 0 ||
        results.duplicateBudgetMonthCategoryCount > 0 ||
        results.budgetMissingCategoryCount > 0 ||
        results.appVersionWarning != null ||
        results.settingsWarning != null;

    return BackupConflictSummary(
      duplicateExpenseIdCount: results.duplicateExpenseIdCount,
      softDeletedBackupExpenseCount: results.softDeletedBackupExpenseCount,
      receiptReferenceCount: results.receiptReferenceCount,
      groceryOrphanCount: results.groceryOrphanCount,
      duplicateCategoryIdCount: results.duplicateCategoryIdCount,
      categoryNameIdMismatchCount: results.categoryNameIdMismatchCount,
      duplicateBudgetMonthCategoryCount:
          results.duplicateBudgetMonthCategoryCount,
      budgetMissingCategoryCount: results.budgetMissingCategoryCount,
      appVersionWarning: results.appVersionWarning,
      settingsWarning: results.settingsWarning,
      hasAnyConflict: hasAny,
    );
  }

  // -------------------------------------------------------------------------
  // Internal helpers.
  // -------------------------------------------------------------------------

  /// Safely casts a JSON value to a list of string-keyed maps.
  List<Map<String, Object?>> _asMaps(Object? value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((e) => e.cast<String, Object?>())
        .toList();
  }

  void _detectExpenseConflicts({
    required List<Map<String, Object?>> backupExpenses,
    required LocalAppSnapshot localSnapshot,
    required _ConflictCounts out,
  }) {
    final localExpenseIds = localSnapshot.allExpenses.map((e) => e.id).toSet();

    for (final exp in backupExpenses) {
      final id = exp['id']?.toString();
      if (id != null && localExpenseIds.contains(id)) {
        out.duplicateExpenseIdCount++;
      }
      if (exp['deleted_at'] != null) {
        out.softDeletedBackupExpenseCount++;
      }
      final receiptUri = exp['receipt_image_uri']?.toString();
      if (receiptUri != null && receiptUri.isNotEmpty) {
        out.receiptReferenceCount++;
      }
    }
  }

  void _detectGroceryOrphans({
    required List<Map<String, Object?>> backupGroceryItems,
    required Set<String> backupExpenseIds,
    required LocalAppSnapshot localSnapshot,
    required _ConflictCounts out,
  }) {
    final localExpenseIds = localSnapshot.allExpenses.map((e) => e.id).toSet();

    for (final item in backupGroceryItems) {
      final refId = item['expense_id']?.toString();
      if (refId == null || refId.isEmpty) {
        out.groceryOrphanCount++;
        continue;
      }
      // Orphan if expense_id is absent from both the backup AND local data.
      final inBackup = backupExpenseIds.contains(refId);
      final inLocal = localExpenseIds.contains(refId);
      if (!inBackup && !inLocal) {
        out.groceryOrphanCount++;
      }
    }
  }

  void _detectCategoryConflicts({
    required List<Map<String, Object?>> backupCategories,
    required LocalAppSnapshot localSnapshot,
    required _ConflictCounts out,
  }) {
    final localById = {for (final c in localSnapshot.categories) c.id: c};
    final localByName = {
      for (final c in localSnapshot.categories) c.name.toLowerCase(): c
    };

    for (final cat in backupCategories) {
      final id = cat['id']?.toString();
      final name = cat['name']?.toString();

      if (id != null && localById.containsKey(id)) {
        out.duplicateCategoryIdCount++;
        // Additionally check if the name differs (same ID, different name).
        final localCat = localById[id]!;
        if (name != null && name.toLowerCase() != localCat.name.toLowerCase()) {
          out.categoryNameIdMismatchCount++;
        }
        continue;
      }

      // Same name, different ID.
      if (name != null && localByName.containsKey(name.toLowerCase())) {
        final localCat = localByName[name.toLowerCase()]!;
        if (id != null && id != localCat.id) {
          out.categoryNameIdMismatchCount++;
        }
      }
    }
  }

  void _detectBudgetConflicts({
    required List<Map<String, Object?>> backupBudgets,
    required Set<String> backupCategoryIds,
    required LocalAppSnapshot localSnapshot,
    required _ConflictCounts out,
  }) {
    // Build a set of (month, categoryId) pairs from local budgets.
    final localPairs =
        localSnapshot.budgets.map((b) => '${b.month}|${b.categoryId}').toSet();

    for (final budget in backupBudgets) {
      final month = budget['month']?.toString();
      final categoryId = budget['category_id']?.toString();

      if (month != null && categoryId != null) {
        final pairKey = '$month|$categoryId';
        if (localPairs.contains(pairKey)) {
          out.duplicateBudgetMonthCategoryCount++;
        }
      }

      // Warn if backup budget references a category not in the backup itself.
      if (categoryId != null && !backupCategoryIds.contains(categoryId)) {
        out.budgetMissingCategoryCount++;
      }
    }
  }

  void _detectMetadataWarnings({
    required Map? backupMetadata,
    required _ConflictCounts out,
  }) {
    if (backupMetadata == null) return;
    final appVersion = backupMetadata['app_version']?.toString();
    if (appVersion == null || appVersion.isEmpty) {
      out.appVersionWarning =
          'Backup app_version is unknown or missing. Compatibility cannot '
          'be fully verified.';
    }
  }

  void _detectSettingsWarning({
    required Map? backupSettings,
    required LocalAppSnapshot localSnapshot,
    required _ConflictCounts out,
  }) {
    if (backupSettings == null) {
      out.settingsWarning =
          'Backup does not include a settings block. Local settings will be '
          'unaffected if this backup is restored.';
      return;
    }

    final currentSettings = localSnapshot.settings;
    if (currentSettings == null) return;

    final backupCurrency = backupSettings['currency']?.toString();
    final backupTheme = backupSettings['theme_preference']?.toString();

    final currencyDiffers =
        backupCurrency != null && backupCurrency != currentSettings.currency;
    final themeDiffers = backupTheme != null &&
        backupTheme != currentSettings.themePreference.name;

    if (currencyDiffers || themeDiffers) {
      final parts = <String>[];
      if (currencyDiffers) {
        parts.add(
            'currency (backup: $backupCurrency, current: ${currentSettings.currency})');
      }
      if (themeDiffers) {
        parts.add(
            'theme (backup: $backupTheme, current: ${currentSettings.themePreference.name})');
      }
      out.settingsWarning =
          'Backup settings differ from current settings: ${parts.join(', ')}.';
    }
  }
}

// ---------------------------------------------------------------------------
// Internal mutable accumulator (private to this file).
// ---------------------------------------------------------------------------

class _ConflictCounts {
  int duplicateExpenseIdCount = 0;
  int softDeletedBackupExpenseCount = 0;
  int receiptReferenceCount = 0;
  int groceryOrphanCount = 0;
  int duplicateCategoryIdCount = 0;
  int categoryNameIdMismatchCount = 0;
  int duplicateBudgetMonthCategoryCount = 0;
  int budgetMissingCategoryCount = 0;
  String? appVersionWarning;
  String? settingsWarning;
}
