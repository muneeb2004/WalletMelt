import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../local/wallet_melt_database.dart' as local;

class DriftReceiptRepository {
  DriftReceiptRepository(this._db);

  final local.WalletMeltDatabase _db;
  final _uuid = const Uuid();

  Future<local.Receipt> create({
    required String expenseId,
    required String uri,
    String? mimeType,
    int? fileSizeBytes,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now().toIso8601String();
    await _db.into(_db.receipts).insert(
          local.ReceiptsCompanion.insert(
            id: id,
            expenseId: expenseId,
            uri: uri,
            mimeType: Value(mimeType),
            fileSizeBytes: Value(fileSizeBytes),
            createdAt: now,
          ),
        );
    return (await (_db.select(_db.receipts)..where((receipt) => receipt.id.equals(id))).getSingle());
  }

  Future<List<local.Receipt>> listForExpense(String expenseId, {bool includeDeleted = false}) {
    final query = _db.select(_db.receipts)..where((receipt) => receipt.expenseId.equals(expenseId));
    if (!includeDeleted) {
      query.where((receipt) => receipt.deletedAt.isNull());
    }
    query.orderBy([
      (receipt) => OrderingTerm(expression: receipt.createdAt),
    ]);
    return query.get();
  }

  Future<void> softDelete(String id) async {
    await (_db.update(_db.receipts)..where((receipt) => receipt.id.equals(id))).write(
      local.ReceiptsCompanion(
        deletedAt: Value(DateTime.now().toIso8601String()),
      ),
    );
  }
}
