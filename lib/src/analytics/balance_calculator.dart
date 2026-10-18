import '../types/account.dart';

/// Pure balance rules from ADR-0011. The repository supplies SQL aggregates;
/// this class owns the formula so it can be tested and documented in one place.
///
/// `balance = openingBalance - expenseOutflow + movementNet + incomeInflow
/// + debtNet` (ADR-0011, ADR-0012, ADR-0014), where all sums
/// only cover rows dated on/after the account's opening date and (for expenses)
/// whose currency equals the account currency.
class BalanceCalculator {
  const BalanceCalculator._();

  static int balanceMinorUnits({
    required int openingBalanceMinorUnits,
    required int expenseOutflowMinorUnits,
    required int movementNetMinorUnits,
    int incomeInflowMinorUnits = 0,
    int debtNetMinorUnits = 0,
  }) {
    return openingBalanceMinorUnits -
        expenseOutflowMinorUnits +
        movementNetMinorUnits +
        incomeInflowMinorUnits +
        debtNetMinorUnits;
  }

  /// One total per currency over accounts that are included, not archived and
  /// not deleted. Currencies are never converted or mixed.
  static List<CurrencyTotal> totalsByCurrency(Iterable<AccountBalance> balances) {
    final sums = <String, int>{};
    for (final b in balances) {
      final a = b.account;
      if (!a.includeInTotal || a.isArchived || a.deletedAt != null) continue;
      sums[a.currency] = (sums[a.currency] ?? 0) + b.balanceMinorUnits;
    }
    final currencies = sums.keys.toList()..sort();
    return [
      for (final c in currencies) CurrencyTotal(currency: c, minorUnits: sums[c]!),
    ];
  }

  /// Signed adjustment needed to make [currentMinorUnits] equal the balance the
  /// user actually sees in their bank/wallet/cash.
  static int reconcileDelta({
    required int currentMinorUnits,
    required int actualMinorUnits,
  }) {
    return actualMinorUnits - currentMinorUnits;
  }
}
