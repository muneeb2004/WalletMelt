import 'package:flutter/material.dart';
import '../../widgets/fluid_list.dart';
import 'package:provider/provider.dart';

import '../../analytics/goal_planner.dart';
import '../../components/account/compact_button_style.dart';
import '../../state/app_state.dart';
import '../../theme/wallet_melt_theme.dart';
import '../../types/account.dart';
import '../../types/savings_goal.dart';
import '../../utils/currency_format.dart';
import '../../utils/number_parser.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/progress_bar.dart';

String _dateLabel(String iso) => iso.length >= 10 ? iso.substring(0, 10) : iso;

class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final all = state.goalProgress;
    final active = [for (final p in all) if (p.goal.isActive) p];
    final closed = [for (final p in all) if (!p.goal.isActive) p];
    final hasAccount = state.accounts.any((a) => !a.isArchived);

    return Scaffold(
      appBar: AppBar(title: const Text('Savings goals')),
      floatingActionButton: state.goalsAvailable && hasAccount
          ? FloatingActionButton.extended(
              onPressed: () => showGoalEditorSheet(context),
              icon: const Icon(Icons.add),
              label: const Text('Add goal'),
            )
          : null,
      body: !state.goalsAvailable
          ? const Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: EmptyState(
                icon: Icons.info_outline,
                title: 'Goals are unavailable',
                subtitle:
                    'This device is using the legacy storage engine, which cannot track goals.',
              ),
            )
          : ListView(
              padding: FluidList.padding,
              physics: FluidList.physics,
              children: [
                if (!hasAccount)
                  const EmptyState(
                    icon: Icons.account_balance_wallet_outlined,
                    title: 'Add an account first',
                    subtitle:
                        'A goal is money set aside inside one of your accounts. Add a cash, bank or wallet account, then come back.',
                  )
                else if (all.isEmpty)
                  const EmptyState(
                    icon: Icons.savings_outlined,
                    title: 'Save toward something',
                    subtitle:
                        'Set money aside for a laptop, fees or a trip. Your balance stays the same; WalletMelt shows what is still free to spend.',
                  )
                else if (state.freeToSpendTotals.isNotEmpty &&
                    state.reservedByAccount.values.any((v) => v > 0)) ...[
                  WMCard(
                    tone: WMCardTone.brand,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Free to spend',
                            style: textTheme.bodyMedium
                                ?.copyWith(color: scheme.onPrimaryContainer)),
                        const SizedBox(height: AppSpacing.xs),
                        for (final t in state.freeToSpendTotals)
                          Text(
                            formatMoneyMinorUnits(t.minorUnits, t.currency),
                            style: withTabularFigures(textTheme.headlineMedium)
                                .copyWith(color: scheme.onPrimaryContainer),
                          ),
                        Text('Balance minus money set aside for goals',
                            style: textTheme.bodySmall
                                ?.copyWith(color: scheme.onPrimaryContainer)),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                for (final (idx, p) in active.indexed) ...[
                  FluidItem(index: idx, child: _GoalTile(progress: p)),
                  const SizedBox(height: FluidList.gap),
                ],
                if (closed.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text('Finished and archived',
                      style: textTheme.titleMedium
                          ?.copyWith(color: scheme.onSurfaceVariant)),
                  const SizedBox(height: AppSpacing.sm),
                  for (final (idx, p) in closed.indexed) ...[
                    FluidItem(index: idx, child: _GoalTile(progress: p)),
                    const SizedBox(height: FluidList.gap),
                  ],
                ],
              ],
            ),
    );
  }
}

class _GoalTile extends StatelessWidget {
  const _GoalTile({required this.progress});

  final GoalProgress progress;

  @override
  Widget build(BuildContext context) {
    final goal = progress.goal;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final state = context.read<AppState>();
    final accountName = state.accounts
        .where((a) => a.id == goal.accountId)
        .map((a) => a.name)
        .firstOrNull;
    final pace = GoalPlanner.monthlyPaceMinorUnits(
        progress: progress, now: DateTime.now());
    final statusText = switch (goal.status) {
      GoalStatus.achieved => 'Achieved',
      GoalStatus.archived => 'Archived',
      GoalStatus.active => progress.isReached ? 'Target reached' : null,
    };
    return WMCard(
      tone: WMCardTone.raised,
      onTap: () => showGoalDetailSheet(context, goal.id),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(goal.name, style: textTheme.titleMedium)),
              if (statusText != null)
                Text(statusText,
                    style: textTheme.labelMedium?.copyWith(color: scheme.primary)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ProgressBar(fraction: progress.fraction, color: scheme.primary),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${formatMoneyMinorUnits(progress.savedMinorUnits, goal.currency)} of ${formatMoneyMinorUnits(goal.targetMinorUnits, goal.currency)}',
            style: withTabularFigures(textTheme.bodyMedium),
          ),
          Text(
            [
              if (accountName != null) 'In $accountName',
              if (goal.targetDate != null) 'by ${_dateLabel(goal.targetDate!)}',
              if (pace != null)
                'about ${formatMoneyMinorUnits(pace, goal.currency)} a month',
            ].join(' · '),
            style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

// ── Sheets ───────────────────────────────────────────────────────────────

Future<void> showGoalEditorSheet(BuildContext context) {
  final state = context.read<AppState>();
  return showAppBottomSheet<void>(
    context,
    builder: (_) => _GoalEditor(state: state),
  );
}

class _GoalEditor extends StatefulWidget {
  const _GoalEditor({required this.state});

  final AppState state;

  @override
  State<_GoalEditor> createState() => _GoalEditorState();
}

class _GoalEditorState extends State<_GoalEditor> {
  final _name = TextEditingController();
  final _target = TextEditingController();
  String? _accountId;
  DateTime? _date;
  String? _error;

  List<Account> get _accounts => [
        for (final a in widget.state.accounts)
          if (!a.isArchived) a,
      ];

  @override
  void initState() {
    super.initState();
    _accountId = _accounts.firstOrNull?.id;
  }

  @override
  void dispose() {
    _name.dispose();
    _target.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? DateTime.now().add(const Duration(days: 90)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    final value = parseTolerantNumber(_target.text);
    if (_name.text.trim().isEmpty) {
      setState(() => _error = 'Enter what you are saving for.');
      return;
    }
    if (value == null || value <= 0) {
      setState(() => _error = 'Enter a target amount above zero.');
      return;
    }
    if (_accountId == null) {
      setState(() => _error = 'Choose an account.');
      return;
    }
    final navigator = Navigator.of(context);
    try {
      await widget.state.createGoal(
        name: _name.text,
        targetMinorUnits: toMinorUnits(value),
        accountId: _accountId!,
        targetDate: _date,
      );
      navigator.pop();
    } catch (error) {
      setState(() => _error = '$error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final currency = _accounts
            .where((a) => a.id == _accountId)
            .map((a) => a.currency)
            .firstOrNull ??
        widget.state.settings.currency;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.smMd, AppSpacing.lg, AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Add goal', style: textTheme.titleLarge),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'What are you saving for?'),
          ),
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<String>(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            dropdownColor: Theme.of(context).colorScheme.surfaceContainerHigh,
            menuMaxHeight: 320,
            key: const ValueKey('goal-account'),
            initialValue: _accountId,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Set aside inside',
              helperText: 'The money stays in this account.',
            ),
            items: [
              for (final a in _accounts)
                DropdownMenuItem(value: a.id, child: Text('${a.name} (${a.currency})')),
            ],
            onChanged: (v) => setState(() => _accountId = v),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _target,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
                labelText: 'Target amount', prefixText: '$currency '),
          ),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton.icon(
            style: compactButtonStyle,
            onPressed: _pickDate,
            icon: const Icon(Icons.event_outlined),
            label: Text(_date == null
                ? 'Add a target date (optional)'
                : 'By ${_dateLabel(_date!.toIso8601String())}'),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Text(_error!,
                  style: textTheme.bodyMedium
                      ?.copyWith(color: Theme.of(context).colorScheme.error)),
            ),
          const SizedBox(height: AppSpacing.md),
          PrimaryButton(label: 'Add goal', onPressed: _save),
        ],
      ),
    );
  }
}

Future<void> showGoalDetailSheet(BuildContext context, String goalId) {
  final state = context.read<AppState>();
  return showAppBottomSheet<void>(
    context,
    builder: (_) => _GoalDetail(state: state, goalId: goalId),
  );
}

class _GoalDetail extends StatefulWidget {
  const _GoalDetail({required this.state, required this.goalId});

  final AppState state;
  final String goalId;

  @override
  State<_GoalDetail> createState() => _GoalDetailState();
}

class _GoalDetailState extends State<_GoalDetail> {
  late Future<List<GoalContribution>> _history;

  @override
  void initState() {
    super.initState();
    _history = widget.state.goalContributions(widget.goalId);
  }

  void _reload() {
    final next = widget.state.goalContributions(widget.goalId);
    setState(() {
      _history = next;
    });
  }

  Future<void> _amountDialog({
    required String title,
    required String actionLabel,
    required Future<void> Function(int minor) onConfirm,
  }) async {
    final result = await showDialog<int>(
      context: context,
      builder: (_) => _AmountDialog(title: title, actionLabel: actionLabel),
    );
    if (result == null) return;
    try {
      await onConfirm(result);
      _reload();
    } catch (error) {
      if (mounted) showErrorSnackbar(context, '$error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.state,
      builder: (context, _) {
        final progress = widget.state.goalProgress
            .where((p) => p.goal.id == widget.goalId)
            .firstOrNull;
        if (progress == null) return const SizedBox(height: 120);
        final goal = progress.goal;
        final textTheme = Theme.of(context).textTheme;
        final scheme = Theme.of(context).colorScheme;
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.smMd, AppSpacing.lg, AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(goal.name, style: textTheme.titleLarge),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${formatMoneyMinorUnits(progress.savedMinorUnits, goal.currency)} of ${formatMoneyMinorUnits(goal.targetMinorUnits, goal.currency)}',
                style: withTabularFigures(textTheme.headlineMedium),
              ),
              const SizedBox(height: AppSpacing.sm),
              ProgressBar(fraction: progress.fraction, color: scheme.primary),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  if (goal.isActive) ...[
                    FilledButton.tonalIcon(
                      style: compactButtonStyle,
                      onPressed: () => _amountDialog(
                        title: 'Set money aside',
                        actionLabel: 'Set aside',
                        onConfirm: (m) =>
                            widget.state.setAsideForGoal(goal.id, m),
                      ),
                      icon: const Icon(Icons.add),
                      label: const Text('Set aside'),
                    ),
                    OutlinedButton.icon(
                      style: compactButtonStyle,
                      onPressed: progress.savedMinorUnits <= 0
                          ? null
                          : () => _amountDialog(
                                title: 'Release money',
                                actionLabel: 'Release',
                                onConfirm: (m) =>
                                    widget.state.releaseFromGoal(goal.id, m),
                              ),
                      icon: const Icon(Icons.remove),
                      label: const Text('Release'),
                    ),
                    OutlinedButton.icon(
                      style: compactButtonStyle,
                      onPressed: () async {
                        await widget.state.markGoalAchieved(goal.id);
                        _reload();
                      },
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Mark achieved'),
                    ),
                  ] else
                    OutlinedButton.icon(
                      style: compactButtonStyle,
                      onPressed: () async {
                        await widget.state.reopenGoal(goal.id);
                        _reload();
                      },
                      icon: const Icon(Icons.replay),
                      label: const Text('Reopen'),
                    ),
                  if (goal.status != GoalStatus.archived)
                    OutlinedButton.icon(
                      style: compactButtonStyle,
                      onPressed: () async {
                        final navigator = Navigator.of(context);
                        await widget.state.archiveGoal(goal.id);
                        navigator.pop();
                      },
                      icon: const Icon(Icons.archive_outlined),
                      label: const Text('Archive'),
                    ),
                  OutlinedButton.icon(
                    style: compactButtonStyle,
                    onPressed: () async {
                      final ok = await showConfirmDialog(
                        context,
                        title: 'Delete ${goal.name}?',
                        body:
                            'The goal and its history are removed. Your account balance is not affected.',
                        confirmLabel: 'Delete',
                        isDestructive: true,
                      );
                      if (ok != true || !context.mounted) return;
                      final navigator = Navigator.of(context);
                      await widget.state.deleteGoal(goal.id);
                      navigator.pop();
                    },
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Delete'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('History', style: textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              FutureBuilder<List<GoalContribution>>(
                future: _history,
                builder: (context, snap) {
                  final rows = snap.data ?? const [];
                  if (rows.isEmpty) {
                    return Text('Nothing set aside yet.',
                        style: textTheme.bodyMedium);
                  }
                  return Column(
                    children: [
                      for (final c in rows)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(c.amountMinorUnits >= 0
                              ? 'Set aside'
                              : (c.notes ?? 'Released')),
                          subtitle: Text(_dateLabel(c.date)),
                          trailing: Text(
                            formatMoneyMinorUnits(
                                c.amountMinorUnits, goal.currency),
                            style: withTabularFigures(textTheme.bodyLarge),
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
}

/// Asks for a money amount. Owns its controller so it is disposed only after
/// the dialog's closing animation has finished.
class _AmountDialog extends StatefulWidget {
  const _AmountDialog({required this.title, required this.actionLabel});

  final String title;
  final String actionLabel;

  @override
  State<_AmountDialog> createState() => _AmountDialogState();
}

class _AmountDialogState extends State<_AmountDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: const InputDecoration(labelText: 'Amount'),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        FilledButton(
          style: compactButtonStyle,
          onPressed: () {
            final v = parseTolerantNumber(_controller.text);
            if (v == null || v <= 0) return;
            Navigator.pop(context, toMinorUnits(v));
          },
          child: Text(widget.actionLabel),
        ),
      ],
    );
  }
}
