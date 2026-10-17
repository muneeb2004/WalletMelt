enum AccountType { cash, bank, wallet, card, other }

enum AccountMovementKind { adjustment, transferIn, transferOut }

extension AccountMovementKindStorage on AccountMovementKind {
  String get storageName => switch (this) {
        AccountMovementKind.adjustment => 'adjustment',
        AccountMovementKind.transferIn => 'transfer_in',
        AccountMovementKind.transferOut => 'transfer_out',
      };

  static AccountMovementKind fromStorage(String value) => switch (value) {
        'transfer_in' => AccountMovementKind.transferIn,
        'transfer_out' => AccountMovementKind.transferOut,
        _ => AccountMovementKind.adjustment,
      };
}

AccountType accountTypeFromName(String? name) {
  for (final value in AccountType.values) {
    if (value.name == name) return value;
  }
  return AccountType.other;
}

class Account {
  const Account({
    required this.id,
    required this.name,
    required this.type,
    required this.currency,
    required this.openingBalanceMinorUnits,
    required this.openingDate,
    required this.createdAt,
    required this.updatedAt,
    this.iconKey,
    this.colorRole,
    this.sortOrder = 0,
    this.isArchived = false,
    this.includeInTotal = true,
    this.deletedAt,
  });

  final String id;
  final String name;
  final AccountType type;
  final String currency;
  final int openingBalanceMinorUnits;

  /// ISO-8601 date at local midnight, same format as `Expense.date`.
  final String openingDate;
  final String? iconKey;

  /// Name of a `ColorScheme` role (never a hex value).
  final String? colorRole;
  final int sortOrder;
  final bool isArchived;
  final bool includeInTotal;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;

  Account copyWith({
    String? name,
    AccountType? type,
    String? currency,
    int? openingBalanceMinorUnits,
    String? openingDate,
    String? iconKey,
    String? colorRole,
    int? sortOrder,
    bool? isArchived,
    bool? includeInTotal,
    String? updatedAt,
    String? deletedAt,
  }) {
    return Account(
      id: id,
      name: name ?? this.name,
      type: type ?? this.type,
      currency: currency ?? this.currency,
      openingBalanceMinorUnits:
          openingBalanceMinorUnits ?? this.openingBalanceMinorUnits,
      openingDate: openingDate ?? this.openingDate,
      iconKey: iconKey ?? this.iconKey,
      colorRole: colorRole ?? this.colorRole,
      sortOrder: sortOrder ?? this.sortOrder,
      isArchived: isArchived ?? this.isArchived,
      includeInTotal: includeInTotal ?? this.includeInTotal,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Account &&
          id == other.id &&
          name == other.name &&
          type == other.type &&
          currency == other.currency &&
          openingBalanceMinorUnits == other.openingBalanceMinorUnits &&
          openingDate == other.openingDate &&
          iconKey == other.iconKey &&
          colorRole == other.colorRole &&
          sortOrder == other.sortOrder &&
          isArchived == other.isArchived &&
          includeInTotal == other.includeInTotal &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt &&
          deletedAt == other.deletedAt;

  @override
  int get hashCode => Object.hash(
        id,
        name,
        type,
        currency,
        openingBalanceMinorUnits,
        openingDate,
        iconKey,
        colorRole,
        sortOrder,
        isArchived,
        includeInTotal,
        createdAt,
        updatedAt,
        deletedAt,
      );
}

class AccountMovement {
  const AccountMovement({
    required this.id,
    required this.accountId,
    required this.kind,
    required this.amountMinorUnits,
    required this.date,
    required this.createdAt,
    required this.updatedAt,
    this.transferGroupId,
    this.notes,
    this.deletedAt,
  });

  final String id;
  final String accountId;
  final AccountMovementKind kind;

  /// Signed: positive adds to the account, negative removes.
  final int amountMinorUnits;
  final String date;
  final String? transferGroupId;
  final String? notes;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;
}

/// Derived balance of one account (ADR-0011). Never persisted.
class AccountBalance {
  const AccountBalance({
    required this.account,
    required this.balanceMinorUnits,
  });

  final Account account;
  final int balanceMinorUnits;
}

/// Sum of included, non-archived account balances for one currency.
class CurrencyTotal {
  const CurrencyTotal({required this.currency, required this.minorUnits});

  final String currency;
  final int minorUnits;
}
