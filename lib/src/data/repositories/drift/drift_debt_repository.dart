import 'package:drift/drift.dart';

import '../../local/wallet_melt_database.dart' as local;
import '../../../types/debt.dart' as domain;

class DriftDebtRepository {
  DriftDebtRepository(this._db);

  final local.WalletMeltDatabase _db;

  Future<List<domain.DebtRecord>> listAll() async {
    final rows = await (_db.select(_db.debtRecords)
          ..orderBy([
            (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
          ]))
        .get();
    return rows.map(_debtToDomain).toList();
  }

  Future<domain.DebtRecord?> getById(String id) async {
    final row = await (_db.select(_db.debtRecords)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    if (row == null) return null;
    return _debtToDomain(row);
  }

  Future<List<domain.DebtRepayment>> getRepayments(String debtId) async {
    final rows = await (_db.select(_db.debtRepayments)
          ..where((t) => t.debtId.equals(debtId))
          ..orderBy([
            (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.asc),
          ]))
        .get();
    return rows.map(_repaymentToDomain).toList();
  }

  Future<domain.DebtRecord> createDebt(domain.DebtRecord debt) async {
    final row = local.DebtRecordsCompanion.insert(
      id: debt.id,
      personName: debt.personName,
      payeeId: Value(debt.payeeId),
      type: debt.type.name,
      principalAmount: debt.principalAmount,
      remainingAmount: debt.remainingAmount,
      currency: debt.currency,
      description: Value(debt.description),
      createdAt: debt.createdAt,
      dueDate: Value(debt.dueDate),
      settledAt: Value(debt.settledAt),
      status: debt.status.name,
      notes: Value(debt.notes),
    );
    await _db.into(_db.debtRecords).insert(row);
    return debt;
  }

  Future<void> deleteDebt(String id) async {
    await (_db.delete(_db.debtRecords)..where((t) => t.id.equals(id))).go();
  }

  Future<void> addRepayment(domain.DebtRepayment repayment) async {
    await _db.transaction(() async {
      // Insert repayment
      final repaymentRow = local.DebtRepaymentsCompanion.insert(
        id: repayment.id,
        debtId: repayment.debtId,
        amount: repayment.amount,
        createdAt: repayment.createdAt,
        notes: Value(repayment.notes),
      );
      await _db.into(_db.debtRepayments).insert(repaymentRow);

      // Load existing debt record
      final debt = await (_db.select(_db.debtRecords)
            ..where((t) => t.id.equals(repayment.debtId)))
          .getSingle();

      final newRemaining = (debt.remainingAmount - repayment.amount).clamp(0.0, double.infinity);
      final isSettled = newRemaining <= 0;
      final newStatus = isSettled
          ? domain.DebtStatus.settled.name
          : domain.DebtStatus.partiallyPaid.name;

      final settledAtStr = isSettled ? DateTime.now().toIso8601String() : null;

      // Update remainingAmount, status and settledAt
      await (_db.update(_db.debtRecords)
            ..where((t) => t.id.equals(repayment.debtId)))
          .write(
        local.DebtRecordsCompanion(
          remainingAmount: Value(newRemaining),
          status: Value(newStatus),
          settledAt: Value(settledAtStr),
        ),
      );
    });
  }

  domain.DebtRecord _debtToDomain(local.DebtRecord row) {
    return domain.DebtRecord(
      id: row.id,
      personName: row.personName,
      payeeId: row.payeeId,
      type: domain.DebtType.values.firstWhere(
        (e) => e.name == row.type,
        orElse: () => row.type == 'lent' ? domain.DebtType.owedToMe : domain.DebtType.iOwe,
      ),
      principalAmount: row.principalAmount,
      remainingAmount: row.remainingAmount,
      currency: row.currency,
      description: row.description,
      createdAt: row.createdAt,
      dueDate: row.dueDate,
      settledAt: row.settledAt,
      status: domain.DebtStatus.values.firstWhere(
        (e) => e.name == row.status,
        orElse: () => domain.DebtStatus.active,
      ),
      notes: row.notes,
    );
  }

  domain.DebtRepayment _repaymentToDomain(local.DebtRepayment row) {
    return domain.DebtRepayment(
      id: row.id,
      debtId: row.debtId,
      amount: row.amount,
      createdAt: row.createdAt,
      notes: row.notes,
    );
  }
}
