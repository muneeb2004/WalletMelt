import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../components/account/account_picker_field.dart';
import '../../components/category/category_chip.dart';
import '../../state/app_state.dart';
import '../../theme/wallet_melt_theme.dart';
import '../../types/subscription.dart';
import '../../utils/currency_format.dart';
import '../../utils/number_parser.dart';
import '../../utils/recurrence.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/primary_button.dart';

/// Billing cycle choices shown in the form. Stored values stay the strings
/// `advanceByCycle` understands (`monthly`, `semi_annual`, `custom_45`, ...).
enum SubscriptionCycle {
  weekly('Weekly', 'weekly'),
  monthly('Monthly', 'monthly'),
  quarterly('Every 3 months', 'quarterly'),
  semiAnnual('Every 6 months', 'semi_annual'),
  annual('Yearly', 'annual'),
  custom('Every N days', 'custom');

  const SubscriptionCycle(this.label, this.stored);
  final String label;
  final String stored;

  /// Maps any stored spelling (including legacy "Semi-Annual", "yearly" and
  /// `custom_N`) to a form choice plus its custom day count, if any.
  static (SubscriptionCycle, int?) parse(String stored) {
    final s = stored.toLowerCase().trim();
    switch (s) {
      case 'weekly':
        return (weekly, null);
      case 'quarterly':
        return (quarterly, null);
      case 'semi-annual':
      case 'semi_annual':
        return (semiAnnual, null);
      case 'annual':
      case 'yearly':
        return (annual, null);
    }
    if (s.startsWith('custom_')) {
      final days = int.tryParse(s.split('_').last);
      return (custom, days != null && days > 0 ? days : 30);
    }
    return (monthly, null);
  }
}

/// Human label for a stored billing cycle, used by the list card.
String subscriptionCycleLabel(String stored) {
  final (cycle, days) = SubscriptionCycle.parse(stored);
  if (cycle == SubscriptionCycle.custom) {
    return days == 1 ? 'Every day' : 'Every $days days';
  }
  return cycle.label;
}

String formatRenewalDate(DateTime d) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${d.day} ${months[d.month - 1]} ${d.year}';
}

String _ymd(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Opens the create sheet, or the edit sheet when [existing] is given.
Future<void> showSubscriptionFormSheet(BuildContext context,
    {Subscription? existing}) {
  return showAppBottomSheet<void>(
    context,
    builder: (_) => SubscriptionFormSheet(existing: existing),
  );
}

class SubscriptionFormSheet extends StatefulWidget {
  const SubscriptionFormSheet({this.existing, super.key});

  final Subscription? existing;

  @override
  State<SubscriptionFormSheet> createState() => _SubscriptionFormSheetState();
}

class _SubscriptionFormSheetState extends State<SubscriptionFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _amount = TextEditingController();
  final _tax = TextEditingController();
  final _taxPct = TextEditingController();
  final _description = TextEditingController();
  final _customDays = TextEditingController();

  String? _categoryId;
  String? _accountId;
  SubscriptionCycle _cycle = SubscriptionCycle.monthly;
  late DateTime _date;
  int _reminder = 0;
  bool _accountTouched = false;

  Subscription? get _existing => widget.existing;
  bool get _isEdit => _existing != null;

  DateTime get _today {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  @override
  void initState() {
    super.initState();
    final sub = _existing;
    if (sub == null) {
      _date = _today;
      return;
    }
    _name.text = sub.name;
    _categoryId = sub.categoryId;
    _accountId = sub.accountId;
    _amount.text = _plain(sub.amount);
    if (sub.taxAmount != null && sub.taxAmount! > 0) {
      _tax.text = _plain(sub.taxAmount!);
      if (sub.amount > 0) {
        _taxPct.text = _plain(sub.taxAmount! / sub.amount * 100, 1);
      }
    }
    _description.text = sub.description ?? '';
    final (cycle, days) = SubscriptionCycle.parse(sub.billingCycle);
    _cycle = cycle;
    if (days != null) _customDays.text = '$days';
    _reminder = sub.notificationOffset ?? 0;
    _date = DateTime.tryParse(sub.nextOccurrenceDate) ?? _today;
    _date = DateTime(_date.year, _date.month, _date.day);
  }

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    _tax.dispose();
    _taxPct.dispose();
    _description.dispose();
    _customDays.dispose();
    super.dispose();
  }

  static String _plain(double v, [int digits = 2]) =>
      v.toStringAsFixed(v % 1 == 0 ? 0 : digits);

  /// Stored form of the chosen cycle, or null while the custom days are invalid.
  String? get _cycleValue {
    if (_cycle != SubscriptionCycle.custom) return _cycle.stored;
    final days = int.tryParse(_customDays.text.trim());
    if (days == null || days <= 0) return null;
    return 'custom_$days';
  }

  bool get _dateChanged {
    final sub = _existing;
    if (sub == null) return true;
    return _ymd(_date) != sub.nextOccurrenceDate.split('T').first;
  }

  /// Day of month later renewals stick to. A manually chosen date becomes the
  /// new anchor; an untouched date keeps the subscription's original one.
  int get _anchorDay {
    final sub = _existing;
    if (sub == null || _dateChanged) return _date.day;
    return DateTime.tryParse(sub.startDate)?.day ?? _date.day;
  }

  void _syncTaxFromRate() {
    final amount = parseTolerantNumber(_amount.text.trim());
    final pct = parseTolerantNumber(_taxPct.text.trim());
    if (amount == null || pct == null) return;
    _tax.text = _plain(amount * pct / 100);
  }

  void _syncRateFromTax(String value) {
    final tax = parseTolerantNumber(value);
    final amount = parseTolerantNumber(_amount.text);
    if (tax != null && amount != null && amount > 0) {
      _taxPct.text = _plain(tax / amount * 100, 1);
    } else if (value.trim().isEmpty) {
      _taxPct.clear();
    }
  }

  Future<void> _pickDate() async {
    final first = _isEdit ? _today : DateTime(2000);
    final initial = _date.isBefore(first) ? first : _date;
    final picked = await showDatePicker(
      context: context,
      useRootNavigator: true,
      initialDate: initial,
      firstDate: first,
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) {
      setState(() => _date = DateTime(picked.year, picked.month, picked.day));
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_categoryId == null) {
      showErrorSnackbar(context, 'Choose a category.');
      return;
    }
    final cycleValue = _cycleValue;
    if (cycleValue == null) return;

    final state = context.read<AppState>();
    final name = _name.text.trim();
    final amount = parseTolerantNumber(_amount.text) ?? 0.0;
    final tax = parseTolerantNumber(_tax.text);
    final taxValue = (tax == null || tax <= 0) ? null : tax;
    final description = _description.text.trim();
    final now = DateTime.now().toIso8601String();
    final dateStr = _ymd(_date);

    final sub = _existing;
    if (sub == null) {
      await state.addSubscription(Subscription(
        id: const Uuid().v4(),
        name: name,
        categoryId: _categoryId!,
        amount: amount,
        taxAmount: taxValue,
        currency: state.settings.currency,
        description: description.isEmpty ? null : description,
        startDate: dateStr,
        nextOccurrenceDate: dateStr,
        billingCycle: cycleValue,
        status: SubscriptionStatus.active,
        createdAt: now,
        updatedAt: now,
        notificationOffset: _reminder,
        accountId: _accountId,
      ));
    } else {
      await state.updateSubscription(sub.copyWith(
        name: name,
        categoryId: _categoryId,
        amount: amount,
        taxAmount: taxValue,
        clearTax: taxValue == null,
        description: description.isEmpty ? null : description,
        clearDescription: description.isEmpty,
        billingCycle: cycleValue,
        // A manual date is the new anchor, so later renewals keep its day.
        startDate: _dateChanged ? dateStr : null,
        nextOccurrenceDate: _dateChanged ? dateStr : null,
        notificationOffset: _reminder,
        accountId: _accountTouched ? _accountId : null,
        clearAccountId: _accountTouched && _accountId == null,
        updatedAt: now,
      ));
    }
    if (!mounted) return;
    Navigator.pop(context);
    showSuccessSnackbar(
        context, _isEdit ? 'Saved "$name".' : 'Added "$name".');
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final currency = state.settings.currency;
    final textTheme = Theme.of(context).textTheme;
    final scheme = context.scheme;
    final total = (parseTolerantNumber(_amount.text) ?? 0.0) +
        (parseTolerantNumber(_tax.text) ?? 0.0);
    final cycleValue = _cycleValue;
    final upcoming = cycleValue == null
        ? const <DateTime>[]
        : upcomingRenewals(cycleValue, _date, _anchorDay, 3);
    final clamped = _cycle != SubscriptionCycle.weekly &&
        _cycle != SubscriptionCycle.custom &&
        _anchorDay > 28;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.smMd, AppSpacing.lg, AppSpacing.lg),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_isEdit ? 'Edit subscription' : 'Add subscription',
                style: textTheme.titleLarge),
            const SizedBox(height: AppSpacing.xs),
            Text(
              _isEdit
                  ? 'Changes apply to future renewals. Past expenses stay as recorded.'
                  : 'Renewals are added to your expenses automatically on their date.',
              style: textTheme.bodyMedium
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'Netflix, rent, gym',
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Enter a name.' : null,
            ),
            const SizedBox(height: AppSpacing.md),
            Text('Category', style: textTheme.labelMedium),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              height: 48,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                itemCount: state.categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
                itemBuilder: (_, i) {
                  final category = state.categories[i];
                  return WalletCategoryChip(
                    category: category,
                    selected: category.id == _categoryId,
                    onTap: () => setState(() => _categoryId = category.id),
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _amount,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Amount ($currency)',
                hintText: '0.00',
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Enter an amount.';
                if (parseTolerantNumber(v) == null) return 'Enter a number.';
                return null;
              },
              onChanged: (_) => setState(_syncTaxFromRate),
            ),
            const SizedBox(height: AppSpacing.smMd),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _taxPct,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Tax rate (%)'),
                    onChanged: (_) => setState(_syncTaxFromRate),
                  ),
                ),
                const SizedBox(width: AppSpacing.smMd),
                Expanded(
                  child: TextFormField(
                    controller: _tax,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(labelText: 'Tax ($currency)'),
                    onChanged: (v) => setState(() => _syncRateFromTax(v)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.smMd),
            WMCard(
              tone: WMCardTone.raised,
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: AppSpacing.smMd),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total per renewal', style: textTheme.bodyMedium),
                  Text(formatMoney(total, currency),
                      style: textTheme.titleLarge
                          ?.copyWith(color: scheme.primary)),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<SubscriptionCycle>(
              key: ValueKey('cycle-${_cycle.name}'),
              initialValue: _cycle,
              menuMaxHeight: 320,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              dropdownColor: scheme.surfaceContainerHigh,
              decoration: const InputDecoration(labelText: 'Repeats'),
              items: [
                for (final c in SubscriptionCycle.values)
                  DropdownMenuItem(value: c, child: Text(c.label)),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _cycle = v);
              },
            ),
            if (_cycle == SubscriptionCycle.custom) ...[
              const SizedBox(height: AppSpacing.smMd),
              TextFormField(
                controller: _customDays,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Number of days',
                  hintText: '45',
                ),
                validator: (v) {
                  final days = int.tryParse((v ?? '').trim());
                  return (days == null || days <= 0)
                      ? 'Enter a whole number of days.'
                      : null;
                },
                onChanged: (_) => setState(() {}),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            InkWell(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              onTap: _pickDate,
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: _isEdit ? 'Next renewal' : 'First renewal',
                  suffixIcon: const Icon(Icons.calendar_today_rounded),
                ),
                child: Text(formatRenewalDate(_date),
                    style: textTheme.bodyLarge),
              ),
            ),
            if (_isEdit && _dateChanged)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Text(
                  'Later renewals will follow this date.',
                  style: textTheme.bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ),
            if (upcoming.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.smMd),
              WMCard(
                tone: WMCardTone.outlined,
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Then', style: textTheme.labelMedium),
                    const SizedBox(height: AppSpacing.xs),
                    for (final d in upcoming)
                      Text(formatRenewalDate(d), style: textTheme.bodyMedium),
                    if (clamped) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Shorter months renew on their last day, then return to the ${_ordinal(_anchorDay)}.',
                        style: textTheme.bodySmall
                            ?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            if (state.accountsAvailable) ...[
              AccountPickerField(
                accounts: state.accounts,
                currency: _existing?.currency ?? currency,
                value: _accountId,
                label: 'Paid from (optional)',
                helperText: 'Renewals reduce this account balance.',
                onChanged: (id) => setState(() {
                  _accountId = id;
                  _accountTouched = true;
                }),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            DropdownButtonFormField<int>(
              initialValue: _reminder,
              menuMaxHeight: 320,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              dropdownColor: scheme.surfaceContainerHigh,
              decoration: const InputDecoration(labelText: 'Reminder'),
              items: [
                const DropdownMenuItem(value: 0, child: Text('On renewal day')),
                const DropdownMenuItem(value: 1, child: Text('1 day before')),
                const DropdownMenuItem(value: 2, child: Text('2 days before')),
                const DropdownMenuItem(value: 3, child: Text('3 days before')),
                const DropdownMenuItem(value: 7, child: Text('1 week before')),
                // Keep any other stored value (backup restore) selectable.
                if (!const [0, 1, 2, 3, 7].contains(_reminder))
                  DropdownMenuItem(
                      value: _reminder, child: Text('$_reminder days before')),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _reminder = v);
              },
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _description,
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                hintText: 'Account number or reference',
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: PrimaryButton(
                    label: _isEdit ? 'Save' : 'Add',
                    onPressed: _save,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _ordinal(int n) {
    if (n >= 11 && n <= 13) return '${n}th';
    return switch (n % 10) {
      1 => '${n}st',
      2 => '${n}nd',
      3 => '${n}rd',
      _ => '${n}th',
    };
  }
}
