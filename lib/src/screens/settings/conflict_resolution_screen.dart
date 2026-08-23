import 'package:flutter/material.dart';
import '../../widgets/app_snackbar.dart';
import '../../types/category.dart';
import '../../types/expense.dart';
import '../../theme/wallet_melt_theme.dart';
import '../../utils/currency_format.dart';
import '../../services/export/wallet_melt_json_restore_plan.dart';

class ConflictResolutionScreen extends StatefulWidget {
  const ConflictResolutionScreen({
    super.key,
    required this.conflicts,
    required this.localExpenses,
    required this.localCategories,
    required this.backupCategories,
    required this.onResolved,
  });

  final List<Map<String, Object?>> conflicts;
  final List<Expense> localExpenses;
  final List<Category> localCategories;
  final List<Map<String, Object?>> backupCategories;
  final ValueChanged<Map<String, ConflictResolution>> onResolved;

  @override
  State<ConflictResolutionScreen> createState() => _ConflictResolutionScreenState();
}

class _ConflictResolutionScreenState extends State<ConflictResolutionScreen> {
  final Map<String, ConflictResolution> _resolutions = {};
  late final Map<String, Expense> _localExpensesMap;
  late final Map<String, Map<String, Object?>> _backupCategoriesMap;
  late final Map<String, Category> _localCategoriesMap;

  @override
  void initState() {
    super.initState();
    _localExpensesMap = {
      for (final e in widget.localExpenses) e.id: e
    };
    _backupCategoriesMap = {
      for (final c in widget.backupCategories) c['id']?.toString() ?? '': c
    };
    _localCategoriesMap = {
      for (final c in widget.localCategories) c.id: c
    };

    // Default to keep local (safe default)
    for (final expense in widget.conflicts) {
      final id = expense['id']?.toString() ?? '';
      if (id.isNotEmpty) {
        _resolutions[id] = ConflictResolution.keepExisting;
      }
    }
  }

  void _applyBulkAction(ConflictResolution resolution) {
    setState(() {
      for (final id in _resolutions.keys) {
        _resolutions[id] = resolution;
      }
    });
    showSuccessSnackbar(context, 'Applied bulk resolution to ${widget.conflicts.length} conflicts.');
  }

  void _applyAutoResolve() {
    setState(() {
      for (final expense in widget.conflicts) {
        final id = expense['id']?.toString() ?? '';
        if (id.isEmpty) continue;

        final local = _localExpensesMap[id];
        if (local == null) continue;
        final backupUpdatedAtStr = expense['updated_at']?.toString();
        
        if (backupUpdatedAtStr != null) {
          try {
            final backupTime = DateTime.parse(backupUpdatedAtStr);
            final localTime = DateTime.parse(local.updatedAt);
            if (backupTime.isAfter(localTime)) {
              _resolutions[id] = ConflictResolution.useBackup;
              continue;
            }
          } catch (_) {}
        }
        _resolutions[id] = ConflictResolution.keepExisting;
      }
    });
    showSuccessSnackbar(context, 'Auto-resolved conflicts by choosing the newest records.');
  }

  String _getCategoryName(String categoryId, bool isBackup) {
    if (isBackup) {
      final match = _backupCategoriesMap[categoryId];
      if (match != null) {
        return match['name']?.toString() ?? categoryId;
      }
      return categoryId;
    }
    final match = _localCategoriesMap[categoryId];
    return match?.name ?? 'Unknown';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? WalletMeltColors.darkBackgroundAlt : const Color(0xFFF7F7F4),
      appBar: AppBar(
        title: const Text('Resolve Conflicts', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Bulk Actions Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? WalletMeltColors.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bulk Actions (${widget.conflicts.length} duplicate IDs detected)',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        ActionChip(
                          avatar: const Icon(Icons.shield_outlined, size: 16),
                          label: const Text('Keep All Local'),
                          onPressed: () => _applyBulkAction(ConflictResolution.keepExisting),
                        ),
                        const SizedBox(width: 8),
                        ActionChip(
                          avatar: const Icon(Icons.cloud_download_outlined, size: 16),
                          label: const Text('Use All Backup'),
                          onPressed: () => _applyBulkAction(ConflictResolution.useBackup),
                        ),
                        const SizedBox(width: 8),
                        ActionChip(
                          avatar: const Icon(Icons.merge_type_outlined, size: 16),
                          label: const Text('Merge Fields'),
                          onPressed: () => _applyBulkAction(ConflictResolution.mergeFields),
                        ),
                        const SizedBox(width: 8),
                        ActionChip(
                          avatar: const Icon(Icons.auto_awesome_outlined, size: 16),
                          label: const Text('Auto Resolve'),
                          onPressed: _applyAutoResolve,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Side-by-side scrollable list of conflicts
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: widget.conflicts.length,
                itemBuilder: (context, index) {
                  final backupExpense = widget.conflicts[index];
                  final id = backupExpense['id']?.toString() ?? '';
                  final localExpense = _localExpensesMap[id];
                  if (localExpense == null) return const SizedBox.shrink();
                  final currentChoice = _resolutions[id] ?? ConflictResolution.keepExisting;

                  return _ConflictCard(
                    id: id,
                    localExpense: localExpense,
                    backupExpense: backupExpense,
                    localCategoryName: _getCategoryName(localExpense.categoryId, false),
                    backupCategoryName: _getCategoryName(backupExpense['category_id']?.toString() ?? '', true),
                    currentChoice: currentChoice,
                    onChoiceChanged: (choice) {
                      setState(() {
                        _resolutions[id] = choice;
                      });
                    },
                  );
                },
              ),
            ),

            // Confirm Resolution Footer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                border: Border(
                  top: BorderSide(
                    color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.1),
                  ),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: WalletMeltColors.brand,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () => widget.onResolved(_resolutions),
                  child: const Text(
                    'Resolve & Save Conflicts',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConflictCard extends StatelessWidget {
  const _ConflictCard({
    required this.id,
    required this.localExpense,
    required this.backupExpense,
    required this.localCategoryName,
    required this.backupCategoryName,
    required this.currentChoice,
    required this.onChoiceChanged,
  });

  final String id;
  final Expense localExpense;
  final Map<String, Object?> backupExpense;
  final String localCategoryName;
  final String backupCategoryName;
  final ConflictResolution currentChoice;
  final ValueChanged<ConflictResolution> onChoiceChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final backupTitle = backupExpense['title']?.toString() ?? 'Untitled';
    final backupAmount = backupExpense['amount'] is num 
        ? (backupExpense['amount'] as num).toDouble() 
        : 0.0;
    final backupCurrency = backupExpense['currency']?.toString() ?? 'PKR';
    final backupDate = backupExpense['date']?.toString() ?? '';
    final backupHasReceipt = backupExpense['receipt_image_uri']?.toString().isNotEmpty ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161616) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: currentChoice == ConflictResolution.keepExisting
              ? Colors.blue.withValues(alpha: 0.3)
              : currentChoice == ConflictResolution.useBackup
                  ? Colors.green.withValues(alpha: 0.3)
                  : WalletMeltColors.warning.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Local Version Card
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.phone_android, size: 14, color: Colors.blue),
                            SizedBox(width: 4),
                            Text('LOCAL VERSION', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(localExpense.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 4),
                        Text(
                          formatMoney(localExpense.amount, localExpense.currency),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        _buildDetailRow(Icons.calendar_today_outlined, localExpense.date),
                        _buildDetailRow(Icons.category_outlined, localCategoryName),
                        _buildDetailRow(
                          localExpense.receiptImageUri != null ? Icons.receipt_long : Icons.receipt_long_outlined,
                          localExpense.receiptImageUri != null ? 'Has Receipt' : 'No Receipt',
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Backup Version Card
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.cloud_upload_outlined, size: 14, color: Colors.green),
                            SizedBox(width: 4),
                            Text('BACKUP VERSION', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(backupTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 4),
                        Text(
                          formatMoney(backupAmount, backupCurrency),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        _buildDetailRow(Icons.calendar_today_outlined, backupDate),
                        _buildDetailRow(Icons.category_outlined, backupCategoryName),
                        _buildDetailRow(
                          backupHasReceipt ? Icons.receipt_long : Icons.receipt_long_outlined,
                          backupHasReceipt ? 'Has Receipt' : 'No Receipt',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Action Buttons Segment
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: currentChoice == ConflictResolution.keepExisting
                          ? Colors.blue.withValues(alpha: 0.1)
                          : Colors.transparent,
                      side: BorderSide(
                        color: currentChoice == ConflictResolution.keepExisting ? Colors.blue : Colors.transparent,
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => onChoiceChanged(ConflictResolution.keepExisting),
                    child: const Text('Keep Local', style: TextStyle(fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: currentChoice == ConflictResolution.useBackup
                          ? Colors.green.withValues(alpha: 0.1)
                          : Colors.transparent,
                      side: BorderSide(
                        color: currentChoice == ConflictResolution.useBackup ? Colors.green : Colors.transparent,
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => onChoiceChanged(ConflictResolution.useBackup),
                    child: const Text('Use Backup', style: TextStyle(fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: currentChoice == ConflictResolution.mergeFields
                          ? WalletMeltColors.warning.withValues(alpha: 0.1)
                          : Colors.transparent,
                      side: BorderSide(
                        color: currentChoice == ConflictResolution.mergeFields ? WalletMeltColors.warning : Colors.transparent,
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => onChoiceChanged(ConflictResolution.mergeFields),
                    child: const Text('Merge Fields', style: TextStyle(fontSize: 12)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 12, color: Colors.grey),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
