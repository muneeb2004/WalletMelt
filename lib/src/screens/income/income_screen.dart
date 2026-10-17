import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../../theme/wallet_melt_theme.dart';
import '../../types/account.dart';
import '../../types/income.dart';
import '../../utils/currency_format.dart';
import '../../utils/number_parser.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/primary_button.dart';

String incomeSourceLabel(IncomeSource s) => switch (s) {
      IncomeSource.salary => 'Salary',
      IncomeSource.allowance => 'Allowance',
      IncomeSource.scholarship => 'Scholarship',
      IncomeSource.freelance => 'Freelance',
      IncomeSource.gift => 'Gift',
      IncomeSource.other => 'Other',
    };

const Map<String, String> incomeCycleLabels = {
  'weekly': 'Every week',
  'monthly': 'Every month',
  'quarterly': 'Every 3 months',
  'semi_annual': 'Every 6 months',
  'annual': 'Every year',
};

String incomeCycleLabel(String cycle) {
  final known = incomeCycleLabels[cycle];
  if (known != null) return known;
  if (cycle.startsWith('custom_')) {
    return 'Every ${cycle.substring(7)} days';
  }
  return cycle;
}

String _dateLabel(String iso) => iso.length >= 10 ? iso.substring(0, 10) : iso;

class IncomeScreen extends StatelessWidget {
  const IncomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final currency = state.settings.currency;
    final expected = state.expectedIncomeThisMonthMinorUnits;
    final schedules = state.incomeSchedules;
    final received = state.incomes;

    return Scaffold(
      appBar: AppBar(title: const Text('Income')),
      floatingActionButton: state.incomeAvailable
          ? FloatingActionButton.extended(
              onPressed: () => showIncomeEditorSheet(context),
              icon: const Icon(Icons.add),
              label: const Text('Add income'),
            )
          : null,
      body: !state.incomeAvailable
          ? const Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: EmptyState(
                icon: Icons.info_outline,
                title: 'Income is unavailable',
                subtitle:
                    'This device is using the legacy storage engine, which cannot track income.',
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md, AppSpacing.md, AppSpacing.md, 96),
              children: [
                if (schedules.isEmpty && received.isEmpty)
                  const EmptyState(
                    icon: Icons.payments_outlined,
                    title: 'Record money coming in',
                    subtitle:
                        'Add your salary, allowance or stipend. Repeating income asks you to confirm when it arrives, then updates your balance.',
                  )
                else ...[
                  WMCard(
                    tone: WMCardTone.brand,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Expected this month',
                            style: textTheme.bodyMedium?.copyWith(
                                color: scheme.onPrimaryContainer)),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          formatMoneyMinorUnits(expected, currency),
                          style: withTabularFigures(textTheme.headlineMedium)
                              .copyWith(color: scheme.onPrimaryContainer),
                        ),
                        Text('Received plus what is still due',
                            style: textTheme.bodySmall?.copyWith(
                                color: scheme.onPrimaryContainer)),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                if (schedules.isNotEmpty) ...[
                  Text('Repeating', style: textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.sm),
                  for (final s in schedules) ...[
                    _ScheduleTile(schedule: s),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                  const SizedBox(height: AppSpacing.md),
                ],
                if (received.isNotEmpty) ...[
                  Text('Received', style: textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.sm),
                  for (final i in received) ...[
                    _IncomeTile(income: i),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                ],
              ],
            ),
    );
  }
}

class _ScheduleTile extends StatelessWidget {
  const _ScheduleTile({required this.schedule});

  final IncomeSchedule schedule;

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return WMCard(
      tone: WMCardTone.raised,
      child: Row(
        children: [
          Icon(Icons.event_repeat_outlined, color: scheme.primary),
          const SizedBox(width: AppSpacing.smMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(schedule.title, style: textTheme.titleMedium),
                Text(
                  '${incomeCycleLabel(schedule.cycle)} · next ${_dateLabel(schedule.nextDueDate)}'
                  '${schedule.isActive ? '' : ' · paused'}',
                  style: textTheme.bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Text(
            formatMoneyMinorUnits(schedule.amountMinorUnits, schedule.currency),
            style: withTabularFigures(textTheme.titleMedium),
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'toggle') {
                await state.setIncomeScheduleStatus(
                  schedule.id,
                  schedule.isActive
                      ? IncomeScheduleStatus.paused
                      : IncomeScheduleStatus.active,
                );
              } else if (value == 'delete') {
                final ok = await showConfirmDialog(
                  context,
                  title: 'Remove ${schedule.title}?',
                  body:
                      'Income you already received stays in your history and balance.',
                  confirmLabel: 'Remove',
                  isDestructive: true,
                );
                if (ok == true) await state.deleteIncomeSchedule(schedule.id);
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                  value: 'toggle',
                  child: Text(schedule.isActive ? 'Pause' : 'Resume')),
              const PopupMenuItem(value: 'delete', child: Text('Remove')),
            ],
          ),
        ],
      ),
    );
  }
}

class _IncomeTile extends StatelessWidget {
  const _IncomeTile({required this.income});

  final Income income;

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final accountName = state.accounts
        .where((a) => a.id == income.accountId)
        .map((a) => a.name)
        .firstOrNull;
    return WMCard(
      tone: WMCardTone.raised,
      child: Row(
        children: [
          Icon(Icons.south_west_rounded, color: scheme.primary),
          const SizedBox(width: AppSpacing.smMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(income.title, style: textTheme.titleMedium),
                Text(
                  [
                    incomeSourceLabel(income.source),
                    _dateLabel(income.date),
                    if (accountName != null) accountName,
                  ].join(' · '),
                  style: textTheme.bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Text(
            formatMoneyMinorUnits(income.amountMinorUnits, income.currency),
            style: withTabularFigures(textTheme.titleMedium),
          ),
          IconButton(
            tooltip: 'Delete',
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              final ok = await showConfirmDialog(
                context,
                title: 'Delete this income?',
                body: income.accountId == null
                    ? 'It will be removed from your income history.'
                    : 'The account balance goes back down by this amount.',
                confirmLabel: 'Delete',
                isDestructive: true,
              );
              if (ok == true) await state.deleteIncome(income.id);
            },
          ),
        ],
      ),
    );
  }
}

Future<void> showIncomeEditorSheet(BuildContext context) {
  final state = context.read<AppState>();
  return showAppBottomSheet<void>(
    context,
    builder: (_) => _IncomeEditor(state: state),
  );
}

class _IncomeEditor extends StatefulWidget {
  const _IncomeEditor({required this.state});

  final AppState state;

  @override
  State<_IncomeEditor> createState() => _IncomeEditorState();
}

class _IncomeEditorState extends State<_IncomeEditor> {
  final _title = TextEditingController();
  final _amount = TextEditingController();
  IncomeSource _source = IncomeSource.salary;
  DateTime _date = DateTime.now();
  bool _repeats = false;
  String _cycle = 'monthly';
  String? _accountId;
  String? _error;

  @override
  void initState() {
    super.initState();
    final eligible = _eligibleAccounts;
    if (eligible.length == 1) _accountId = eligible.first.id;
  }

  @override
  void dispose() {
    _title.dispose();
    _amount.dispose();
    super.dispose();
  }

  List<Account> get _eligibleAccounts => [
        for (final a in widget.state.accounts)
          if (!a.isArchived && a.currency == widget.state.settings.currency) a,
      ];

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    final amountValue = parseTolerantNumber(_amount.text);
    if (_title.text.trim().isEmpty) {
      setState(() => _error = 'Enter what this income is for.');
      return;
    }
    if (amountValue == null || amountValue <= 0) {
      setState(() => _error = 'Enter an amount greater than zero.');
      return;
    }
    final minor = toMinorUnits(amountValue);
    final navigator = Navigator.of(context);
    try {
      if (_repeats) {
        await widget.state.createIncomeSchedule(
          title: _title.text,
          source: _source,
          amountMinorUnits: minor,
          cycle: _cycle,
          firstDueDate: _date,
          accountId: _accountId,
        );
      } else {
        await widget.state.addIncome(
          title: _title.text,
          source: _source,
          amountMinorUnits: minor,
          date: _date,
          accountId: _accountId,
        );
      }
      navigator.pop();
    } catch (error) {
      setState(() => _error = '$error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final currency = widget.state.settings.currency;
    final eligible = _eligibleAccounts;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.smMd, AppSpacing.lg, AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Add income', style: textTheme.titleLarge),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _title,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'Title'),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _amount,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration:
                InputDecoration(labelText: 'Amount', prefixText: '$currency '),
          ),
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<IncomeSource>(
            initialValue: _source,
            decoration: const InputDecoration(labelText: 'Source'),
            items: [
              for (final s in IncomeSource.values)
                DropdownMenuItem(value: s, child: Text(incomeSourceLabel(s))),
            ],
            onChanged: (v) => setState(() => _source = v!),
          ),
          const SizedBox(height: AppSpacing.md),
          if (eligible.isNotEmpty) ...[
            DropdownButtonFormField<String?>(
              key: const ValueKey('income-account'),
              initialValue: _accountId,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Deposited to'),
              items: [
                const DropdownMenuItem<String?>(
                    value: null, child: Text('No account')),
                for (final a in eligible)
                  DropdownMenuItem<String?>(
                      value: a.id, child: Text(a.name)),
              ],
              onChanged: (v) => setState(() => _accountId = v),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          OutlinedButton.icon(
            onPressed: _pickDate,
            icon: const Icon(Icons.event_outlined),
            label: Text(_repeats
                ? 'First date: ${_dateLabel(_date.toIso8601String())}'
                : 'Date: ${_dateLabel(_date.toIso8601String())}'),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('This repeats'),
            subtitle: const Text('You confirm each time it arrives.'),
            value: _repeats,
            onChanged: (v) => setState(() => _repeats = v),
          ),
          if (_repeats)
            DropdownButtonFormField<String>(
              initialValue: _cycle,
              decoration: const InputDecoration(labelText: 'How often'),
              items: [
                for (final e in incomeCycleLabels.entries)
                  DropdownMenuItem(value: e.key, child: Text(e.value)),
              ],
              onChanged: (v) => setState(() => _cycle = v!),
            ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Text(_error!,
                  style: textTheme.bodyMedium
                      ?.copyWith(color: Theme.of(context).colorScheme.error)),
            ),
          const SizedBox(height: AppSpacing.md),
          PrimaryButton(label: _repeats ? 'Add repeating income' : 'Add income', onPressed: _save),
        ],
      ),
    );
  }
}

/// Asks the user to confirm a due occurrence (amount and date editable).
Future<void> showConfirmIncomeSheet(
    BuildContext context, IncomeSchedule schedule) {
  final state = context.read<AppState>();
  final controller = TextEditingController(
      text: fromMinorUnits(schedule.amountMinorUnits).toStringAsFixed(2));
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
            Text('Confirm ${schedule.title}', style: textTheme.titleLarge),
            const SizedBox(height: AppSpacing.xs),
            Text('Enter what actually arrived.', style: textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                  labelText: 'Amount received',
                  prefixText: '${schedule.currency} '),
            ),
            const SizedBox(height: AppSpacing.md),
            PrimaryButton(
              label: 'Confirm received',
              onPressed: () async {
                final value = parseTolerantNumber(controller.text);
                if (value == null || value <= 0) {
                  showErrorSnackbar(sheetContext, 'Enter a number above zero.');
                  return;
                }
                final navigator = Navigator.of(sheetContext);
                await state.confirmIncomeReceived(schedule.id,
                    amountMinorUnits: toMinorUnits(value));
                navigator.pop();
              },
            ),
          ],
        ),
      );
    },
  );
}
