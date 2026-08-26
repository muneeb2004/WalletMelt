import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../components/glass/app_background.dart';
import '../../state/app_state.dart';
import '../../theme/wallet_melt_theme.dart';
import '../../types/payee.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/primary_button.dart';

class PayeesScreen extends StatefulWidget {
  const PayeesScreen({super.key});

  @override
  State<PayeesScreen> createState() => _PayeesScreenState();
}

class _PayeesScreenState extends State<PayeesScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddEditPayeeSheet(BuildContext context, {Payee? payee}) {
    final state = context.read<AppState>();
    final nameController = TextEditingController(text: payee?.name);
    final phoneController = TextEditingController(text: payee?.phone);
    final notesController = TextEditingController(text: payee?.notes);

    showAppBottomSheet<void>(
      context,
      builder: (sheetContext) {
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  payee == null ? 'Add Contact / Payee' : 'Edit Contact / Payee',
                  style: Theme.of(sheetContext).textTheme.titleLarge,
                ),
                AppSpacing.gapMd,
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    hintText: 'e.g., Ali Ahmed',
                  ),
                ),
                AppSpacing.gapSm,
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number (Optional)',
                    hintText: 'e.g., +923001234567',
                  ),
                ),
                AppSpacing.gapSm,
                TextField(
                  controller: notesController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Notes (Optional)',
                    hintText: 'e.g., Work colleague, landlord...',
                  ),
                ),
                AppSpacing.gapMd,
                PrimaryButton(
                  label: payee == null ? 'Create Contact' : 'Save Changes',
                  onPressed: () async {
                    final name = nameController.text.trim();
                    if (name.isEmpty) {
                      showErrorSnackbar(context, 'Please enter a name');
                      return;
                    }

                    // Check duplicate
                    final normalized = name.toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
                    final isDuplicate = state.payees.any((p) =>
                        p.id != payee?.id &&
                        p.deletedAt == null &&
                        p.name.toLowerCase().replaceAll(RegExp(r'\s+'), ' ') == normalized);

                    if (isDuplicate) {
                      showErrorSnackbar(context, 'A contact with this name already exists.');
                      return;
                    }

                    final navigator = Navigator.of(sheetContext);
                    final rootContext = context;
                    if (payee == null) {
                      final newPayee = Payee(
                        id: 'payee_${const Uuid().v4()}',
                        name: name,
                        phone: phoneController.text.trim().isEmpty ? null : phoneController.text.trim(),
                        notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
                        createdAt: DateTime.now().toIso8601String(),
                        updatedAt: DateTime.now().toIso8601String(),
                      );
                      await state.addPayee(newPayee);
                      if (rootContext.mounted) {
                        showSuccessSnackbar(rootContext, 'Contact created successfully.');
                      }
                    } else {
                      final updatedPayee = payee.copyWith(
                        name: name,
                        phone: phoneController.text.trim().isEmpty ? null : phoneController.text.trim(),
                        notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
                        updatedAt: DateTime.now().toIso8601String(),
                      );
                      await state.updatePayee(updatedPayee);
                      if (rootContext.mounted) {
                        showSuccessSnackbar(rootContext, 'Contact updated successfully.');
                      }
                    }
                    navigator.pop();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showMergeSheet(BuildContext context, Payee duplicatePayee) {
    final state = context.read<AppState>();
    final otherPayees = state.payees
        .where((p) => p.id != duplicatePayee.id && p.deletedAt == null && p.isActive)
        .toList();

    showAppBottomSheet<void>(
      context,
      builder: (sheetContext) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Merge "${duplicatePayee.name}" into...',
                style: Theme.of(sheetContext).textTheme.titleLarge,
              ),
              AppSpacing.gapSm,
              Text(
                'All transactions linked to "${duplicatePayee.name}" will be reassigned to the selected contact. "${duplicatePayee.name}" will be archived.',
                style: const TextStyle(fontSize: 12, color: WalletMeltColors.textMuted),
              ),
              AppSpacing.gapMd,
              if (otherPayees.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Text('No other active contacts available to merge into.'),
                  ),
                )
              else
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 250),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: otherPayees.length,
                    itemBuilder: (ctx, idx) {
                      final keepPayee = otherPayees[idx];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: WMGlassSurface.tier2(
                          padding: const EdgeInsets.all(12),
                          onTap: () async {
                            final navigator = Navigator.of(sheetContext);
                            final rootContext = context;
                            
                            // Merge
                            await state.mergePayees(
                              keepId: keepPayee.id,
                              duplicateId: duplicatePayee.id,
                            );
                            
                            navigator.pop();
                            if (rootContext.mounted) {
                              showSuccessSnackbar(
                                rootContext,
                                'Merged "${duplicatePayee.name}" into "${keepPayee.name}" successfully.',
                              );
                            }
                          },
                          child: Text(
                            keepPayee.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Filter payees based on search and soft deleted status
    final filtered = state.payees.where((p) {
      if (p.deletedAt != null) return false;
      if (_searchQuery.isEmpty) return true;
      return p.name.toLowerCase().contains(_searchQuery) ||
          (p.phone?.toLowerCase().contains(_searchQuery) ?? false) ||
          (p.notes?.toLowerCase().contains(_searchQuery) ?? false);
    }).toList();

    return Scaffold(
      body: AppBackground(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Back',
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Payees & Contacts',
                      style: theme.textTheme.headlineMedium,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Add Contact',
                    onPressed: () => _showAddEditPayeeSheet(context),
                    icon: const Icon(Icons.add_rounded),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search_rounded),
                  labelText: 'Search contacts...',
                ),
              ),
            ),
            Expanded(
              child: filtered.isEmpty
                  ? EmptyState(
                      icon: Icons.people_outline_rounded,
                      title: _searchQuery.isEmpty ? 'No contacts yet' : 'No contacts found',
                      subtitle: _searchQuery.isEmpty
                          ? 'Add contacts or record obligations to see them here.'
                          : 'Try a different search term.',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                      itemCount: filtered.length,
                      itemBuilder: (ctx, idx) {
                        final payee = filtered[idx];
                        final linkedCount = state.debts.where((d) => d.payeeId == payee.id).length;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: WMGlassSurface.tier2(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  payee.name,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w800,
                                                    fontSize: 16,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              if (!payee.isActive) ...[
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                      horizontal: 8, vertical: 3),
                                                  decoration: BoxDecoration(
                                                    color: WalletMeltColors.textMuted
                                                        .withValues(alpha: 0.16),
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: const Text(
                                                    'INACTIVE',
                                                    style: TextStyle(
                                                      fontSize: 8,
                                                      fontWeight: FontWeight.w900,
                                                      color: WalletMeltColors.textMuted,
                                                    ),
                                                  ),
                                                ),
                                              ]
                                            ],
                                          ),
                                          if (payee.phone != null && payee.phone!.isNotEmpty) ...[
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                const Icon(Icons.phone_rounded,
                                                    size: 13, color: WalletMeltColors.textMuted),
                                                const SizedBox(width: 6),
                                                Text(
                                                  payee.phone!,
                                                  style: const TextStyle(
                                                      fontSize: 12,
                                                      color: WalletMeltColors.textMuted),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primary.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: theme.colorScheme.primary.withValues(alpha: 0.24),
                                        ),
                                      ),
                                      child: Text(
                                        '$linkedCount transaction${linkedCount == 1 ? '' : 's'}',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: theme.colorScheme.primary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (payee.notes != null && payee.notes!.isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  Text(
                                    payee.notes!,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                      color: WalletMeltColors.textMuted,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 12),
                                Divider(
                                  height: 1,
                                  color: isDark
                                      ? WalletMeltColors.darkBorder
                                      : WalletMeltColors.lightBorder,
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton.icon(
                                      onPressed: () => _showMergeSheet(context, payee),
                                      icon: const Icon(Icons.merge_type_rounded, size: 16),
                                      label: const Text('Merge', style: TextStyle(fontSize: 12)),
                                    ),
                                    const SizedBox(width: 8),
                                    TextButton.icon(
                                      onPressed: () => _showAddEditPayeeSheet(context, payee: payee),
                                      icon: const Icon(Icons.edit_rounded, size: 16),
                                      label: const Text('Edit', style: TextStyle(fontSize: 12)),
                                    ),
                                    const SizedBox(width: 8),
                                    TextButton.icon(
                                      style: TextButton.styleFrom(
                                        foregroundColor: theme.colorScheme.error,
                                      ),
                                      onPressed: () async {
                                        final rootContext = context;
                                        final hasTransactions = linkedCount > 0;
                                        
                                        final confirm = await showDialog<bool>(
                                          context: context,
                                          useRootNavigator: true,
                                          builder: (dialogContext) {
                                            return AlertDialog(
                                              backgroundColor: isDark
                                                  ? WalletMeltColors.darkSurface
                                                  : Colors.white,
                                              title: Text(hasTransactions ? 'Deactivate Contact?' : 'Delete Contact?'),
                                              content: Text(
                                                hasTransactions
                                                    ? 'This contact has linked transactions and cannot be deleted. Do you want to mark them inactive?'
                                                    : 'Are you sure you want to delete this contact?',
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.pop(dialogContext, false),
                                                  child: const Text('Cancel'),
                                                ),
                                                TextButton(
                                                  style: TextButton.styleFrom(
                                                    foregroundColor: theme.colorScheme.error,
                                                  ),
                                                  onPressed: () => Navigator.pop(dialogContext, true),
                                                  child: Text(hasTransactions ? 'Deactivate' : 'Delete'),
                                                ),
                                              ],
                                            );
                                          },
                                        );

                                        if (confirm == true) {
                                          await state.deletePayee(payee.id);
                                          if (rootContext.mounted) {
                                            showSuccessSnackbar(
                                              rootContext,
                                              hasTransactions
                                                  ? 'Contact marked inactive.'
                                                  : 'Contact deleted successfully.',
                                            );
                                          }
                                        }
                                      },
                                      icon: const Icon(Icons.delete_outline_rounded, size: 16),
                                      label: Text(
                                        linkedCount > 0 ? 'Deactivate' : 'Delete',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditPayeeSheet(context),
        child: const Icon(Icons.person_add_rounded),
      ),
    );
  }
}
