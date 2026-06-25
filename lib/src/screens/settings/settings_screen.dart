import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
import '../../services/export/wallet_melt_json_backup_validator.dart';
import '../../services/export/wallet_melt_json_restore_dry_run_planner.dart';
import '../../services/export/wallet_melt_json_restore_service.dart';
import '../../services/export/wallet_melt_json_restore_plan.dart';
import 'backup_restore_dialog.dart';
import 'restore_summary_dialog.dart';
import '../../state/app_state.dart';
import '../../theme/wallet_melt_theme.dart';
import '../../types/settings.dart';
import '../../widgets/app_snackbar.dart';

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
    this.safetyBackupDirectory,
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
  final Directory? safetyBackupDirectory;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isExportingExpenses = false;
  bool _isCreatingJsonBackup = false;
  bool _includeDeletedExpenses = false;
  bool _isValidatingBackup = false;
  bool _isRestoreInProgress = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AppState>().loadDeletedExpenses();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    final theme = Theme.of(context);
    final currency = context.select((AppState s) => s.settings.currency);
    final themePreference =
        context.select((AppState s) => s.settings.themePreference);
    final lastExportedAt =
        context.select((AppState s) => s.settings.lastExportedAt);
    final expensesLength = context.select((AppState s) => s.expenses.length);
    final deletedExpensesLength =
        context.select((AppState s) => s.deletedExpenses.length);

    return Scaffold(
      body: AppBackground(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
          children: [
            Row(
              children: [
                IconButton(
                  tooltip: 'Back',
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Settings',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.headlineMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // CARD 1: PREFERENCES
            WMGlassSurface.tier2(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Preferences',
                      style: theme.textTheme.titleLarge),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: currency,
                    decoration: const InputDecoration(labelText: 'Currency'),
                    dropdownColor:
                        theme.brightness == Brightness.dark
                            ? WalletMeltColors.darkSurface
                            : Colors.white,
                    borderRadius: BorderRadius.circular(20),
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
                    initialValue: themePreference,
                    decoration: const InputDecoration(labelText: 'Theme'),
                    dropdownColor:
                        theme.brightness == Brightness.dark
                            ? WalletMeltColors.darkSurface
                            : Colors.white,
                    borderRadius: BorderRadius.circular(20),
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

            // CARD 2: BACKUP & DATA MANAGEMENT
            WMGlassSurface.tier2(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Backup & Data Management',
                      style: theme.textTheme.titleLarge),
                  const SizedBox(height: 12),

                  // Data export subsection
                  Text('Data export',
                      style: theme.textTheme.titleMedium?.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          )),
                  const SizedBox(height: 4),
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

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child:
                        Divider(height: 1, color: Colors.grey, thickness: 0.12),
                  ),

                  // Data import subsection
                  Text('Data import',
                      style: theme.textTheme.titleMedium?.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          )),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isValidatingBackup || _isRestoreInProgress
                          ? null
                          : _validateBackupFile,
                      icon: _isValidatingBackup
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.restore_outlined),
                      label: Text(_isValidatingBackup
                          ? 'Validating...'
                          : 'Validate backup file'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Select a backup JSON file to verify its structure and compatibility before importing. No changes will be made to your data.',
                    style: theme.textTheme.bodySmall,
                  ),

                  const SizedBox(height: AppSpacing.md),
                  Text(
                    _exportStatusText(currency, expensesLength,
                        deletedExpensesLength, lastExportedAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // CARD 3: ABOUT & PRIVACY
            WMGlassSurface.tier2(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('About WalletMelt',
                      style: theme.textTheme.titleLarge),
                  const SizedBox(height: 12),
                  Text('Privacy First',
                      style: theme.textTheme.titleMedium?.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          )),
                  const SizedBox(height: 4),
                  Text(
                    'All expenses, settings, categories, budgets, and receipt images stay stored locally on this device. There is no remote login, backend databases, or cloud tracking.',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontSize: 13),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child:
                        Divider(height: 1, color: Colors.grey, thickness: 0.12),
                  ),
                  Text('Future Scope',
                      style: theme.textTheme.titleMedium?.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          )),
                  const SizedBox(height: 4),
                  Text(
                    'Automatic cloud synchronization, shared household ledger profiles, OCR-based receipt scanning, and recurring expense reminders are planned for future versions.',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontSize: 13),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child:
                        Divider(height: 1, color: Colors.grey, thickness: 0.12),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Version',
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      Text('v0.1.1',
                          style: theme.textTheme.bodyMedium),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 84), // Space for floating app navigation bar
          ],
        ),
      ),
    );
  }

  Future<void> _exportExpensesCsv(AppState state) async {
    setState(() => _isExportingExpenses = true);

    try {
      if (_includeDeletedExpenses) {
        await state.loadDeletedExpenses();
      }
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
      await state.loadDeletedExpenses();
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
    if (kDebugMode) {
      debugPrint('_validateBackupFile CALLED');
    }
    setState(() => _isValidatingBackup = true);

    try {
      final backupFile = await widget.filePickerService.pickBackupFile();
      if (!mounted) return;

      if (backupFile == null) {
        return;
      }

      final result = Platform.environment.containsKey('FLUTTER_TEST')
          ? widget.importValidationService.validateBackup(backupFile.jsonText)
          : await compute(_validateBackupIsolate, backupFile.jsonText);
      if (!mounted) return;

      if (result.isValid) {
        final preview = Platform.environment.containsKey('FLUTTER_TEST')
            ? widget.previewService.generatePreview(backupFile.jsonText)
            : await compute(_generatePreviewIsolate, backupFile.jsonText);
        if (!mounted) return;
        if (preview.isValid) {
          final state = context.read<AppState>();
          await state.loadDeletedExpenses();
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

          BackupConflictSummary? conflictSummary;
          RestoreDryRunPlan? dryRunPlan;
          try {
            if (Platform.environment.containsKey('FLUTTER_TEST')) {
              conflictSummary = widget.conflictService.detect(
                jsonText: backupFile.jsonText,
                localSnapshot: snapshot,
              );
              dryRunPlan = widget.restoreDryRunPlanner.plan(
                jsonText: backupFile.jsonText,
                localSnapshot: snapshot,
                conflictSummary: conflictSummary,
                mode: RestoreMode.safeMerge,
              );
            } else {
              conflictSummary = await compute(
                _detectConflictsIsolate,
                _ConflictDetectionArgs(backupFile.jsonText, snapshot),
              );
              if (!mounted) return;
              dryRunPlan = await compute(
                _planRestoreIsolate,
                _RestorePlanArgs(
                  jsonText: backupFile.jsonText,
                  localSnapshot: snapshot,
                  conflictSummary: conflictSummary,
                  mode: RestoreMode.safeMerge,
                ),
              );
            }
          } catch (e) {
            if (kDebugMode) {
              debugPrint('Conflict/dry-run detection threw: $e');
            }
          }

          if (!mounted) return;

          _showBackupRestoreDialog(
            backupFile: backupFile,
            preview: preview,
            localSnapshot: snapshot,
            conflictSummary: conflictSummary,
            dryRunPlan: dryRunPlan,
          );
        } else {
          // Fallback snackbar when preview is invalid but validation result is valid (e.g. legacy tests)
          showSuccessSnackbar(
            context,
            'Backup file is valid. Preview found ${result.expensesCount} expenses, '
            '${result.groceryItemsCount} items, ${result.categoriesCount} categories, '
            'and ${result.budgetsCount} budgets. No data has been imported or changed.',
          );
        }
      } else {
        showErrorSnackbar(
          context,
          'Invalid backup file: '
          '${_safeRestoreErrorMessage(result.error ?? "Unknown error")}',
        );
        if (kDebugMode) {
          debugPrint('VALIDATION RESULT INVALID: ${result.error}');
        }
      }
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('VALIDATION EXCEPTION: $e\n$stack');
      }
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

  void _showBackupRestoreDialog({
    required WalletMeltBackupFile backupFile,
    required WalletMeltBackupPreview preview,
    required LocalAppSnapshot localSnapshot,
    BackupConflictSummary? conflictSummary,
    RestoreDryRunPlan? dryRunPlan,
  }) {
    if (kDebugMode) {
      debugPrint('SHOW DIALOG CALLED');
    }
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return BackupRestoreDialog(
          backupFile: backupFile,
          preview: preview,
          localSnapshot: localSnapshot,
          initialConflictSummary: conflictSummary,
          initialDryRunPlan: dryRunPlan,
          jsonBackupService: widget.jsonBackupService,
          restoreService: widget.restoreService,
          onSuccess: (result, durationSeconds, mode, backupVersion) {
            _showRestoreSummaryDialog(
                result, durationSeconds, mode, backupVersion);
          },
          onRestoreStarted: () {
            setState(() => _isRestoreInProgress = true);
          },
          onRestoreFinished: () {
            setState(() => _isRestoreInProgress = false);
          },
          safetyBackupDirectory: widget.safetyBackupDirectory,
        );
      },
    );
  }

  void _showRestoreSummaryDialog(
    WalletMeltJsonRestoreResult result,
    double durationSeconds,
    RestoreMode mode,
    int backupVersion,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return RestoreSummaryDialog(
          result: result,
          durationSeconds: durationSeconds,
          mode: mode,
          backupVersion: backupVersion,
        );
      },
    );
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

  String _exportStatusText(String currency, int expensesLength,
      int deletedExpensesLength, String? lastExportedAt) {
    final activeCount = expensesLength;
    final deletedCount = deletedExpensesLength;
    final countText = _includeDeletedExpenses
        ? '$activeCount active, $deletedCount deleted'
        : '$activeCount active';
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

class _ConflictDetectionArgs {
  final String jsonText;
  final LocalAppSnapshot localSnapshot;
  const _ConflictDetectionArgs(this.jsonText, this.localSnapshot);
}

BackupConflictSummary _detectConflictsIsolate(_ConflictDetectionArgs args) {
  const conflictService = WalletMeltJsonBackupConflictService();
  return conflictService.detect(
    jsonText: args.jsonText,
    localSnapshot: args.localSnapshot,
  );
}

class _RestorePlanArgs {
  final String jsonText;
  final LocalAppSnapshot localSnapshot;
  final BackupConflictSummary? conflictSummary;
  final RestoreMode mode;
  const _RestorePlanArgs({
    required this.jsonText,
    required this.localSnapshot,
    this.conflictSummary,
    required this.mode,
  });
}

RestoreDryRunPlan _planRestoreIsolate(_RestorePlanArgs args) {
  const planner = WalletMeltJsonRestoreDryRunPlanner();
  return planner.plan(
    jsonText: args.jsonText,
    localSnapshot: args.localSnapshot,
    conflictSummary: args.conflictSummary,
    mode: args.mode,
  );
}

BackupValidationResult _validateBackupIsolate(String jsonText) {
  const service = WalletMeltJsonBackupImportValidationService();
  return service.validateBackup(jsonText);
}

WalletMeltBackupPreview _generatePreviewIsolate(String jsonText) {
  const service = WalletMeltJsonBackupPreviewService();
  return service.generatePreview(jsonText);
}
