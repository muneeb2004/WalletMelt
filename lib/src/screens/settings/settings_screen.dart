import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';

import '../../components/glass/app_background.dart';
import '../../constants/categories.dart';
import '../../services/export/expense_csv_export_service.dart';
import '../../services/export/export_share_service.dart';
import '../../services/export/file_picker_service.dart';
import '../../services/export/wallet_melt_json_backup_conflict_service.dart';
import '../../services/export/wallet_melt_json_backup_import_validation_service.dart';
import '../../services/export/wallet_melt_json_backup_preview_service.dart';
import '../../services/export/wallet_melt_json_backup_service.dart';
import '../../services/export/wallet_melt_json_restore_dry_run_planner.dart';
import '../../services/export/wallet_melt_json_restore_service.dart';
import '../../state/app_state.dart';
import '../../theme/wallet_melt_theme.dart';
import '../../types/settings.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/confirm_dialog.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    this.expenseCsvExportService = const ExpenseCsvExportService(),
    this.jsonBackupService = const WalletMeltJsonBackupService(),
    this.exportShareService = const SharePlusExportShareService(),
    this.filePickerService = const FilePickerService(),
    this.importValidationService =
        const WalletMeltJsonBackupImportValidationService(),
    this.previewService = const WalletMeltJsonBackupPreviewService(),
    this.conflictService = const WalletMeltJsonBackupConflictService(),
    this.restoreDryRunPlanner = const WalletMeltJsonRestoreDryRunPlanner(),
    this.restoreService = const WalletMeltJsonRestoreService(),
    super.key,
  });

  final ExpenseCsvExportService expenseCsvExportService;
  final WalletMeltJsonBackupService jsonBackupService;
  final ExportShareService exportShareService;
  final FilePickerService filePickerService;
  final WalletMeltJsonBackupImportValidationService importValidationService;
  final WalletMeltJsonBackupPreviewService previewService;
  final WalletMeltJsonBackupConflictService conflictService;
  final WalletMeltJsonRestoreDryRunPlanner restoreDryRunPlanner;
  final WalletMeltJsonRestoreService restoreService;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isExportingExpenses = false;
  bool _isCreatingJsonBackup = false;
  bool _includeDeletedExpenses = false;
  bool _isValidatingBackup = false;
  bool _isRestoringBackup = false;

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
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isCreatingJsonBackup
                          ? null
                          : () => _createJsonBackup(state),
                      icon: _isCreatingJsonBackup
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.backup_outlined),
                      label: Text(_isCreatingJsonBackup
                          ? 'Preparing backup'
                          : 'Back up JSON'),
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
                  Text('Data import',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isValidatingBackup || _isRestoringBackup
                          ? null
                          : _validateBackupFile,
                      icon: _isValidatingBackup
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.file_open_outlined),
                      label: Text(_isValidatingBackup
                          ? 'Validating...'
                          : 'Validate backup file'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Select a backup JSON file to verify its structure and compatibility before importing. No changes will be made to your data.',
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
      showSuccessSnackbar(context, message);
    } catch (_) {
      if (!mounted) return;
      showErrorSnackbar(context, 'CSV export failed.');
    } finally {
      if (mounted) {
        setState(() => _isExportingExpenses = false);
      }
    }
  }

  Future<void> _createJsonBackup(AppState state) async {
    setState(() => _isCreatingJsonBackup = true);

    try {
      final file = await widget.jsonBackupService.createBackup(
        expenses: [...state.expenses, ...state.deletedExpenses],
        groceryItems: await state.listAllGroceryItemsForExport(),
        categories: state.categories,
        budgets: await state.listAllBudgetsForExport(),
        settings: state.settings,
      );
      final shareResult = await widget.exportShareService.shareFile(
        file,
        subject: 'WalletMelt JSON backup',
        title: 'Back up WalletMelt data',
      );
      if (!mounted) return;

      await state.recordExportedAt(file.createdAt);
      if (!mounted) return;

      final message = switch (shareResult.status) {
        ExportShareStatus.success => 'JSON backup shared.',
        ExportShareStatus.dismissed => 'JSON backup canceled.',
        ExportShareStatus.unavailable => 'JSON backup file is ready.',
      };
      showSuccessSnackbar(context, message);
    } catch (_) {
      if (!mounted) return;
      showErrorSnackbar(context, 'JSON backup failed.');
    } finally {
      if (mounted) {
        setState(() => _isCreatingJsonBackup = false);
      }
    }
  }

  Future<void> _validateBackupFile() async {
    setState(() => _isValidatingBackup = true);

    try {
      final content = await widget.filePickerService.pickJsonFileContent();
      if (!mounted) return;

      if (content == null) {
        return;
      }

      final result = widget.importValidationService.validateBackup(content);
      if (!mounted) return;

      if (result.isValid) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Backup file is valid.\n'
              'Preview found ${result.expensesCount} expenses, '
              '${result.groceryItemsCount} items, '
              '${result.categoriesCount} categories, and '
              '${result.budgetsCount} budgets. No data has been imported.',
            ),
            backgroundColor: WalletMeltColors.positive,
          ),
        );

        final preview = widget.previewService.generatePreview(content);
        if (preview.isValid) {
          // Run read-only conflict detection against current app data.
          final state = context.read<AppState>();
          BackupConflictSummary? conflictSummary;
          RestoreDryRunPlan? dryRunPlan;
          try {
            final groceryItems = await state.listAllGroceryItemsForExport();
            final budgets = await state.listAllBudgetsForExport();
            if (!mounted) return;
            final snapshot = LocalAppSnapshot(
              expenses: state.expenses,
              deletedExpenses: state.deletedExpenses,
              categories: state.categories,
              budgets: budgets,
              groceryItems: groceryItems,
              settings: state.settings,
            );
            conflictSummary = widget.conflictService.detect(
              jsonText: content,
              localSnapshot: snapshot,
            );
            dryRunPlan = widget.restoreDryRunPlanner.plan(
              jsonText: content,
              localSnapshot: snapshot,
              conflictSummary: conflictSummary,
            );
          } catch (_) {
            // Conflict detection failure is non-blocking; preview still shows.
          }
          if (!mounted) return;

          _showBackupPreviewDialog(
            content,
            preview,
            conflictSummary: conflictSummary,
            dryRunPlan: dryRunPlan,
          );
        }
      } else {
        showErrorSnackbar(
          context,
          'Invalid backup file: '
          '${_safeRestoreErrorMessage(result.error ?? "Unknown error")}',
        );
      }
    } catch (e) {
      if (!mounted) return;
      showErrorSnackbar(
        context,
        'Could not read the selected backup file. No data was changed. '
        '${_safeRestoreErrorMessage(e.toString())}',
      );
    } finally {
      if (mounted) {
        setState(() => _isValidatingBackup = false);
      }
    }
  }

  void _showBackupPreviewDialog(
    String jsonText,
    WalletMeltBackupPreview preview, {
    BackupConflictSummary? conflictSummary,
    RestoreDryRunPlan? dryRunPlan,
  }) {
    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final sectionTitleStyle = Theme.of(context).textTheme.titleMedium;
        final bodyStyle = Theme.of(context).textTheme.bodyMedium;
        final canRestore = dryRunPlan != null && _canRestoreSafely(dryRunPlan);

        return Dialog(
          backgroundColor:
              isDark ? const Color(0xFF161616) : const Color(0xFFFAFAF6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.preview_rounded,
                          color: WalletMeltColors.brand, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Backup Preview',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 16),
                  Text('Metadata', style: sectionTitleStyle),
                  const SizedBox(height: 8),
                  _buildMetadataRow('Format', preview.format ?? 'Unknown'),
                  _buildMetadataRow('Format Version',
                      '${preview.formatVersion ?? "Unknown"}'),
                  _buildMetadataRow(
                      'App Version', preview.appVersion ?? 'Unknown'),
                  _buildMetadataRow('Exported At',
                      _formatExportedAt(preview.exportedAt) ?? 'Unknown'),
                  const SizedBox(height: 16),
                  Text('Contents', style: sectionTitleStyle),
                  const SizedBox(height: 8),
                  _buildContentCountRow(
                      Icons.monetization_on_outlined,
                      'Expenses',
                      '${preview.expensesCount} (${preview.deletedExpensesCount} deleted)'),
                  _buildContentCountRow(Icons.shopping_basket_outlined,
                      'Grocery Items', '${preview.groceryItemsCount} items'),
                  _buildContentCountRow(Icons.category_outlined, 'Categories',
                      '${preview.categoriesCount} categories'),
                  _buildContentCountRow(Icons.calendar_month_outlined,
                      'Budgets', '${preview.budgetsCount} budgets'),
                  _buildContentCountRow(
                      Icons.settings_suggest_outlined,
                      'Settings Configuration',
                      preview.hasSettings ? 'Included' : 'Missing'),
                  // Conflict check section.
                  if (conflictSummary != null) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(
                          conflictSummary.hasAnyConflict
                              ? Icons.rule_rounded
                              : Icons.check_circle_outline_rounded,
                          color: conflictSummary.hasAnyConflict
                              ? WalletMeltColors.warning
                              : Colors.green,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Conflict check',
                            style: sectionTitleStyle?.copyWith(
                              color: conflictSummary.hasAnyConflict
                                  ? WalletMeltColors.warning
                                  : Colors.green,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (!conflictSummary.hasAnyConflict)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          'No conflicts detected with current local data.',
                          style: bodyStyle?.copyWith(
                            color: Colors.green,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    for (final line in conflictSummary.summaryLines)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.warning_amber_rounded,
                              color: WalletMeltColors.warning,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                line,
                                style: bodyStyle?.copyWith(
                                  color: WalletMeltColors.warning,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      canRestore
                          ? 'Safe merge is available after confirmation. '
                              'Local data will be preserved and no receipt '
                              'files will be recovered.'
                          : _disabledRestoreReason(dryRunPlan),
                      style: bodyStyle?.copyWith(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                  if (dryRunPlan != null) ...[
                    const SizedBox(height: 16),
                    _buildDryRunPlanSection(dryRunPlan),
                  ],
                  if (preview.warnings.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text('Warnings',
                        style: sectionTitleStyle?.copyWith(
                            color: WalletMeltColors.warning)),
                    const SizedBox(height: 8),
                    for (final warning in preview.warnings)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.warning_amber_rounded,
                                color: WalletMeltColors.warning, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                warning,
                                style: bodyStyle?.copyWith(
                                    color: WalletMeltColors.warning,
                                    fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: WalletMeltColors.brand.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: WalletMeltColors.brand.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline_rounded,
                            color: WalletMeltColors.brandDeep, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'No data has been imported yet. You are looking at a read-only preview of the backup file.',
                            style: bodyStyle?.copyWith(
                              color: isDark
                                  ? WalletMeltColors.brandSoft
                                  : WalletMeltColors.brandDeep,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text('Close'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: canRestore && !_isRestoringBackup
                              ? () {
                                  Navigator.pop(context);
                                  _confirmAndRestoreBackup(
                                    jsonText,
                                    dryRunPlan,
                                  );
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                WalletMeltColors.brand.withValues(alpha: 0.5),
                            disabledBackgroundColor:
                                isDark ? Colors.white12 : Colors.black12,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            _isRestoringBackup
                                ? 'Restoring...'
                                : canRestore
                                    ? 'Safe merge'
                                    : 'Restore (N/A)',
                            style: TextStyle(
                              color: canRestore ? Colors.white : Colors.white24,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmAndRestoreBackup(
    String jsonText,
    RestoreDryRunPlan dryRunPlan,
  ) async {
    if (_isRestoringBackup) return;

    final confirmed = await showConfirmDialog(
      context,
      title: 'Safe merge backup?',
      confirmLabel: 'Create safety backup and merge',
      body:
          'Safe merge adds only restorable backup records. Existing local data is preserved.\n\n'
          'Duplicate IDs may be remapped, but local records and budgets will not be overwritten.\n\n'
          'Receipt paths stay as text references only. Receipt image files are not recovered or copied.\n\n'
          'A safety backup of current local data is created before restore. If that backup cannot be created, restore stops before any import.',
    );

    if (confirmed != true || !mounted) return;
    if (_isRestoringBackup) return;

    setState(() => _isRestoringBackup = true);
    try {
      final state = context.read<AppState>();
      final safetyBackup = await widget.jsonBackupService.createBackup(
        expenses: [...state.expenses, ...state.deletedExpenses],
        groceryItems: await state.listAllGroceryItemsForExport(),
        categories: state.categories,
        budgets: await state.listAllBudgetsForExport(),
        settings: state.settings,
      );
      if (!mounted) return;

      final result = await state.restoreJsonBackupSafeMerge(
        jsonText: jsonText,
        dryRunPlan: dryRunPlan,
        safetyBackup: safetyBackup,
        restoreService: widget.restoreService,
        options: const WalletMeltJsonRestoreOptions(confirmed: true),
      );
      if (!mounted) return;

      if (result.success) {
        _showRestoreSuccessSnackbar(context, result);
      } else {
        _showRestoreFailureSnackbar(context, result);
      }
    } catch (error) {
      if (!mounted) return;
      showErrorSnackbar(
        context,
        'Restore did not start. No data was changed. '
        'Check that a safety backup can be created, then try again. '
        '${_safeRestoreErrorMessage(error.toString())}',
      );
    } finally {
      if (mounted) {
        setState(() => _isRestoringBackup = false);
      }
    }
  }

  bool _canRestoreSafely(RestoreDryRunPlan plan) {
    if (!plan.isValid || plan.hasBlockers) return false;
    final requiredGates = {
      RestoreDryRunSafetyGate.backupFormatSupported,
      RestoreDryRunSafetyGate.formatVersionSupported,
      RestoreDryRunSafetyGate.previewGenerated,
      RestoreDryRunSafetyGate.conflictSummaryReviewed,
      RestoreDryRunSafetyGate.noUnresolvedBlockers,
    };
    for (final gate in requiredGates) {
      final status = plan.safetyGates.where((entry) => entry.gate == gate);
      if (status.isEmpty || !status.first.satisfied) return false;
    }
    return true;
  }

  void _showRestoreSuccessSnackbar(
      BuildContext context, WalletMeltJsonRestoreResult result) {
    final safetyBackupName = _safetyBackupName(result.safetyBackupPath);
    final backupText = safetyBackupName == null
        ? 'A pre-restore safety backup was created.'
        : 'Safety backup created: $safetyBackupName.';
    showSuccessSnackbar(
      context,
      'Safe merge complete: ${result.insertedExpenses} expenses, '
      '${result.insertedGroceryItems} items, '
      '${result.insertedCategories} categories, and '
      '${result.insertedBudgets} budgets imported. '
      'Local data was preserved. $backupText '
      'Receipt paths remain text references only.',
    );
  }

  void _showRestoreFailureSnackbar(
      BuildContext context, WalletMeltJsonRestoreResult result) {
    final safetyBackupName = _safetyBackupName(result.safetyBackupPath);
    final backupText = safetyBackupName == null
        ? 'No verified safety backup was reported.'
        : 'Safety backup created before the failed restore: $safetyBackupName.';
    showErrorSnackbar(
      context,
      'Restore failed safely. No partial import should remain because '
      'WalletMelt rolls back the transaction. $backupText '
      'Reason: ${_safeRestoreErrorMessage(result.errorMessage ?? "Unknown restore error.")}',
    );
  }

  String? _safetyBackupName(String? path) {
    if (path == null || path.trim().isEmpty) return null;
    return p.basename(path);
  }

  String _safeRestoreErrorMessage(String message) {
    final firstLine = message
        .replaceAll(RegExp(r'\s+'), ' ')
        .split(RegExp(r'[#\n\r]'))
        .first
        .trim();
    var sanitized = firstLine
        .replaceFirst(RegExp(r'^Exception:\s*'), '')
        .replaceFirst(RegExp(r'^StateError:\s*'), '')
        .replaceFirst(RegExp(r'^SqliteException\(\d+\):\s*'), '')
        .replaceAll(RegExp(r'at package:[^ ]+'), '')
        .trim();
    const maxLength = 180;
    if (sanitized.length > maxLength) {
      sanitized = '${sanitized.substring(0, maxLength).trimRight()}...';
    }
    return sanitized.isEmpty ? 'Unknown restore error.' : sanitized;
  }

  String _disabledRestoreReason(RestoreDryRunPlan? plan) {
    if (_isRestoringBackup) {
      return 'Restore is already running. Wait for it to finish before selecting another backup.';
    }
    if (plan == null || !plan.isValid) {
      return 'Restore is unavailable because the backup could not be fully planned. No data has been changed.';
    }
    if (plan.hasBlockers) {
      return 'Restore is unavailable because blockers must be resolved first. WalletMelt will not resolve conflicts automatically.';
    }
    return 'Restore is unavailable until validation, preview, conflict review, confirmation, safety backup, and transaction checks are complete.';
  }

  Widget _buildDryRunPlanSection(RestoreDryRunPlan plan) {
    final theme = Theme.of(context);
    final sectionTitleStyle = theme.textTheme.titleMedium;
    final bodyStyle = theme.textTheme.bodyMedium;
    final pendingSafetyGates = plan.unsatisfiedSafetyGates
        .map((gate) => gate.label)
        .take(3)
        .join(', ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              plan.hasBlockers
                  ? Icons.report_problem_outlined
                  : Icons.fact_check_outlined,
              color: plan.hasBlockers
                  ? WalletMeltColors.warning
                  : WalletMeltColors.positive,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Dry-run restore plan',
                style: sectionTitleStyle?.copyWith(
                  color: plan.hasBlockers
                      ? WalletMeltColors.warning
                      : Colors.green,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildContentCountRow(
          Icons.category_outlined,
          'Planned categories',
          '${plan.plannedCounts.categories}',
        ),
        _buildContentCountRow(
          Icons.monetization_on_outlined,
          'Planned expenses',
          '${plan.plannedCounts.expenses}',
        ),
        _buildContentCountRow(
          Icons.shopping_basket_outlined,
          'Planned grocery items',
          '${plan.plannedCounts.groceryItems}',
        ),
        _buildContentCountRow(
          Icons.calendar_month_outlined,
          'Planned budgets',
          '${plan.plannedCounts.budgets}',
        ),
        _buildContentCountRow(
          Icons.warning_amber_outlined,
          'Blockers / warnings',
          '${plan.blockerCount} / ${plan.warningCount}',
        ),
        const SizedBox(height: 8),
        Text(
          pendingSafetyGates.isEmpty
              ? _disabledRestoreReason(plan)
              : 'Dry-run only. Pending safety checks: $pendingSafetyGates.',
          style: bodyStyle?.copyWith(
            fontSize: 12,
            color: theme.colorScheme.onSurfaceVariant,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildMetadataRow(String label, String value) {
    final style = Theme.of(context).textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(
            value,
            style: style?.copyWith(
                fontWeight: FontWeight.w700,
                color: Theme.of(context).brightness == Brightness.dark
                    ? WalletMeltColors.darkTextPrimary
                    : WalletMeltColors.textPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildContentCountRow(IconData icon, String label, String value) {
    final style = Theme.of(context).textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: WalletMeltColors.textSecondary),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: style)),
          Text(
            value,
            style: style?.copyWith(
                fontWeight: FontWeight.w700,
                color: Theme.of(context).brightness == Brightness.dark
                    ? WalletMeltColors.darkTextPrimary
                    : WalletMeltColors.textPrimary),
          ),
        ],
      ),
    );
  }

  String? _formatExportedAt(String? isoString) {
    if (isoString == null) return null;
    final parsed = DateTime.tryParse(isoString);
    if (parsed == null) return isoString;
    final local = parsed.toLocal();
    return '${local.year}-${_twoDigits(local.month)}-${_twoDigits(local.day)} '
        '${_twoDigits(local.hour)}:${_twoDigits(local.minute)}';
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
