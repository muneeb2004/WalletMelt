import 'package:flutter/material.dart';
import '../../widgets/fluid_list.dart';
import 'package:provider/provider.dart';

import '../../analytics/committee_planner.dart';
import '../../components/account/choose_account_sheet.dart';
import '../../components/account/compact_button_style.dart';
import '../../state/app_state.dart';
import '../../theme/wallet_melt_theme.dart';
import '../../types/account.dart';
import '../../types/committee.dart';
import '../../utils/currency_format.dart';
import '../../utils/number_parser.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/progress_bar.dart';

String _dateLabel(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

class CommitteesScreen extends StatelessWidget {
  const CommitteesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final all = state.committeeProgress;
    final active = [for (final p in all) if (p.committee.isActive) p];
    final closed = [for (final p in all) if (!p.committee.isActive) p];
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Committees')),
      floatingActionButton: state.committeesAvailable
          ? FloatingActionButton.extended(
              onPressed: () => showCommitteeEditorSheet(context),
              icon: const Icon(Icons.add),
              label: const Text('Add committee'),
            )
          : null,
      body: !state.committeesAvailable
          ? const Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: EmptyState(
                icon: Icons.info_outline,
                title: 'Committees are unavailable',
                subtitle:
                    'This device is using the legacy storage engine, which cannot track committees.',
              ),
            )
          : ListView(
              padding: FluidList.padding,
              physics: FluidList.physics,
              children: [
                if (all.isEmpty)
                  const EmptyState(
                    icon: Icons.groups_outlined,
                    title: 'Track your committee',
                    subtitle:
                        'Add your BC with the monthly amount and the month you receive the pot. WalletMelt reminds you to confirm each installment and your payout.',
                  ),
                for (final (idx, p) in active.indexed) ...[
                  FluidItem(index: idx, child: _CommitteeTile(progress: p)),
                  const SizedBox(height: FluidList.gap),
                ],
                if (closed.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text('Finished and archived',
                      style: textTheme.titleMedium
                          ?.copyWith(color: scheme.onSurfaceVariant)),
                  const SizedBox(height: AppSpacing.sm),
                  for (final (idx, p) in closed.indexed) ...[
                    FluidItem(index: idx, child: _CommitteeTile(progress: p)),
                    const SizedBox(height: FluidList.gap),
                  ],
                ],
              ],
            ),
    );
  }
}

class _CommitteeTile extends StatelessWidget {
  const _CommitteeTile({required this.progress});

  final CommitteeProgress progress;

  @override
  Widget build(BuildContext context) {
    final c = progress.committee;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final next = progress.nextInstallmentMonth;
    final statusText = switch (c.status) {
      CommitteeStatus.completed => 'Completed',
      CommitteeStatus.archived => 'Archived',
      CommitteeStatus.active => null,
    };
    return WMCard(
      tone: WMCardTone.raised,
      onTap: () => showCommitteeDetailSheet(context, c.id),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(c.name, style: textTheme.titleMedium)),
              if (statusText != null)
                Text(statusText,
                    style: textTheme.labelMedium?.copyWith(color: scheme.primary)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ProgressBar(
            fraction: c.memberCount == 0 ? 0 : progress.paidCount / c.memberCount,
            color: scheme.primary,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Paid ${progress.paidCount} of ${c.memberCount} · ${formatMoneyMinorUnits(c.monthlyMinorUnits, c.currency)} a month',
            style: withTabularFigures(textTheme.bodyMedium),
          ),
          Text(
            [
              'Your payout: month ${c.payoutMonth}'
                  '${progress.payoutReceived ? ' (received)' : ''}',
              if (next != null && c.isActive)
                'next ${_dateLabel(CommitteePlanner.dueDate(c, next))}',
            ].join(' · '),
            style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

// ── Sheets ───────────────────────────────────────────────────────────────

Future<void> showCommitteeEditorSheet(BuildContext context) {
  final state = context.read<AppState>();
  return showAppBottomSheet<void>(
    context,
    builder: (_) => _CommitteeEditor(state: state),
  );
}

class _CommitteeEditor extends StatefulWidget {
  const _CommitteeEditor({required this.state});

  final AppState state;

  @override
  State<_CommitteeEditor> createState() => _CommitteeEditorState();
}

class _CommitteeEditorState extends State<_CommitteeEditor> {
  final _name = TextEditingController();
  final _monthly = TextEditingController();
  final _members = TextEditingController(text: '10');
  final _pot = TextEditingController();
  int _turn = 1;
  DateTime _start = DateTime.now();
  String? _accountId;
  String? _error;

  int get _memberCount => int.tryParse(_members.text.trim()) ?? 0;

  List<Account> get _accounts => [
        for (final a in widget.state.accounts)
          if (!a.isArchived && a.currency == widget.state.settings.currency) a,
      ];

  @override
  void dispose() {
    _name.dispose();
    _monthly.dispose();
    _members.dispose();
    _pot.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _start,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _start = picked);
  }

  Future<void> _save() async {
    final monthly = parseTolerantNumber(_monthly.text);
    final members = _memberCount;
    if (_name.text.trim().isEmpty) {
      setState(() => _error = 'Give the committee a name.');
      return;
    }
    if (monthly == null || monthly <= 0) {
      setState(() => _error = 'Enter your monthly installment.');
      return;
    }
    if (members < 2 || members > 60) {
      setState(() => _error = 'Members must be between 2 and 60.');
      return;
    }
    if (_turn < 1 || _turn > members) {
      setState(() => _error = 'Your payout month must be within 1 and $members.');
      return;
    }
    int? pot;
    if (_pot.text.trim().isNotEmpty) {
      final v = parseTolerantNumber(_pot.text);
      if (v == null || v <= 0) {
        setState(() => _error = 'Enter the payout amount as a number.');
        return;
      }
      pot = toMinorUnits(v);
    }
    final navigator = Navigator.of(context);
    try {
      await widget.state.createCommittee(
        name: _name.text,
        monthlyMinorUnits: toMinorUnits(monthly),
        memberCount: members,
        payoutMonth: _turn,
        startDate: _start,
        payoutMinorUnits: pot,
        accountId: _accountId,
      );
      navigator.pop();
    } catch (error) {
      setState(() => _error = '$error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final currency = widget.state.settings.currency;
    final members = _memberCount.clamp(0, 60);
    final turn = _turn > members && members > 0 ? members : _turn;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.smMd, AppSpacing.lg, AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Add committee', style: textTheme.titleLarge),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Name'),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _monthly,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
                labelText: 'Your monthly installment', prefixText: '$currency '),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _members,
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(labelText: 'Number of members'),
          ),
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<int>(
            key: ValueKey('turn-$members'),
            initialValue: members >= 1 ? turn.clamp(1, members) : null,
            decoration: const InputDecoration(labelText: 'Your payout month'),
            items: [
              for (var k = 1; k <= members; k++)
                DropdownMenuItem(value: k, child: Text('Month $k')),
            ],
            onChanged: (v) => setState(() => _turn = v ?? 1),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _pot,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Payout amount (optional)',
              prefixText: '$currency ',
              helperText: 'Leave empty to use monthly amount times members.',
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton.icon(
            style: compactButtonStyle,
            onPressed: _pickDate,
            icon: const Icon(Icons.event_outlined),
            label: Text('First installment: ${_dateLabel(_start)}'),
          ),
          if (_accounts.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<String?>(
              key: const ValueKey('committee-account'),
              initialValue: _accountId,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Account (optional)',
                helperText:
                    'Installments leave it and your payout arrives in it.',
              ),
              items: [
                const DropdownMenuItem<String?>(
                    value: null, child: Text('No account')),
                for (final a in _accounts)
                  DropdownMenuItem<String?>(value: a.id, child: Text(a.name)),
              ],
              onChanged: (v) => setState(() => _accountId = v),
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
          PrimaryButton(label: 'Add committee', onPressed: _save),
        ],
      ),
    );
  }
}

Future<void> showCommitteeDetailSheet(BuildContext context, String id) {
  final state = context.read<AppState>();
  return showAppBottomSheet<void>(
    context,
    builder: (_) => _CommitteeDetail(state: state, committeeId: id),
  );
}

class _CommitteeDetail extends StatelessWidget {
  const _CommitteeDetail({required this.state, required this.committeeId});

  final AppState state;
  final String committeeId;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: state,
      builder: (context, _) {
        final progress = state.committeeProgress
            .where((p) => p.committee.id == committeeId)
            .firstOrNull;
        if (progress == null) return const SizedBox(height: 120);
        final c = progress.committee;
        final textTheme = Theme.of(context).textTheme;
        final scheme = Theme.of(context).colorScheme;
        final accountName = state.accounts
            .where((a) => a.id == c.accountId)
            .map((a) => a.name)
            .firstOrNull;
        final paid = progress.paidMonths;
        final today = DateTime.now();
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.smMd, AppSpacing.lg, AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(c.name, style: textTheme.titleLarge),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Pays ${formatMoneyMinorUnits(c.totalToPayMinorUnits, c.currency)} in total, '
                'receives ${formatMoneyMinorUnits(c.payoutMinorUnits, c.currency)} in month ${c.payoutMonth}.',
                style: textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  if (state.accountsAvailable)
                    OutlinedButton.icon(
                      style: compactButtonStyle,
                      icon: const Icon(Icons.account_balance_wallet_outlined),
                      label: Text(accountName == null
                          ? 'Link to an account'
                          : 'Account: $accountName'),
                      onPressed: () => showChooseAccountSheet(
                        context,
                        accounts: state.accounts,
                        currency: c.currency,
                        currentAccountId: c.accountId,
                        title: 'Account for this committee',
                        explanation:
                            'Recorded installments leave this account and your payout arrives in it.',
                        onSelected: (id) => state.setCommitteeAccount(c.id, id),
                      ),
                    ),
                  if (c.status == CommitteeStatus.archived)
                    OutlinedButton.icon(
                      style: compactButtonStyle,
                      icon: const Icon(Icons.unarchive_outlined),
                      label: const Text('Reopen'),
                      onPressed: () => state.reopenCommittee(c.id),
                    )
                  else
                    OutlinedButton.icon(
                      style: compactButtonStyle,
                      icon: const Icon(Icons.archive_outlined),
                      label: const Text('Archive'),
                      onPressed: () async {
                        final navigator = Navigator.of(context);
                        await state.archiveCommittee(c.id);
                        navigator.pop();
                      },
                    ),
                  OutlinedButton.icon(
                    style: compactButtonStyle,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Delete'),
                    onPressed: () async {
                      final ok = await showConfirmDialog(
                        context,
                        title: 'Delete ${c.name}?',
                        body:
                            'The committee and its history are removed, and any account balance effect goes with it.',
                        confirmLabel: 'Delete',
                        isDestructive: true,
                      );
                      if (ok != true || !context.mounted) return;
                      final navigator = Navigator.of(context);
                      await state.deleteCommittee(c.id);
                      navigator.pop();
                    },
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Months', style: textTheme.titleMedium),
              const SizedBox(height: AppSpacing.xs),
              for (var k = 1; k <= c.memberCount; k++)
                _MonthRow(
                  state: state,
                  progress: progress,
                  month: k,
                  paid: paid.contains(k),
                  due: CommitteePlanner.dueDate(c, k),
                  today: today,
                  scheme: scheme,
                ),
            ],
          ),
        );
      },
    );
  }
}

class _MonthRow extends StatelessWidget {
  const _MonthRow({
    required this.state,
    required this.progress,
    required this.month,
    required this.paid,
    required this.due,
    required this.today,
    required this.scheme,
  });

  final AppState state;
  final CommitteeProgress progress;
  final int month;
  final bool paid;
  final DateTime due;
  final DateTime today;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final c = progress.committee;
    final textTheme = Theme.of(context).textTheme;
    final isTurn = month == c.payoutMonth;
    final installment = progress.events
        .where((e) =>
            e.kind == CommitteeEventKind.installment &&
            e.monthIndex == month &&
            e.deletedAt == null)
        .firstOrNull;
    final isDue = !due.isAfter(DateTime(today.year, today.month, today.day));
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        paid ? Icons.check_circle : Icons.radio_button_unchecked,
        color: paid ? scheme.primary : scheme.outline,
      ),
      title: Text('Month $month${isTurn ? ' · your payout' : ''}'),
      subtitle: Text(
        paid
            ? 'Paid ${formatMoneyMinorUnits(installment?.amountMinorUnits ?? c.monthlyMinorUnits, c.currency)}'
            : '${isDue ? 'Due' : 'Due on'} ${_dateLabel(due)}',
        style: textTheme.bodySmall,
      ),
      trailing: Wrap(
        spacing: AppSpacing.xs,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          if (!paid && c.status != CommitteeStatus.archived)
            TextButton(
              onPressed: () async {
                try {
                  await state.recordCommitteeInstallment(c.id, month);
                } catch (e) {
                  if (context.mounted) showErrorSnackbar(context, '$e');
                }
              },
              child: const Text('Mark paid'),
            ),
          if (paid && installment != null)
            IconButton(
              tooltip: 'Undo',
              icon: const Icon(Icons.undo),
              onPressed: () => state.undoCommitteeEvent(installment.id),
            ),
          if (isTurn && !progress.payoutReceived && c.status != CommitteeStatus.archived)
            TextButton(
              onPressed: () => showConfirmPayoutSheet(context, c),
              child: const Text('Received'),
            ),
          if (isTurn && progress.payoutReceived)
            IconButton(
              tooltip: 'Undo payout',
              icon: const Icon(Icons.undo),
              onPressed: () =>
                  state.undoCommitteeEvent(progress.payoutEvent!.id),
            ),
        ],
      ),
    );
  }
}

/// Asks the user to confirm an installment with an editable amount.
Future<void> showConfirmInstallmentSheet(
    BuildContext context, Committee committee, int monthIndex) {
  return _showAmountConfirm(
    context,
    title: 'Confirm installment for month $monthIndex',
    prompt: 'Enter what you actually paid.',
    initialMinorUnits: committee.monthlyMinorUnits,
    currency: committee.currency,
    actionLabel: 'Confirm paid',
    onConfirm: (minor) => context
        .read<AppState>()
        .recordCommitteeInstallment(committee.id, monthIndex,
            amountMinorUnits: minor),
  );
}

/// Asks the user to confirm the payout with an editable amount.
Future<void> showConfirmPayoutSheet(BuildContext context, Committee committee) {
  return _showAmountConfirm(
    context,
    title: 'Confirm your payout',
    prompt: 'Enter what you actually received.',
    initialMinorUnits: committee.payoutMinorUnits,
    currency: committee.currency,
    actionLabel: 'Confirm received',
    onConfirm: (minor) => context
        .read<AppState>()
        .recordCommitteePayout(committee.id, amountMinorUnits: minor),
  );
}

Future<void> _showAmountConfirm(
  BuildContext context, {
  required String title,
  required String prompt,
  required int initialMinorUnits,
  required String currency,
  required String actionLabel,
  required Future<void> Function(int minor) onConfirm,
}) {
  return showAppBottomSheet<void>(
    context,
    builder: (sheetContext) => _AmountConfirm(
      title: title,
      prompt: prompt,
      initialMinorUnits: initialMinorUnits,
      currency: currency,
      actionLabel: actionLabel,
      onConfirm: onConfirm,
    ),
  );
}

class _AmountConfirm extends StatefulWidget {
  const _AmountConfirm({
    required this.title,
    required this.prompt,
    required this.initialMinorUnits,
    required this.currency,
    required this.actionLabel,
    required this.onConfirm,
  });

  final String title;
  final String prompt;
  final int initialMinorUnits;
  final String currency;
  final String actionLabel;
  final Future<void> Function(int minor) onConfirm;

  @override
  State<_AmountConfirm> createState() => _AmountConfirmState();
}

class _AmountConfirmState extends State<_AmountConfirm> {
  late final TextEditingController _controller = TextEditingController(
      text: fromMinorUnits(widget.initialMinorUnits).toStringAsFixed(2));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.smMd, AppSpacing.lg, AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.title, style: textTheme.titleLarge),
          const SizedBox(height: AppSpacing.xs),
          Text(widget.prompt, style: textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _controller,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
                labelText: 'Amount', prefixText: '${widget.currency} '),
          ),
          const SizedBox(height: AppSpacing.md),
          PrimaryButton(
            label: widget.actionLabel,
            onPressed: () async {
              final v = parseTolerantNumber(_controller.text);
              if (v == null || v <= 0) {
                showErrorSnackbar(context, 'Enter a number above zero.');
                return;
              }
              final navigator = Navigator.of(context);
              try {
                await widget.onConfirm(toMinorUnits(v));
                navigator.pop();
              } catch (e) {
                if (context.mounted) showErrorSnackbar(context, '$e');
              }
            },
          ),
        ],
      ),
    );
  }
}
