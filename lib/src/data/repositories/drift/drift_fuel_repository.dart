import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../local/wallet_melt_database.dart' as local;
import '../../../types/fuel.dart';

class DriftFuelRepository {
  DriftFuelRepository(this._db);

  final local.WalletMeltDatabase _db;
  final _uuid = const Uuid();

  Future<FuelTransaction?> getByExpenseId(String expenseId) async {
    final txRow = await (_db.select(_db.fuelTransactions)
          ..where((row) => row.expenseId.equals(expenseId)))
        .getSingleOrNull();

    if (txRow == null) return null;

    final componentRows = await (_db.select(_db.fuelComponents)
          ..where((row) => row.fuelTransactionId.equals(txRow.id))
          ..orderBy([(row) => OrderingTerm(expression: row.createdAt)]))
        .get();

    final components = componentRows.map((row) {
      return FuelComponent(
        id: row.id,
        fuelTransactionId: row.fuelTransactionId,
        fuelType: FuelType.fromName(row.fuelType),
        quantityLitres: row.quantityLitres,
        pricePerLitre: row.pricePerLitre,
        subtotal: row.subtotal,
        createdAt: row.createdAt,
      );
    }).toList();

    return FuelTransaction(
      id: txRow.id,
      expenseId: txRow.expenseId,
      odometerReading: txRow.odometerReading,
      createdAt: txRow.createdAt,
      components: components,
    );
  }

  Future<FuelTransaction?> create(
      String expenseId, FuelTransactionDraft draft) async {
    if (draft.components.isEmpty) return null;

    final now = DateTime.now().toIso8601String();
    final txId = draft.id ?? _uuid.v4();

    final tx = FuelTransaction(
      id: txId,
      expenseId: expenseId,
      odometerReading: draft.odometerReading,
      createdAt: now,
    );

    await _db.transaction(() async {
      await _db.into(_db.fuelTransactions).insert(
            local.FuelTransactionsCompanion(
              id: Value(tx.id),
              expenseId: Value(tx.expenseId),
              odometerReading: Value(tx.odometerReading),
              createdAt: Value(tx.createdAt),
            ),
          );

      for (final compDraft in draft.components) {
        final compId = compDraft.id ?? _uuid.v4();
        await _db.into(_db.fuelComponents).insert(
              local.FuelComponentsCompanion(
                id: Value(compId),
                fuelTransactionId: Value(tx.id),
                fuelType: Value(compDraft.fuelType.name),
                quantityLitres: Value(compDraft.quantityLitres),
                pricePerLitre: Value(compDraft.pricePerLitre),
                subtotal: Value(compDraft.subtotal),
                createdAt: Value(now),
              ),
            );
      }
    });

    return getByExpenseId(expenseId);
  }

  Future<void> update(String expenseId, FuelTransactionDraft draft) async {
    await _db.transaction(() async {
      // Find existing transaction if any
      final existingTx = await (_db.select(_db.fuelTransactions)
            ..where((row) => row.expenseId.equals(expenseId)))
          .getSingleOrNull();

      if (draft.components.isEmpty) {
        if (existingTx != null) {
          await (_db.delete(_db.fuelTransactions)
                ..where((row) => row.id.equals(existingTx.id)))
              .go();
        }
        return;
      }

      final now = DateTime.now().toIso8601String();
      final txId = existingTx?.id ?? draft.id ?? _uuid.v4();

      if (existingTx == null) {
        await _db.into(_db.fuelTransactions).insert(
              local.FuelTransactionsCompanion(
                id: Value(txId),
                expenseId: Value(expenseId),
                odometerReading: Value(draft.odometerReading),
                createdAt: Value(now),
              ),
            );
      } else {
        await (_db.update(_db.fuelTransactions)
              ..where((row) => row.id.equals(existingTx.id)))
            .write(
          local.FuelTransactionsCompanion(
            odometerReading: Value(draft.odometerReading),
          ),
        );
        // Delete old components
        await (_db.delete(_db.fuelComponents)
              ..where((row) => row.fuelTransactionId.equals(existingTx.id)))
            .go();
      }

      // Insert new components
      for (final compDraft in draft.components) {
        final compId = compDraft.id ?? _uuid.v4();
        await _db.into(_db.fuelComponents).insert(
              local.FuelComponentsCompanion(
                id: Value(compId),
                fuelTransactionId: Value(txId),
                fuelType: Value(compDraft.fuelType.name),
                quantityLitres: Value(compDraft.quantityLitres),
                pricePerLitre: Value(compDraft.pricePerLitre),
                subtotal: Value(compDraft.subtotal),
                createdAt: Value(now),
              ),
            );
      }
    });
  }

  Future<void> deleteForExpense(String expenseId) async {
    await (_db.delete(_db.fuelTransactions)
          ..where((row) => row.expenseId.equals(expenseId)))
        .go();
  }

  Future<List<FuelTransaction>> listAll() async {
    final txRows = await _db.select(_db.fuelTransactions).get();
    final allComponents = await _db.select(_db.fuelComponents).get();

    final componentsByTx = <String, List<FuelComponent>>{};
    for (final row in allComponents) {
      componentsByTx.putIfAbsent(row.fuelTransactionId, () => []).add(
            FuelComponent(
              id: row.id,
              fuelTransactionId: row.fuelTransactionId,
              fuelType: FuelType.fromName(row.fuelType),
              quantityLitres: row.quantityLitres,
              pricePerLitre: row.pricePerLitre,
              subtotal: row.subtotal,
              createdAt: row.createdAt,
            ),
          );
    }

    return txRows.map((tx) {
      return FuelTransaction(
        id: tx.id,
        expenseId: tx.expenseId,
        odometerReading: tx.odometerReading,
        createdAt: tx.createdAt,
        components: componentsByTx[tx.id] ?? [],
      );
    }).toList();
  }
}
