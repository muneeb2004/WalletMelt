import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_melt/src/security/ledger_integrity_service.dart';
import 'package:wallet_melt/src/types/budget.dart';
import 'package:wallet_melt/src/types/debt.dart';
import 'package:wallet_melt/src/types/expense.dart';
import 'package:wallet_melt/src/types/subscription.dart';

void main() {
  group('LedgerIntegrityService Hash-Chain Tests', () {
    late LedgerIntegrityService service;

    setUp(() {
      service = LedgerIntegrityService(
        macProvider: FallbackSoftwareMacProvider([1, 2, 3, 4, 5, 6, 7, 8]),
      );
    });

    test('Serializes full field coverage for Expense, Budget, Debt, and Subscription', () {
      const exp = Expense(
        id: 'exp_1',
        amount: 25.50,
        currency: 'USD',
        categoryId: 'cat_food',
        title: 'Grocery Run',
        date: '2026-06-15',
        isRecurring: false,
        createdAt: '2026-06-15T10:00:00Z',
        updatedAt: '2026-06-15T10:00:00Z',
        vendor: 'Supermarket',
        subtotalAmount: 23.00,
        taxAmount: 2.50,
      );

      final expSerialized = service.serializeExpense(exp);
      expect(expSerialized, contains('EXPENSE:exp_1|Grocery Run|25.5|USD|cat_food|Supermarket||2026-06-15|||0||23.0|2.5|2026-06-15T10:00:00Z|2026-06-15T10:00:00Z|'));

      const budget = CategoryBudget(
        id: 'bgt_1',
        categoryId: 'cat_food',
        amount: 500.0,
        currency: 'USD',
        month: '2026-06',
        createdAt: '2026-06-01T00:00:00Z',
        updatedAt: '2026-06-01T00:00:00Z',
      );
      final budgetSerialized = service.serializeBudget(budget);
      expect(budgetSerialized, 'BUDGET:bgt_1|cat_food|500.0|USD|2026-06|2026-06-01T00:00:00Z|2026-06-01T00:00:00Z');

      const debt = DebtRecord(
        id: 'debt_1',
        personName: 'Alice',
        type: DebtType.owedToMe,
        principalAmount: 100.0,
        remainingAmount: 50.0,
        currency: 'USD',
        createdAt: '2026-06-10T00:00:00Z',
        status: DebtStatus.partiallyPaid,
      );
      final debtSerialized = service.serializeDebt(debt);
      expect(debtSerialized, 'DEBT:debt_1|Alice||owedToMe|100.0|50.0|USD||||partiallyPaid|2026-06-10T00:00:00Z');

      const sub = Subscription(
        id: 'sub_1',
        name: 'Streaming Service',
        categoryId: 'cat_entertainment',
        amount: 14.99,
        currency: 'USD',
        startDate: '2026-01-01',
        nextOccurrenceDate: '2026-07-01',
        billingCycle: 'monthly',
        status: SubscriptionStatus.active,
        createdAt: '2026-01-01T00:00:00Z',
        updatedAt: '2026-06-01T00:00:00Z',
      );
      final subSerialized = service.serializeSubscription(sub);
      expect(subSerialized, 'SUB:sub_1|Streaming Service|cat_entertainment|14.99||USD|2026-01-01|2026-07-01|monthly|active|2026-01-01T00:00:00Z|2026-06-01T00:00:00Z||');
    });

    test('Computes hash chain and validates intact ledger cleanly', () async {
      final entries = [
        'ENTRY_1',
        'ENTRY_2',
        'ENTRY_3',
      ];

      final anchor = await service.computeAnchor(entries);
      expect(anchor.recordCount, 3);
      expect(anchor.blockHashHex.length, 64);

      final isValid = await service.verifyChain(
        serializedEntries: entries,
        expectedAnchor: anchor,
      );
      expect(isValid, isTrue);
    });

    test('Detects out-of-band row content modification', () async {
      final entries = [
        'ENTRY_1: amount=10.0',
        'ENTRY_2: amount=20.0',
        'ENTRY_3: amount=30.0',
      ];

      final anchor = await service.computeAnchor(entries);

      // Attacker tampers with row 2 amount
      final tamperedEntries = [
        'ENTRY_1: amount=10.0',
        'ENTRY_2: amount=500.0', // Tampered!
        'ENTRY_3: amount=30.0',
      ];

      final isValid = await service.verifyChain(
        serializedEntries: tamperedEntries,
        expectedAnchor: anchor,
      );
      expect(isValid, isFalse);
    });

    test('Detects silent row deletion (dropping an entry breaks hash chain and count)', () async {
      final entries = [
        'ENTRY_1',
        'ENTRY_2',
        'ENTRY_3',
      ];

      final anchor = await service.computeAnchor(entries);

      // Attacker silently deletes row 2 from SQLite
      final deletedEntries = [
        'ENTRY_1',
        'ENTRY_3',
      ];

      final isValid = await service.verifyChain(
        serializedEntries: deletedEntries,
        expectedAnchor: anchor,
      );
      expect(isValid, isFalse);
    });

    test('Detects unauthorized row insertion', () async {
      final entries = [
        'ENTRY_1',
        'ENTRY_2',
      ];

      final anchor = await service.computeAnchor(entries);

      // Attacker inserts an unauthorized row
      final insertedEntries = [
        'ENTRY_1',
        'ENTRY_2',
        'ENTRY_UNAUTHORIZED_3',
      ];

      final isValid = await service.verifyChain(
        serializedEntries: insertedEntries,
        expectedAnchor: anchor,
      );
      expect(isValid, isFalse);
    });

    test('Detects row reordering tampering', () async {
      final entries = [
        'ENTRY_1',
        'ENTRY_2',
        'ENTRY_3',
      ];

      final anchor = await service.computeAnchor(entries);

      // Reordered rows
      final reorderedEntries = [
        'ENTRY_2',
        'ENTRY_1',
        'ENTRY_3',
      ];

      final isValid = await service.verifyChain(
        serializedEntries: reorderedEntries,
        expectedAnchor: anchor,
      );
      expect(isValid, isFalse);
    });
  });
}
