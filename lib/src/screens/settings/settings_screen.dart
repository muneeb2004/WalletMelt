import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../components/glass/app_background.dart';
import '../../constants/categories.dart';
import '../../services/export/expense_csv_export_service.dart';
import '../../services/export/export_share_service.dart';
import '../../state/app_state.dart';
import '../../theme/wallet_melt_theme.dart';
import '../../types/settings.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    this.expenseCsvExportService = const ExpenseCsvExportService(),
    this.exportShareService = const SharePlusExportShareService(),
    super.key,
  });

  final ExpenseCsvExportService expenseCsvExportService;
  final ExportShareService exportShareService;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isExportingExpenses = false;
  bool _includeDeletedExpenses = false;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      body: AppBackground(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Text('Settings', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 18),
            LiquidGlass(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Preferences',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: state.settings.currency,
                    decoration: const InputDecoration(labelText: 'Currency'),
                    items: [
                      for (final currency in defaultCurrencyCodes)
                        DropdownMenuItem(
                            value: currency, child: Text(currency)),
                    ],
                    onChanged: (value) {
                      if (value != null) state.updateCurrency(value);
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<ThemePreference>(
                    initialValue: state.settings.themePreference,
                    decoration: const InputDecoration(labelText: 'Theme'),
                    items: const [
                      DropdownMenuItem(
                          value: ThemePreference.system, child: Text('System')),
                      DropdownMenuItem(
                          value: ThemePreference.light, child: Text('Light')),
                      DropdownMenuItem(
                          value: ThemePreference.dark, child: Text('Dark')),
                    ],
                    onChanged: (value) {
                      if (value != null) state.updateTheme(value);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            LiquidGlass(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Data export',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  Material(
                    type: MaterialType.transparency,
                    child: CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      value: _includeDeletedExpenses,
                      title: const Text('Include deleted expenses'),
                      onChanged: _isExportingExpenses
                          ? null
                          : (value) {
                              setState(() {
                                _includeDeletedExpenses = value ?? false;
                              });
                            },
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _isExportingExpenses
                          ? null
                          : () => _exportExpensesCsv(state),
                      icon: _isExportingExpenses
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.ios_share_rounded),
                      label: Text(_isExportingExpenses
                          ? 'Preparing CSV'
                          : 'Export expenses CSV'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _exportStatusText(state),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            LiquidGlass(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Privacy',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(
                      'All v1 expenses, settings, categories, budgets, and receipt images stay on this device. There is no login, backend, cloud storage, or remote database.',
                      style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
            const SizedBox(height: 16),
            LiquidGlass(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Coming later',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(
                      'Cloud sync, accounts, shared households, backup/restore, OCR, and recurring reminders are intentionally outside this v1 scope.',
                      style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
            const SizedBox(height: 16),
            LiquidGlass(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('WalletMelt',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 6),
                  Text('Know where your money went.',
                      style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportExpensesCsv(AppState state) async {
    setState(() => _isExportingExpenses = true);

    try {
      final expenses = _includeDeletedExpenses
          ? [...state.expenses, ...state.deletedExpenses]
          : state.expenses;
      final file = await widget.expenseCsvExportService.exportActiveExpenses(
        expenses: expenses,
        categories: state.categories,
        includeDeleted: _includeDeletedExpenses,
      );
      final shareResult = await widget.exportShareService.shareFile(file);
      if (!mounted) return;

      await state.recordExportedAt(file.createdAt);
      if (!mounted) return;

      final message = switch (shareResult.status) {
        ExportShareStatus.success => 'CSV export shared.',
        ExportShareStatus.dismissed => 'CSV export canceled.',
        ExportShareStatus.unavailable => 'CSV export file is ready.',
      };
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('CSV export failed.')),
      );
    } finally {
      if (mounted) {
        setState(() => _isExportingExpenses = false);
      }
    }
  }

  String _exportStatusText(AppState state) {
    final activeCount = state.expenses.length;
    final deletedCount = state.deletedExpenses.length;
    final countText = _includeDeletedExpenses
        ? '$activeCount active, $deletedCount deleted'
        : '$activeCount active';
    final lastExportedAt = state.settings.lastExportedAt;
    if (lastExportedAt == null || lastExportedAt.isEmpty) {
      return 'Ready to export $countText. Last export: never.';
    }

    return 'Ready to export $countText. Last export: ${_compactTimestamp(lastExportedAt)}.';
  }

  String _compactTimestamp(String value) {
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return value;

    final local = parsed.toLocal();
    return '${local.year}-${_twoDigits(local.month)}-${_twoDigits(local.day)} '
        '${_twoDigits(local.hour)}:${_twoDigits(local.minute)}';
  }

  String _twoDigits(int value) => value.toString().padLeft(2, '0');
}
