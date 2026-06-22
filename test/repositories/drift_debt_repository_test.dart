import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_melt/src/data/local/wallet_melt_database.dart' hide DebtRecord, DebtRepayment;
import 'package:wallet_melt/src/data/repositories/drift/drift_debt_repository.dart';
import 'package:wallet_melt/src/types/debt.dart';

void main() {
  test('Debt CRUD, repayments tracking, and status transitions', () async {
    final db = WalletMeltDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repository = DriftDebtRepository(db);

    // 1. Create a Debt Record
    final debt = DebtRecord(
      id: 'debt-1',
      personName: 'Ali',
      type: DebtType.owedToMe,
      principalAmount: 10000,
      remainingAmount: 10000,
      currency: 'PKR',
      createdAt: DateTime.now().toIso8601String(),
      status: DebtStatus.active,
      description: 'Lent for groceries',
    );

    await repository.createDebt(debt);

    // Verify it exists
    final fetched = await repository.getById('debt-1');
    expect(fetched, isNotNull);
    expect(fetched!.personName, 'Ali');
    expect(fetched.type, DebtType.owedToMe);
    expect(fetched.principalAmount, 10000);
    expect(fetched.remainingAmount, 10000);
    expect(fetched.status, DebtStatus.active);

    // List all
    final allDebts = await repository.listAll();
    expect(allDebts.length, 1);
    expect(allDebts.first.id, 'debt-1');

    // 2. Add a partial repayment
    final repayment1 = DebtRepayment(
      id: 'pay-1',
      debtId: 'debt-1',
      amount: 4000,
      createdAt: DateTime.now().toIso8601String(),
      notes: 'First installment',
    );

    await repository.addRepayment(repayment1);

    // Verify outstanding balance and status
    final afterRepayment1 = await repository.getById('debt-1');
    expect(afterRepayment1!.remainingAmount, 6000);
    expect(afterRepayment1.status, DebtStatus.partiallyPaid);

    // Verify repayment records
    final repayments = await repository.getRepayments('debt-1');
    expect(repayments.length, 1);
    expect(repayments.first.amount, 4000);
    expect(repayments.first.notes, 'First installment');

    // 3. Add second repayment to settle the debt
    final repayment2 = DebtRepayment(
      id: 'pay-2',
      debtId: 'debt-1',
      amount: 6000,
      createdAt: DateTime.now().toIso8601String(),
      notes: 'Final settlement',
    );

    await repository.addRepayment(repayment2);

    final afterRepayment2 = await repository.getById('debt-1');
    expect(afterRepayment2!.remainingAmount, 0);
    expect(afterRepayment2.status, DebtStatus.settled);
    expect(afterRepayment2.settledAt, isNotNull);

    // 4. Delete debt
    await repository.deleteDebt('debt-1');
    expect(await repository.getById('debt-1'), isNull);
    expect(await repository.getRepayments('debt-1'), isEmpty);
  });
}
