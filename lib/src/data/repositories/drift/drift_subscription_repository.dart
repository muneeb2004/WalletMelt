import 'drift_expense_repository.dart';
import '../../../types/expense.dart' show ExpenseDraft;
import '../../../utils/currency_format.dart';
import 'package:drift/drift.dart';

import '../../local/wallet_melt_database.dart' as local;
import '../../../types/subscription.dart' as domain;

class DriftSubscriptionRepository {
  DriftSubscriptionRepository(this._db);

  final local.WalletMeltDatabase _db;

  Future<List<domain.Subscription>> listAll() async {
    final rows = await (_db.select(_db.subscriptions)
          ..where((t) => t.deletedAt.isNull())
          ..orderBy([
            (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
          ]))
        .get();
    return rows.map(_toDomain).toList();
  }

  Future<domain.Subscription?> getById(String id) async {
    final row = await (_db.select(_db.subscriptions)
          ..where((t) => t.id.equals(id) & t.deletedAt.isNull()))
        .getSingleOrNull();
    if (row == null) return null;
    return _toDomain(row);
  }

  Future<domain.Subscription> create(domain.Subscription sub) async {
    final row = local.SubscriptionsCompanion.insert(
      id: sub.id,
      name: sub.name,
      categoryId: sub.categoryId,
      amount: sub.amount,
      taxAmount: Value(sub.taxAmount),
      amountMinorUnits: Value(toMinorUnits(sub.amount)),
      taxAmountMinorUnits: Value(sub.taxAmount == null ? null : toMinorUnits(sub.taxAmount!)),
      currency: sub.currency,
      description: Value(sub.description),
      startDate: sub.startDate,
      nextOccurrenceDate: sub.nextOccurrenceDate,
      billingCycle: sub.billingCycle,
      status: sub.status.name,
      createdAt: sub.createdAt,
      updatedAt: sub.updatedAt,
      cancelledAt: Value(sub.cancelledAt),
      notificationOffset: Value(sub.notificationOffset),
      deletedAt: Value(sub.deletedAt),
      version: Value(sub.version),
      accountId: Value(sub.accountId),
    );
    await _db.into(_db.subscriptions).insert(row);
    return sub;
  }

  /// Creates every renewal expense and advances the subscription in ONE
  /// transaction: either all of it is saved or none of it, so a failure part
  /// way through can never leave expenses behind that a later run would
  /// generate again.
  Future<void> applyRenewals({
    required domain.Subscription updated,
    required List<ExpenseDraft> drafts,
    required DriftExpenseRepository expenseRepository,
  }) {
    return _db.transaction(() async {
      for (final draft in drafts) {
        await expenseRepository.create(draft);
      }
      await update(updated);
    });
  }

  Future<void> update(domain.Subscription sub) async {
    await (_db.update(_db.subscriptions)..where((t) => t.id.equals(sub.id)))
        .write(
      local.SubscriptionsCompanion(
        name: Value(sub.name),
        categoryId: Value(sub.categoryId),
        amount: Value(sub.amount),
        taxAmount: Value(sub.taxAmount),
        amountMinorUnits: Value(toMinorUnits(sub.amount)),
        taxAmountMinorUnits: Value(sub.taxAmount == null ? null : toMinorUnits(sub.taxAmount!)),
        currency: Value(sub.currency),
        description: Value(sub.description),
        startDate: Value(sub.startDate),
        nextOccurrenceDate: Value(sub.nextOccurrenceDate),
        billingCycle: Value(sub.billingCycle),
        status: Value(sub.status.name),
        createdAt: Value(sub.createdAt),
        updatedAt: Value(sub.updatedAt),
        cancelledAt: Value(sub.cancelledAt),
        notificationOffset: Value(sub.notificationOffset),
        deletedAt: Value(sub.deletedAt),
        version: Value(sub.version + 1),
        accountId: Value(sub.accountId),
      ),
    );
  }

  Future<void> delete(String id) async {
    final now = DateTime.now().toIso8601String();
    await (_db.update(_db.subscriptions)..where((t) => t.id.equals(id)))
        .write(
      local.SubscriptionsCompanion(
        deletedAt: Value(now),
        updatedAt: Value(now),
      ),
    );
  }

  domain.Subscription _toDomain(local.Subscription row) {
    return domain.Subscription(
      id: row.id,
      name: row.name,
      categoryId: row.categoryId,
      amount: row.amount,
      taxAmount: row.taxAmount,
      currency: row.currency,
      description: row.description,
      startDate: row.startDate,
      nextOccurrenceDate: row.nextOccurrenceDate,
      billingCycle: row.billingCycle,
      status: _statusFromName(row.status),
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      cancelledAt: row.cancelledAt,
      notificationOffset: row.notificationOffset,
      deletedAt: row.deletedAt,
      version: row.version,
      accountId: row.accountId,
    );
  }

  domain.SubscriptionStatus _statusFromName(String name) {
    for (final value in domain.SubscriptionStatus.values) {
      if (value.name == name) return value;
    }
    return domain.SubscriptionStatus.active;
  }
}
