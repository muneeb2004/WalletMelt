import 'package:flutter/material.dart';
import '../../theme/wallet_melt_theme.dart';
import '../../services/export/wallet_melt_json_restore_plan.dart';
import '../../services/export/wallet_melt_json_restore_service.dart';

class RestoreSummaryDialog extends StatefulWidget {
  const RestoreSummaryDialog({
    super.key,
    required this.result,
    required this.durationSeconds,
    required this.mode,
    required this.backupVersion,
  });

  final WalletMeltJsonRestoreResult result;
  final double durationSeconds;
  final RestoreMode mode;
  final int backupVersion;

  @override
  State<RestoreSummaryDialog> createState() => _RestoreSummaryDialogState();
}

class _RestoreSummaryDialogState extends State<RestoreSummaryDialog> {
  bool _showDetails = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textTheme = theme.textTheme;

    final hasWarnings = widget.result.warnings.isNotEmpty;

    return Dialog(
      backgroundColor: isDark ? const Color(0xFF161616) : const Color(0xFFFAFAF6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16.0 /* AppSpacing.md */, vertical: 24.0 /* AppSpacing.lg */),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 450),
        child: Padding(
          padding: const EdgeInsets.all(16.0 /* AppSpacing.md */),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Success Badge
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.green,
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Restore Complete',
                style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // Detail statistics table
              Table(
                columnWidths: const {
                  0: FlexColumnWidth(1.5),
                  1: FlexColumnWidth(1),
                },
                children: [
                  _buildStatRow('Expenses', '${widget.result.insertedExpenses}', isDark),
                  _buildStatRow('Categories', '${widget.result.insertedCategories}', isDark),
                  _buildStatRow('Grocery Items', '${widget.result.insertedGroceryItems}', isDark),
                  _buildStatRow('Budgets', '${widget.result.insertedBudgets}', isDark),
                  _buildStatRow('Restore Mode', widget.mode == RestoreMode.fullReplace ? 'Replace' : 'Merge', isDark),
                  _buildStatRow('Skipped Duplicates', '${widget.result.skippedItems}', isDark),
                  _buildStatRow('Backup Version', 'v${widget.backupVersion}', isDark),
                  _buildStatRow('Duration', '${widget.durationSeconds.toStringAsFixed(1)}s', isDark),
                ],
              ),
              const SizedBox(height: 20),

              // Warning Details toggle
              if (hasWarnings) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _showDetails = !_showDetails;
                      });
                    },
                    icon: Icon(
                      _showDetails ? Icons.expand_less : Icons.expand_more,
                      size: 18,
                    ),
                    label: Text(
                      _showDetails ? 'Hide Warnings' : 'View Warnings (${widget.result.warnings.length})',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ),
                if (_showDetails)
                  Container(
                    constraints: const BoxConstraints(maxHeight: 120),
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(top: 8),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: widget.result.warnings.map((warning) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.warning_amber_rounded, size: 14, color: Colors.orange),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    warning,
                                    style: textTheme.bodySmall?.copyWith(height: 1.3),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
              ],

              // Close Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: WalletMeltColors.brand,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Close',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  TableRow _buildStatRow(String label, String value, bool isDark) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}
