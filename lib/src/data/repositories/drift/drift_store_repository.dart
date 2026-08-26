import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../types/merchant.dart';
import '../../../utils/merchant_normalizer.dart';
import '../../local/wallet_melt_database.dart' as local;

class DriftStoreRepository {
  DriftStoreRepository(this._db);

  final local.WalletMeltDatabase _db;
  final _uuid = const Uuid();

  Merchant _toDomain(local.Store row) {
    return Merchant(
      id: row.id,
      name: row.name,
      normalizedName: row.normalizedName,
      defaultCategoryId: row.defaultCategoryId,
      notes: row.notes,
      isSaved: row.isSaved,
      isFavorite: row.isFavorite,
      lastUsedAt: row.lastUsedAt,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      archivedAt: row.archivedAt,
    );
  }

  String normalizeName(String value) => normalizeMerchantName(value);

  Future<Merchant?> getByNormalizedName(String normalizedName) async {
    final row = await (_db.select(_db.stores)
          ..where((store) => store.normalizedName.equals(normalizedName)))
        .getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  Future<Merchant?> getById(String id) async {
    final row = await (_db.select(_db.stores)
          ..where((store) => store.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  Future<List<Merchant>> listSavedMerchants() async {
    final rows = await (_db.select(_db.stores)
          ..where((store) => store.isSaved.equals(true) & store.archivedAt.isNull())
          ..orderBy([
            (s) => OrderingTerm(expression: s.isFavorite, mode: OrderingMode.desc),
            (s) => OrderingTerm(expression: s.name, mode: OrderingMode.asc),
          ]))
        .get();
    return rows.map(_toDomain).toList();
  }

  Future<List<Merchant>> getSuggestions({String? query, int limit = 8}) async {
    final trimmed = query?.trim() ?? '';
    final now = DateTime.now();

    if (trimmed.isEmpty) {
      final ninetyDaysAgo =
          now.subtract(const Duration(days: 90)).toIso8601String();

      final rows = await (_db.select(_db.stores)
            ..where((s) =>
                s.archivedAt.isNull() &
                (s.isSaved.equals(true) |
                    (s.lastUsedAt.isNotNull() &
                        s.lastUsedAt.isBiggerOrEqualValue(ninetyDaysAgo))))
            ..orderBy([
              (s) => OrderingTerm(expression: s.isFavorite, mode: OrderingMode.desc),
              (s) => OrderingTerm(expression: s.isSaved, mode: OrderingMode.desc),
              (s) => OrderingTerm(expression: s.lastUsedAt, mode: OrderingMode.desc),
              (s) => OrderingTerm(expression: s.name, mode: OrderingMode.asc),
            ])
            ..limit(limit))
          .get();
      return rows.map(_toDomain).toList();
    }

    final normalized = normalizeMerchantName(trimmed);

    // Prefix matches prioritized first, then substring matches
    final allMatches = await (_db.select(_db.stores)
          ..where((s) =>
              s.archivedAt.isNull() &
              (s.normalizedName.like('%$normalized%') |
                  s.name.like('%$trimmed%')))
          ..orderBy([
            (s) => OrderingTerm(expression: s.isFavorite, mode: OrderingMode.desc),
            (s) => OrderingTerm(expression: s.isSaved, mode: OrderingMode.desc),
            (s) => OrderingTerm(expression: s.lastUsedAt, mode: OrderingMode.desc),
            (s) => OrderingTerm(expression: s.name, mode: OrderingMode.asc),
          ])
          ..limit(limit * 2))
        .get();

    final domainMatches = allMatches.map(_toDomain).toList();

    domainMatches.sort((a, b) {
      final aPrefix = a.normalizedName.startsWith(normalized);
      final bPrefix = b.normalizedName.startsWith(normalized);
      if (aPrefix != bPrefix) {
        return aPrefix ? -1 : 1;
      }
      if (a.isFavorite != b.isFavorite) {
        return a.isFavorite ? -1 : 1;
      }
      if (a.isSaved != b.isSaved) {
        return a.isSaved ? -1 : 1;
      }
      final aLast = a.lastUsedAt ?? '';
      final bLast = b.lastUsedAt ?? '';
      if (aLast != bLast) {
        return bLast.compareTo(aLast);
      }
      return a.name.compareTo(b.name);
    });

    if (domainMatches.length > limit) {
      return domainMatches.sublist(0, limit);
    }
    return domainMatches;
  }

  Future<Merchant> saveMerchant({
    required String name,
    String? defaultCategoryId,
    String? notes,
    bool isFavorite = false,
  }) async {
    final trimmed = name.trim();
    final normalized = normalizeMerchantName(trimmed);
    final now = DateTime.now().toIso8601String();

    final existing = await (_db.select(_db.stores)
          ..where((s) => s.normalizedName.equals(normalized)))
        .getSingleOrNull();

    if (existing != null) {
      await (_db.update(_db.stores)..where((s) => s.id.equals(existing.id))).write(
        local.StoresCompanion(
          name: Value(trimmed),
          defaultCategoryId: Value(defaultCategoryId),
          notes: Value(notes),
          isSaved: const Value(true),
          isFavorite: Value(isFavorite),
          updatedAt: Value(now),
          archivedAt: const Value(null),
        ),
      );
      final updated = await (_db.select(_db.stores)
            ..where((s) => s.id.equals(existing.id)))
          .getSingle();
      return _toDomain(updated);
    }

    final id = _uuid.v4();
    await _db.into(_db.stores).insert(
          local.StoresCompanion.insert(
            id: id,
            name: trimmed,
            normalizedName: normalized,
            defaultCategoryId: Value(defaultCategoryId),
            notes: Value(notes),
            isSaved: const Value(true),
            isFavorite: Value(isFavorite),
            createdAt: now,
            updatedAt: now,
          ),
        );
    final created = await (_db.select(_db.stores)
          ..where((s) => s.id.equals(id)))
        .getSingle();
    return _toDomain(created);
  }

  Future<Merchant> updateMerchant(Merchant merchant) async {
    final trimmed = merchant.name.trim();
    final normalized = normalizeMerchantName(trimmed);
    final now = DateTime.now().toIso8601String();

    // Check collision with other merchants
    final duplicate = await (_db.select(_db.stores)
          ..where((s) =>
              s.normalizedName.equals(normalized) &
              s.id.equals(merchant.id).not()))
        .getSingleOrNull();

    if (duplicate != null) {
      // Merge into the duplicate
      final nextFavorite = merchant.isFavorite || duplicate.isFavorite;
      await (_db.update(_db.stores)..where((s) => s.id.equals(duplicate.id))).write(
        local.StoresCompanion(
          name: Value(trimmed),
          defaultCategoryId: Value(merchant.defaultCategoryId ?? duplicate.defaultCategoryId),
          notes: Value(merchant.notes ?? duplicate.notes),
          isSaved: const Value(true),
          isFavorite: Value(nextFavorite),
          updatedAt: Value(now),
          archivedAt: const Value(null),
        ),
      );
      // Clean up the obsolete record
      await (_db.delete(_db.stores)..where((s) => s.id.equals(merchant.id))).go();
      final updated = await (_db.select(_db.stores)
            ..where((s) => s.id.equals(duplicate.id)))
          .getSingle();
      return _toDomain(updated);
    }

    await (_db.update(_db.stores)..where((s) => s.id.equals(merchant.id))).write(
      local.StoresCompanion(
        name: Value(trimmed),
        normalizedName: Value(normalized),
        defaultCategoryId: Value(merchant.defaultCategoryId),
        notes: Value(merchant.notes),
        isSaved: Value(merchant.isSaved),
        isFavorite: Value(merchant.isSaved ? merchant.isFavorite : false),
        updatedAt: Value(now),
        archivedAt: Value(merchant.archivedAt),
      ),
    );
    final updated = await (_db.select(_db.stores)
          ..where((s) => s.id.equals(merchant.id)))
        .getSingle();
    return _toDomain(updated);
  }

  Future<String?> recordMerchantHistory(String merchantName) async {
    final trimmed = merchantName.trim();
    if (trimmed.isEmpty) return null;

    final normalized = normalizeMerchantName(trimmed);
    final now = DateTime.now().toIso8601String();

    final existing = await (_db.select(_db.stores)
          ..where((s) => s.normalizedName.equals(normalized)))
        .getSingleOrNull();

    if (existing != null) {
      await (_db.update(_db.stores)..where((s) => s.id.equals(existing.id))).write(
        local.StoresCompanion(
          lastUsedAt: Value(now),
          updatedAt: Value(now),
        ),
      );
      return existing.id;
    }

    final id = _uuid.v4();
    await _db.into(_db.stores).insert(
          local.StoresCompanion.insert(
            id: id,
            name: trimmed,
            normalizedName: normalized,
            isSaved: const Value(false),
            isFavorite: const Value(false),
            lastUsedAt: Value(now),
            createdAt: now,
            updatedAt: now,
          ),
        );
    return id;
  }

  Future<void> archiveMerchant(String id) async {
    final now = DateTime.now().toIso8601String();
    await (_db.update(_db.stores)..where((s) => s.id.equals(id))).write(
      local.StoresCompanion(
        archivedAt: Value(now),
        updatedAt: Value(now),
      ),
    );
  }

  Future<void> restoreMerchant(String id) async {
    final now = DateTime.now().toIso8601String();
    await (_db.update(_db.stores)..where((s) => s.id.equals(id))).write(
      local.StoresCompanion(
        archivedAt: const Value(null),
        updatedAt: Value(now),
      ),
    );
  }

  Future<Merchant?> toggleFavorite(String id) async {
    final existing = await getById(id);
    if (existing == null) return null;

    final nextFavorite = !existing.isFavorite;
    final nextSaved = nextFavorite ? true : existing.isSaved;
    final now = DateTime.now().toIso8601String();

    await (_db.update(_db.stores)..where((s) => s.id.equals(id))).write(
      local.StoresCompanion(
        isFavorite: Value(nextFavorite),
        isSaved: Value(nextSaved),
        updatedAt: Value(now),
      ),
    );
    return getById(id);
  }

  Future<local.Store> createOrGet({required String name, String? notes}) async {
    final storeId = await recordMerchantHistory(name);
    return (await (_db.select(_db.stores)..where((s) => s.id.equals(storeId!))).getSingle());
  }
}
