import 'package:drift/drift.dart';
import '../../local/wallet_melt_database.dart' as local;
import '../../../types/payee.dart' as domain;

class DriftPayeeRepository {
  DriftPayeeRepository(this._db);

  final local.WalletMeltDatabase _db;

  Future<List<domain.Payee>> listAll() async {
    final rows = await (_db.select(_db.payees)
          ..orderBy([
            (t) => OrderingTerm(expression: t.name, mode: OrderingMode.asc),
          ]))
        .get();
    return rows.map(_payeeToDomain).toList();
  }

  Future<List<domain.Payee>> listActive() async {
    final rows = await (_db.select(_db.payees)
          ..where((t) => t.deletedAt.isNull() & t.isActive.equals(true))
          ..orderBy([
            (t) => OrderingTerm(expression: t.name, mode: OrderingMode.asc),
          ]))
        .get();
    return rows.map(_payeeToDomain).toList();
  }

  Future<domain.Payee?> getById(String id) async {
    final row = await (_db.select(_db.payees)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    if (row == null) return null;
    return _payeeToDomain(row);
  }

  Future<domain.Payee?> getByNormalizedName(String normalizedName) async {
    final row = await (_db.select(_db.payees)
          ..where((t) => t.normalizedName.equals(normalizedName)))
        .getSingleOrNull();
    if (row == null) return null;
    return _payeeToDomain(row);
  }

  Future<domain.Payee> create(domain.Payee payee) async {
    final normalized = _normalizeName(payee.name);
    
    // Check if a soft-deleted payee with the same normalized name exists
    final existing = await (_db.select(_db.payees)
          ..where((t) => t.normalizedName.equals(normalized)))
        .getSingleOrNull();

    if (existing != null) {
      // Reactivate the existing one instead of inserting a new one to prevent constraint violation
      final updated = existing.copyWith(
        name: payee.name,
        phone: Value(payee.phone),
        notes: Value(payee.notes),
        updatedAt: DateTime.now().toIso8601String(),
        deletedAt: const Value(null),
        isActive: true,
      );
      await _db.update(_db.payees).replace(updated);
      return _payeeToDomain(updated);
    }

    final companion = local.PayeesCompanion.insert(
      id: payee.id,
      name: payee.name,
      normalizedName: normalized,
      phone: Value(payee.phone),
      notes: Value(payee.notes),
      createdAt: payee.createdAt,
      updatedAt: payee.updatedAt,
      deletedAt: Value(payee.deletedAt),
      isActive: Value(payee.isActive),
    );

    await _db.into(_db.payees).insert(companion);
    return payee;
  }

  Future<void> update(domain.Payee payee) async {
    final normalized = _normalizeName(payee.name);
    await (_db.update(_db.payees)..where((t) => t.id.equals(payee.id))).write(
      local.PayeesCompanion(
        name: Value(payee.name),
        normalizedName: Value(normalized),
        phone: Value(payee.phone),
        notes: Value(payee.notes),
        updatedAt: Value(DateTime.now().toIso8601String()),
        deletedAt: Value(payee.deletedAt),
        isActive: Value(payee.isActive),
      ),
    );
  }

  Future<int> countLinkedTransactions(String payeeId) async {
    final row = await _db.customSelect(
      'SELECT COUNT(*) AS val FROM debt_records WHERE payeeId = ?;',
      variables: [Variable.withString(payeeId)],
    ).getSingle();
    return row.read<int>('val');
  }

  Future<void> delete(String id) async {
    final linkedCount = await countLinkedTransactions(id);
    final nowStr = DateTime.now().toIso8601String();
    
    if (linkedCount > 0) {
      // Mark inactive and hide from suggestions, preserving history
      await (_db.update(_db.payees)..where((t) => t.id.equals(id))).write(
        local.PayeesCompanion(
          isActive: const Value(false),
          updatedAt: Value(nowStr),
        ),
      );
    } else {
      // Soft delete: set deletedAt
      await (_db.update(_db.payees)..where((t) => t.id.equals(id))).write(
        local.PayeesCompanion(
          deletedAt: Value(nowStr),
          updatedAt: Value(nowStr),
        ),
      );
    }
  }

  Future<void> merge({required String keepId, required String duplicateId}) async {
    await _db.transaction(() async {
      final nowStr = DateTime.now().toIso8601String();

      // 1. Reassign all linked transactions in database
      await _db.customStatement(
        'UPDATE debt_records SET payeeId = ? WHERE payeeId = ?;',
        [keepId, duplicateId],
      );

      // 2. Load the duplicate payee to check its name (historical references)
      final duplicate = await (_db.select(_db.payees)
            ..where((t) => t.id.equals(duplicateId)))
          .getSingleOrNull();

      if (duplicate != null) {
        // 3. Update keep payee if needed (e.g. merge notes or phone if missing on keep but present on duplicate)
        final keep = await (_db.select(_db.payees)
              ..where((t) => t.id.equals(keepId)))
            .getSingleOrNull();

        if (keep != null) {
          String? mergedPhone = keep.phone;
          if ((mergedPhone == null || mergedPhone.isEmpty) && duplicate.phone != null) {
            mergedPhone = duplicate.phone;
          }

          String? mergedNotes = keep.notes;
          if (duplicate.notes != null && duplicate.notes!.isNotEmpty) {
            mergedNotes = (mergedNotes == null || mergedNotes.isEmpty)
                ? duplicate.notes
                : '$mergedNotes\nMerged notes: ${duplicate.notes}';
          }

          await (_db.update(_db.payees)..where((t) => t.id.equals(keepId))).write(
            local.PayeesCompanion(
              phone: Value(mergedPhone),
              notes: Value(mergedNotes),
              updatedAt: Value(nowStr),
            ),
          );
        }

        // 4. Delete or archive the duplicate. Since it now has 0 linked transactions, we can soft delete it or fully delete it.
        // The requirement says: "Delete or archive the duplicate." Let's soft delete or delete. Let's soft delete (set deletedAt).
        await (_db.update(_db.payees)..where((t) => t.id.equals(duplicateId))).write(
          local.PayeesCompanion(
            deletedAt: Value(nowStr),
            updatedAt: Value(nowStr),
            isActive: const Value(false),
          ),
        );
      }
    });
  }

  domain.Payee _payeeToDomain(local.Payee row) {
    return domain.Payee(
      id: row.id,
      name: row.name,
      phone: row.phone,
      notes: row.notes,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      deletedAt: row.deletedAt,
      isActive: row.isActive,
    );
  }

  String _normalizeName(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }
}
