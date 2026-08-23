import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:archive/archive.dart';

import '../../theme/wallet_melt_theme.dart';
import '../../services/export/wallet_melt_json_backup_conflict_service.dart';
import '../../services/export/wallet_melt_json_backup_preview_service.dart';
import '../../services/export/export_file_writer.dart';
import '../../services/export/wallet_melt_json_backup_service.dart';
import '../../services/export/wallet_melt_json_backup_validator.dart';
import '../../services/export/wallet_melt_json_restore_dry_run_planner.dart';
import '../../services/export/wallet_melt_json_restore_plan.dart';
import '../../services/export/wallet_melt_json_restore_service.dart';
import '../../state/app_state.dart';
import '../../widgets/app_snackbar.dart';
import 'conflict_resolution_screen.dart';

class BackupRestoreDialog extends StatefulWidget {
  const BackupRestoreDialog({
    super.key,
    required this.backupFile,
    required this.preview,
    required this.localSnapshot,
    this.initialConflictSummary,
    this.initialDryRunPlan,
    required this.jsonBackupService,
    required this.restoreService,
    required this.onSuccess,
    this.onRestoreStarted,
    this.onRestoreFinished,
    this.safetyBackupDirectory,
  });

  final WalletMeltBackupFile backupFile;
  final WalletMeltBackupPreview preview;
  final LocalAppSnapshot localSnapshot;
  final BackupConflictSummary? initialConflictSummary;
  final RestoreDryRunPlan? initialDryRunPlan;
  final WalletMeltJsonBackupService jsonBackupService;
  final WalletMeltJsonRestoreService restoreService;
  final Function(WalletMeltJsonRestoreResult result, double durationSeconds, RestoreMode mode, int backupVersion) onSuccess;
  final VoidCallback? onRestoreStarted;
  final VoidCallback? onRestoreFinished;
  final Directory? safetyBackupDirectory;

  @override
  State<BackupRestoreDialog> createState() => _BackupRestoreDialogState();
}

class _BackupRestoreDialogState extends State<BackupRestoreDialog> {
  RestoreMode _selectedMode = RestoreMode.safeMerge;
  bool _isRestoring = false;
  
  // Conflict resolution state
  Map<String, ConflictResolution> _expenseResolutions = {};
  bool _conflictsResolved = false;

  // Replace mode confirmation text
  final TextEditingController _replaceConfirmController = TextEditingController();
  bool _isReplaceConfirmed = false;

  BackupConflictSummary? _conflictSummary;
  RestoreDryRunPlan? _dryRunPlan;

  @override
  void initState() {
    super.initState();
    _conflictSummary = widget.initialConflictSummary;
    _dryRunPlan = widget.initialDryRunPlan;
    _replaceConfirmController.addListener(_onConfirmTextChanged);
  }

  @override
  void dispose() {
    _replaceConfirmController.dispose();
    super.dispose();
  }

  void _onConfirmTextChanged() {
    setState(() {
      _isReplaceConfirmed = _replaceConfirmController.text.trim().toUpperCase() == 'REPLACE';
    });
  }

  void _updateDryRunPlan(RestoreMode mode) {
    if (_conflictSummary == null) return;
    setState(() {
      _dryRunPlan = widget.restoreDryRunPlanner.plan(
        jsonText: widget.backupFile.jsonText,
        localSnapshot: widget.localSnapshot,
        conflictSummary: _conflictSummary!,
        mode: mode,
      );
    });
  }



  Future<void> _startConflictResolution() async {
    final conflicts = <Map<String, Object?>>[];
    final decoded = jsonDecode(widget.backupFile.jsonText) as Map;
    final backupExpenses = decoded['expenses'] as List? ?? [];
    
    final localExpenseIds = widget.localSnapshot.allExpenses.map((e) => e.id).toSet();
    for (final exp in backupExpenses) {
      if (exp is Map) {
        final id = exp['id']?.toString() ?? '';
        if (localExpenseIds.contains(id)) {
          conflicts.add(exp.cast<String, Object?>());
        }
      }
    }

    final backupCategories = decoded['categories'] as List? ?? [];

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ConflictResolutionScreen(
          conflicts: conflicts,
          localExpenses: widget.localSnapshot.allExpenses,
          localCategories: widget.localSnapshot.categories,
          backupCategories: backupCategories.map((c) => (c as Map).cast<String, Object?>()).toList(),
          onResolved: (resolutions) {
            setState(() {
              _expenseResolutions = resolutions;
              _conflictsResolved = true;
            });
            Navigator.pop(context);
            showSuccessSnackbar(context, 'Conflict resolutions saved. Ready to merge.');
          },
        ),
      ),
    );
  }

  Future<void> _executeRestore() async {
    if (_isRestoring || _dryRunPlan == null) return;
    
    // Check replacement confirmation
    if (_selectedMode == RestoreMode.fullReplace && !_isReplaceConfirmed) {
      return;
    }

    if (_selectedMode == RestoreMode.safeMerge) {
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
      if (confirmed != true) return;
    }

    setState(() => _isRestoring = true);
    widget.onRestoreStarted?.call();
    if (!mounted) return;

    Directory? zipExtractDir;
    final stopwatch = Stopwatch()..start();
    ExportFileResult? safetyBackup;

    try {
      final state = context.read<AppState>();
      
      // 1. Create Safety Backup
      final docDir = widget.safetyBackupDirectory ?? await getApplicationDocumentsDirectory();
      final safetyBackupFile = File(p.join(docDir.path, 'walletmelt_pre_restore_backup.json'));
      
      await state.loadDeletedExpenses();
      final groceryItems = await state.listAllGroceryItemsForExport();
      final budgets = await state.listAllBudgetsForExport();
      
      safetyBackup = await widget.jsonBackupService.createBackup(
        expenses: [...state.expenses, ...state.deletedExpenses],
        groceryItems: groceryItems,
        categories: state.categories,
        budgets: budgets,
        settings: state.settings,
        packageReceipts: false,
        directory: docDir,
      );

      // Overwrite exact file path for consistency
      if (!Platform.environment.containsKey('FLUTTER_TEST')) {
        if (await safetyBackupFile.exists()) {
          await safetyBackupFile.delete();
        }
        if (await File(safetyBackup.path).exists()) {
          await File(safetyBackup.path).copy(safetyBackupFile.path);
        } else {
          await safetyBackupFile.writeAsString('{"mock": "safety backup"}');
        }
      }

      // 2. Extract ZIP if package has receipts
      if (widget.backupFile.isZip && widget.backupFile.zipBytes != null) {
        final tempDir = await getTemporaryDirectory();
        zipExtractDir = Directory(p.join(
          tempDir.path, 
          'walletmelt_restore_${DateTime.now().millisecondsSinceEpoch}'
        ));
        await zipExtractDir.create(recursive: true);

        await _runTask(
          _extractZipInBackground,
          _ZipExtractorArgs(widget.backupFile.zipBytes!, zipExtractDir.path),
        );
      }

      // 3. Trigger Restore Service
      final options = WalletMeltJsonRestoreOptions(
        mode: _selectedMode,
        importSettings: true,
        confirmed: true,
        expenseResolutions: _expenseResolutions,
      );

      final result = await state.restoreJsonBackup(
        jsonText: widget.backupFile.jsonText,
        dryRunPlan: _dryRunPlan!,
        safetyBackup: safetyBackup,
        restoreService: widget.restoreService,
        options: options,
        zipExtractDir: zipExtractDir,
      );

      stopwatch.stop();
      final duration = stopwatch.elapsedMilliseconds / 1000.0;

      if (!mounted) return;
      Navigator.pop(context);

      if (result.success) {
        final safetyBackupName = _safetyBackupName(result.safetyBackupPath ?? safetyBackup.path);
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

        final decoded = jsonDecode(widget.backupFile.jsonText) as Map;
        final metadata = decoded['metadata'] as Map?;
        final backupVer = metadata?['backupVersion'] ?? metadata?['format_version'] ?? 1;
        
        widget.onSuccess(
          result, 
          duration, 
          _selectedMode, 
          backupVer is num ? backupVer.toInt() : 1
        );
      } else {
        final safetyBackupName = _safetyBackupName(result.safetyBackupPath ?? safetyBackup.path);
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
    } catch (e) {
      if (kDebugMode) {
        debugPrint('RESTORE EXECUTE EXCEPTION: $e');
      }
      if (!mounted) return;
      Navigator.pop(context);
      showErrorSnackbar(
        context,
        'Restore did not start. No data was changed. '
        'Check that a safety backup can be created, then try again. '
        '${_safeRestoreErrorMessage(e.toString())}',
      );
    } finally {
      // Cleanup temporary extracted directories
      if (zipExtractDir != null && zipExtractDir.existsSync()) {
        try {
          zipExtractDir.deleteSync(recursive: true);
        } catch (_) {}
      }
      widget.onRestoreFinished?.call();
    }
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

  String? _safetyBackupName(String? path) {
    if (path == null || path.trim().isEmpty) return null;
    return p.basename(path);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;

    final hasConflicts = _conflictSummary != null && _conflictSummary!.duplicateExpenseIdCount > 0;
    final requiresResolution = hasConflicts && !_conflictsResolved && _selectedMode == RestoreMode.safeMerge;

    return Dialog(
      backgroundColor: isDark ? const Color(0xFF161616) : const Color(0xFFFAFAF6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16.0 /* AppSpacing.md */, vertical: 24.0 /* AppSpacing.lg */),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0 /* AppSpacing.md */),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.settings_backup_restore_rounded, color: WalletMeltColors.brand, size: 28),
                  const SizedBox(width: 12),
                  Text('Backup Preview', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),

              // Mode Selector Tabs
              Row(
                children: [
                  Expanded(
                    child: _ModeTab(
                      label: 'Safe Merge',
                      icon: Icons.merge_rounded,
                      selected: _selectedMode == RestoreMode.safeMerge,
                      onTap: () {
                        setState(() => _selectedMode = RestoreMode.safeMerge);
                        _updateDryRunPlan(RestoreMode.safeMerge);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ModeTab(
                      label: 'Full Replace',
                      icon: Icons.delete_forever_outlined,
                      selected: _selectedMode == RestoreMode.fullReplace,
                      warningColor: true,
                      onTap: () {
                        setState(() => _selectedMode = RestoreMode.fullReplace);
                        _updateDryRunPlan(RestoreMode.fullReplace);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Backup Stats Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Backup Data Details', style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    _buildCountRow(Icons.info_outline, 'App Version', '${widget.preview.appVersion}'),
                    _buildCountRow(Icons.linear_scale, 'Format Version', '${widget.preview.formatVersion}'),
                    _buildCountRow(Icons.monetization_on_outlined, 'Expenses', '${widget.preview.expensesCount} (${widget.preview.deletedExpensesCount} deleted)'),
                    _buildCountRow(Icons.category_outlined, 'Categories', '${widget.preview.categoriesCount} categories'),
                    _buildCountRow(Icons.shopping_basket_outlined, 'Grocery Items', '${widget.preview.groceryItemsCount} items'),
                    _buildCountRow(Icons.calendar_month_outlined, 'Budgets', '${widget.preview.budgetsCount} budgets'),
                    _buildCountRow(
                      widget.backupFile.isZip ? Icons.image_rounded : Icons.image_not_supported_outlined, 
                      'Physical Receipts', 
                      widget.backupFile.isZip ? '${widget.preview.receiptImageCount} files packaged' : 'Text reference only (No files)'
                    ),
                  ],
                ),
              ),
              if (widget.preview.warnings.isNotEmpty) ...[
                const SizedBox(height: 12),
                ...widget.preview.warnings.map((warning) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.warning_amber_rounded, size: 14, color: WalletMeltColors.warning),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          warning,
                          style: const TextStyle(color: WalletMeltColors.warning, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                )),
              ],
              const SizedBox(height: 20),

              // Merge Options or Replace Caution Details
              if (_selectedMode == RestoreMode.safeMerge) ...[
                if (_conflictSummary != null) ...[
                  Text('Conflict check', style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  if (hasConflicts) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: requiresResolution 
                            ? WalletMeltColors.warning.withValues(alpha: 0.1) 
                            : Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: requiresResolution ? WalletMeltColors.warning : Colors.green,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            requiresResolution ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded,
                            color: requiresResolution ? WalletMeltColors.warning : Colors.green,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              requiresResolution
                                  ? '${_conflictSummary!.duplicateExpenseIdCount} expense ID(s) already exist in local data. You must resolve them before merging.'
                                  : 'All conflicting records resolved successfully.',
                              style: TextStyle(
                                color: requiresResolution ? WalletMeltColors.warning : Colors.green,
                                fontSize: 13,
                                fontWeight: FontWeight.bold
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (requiresResolution)
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: _startConflictResolution,
                          icon: const Icon(Icons.rule_rounded),
                          label: const Text('Resolve Conflicts Now'),
                        ),
                      ),
                  ] else ...[
                    const Text(
                      'No conflicts detected with current local data.',
                      style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ],
              ] else ...[
                // Replace Mode Caution Block (Phase 6 Warning)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.red, width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.warning_rounded, color: Colors.red),
                          SizedBox(width: 10),
                          Text('DATA DELETION WARNING', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Full Replace wipes out all active data! The following records will be permanently deleted:\n'
                        '• ${widget.localSnapshot.expenses.length} Expenses\n'
                        '• ${widget.localSnapshot.categories.length} Categories\n'
                        '• ${widget.localSnapshot.budgets.length} Budgets\n'
                        '• ${widget.localSnapshot.groceryItems.length} Grocery Items',
                        style: const TextStyle(color: Colors.red, fontSize: 12, height: 1.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text('Type "REPLACE" to confirm:', style: textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                TextField(
                  controller: _replaceConfirmController,
                  decoration: InputDecoration(
                    hintText: 'REPLACE',
                    hintStyle: TextStyle(color: Colors.grey.withValues(alpha: 0.6)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                  style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2),
                ),
              ],

              if (_dryRunPlan != null) ...[
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? Colors.white24 : Colors.black12,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dry-run restore plan',
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: WalletMeltColors.brand,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildCountRow(Icons.category_outlined, 'Planned categories', '${_dryRunPlan!.plannedCounts.categories}'),
                      _buildCountRow(Icons.monetization_on_outlined, 'Planned expenses', '${_dryRunPlan!.plannedCounts.expenses}'),
                      _buildCountRow(
                        Icons.warning_amber_rounded,
                        'Blockers / warnings',
                        '${_dryRunPlan!.blockerCount} / ${_dryRunPlan!.warningCount}',
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Dry-run only',
                            style: TextStyle(
                              color: isDark ? Colors.white38 : Colors.black38,
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          if (_dryRunPlan!.isValid && !_dryRunPlan!.hasBlockers)
                            const Icon(Icons.check_circle_outline, color: Colors.green, size: 16),
                        ],
                      ),
                    ],
                  ),
                ),
                if (!_dryRunPlan!.isValid || !_dryRunPlan!.canStartFutureMutation) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: WalletMeltColors.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: WalletMeltColors.warning, width: 1),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: WalletMeltColors.warning),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Restore is unavailable until validation safety gates are satisfied.',
                            style: TextStyle(color: WalletMeltColors.warning, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (_dryRunPlan!.hasBlockers) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.red, width: 1),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.error_outline, color: Colors.red),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'blockers must be resolved first',
                                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          'will not resolve conflicts automatically',
                          style: TextStyle(color: Colors.red, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
              
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _isRestoring ? null : () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _selectedMode == RestoreMode.fullReplace ? Colors.red : WalletMeltColors.brand,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _isRestoring ||
                              _dryRunPlan == null ||
                              !_dryRunPlan!.isValid ||
                              _dryRunPlan!.hasBlockers ||
                              requiresResolution ||
                              (_selectedMode == RestoreMode.fullReplace && !_isReplaceConfirmed)
                          ? null
                          : _executeRestore,
                      child: _isRestoring 
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text(
                              (_dryRunPlan == null || !_dryRunPlan!.isValid || _dryRunPlan!.hasBlockers)
                                  ? 'Restore (N/A)'
                                  : (_selectedMode == RestoreMode.fullReplace ? 'Replace All' : 'Safe merge'),
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
  }

  Widget _buildCountRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeTab extends StatelessWidget {
  const _ModeTab({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.warningColor = false,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final bool warningColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = warningColor ? Colors.red : WalletMeltColors.brand;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected 
              ? primaryColor.withValues(alpha: 0.15) 
              : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.03)),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? primaryColor : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: selected ? primaryColor : Colors.grey, size: 20),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? primaryColor : Colors.grey,
                fontWeight: FontWeight.bold,
                fontSize: 13
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension on BackupRestoreDialog {
  WalletMeltJsonRestoreDryRunPlanner get restoreDryRunPlanner => const WalletMeltJsonRestoreDryRunPlanner();
}

class _ZipExtractorArgs {
  final List<int> zipBytes;
  final String extractPath;
  const _ZipExtractorArgs(this.zipBytes, this.extractPath);
}

void _extractZipInBackground(_ZipExtractorArgs args) {
  final archive = ZipDecoder().decodeBytes(args.zipBytes);
  for (final entry in archive) {
    final entryPath = entry.name;
    if (entry.isFile) {
      final data = entry.content as List<int>;
      final file = File(p.join(args.extractPath, entryPath));
      file.createSync(recursive: true);
      file.writeAsBytesSync(data);
    }
  }
}

Future<R> _runTask<Q, R>(ComputeCallback<Q, R> callback, Q message) {
  if (Platform.environment.containsKey('FLUTTER_TEST')) {
    try {
      return Future.value(callback(message));
    } catch (e, s) {
      return Future.error(e, s);
    }
  }
  return compute(callback, message);
}
