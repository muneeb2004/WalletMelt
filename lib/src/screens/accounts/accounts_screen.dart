import 'package:flutter/material.dart';
import '../../widgets/fluid_list.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../components/account/compact_button_style.dart';
import '../../constants/currencies.dart';
import '../../state/app_state.dart';
import '../../theme/wallet_melt_theme.dart';
import '../../types/account.dart';
import '../../utils/currency_format.dart';
import '../../utils/number_parser.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/primary_button.dart';

IconData accountTypeIcon(AccountType type) => switch (type) {
      AccountType.cash => Icons.payments_outlined,
      AccountType.bank => Icons.account_balance_outlined,
      AccountType.wallet => Icons.account_balance_wallet_outlined,
    };

String accountTypeLabel(AccountType type) => switch (type) {
      AccountType.cash => 'Cash',
      AccountType.bank => 'Bank',
      AccountType.wallet => 'Wallet',
    };

/// Parses a typed money amount into minor units; null when not a number.
int? parseMinorUnits(String text) {
  final value = parseTolerantNumber(text);
  return value == null ? null : toMinorUnits(value);
}

class AccountsScreen extends StatelessWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final balances = state.accountBalances;
    final active = [for (final b in balances) if (!b.account.isArchived) b];
    final archived = [for (final b in balances) if (b.account.isArchived) b];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Accounts'),
        actions: [
          if (state.committeesAvailable)
            IconButton(
              tooltip: 'Committees',
              onPressed: () => context.push('/committees'),
              icon: const Icon(Icons.groups_outlined),
            ),
          if (state.goalsAvailable)
            TextButton.icon(
              onPressed: () => context.push('/goals'),
              icon: const Icon(Icons.savings_outlined),
              label: const Text('Goals'),
            ),
          if (state.incomeAvailable)
            TextButton.icon(
              onPressed: () => context.push('/income'),
              icon: const Icon(Icons.payments_outlined),
              label: const Text('Income'),
            ),
        ],
      ),
      floatingActionButton: state.accountsAvailable
          ? FloatingActionButton.extended(
              onPressed: () => showAccountEditorSheet(context),
              icon: const Icon(Icons.add),
              label: const Text('Add account'),
            )
          : null,
      body: !state.accountsAvailable
          ? const Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: EmptyState(
                icon: Icons.info_outline,
                title: 'Accounts are unavailable',
                subtitle:
                    'This device is using the legacy storage engine, which cannot track balances.',
              ),
            )
          : ListView(
              padding: FluidList.padding,
              physics: FluidList.physics,
              children: [
                if (active.isEmpty)
                  const EmptyState(
                    icon: Icons.account_balance_wallet_outlined,
                    title: 'Track your balance',
                    subtitle:
                        'Add an account, then log money in or out. Expenses and income you record update it for you.',
                  )
                else ...[
                  _TotalsCard(totals: state.accountTotals),
                  const SizedBox(height: AppSpacing.md),
                  if (state.unassignedExpenseCount > 0)
                    _UnassignedBanner(count: state.unassignedExpenseCount),
                  for (final (idx, b) in active.indexed) ...[
                    FluidItem(index: idx, child: _AccountTile(balance: b)),
                    const SizedBox(height: FluidList.gap),
                  ],
                  if (active.length > 1)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () => showTransferSheet(context),
                        icon: const Icon(Icons.swap_horiz),
                        label: const Text('Transfer between accounts'),
                      ),
                    ),
                ],
                if (archived.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text('Archived',
                      style: textTheme.titleMedium
                          ?.copyWith(color: scheme.onSurfaceVariant)),
                  const SizedBox(height: AppSpacing.sm),
                  for (final (idx, b) in archived.indexed) ...[
                    FluidItem(index: idx, child: _AccountTile(balance: b)),
                    const SizedBox(height: FluidList.gap),
                  ],
                ],
              ],
            ),
    );
  }
}

class _TotalsCard extends StatelessWidget {
  const _TotalsCard({required this.totals});

  final List<CurrencyTotal> totals;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return WMCard(
      tone: WMCardTone.brand,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Total balance',
              style: textTheme.bodyMedium
                  ?.copyWith(color: scheme.onPrimaryContainer)),
          const SizedBox(height: AppSpacing.xs),
          if (totals.isEmpty)
            Text('No accounts included in the total',
                style: textTheme.bodyMedium
                    ?.copyWith(color: scheme.onPrimaryContainer))
          else
            for (final t in totals)
              Text(
                formatMoneyMinorUnits(t.minorUnits, t.currency),
                style: withTabularFigures(textTheme.headlineMedium)
                    .copyWith(color: scheme.onPrimaryContainer),
              ),
        ],
      ),
    );
  }
}

class _UnassignedBanner extends StatelessWidget {
  const _UnassignedBanner({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: WMCard(
        tone: WMCardTone.outlined,
        child: Row(
          children: [
            Expanded(
              child: Text(
                '$count ${count == 1 ? 'expense is' : 'expenses are'} not linked to an account, so they do not change any balance.',
                style: textTheme.bodyMedium,
              ),
            ),
            TextButton(
              onPressed: () => showAssignUnassignedSheet(context),
              child: const Text('Assign'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountTile extends StatelessWidget {
  const _AccountTile({required this.balance});

  final AccountBalance balance;

  @override
  Widget build(BuildContext context) {
    final account = balance.account;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final negative = balance.balanceMinorUnits < 0;
    final reserved =
        context.read<AppState>().reservedByAccount[account.id] ?? 0;
    return WMCard(
      tone: WMCardTone.raised,
      onTap: () => showAccountDetailSheet(context, account.id),
      child: Row(
        children: [
          Icon(accountTypeIcon(account.type), color: scheme.primary),
          const SizedBox(width: AppSpacing.smMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(account.name, style: textTheme.titleMedium),
                Text(
                  [
                    accountTypeLabel(account.type),
                    if (!account.includeInTotal) 'Not in total',
                    if (reserved > 0)
                      '${formatMoneyMinorUnits(reserved, account.currency)} set aside',
                  ].join(' · '),
                  style: textTheme.bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Text(
            formatMoneyMinorUnits(balance.balanceMinorUnits, account.currency),
            style: withTabularFigures(textTheme.titleMedium).copyWith(
              color: negative ? scheme.error : scheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sheets ───────────────────────────────────────────────────────────────

Future<void> showAccountEditorSheet(BuildContext context, {Account? account}) {
  final state = context.read<AppState>();
  return showAppBottomSheet<void>(
    context,
    builder: (sheetContext) => _AccountEditor(state: state, account: account),
  );
}

class _AccountEditor extends StatefulWidget {
  const _AccountEditor({required this.state, this.account});

  final AppState state;
  final Account? account;

  @override
  State<_AccountEditor> createState() => _AccountEditorState();
}

class _AccountEditorState extends State<_AccountEditor> {
  late final TextEditingController _name;
  late final TextEditingController _opening;
  late AccountType _type;
  late String _currency;
  late bool _includeInTotal;
  String? _error;
  bool _currencyLocked = false;

  bool get _isEdit => widget.account != null;

  @override
  void initState() {
    super.initState();
    final a = widget.account;
    _name = TextEditingController(text: a?.name);
    _opening = TextEditingController(
        text: a == null
            ? ''
            : fromMinorUnits(a.openingBalanceMinorUnits).toStringAsFixed(2));
    _type = a?.type ?? AccountType.cash;
    _currency = a?.currency ?? widget.state.settings.currency;
    _includeInTotal = a?.includeInTotal ?? true;
    if (a != null) _checkLocked(a.id);
  }

  Future<void> _checkLocked(String id) async {
    final locked = await widget.state.accountHasTransactions(id);
    if (mounted) setState(() => _currencyLocked = locked);
  }

  @override
  void dispose() {
    _name.dispose();
    _opening.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Enter an account name.');
      return;
    }
    final opening =
        _opening.text.trim().isEmpty ? 0 : parseMinorUnits(_opening.text);
    if (opening == null) {
      setState(() => _error = 'Enter the balance as a number.');
      return;
    }
    final navigator = Navigator.of(context);
    try {
      final existing = widget.account;
      if (existing == null) {
        await widget.state.createAccount(
          name: name,
          type: _type,
          currency: _currency,
          openingBalanceMinorUnits: opening,
          includeInTotal: _includeInTotal,
        );
      } else {
        await widget.state.updateAccount(existing.copyWith(
          name: name,
          type: _type,
          currency: _currency,
          openingBalanceMinorUnits: opening,
          includeInTotal: _includeInTotal,
        ));
      }
      navigator.pop();
    } catch (error) {
      setState(() => _error = '$error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.smMd, AppSpacing.lg, AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_isEdit ? 'Edit account' : 'Add account',
              style: textTheme.titleLarge),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Name'),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _opening,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: _isEdit ? 'Opening balance' : 'Starting balance',
              helperText: _isEdit
                  ? 'Balance at the account start date, before logged expenses.'
                  : 'Optional. Leave it empty to start from zero.',
            ),
          ),
          ExpansionTile(
            key: const ValueKey('account-more-options'),
            tilePadding: EdgeInsets.zero,
            childrenPadding: EdgeInsets.zero,
            shape: const Border(),
            collapsedShape: const Border(),
            initiallyExpanded: _isEdit,
            title: const Text('More options'),
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SegmentedButton<AccountType>(
                showSelectedIcon: false,
                segments: [
                  for (final t in AccountType.values)
                    ButtonSegment(value: t, label: Text(accountTypeLabel(t))),
                ],
                selected: {_type},
                onSelectionChanged: (s) => setState(() => _type = s.first),
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<String>(
                initialValue: _currency,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'Currency',
                  helperText: _currencyLocked
                      ? 'Locked because this account has transactions.'
                      : null,
                ),
                items: [
                  for (final c in supportedCurrencies)
                    DropdownMenuItem(
                        value: c.code, child: Text('${c.code} · ${c.name}')),
                ],
                onChanged: _currencyLocked
                    ? null
                    : (v) => setState(() => _currency = v!),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Include in total balance'),
                value: _includeInTotal,
                onChanged: (v) => setState(() => _includeInTotal = v),
              ),
            ],
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Text(_error!,
                  style: textTheme.bodyMedium
                      ?.copyWith(color: Theme.of(context).colorScheme.error)),
            ),
          PrimaryButton(
              label: _isEdit ? 'Save changes' : 'Add account',
              onPressed: _save),
        ],
      ),
    );
  }
}

Future<void> showAccountDetailSheet(BuildContext context, String accountId) {
  final state = context.read<AppState>();
  return showAppBottomSheet<void>(
    context,
    builder: (sheetContext) =>
        _AccountDetail(state: state, accountId: accountId),
  );
}

class _AccountDetail extends StatefulWidget {
  const _AccountDetail({required this.state, required this.accountId});

  final AppState state;
  final String accountId;

  @override
  State<_AccountDetail> createState() => _AccountDetailState();
}

class _AccountDetailState extends State<_AccountDetail> {
  late Future<List<AccountMovement>> _movements;

  @override
  void initState() {
    super.initState();
    _movements = widget.state.accountMovements(widget.accountId);
  }

  void _reload() {
    final next = widget.state.accountMovements(widget.accountId);
    setState(() {
      _movements = next;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.state,
      builder: (context, _) {
        final balance = widget.state.accountBalances
            .where((b) => b.account.id == widget.accountId)
            .firstOrNull;
        if (balance == null) return const SizedBox(height: 120);
        final account = balance.account;
        final textTheme = Theme.of(context).textTheme;
        final scheme = Theme.of(context).colorScheme;
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.smMd, AppSpacing.lg, AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(account.name, style: textTheme.titleLarge),
              const SizedBox(height: AppSpacing.xs),
              Text(
                formatMoneyMinorUnits(balance.balanceMinorUnits, account.currency),
                style: withTabularFigures(textTheme.headlineMedium),
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  FilledButton.tonalIcon(
                    style: compactButtonStyle,
                    onPressed: account.isArchived
                        ? null
                        : () async {
                            await showAdjustSheet(context, account,
                                isCredit: true);
                            _reload();
                          },
                    icon: const Icon(Icons.add),
                    label: const Text('Add money'),
                  ),
                  FilledButton.tonalIcon(
                    style: compactButtonStyle,
                    onPressed: account.isArchived
                        ? null
                        : () async {
                            await showAdjustSheet(context, account,
                                isCredit: false);
                            _reload();
                          },
                    icon: const Icon(Icons.remove),
                    label: const Text('Spend money'),
                  ),
                  OutlinedButton.icon(
                    style: compactButtonStyle,
                    onPressed: account.isArchived
                        ? null
                        : () async {
                            await showTransferSheet(context,
                                fromAccountId: account.id);
                            _reload();
                          },
                    icon: const Icon(Icons.swap_horiz),
                    label: const Text('Transfer'),
                  ),
                  PopupMenuButton<String>(
                    tooltip: 'More',
                    onSelected: (value) async {
                      switch (value) {
                        case 'correct':
                          await showReconcileSheet(
                              context, account, balance.balanceMinorUnits);
                          _reload();
                        case 'edit':
                          await showAccountEditorSheet(context,
                              account: account);
                        case 'restore':
                          await widget.state.updateAccount(
                              account.copyWith(isArchived: false));
                        case 'remove':
                          await _confirmRemove(context, account);
                      }
                    },
                    itemBuilder: (_) => [
                      if (!account.isArchived)
                        const PopupMenuItem(
                            value: 'correct', child: Text('Correct balance')),
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                      if (account.isArchived)
                        const PopupMenuItem(
                            value: 'restore', child: Text('Restore'))
                      else
                        const PopupMenuItem(
                            value: 'remove', child: Text('Remove')),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Balance changes', style: textTheme.titleMedium),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Expenses linked to this account also change the balance; see History.',
                style: textTheme.bodySmall
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: AppSpacing.sm),
              FutureBuilder<List<AccountMovement>>(
                future: _movements,
                builder: (context, snap) {
                  final rows = snap.data ?? const [];
                  if (rows.isEmpty) {
                    return Text('No money added, spent or transferred yet.',
                        style: textTheme.bodyMedium);
                  }
                  return Column(
                    children: [
                      for (final m in rows)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(_movementLabel(m)),
                          subtitle: Text(m.date.substring(0, 10)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                formatMoneyMinorUnits(
                                    m.amountMinorUnits, account.currency),
                                style: withTabularFigures(textTheme.bodyLarge),
                              ),
                              IconButton(
                                tooltip: 'Delete',
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () async {
                                  final ok = await showConfirmDialog(
                                    context,
                                    title: 'Delete this entry?',
                                    body: m.transferGroupId == null
                                        ? 'The balance returns to what it was before.'
                                        : 'Both sides of this transfer will be removed.',
                                    confirmLabel: 'Delete',
                                    isDestructive: true,
                                  );
                                  if (ok != true) return;
                                  await widget.state
                                      .deleteAccountMovement(m.id);
                                  _reload();
                                },
                              ),
                            ],
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  String _movementLabel(AccountMovement m) => switch (m.kind) {
        AccountMovementKind.adjustment => m.notes ??
            (m.amountMinorUnits >= 0 ? 'Money added' : 'Money spent'),
        AccountMovementKind.transferIn => 'Transfer in',
        AccountMovementKind.transferOut => 'Transfer out',
      };

  Future<void> _confirmRemove(BuildContext context, Account account) async {
    final ok = await showConfirmDialog(
      context,
      title: 'Remove ${account.name}?',
      body:
          'Accounts with history are archived, not erased. Empty accounts are deleted.',
      confirmLabel: 'Remove',
      isDestructive: true,
    );
    if (ok != true || !context.mounted) return;
    final navigator = Navigator.of(context);
    await widget.state.deleteOrArchiveAccount(account.id);
    navigator.pop();
  }
}

/// Quick credit ([isCredit]) or debit entry: one amount, optional note.
Future<void> showAdjustSheet(BuildContext context, Account account,
    {required bool isCredit}) {
  final state = context.read<AppState>();
  final amount = TextEditingController();
  final note = TextEditingController();
  return showAppBottomSheet<void>(
    context,
    builder: (sheetContext) {
      final textTheme = Theme.of(sheetContext).textTheme;
      final scheme = Theme.of(sheetContext).colorScheme;
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.smMd, AppSpacing.lg, AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(isCredit ? 'Add money' : 'Spend money',
                style: textTheme.titleLarge),
            const SizedBox(height: AppSpacing.xs),
            Text(
              isCredit
                  ? 'Money coming into ${account.name}. For salary or allowance, use Income so it shows in your records.'
                  : 'Money leaving ${account.name} that you will not log as an expense. To count it in your budget, add it as an expense instead.',
              style: textTheme.bodyMedium
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: amount,
              autofocus: true,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                  labelText: 'Amount', prefixText: '${account.currency} '),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: note,
              textCapitalization: TextCapitalization.sentences,
              decoration:
                  const InputDecoration(labelText: 'Note (optional)'),
            ),
            const SizedBox(height: AppSpacing.md),
            PrimaryButton(
              label: isCredit ? 'Add money' : 'Spend money',
              onPressed: () async {
                final value = parseMinorUnits(amount.text);
                if (value == null || value <= 0) {
                  showErrorSnackbar(
                      sheetContext, 'Enter an amount greater than zero.');
                  return;
                }
                final navigator = Navigator.of(sheetContext);
                final text = note.text.trim();
                await state.adjustAccountBalance(
                  account.id,
                  isCredit ? value : -value,
                  notes: text.isEmpty ? null : text,
                );
                navigator.pop();
              },
            ),
          ],
        ),
      );
    },
  );
}

Future<void> showReconcileSheet(
    BuildContext context, Account account, int currentMinorUnits) {
  final state = context.read<AppState>();
  final controller = TextEditingController(
      text: fromMinorUnits(currentMinorUnits).toStringAsFixed(2));
  return showAppBottomSheet<void>(
    context,
    builder: (sheetContext) {
      final textTheme = Theme.of(sheetContext).textTheme;
      return Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.smMd, AppSpacing.lg, AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Correct balance', style: textTheme.titleLarge),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Enter what ${account.name} really holds now. WalletMelt records the difference as one adjustment you can delete later.',
              style: textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                  labelText: 'Actual balance', prefixText: '${account.currency} '),
            ),
            const SizedBox(height: AppSpacing.md),
            PrimaryButton(
              label: 'Correct balance',
              onPressed: () async {
                final actual = parseMinorUnits(controller.text);
                if (actual == null) {
                  showErrorSnackbar(sheetContext, 'Enter a number.');
                  return;
                }
                final navigator = Navigator.of(sheetContext);
                await state.reconcileAccount(account.id, actual);
                navigator.pop();
              },
            ),
          ],
        ),
      );
    },
  );
}

Future<void> showTransferSheet(BuildContext context, {String? fromAccountId}) {
  final state = context.read<AppState>();
  return showAppBottomSheet<void>(
    context,
    builder: (sheetContext) =>
        _TransferForm(state: state, initialFrom: fromAccountId),
  );
}

class _TransferForm extends StatefulWidget {
  const _TransferForm({required this.state, this.initialFrom});

  final AppState state;
  final String? initialFrom;

  @override
  State<_TransferForm> createState() => _TransferFormState();
}

class _TransferFormState extends State<_TransferForm> {
  final _amount = TextEditingController();
  final _received = TextEditingController();
  String? _from;
  String? _to;
  String? _error;

  List<Account> get _accounts => [
        for (final a in widget.state.accounts)
          if (!a.isArchived) a,
      ];

  Account? _byId(String? id) =>
      _accounts.where((a) => a.id == id).firstOrNull;

  @override
  void initState() {
    super.initState();
    _from = widget.initialFrom ?? _accounts.firstOrNull?.id;
    _to = _accounts.where((a) => a.id != _from).firstOrNull?.id;
  }

  @override
  void dispose() {
    _amount.dispose();
    _received.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final from = _byId(_from);
    final to = _byId(_to);
    if (from == null || to == null || from.id == to.id) {
      setState(() => _error = 'Choose two different accounts.');
      return;
    }
    final amount = parseMinorUnits(_amount.text);
    if (amount == null || amount <= 0) {
      setState(() => _error = 'Enter an amount greater than zero.');
      return;
    }
    int? received;
    if (from.currency != to.currency) {
      received = parseMinorUnits(_received.text);
      if (received == null || received <= 0) {
        setState(() => _error = 'Enter the amount received in ${to.currency}.');
        return;
      }
    }
    final navigator = Navigator.of(context);
    try {
      await widget.state.transferBetweenAccounts(
        fromAccountId: from.id,
        toAccountId: to.id,
        amountMinorUnits: amount,
        receivedMinorUnits: received,
      );
      navigator.pop();
    } catch (error) {
      setState(() => _error = '$error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final from = _byId(_from);
    final to = _byId(_to);
    final cross = from != null && to != null && from.currency != to.currency;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.smMd, AppSpacing.lg, AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Transfer', style: textTheme.titleLarge),
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<String>(
            initialValue: _from,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'From'),
            items: [
              for (final a in _accounts)
                DropdownMenuItem(value: a.id, child: Text(a.name)),
            ],
            onChanged: (v) => setState(() => _from = v),
          ),
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<String>(
            initialValue: _to,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'To'),
            items: [
              for (final a in _accounts)
                DropdownMenuItem(value: a.id, child: Text(a.name)),
            ],
            onChanged: (v) => setState(() => _to = v),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _amount,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: cross ? 'Amount sent' : 'Amount',
              prefixText: from == null ? null : '${from.currency} ',
            ),
          ),
          if (cross) ...[
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _received,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Amount received',
                prefixText: '${to.currency} ',
                helperText: 'The two accounts use different currencies.',
              ),
            ),
          ],
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Text(_error!,
                  style: textTheme.bodyMedium
                      ?.copyWith(color: Theme.of(context).colorScheme.error)),
            ),
          const SizedBox(height: AppSpacing.md),
          PrimaryButton(label: 'Transfer', onPressed: _submit),
        ],
      ),
    );
  }
}

Future<void> showAssignUnassignedSheet(BuildContext context) {
  final state = context.read<AppState>();
  final accounts = [
    for (final a in state.accounts)
      if (!a.isArchived) a,
  ];
  return showAppBottomSheet<void>(
    context,
    builder: (sheetContext) {
      final textTheme = Theme.of(sheetContext).textTheme;
      return Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.smMd, AppSpacing.lg, AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Assign existing expenses', style: textTheme.titleLarge),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Pick the account that paid for expenses without one. Only expenses in the same currency are linked, and only those dated on or after the account start date change its balance.',
              style: textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            for (final a in accounts)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(accountTypeIcon(a.type)),
                title: Text(a.name),
                subtitle: Text(a.currency),
                onTap: () async {
                  final navigator = Navigator.of(sheetContext);
                  final changed = await state.assignUnassignedExpensesTo(a.id);
                  navigator.pop();
                  if (context.mounted) {
                    showSuccessSnackbar(context,
                        'Linked $changed ${changed == 1 ? 'expense' : 'expenses'} to ${a.name}.');
                  }
                },
              ),
          ],
        ),
      );
    },
  );
}
