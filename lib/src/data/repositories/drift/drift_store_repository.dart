import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../local/wallet_melt_database.dart' as local;

class DriftStoreRepository {
  DriftStoreRepository(this._db);

  final local.WalletMeltDatabase _db;
  final _uuid = const Uuid();

  String normalizeName(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  Future<local.Store> createOrGet({required String name, String? notes}) async {
    final trimmedName = name.trim();
    final normalizedName = normalizeName(trimmedName);
    final existing = await getByNormalizedName(normalizedName);
    if (existing != null) return existing;

    final now = DateTime.now().toIso8601String();
    final id = _uuid.v4();
    await _db.into(_db.stores).insert(
          local.StoresCompanion.insert(
            id: id,
            name: trimmedName,
            normalizedName: normalizedName,
            notes: Value(notes),
            createdAt: now,
            updatedAt: now,
          ),
        );
    return (await (_db.select(_db.stores)..where((store) => store.id.equals(id))).getSingle());
  }

  Future<local.Store?> getByNormalizedName(String normalizedName) {
    return (_db.select(_db.stores)..where((store) => store.normalizedName.equals(normalizedName))).getSingleOrNull();
  }
}
