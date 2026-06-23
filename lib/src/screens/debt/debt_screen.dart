import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../components/glass/app_background.dart';
import '../../state/app_state.dart';
import '../../theme/wallet_melt_theme.dart';
import '../../types/debt.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/app_snackbar.dart';

class DebtScreen extends StatefulWidget {
  const DebtScreen({super.key});

  static void showQuickRepaymentSelector(BuildContext context) {
    final state = context.read<AppState>();
    final active = state.debts.where((d) => !d.isSettled).toList();

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
                'Select Obligation for Repayment',
                style: Theme.of(sheetContext).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 14),
              if (active.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      'No active debts or loans found.',
                      style: TextStyle(color: WalletMeltColors.textMuted),
                    ),
                  ),
                )
              else
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 300),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: active.length,
                    itemBuilder: (ctx, idx) {
                      final debt = active[idx];
                      final isReceivable = debt.type == DebtType.owedToMe || debt.type == DebtType.loanGiven;
                      final typeColor = isReceivable ? WalletMeltColors.positive : WalletMeltColors.danger;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: WMGlassSurface.tier2(
                          padding: const EdgeInsets.all(12),
                          onTap: () {
                            Navigator.pop(sheetContext);
                            showDebtDetailSheet(context, debt);
                          },
                          child: Row(
                            children: [
                              Icon(
                                isReceivable
                                    ? Icons.arrow_outward_rounded
                                    : Icons.call_received_rounded,
                                color: typeColor,
                                size: 16,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      debt.personName,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                    Text(
                                      debt.type.name.toUpperCase(),
                                      style: TextStyle(fontSize: 9, color: typeColor, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '${debt.remainingAmount.toStringAsFixed(debt.remainingAmount % 1 == 0 ? 0 : 2)} ${debt.currency}',
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
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
        );
      },
    );
  }

  static Future<void> showAddDebtSheet(BuildContext context, {DebtType? initialType}) async {
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    final notesController = TextEditingController();
    final descController = TextEditingController();
    final state = context.read<AppState>();

    DebtType selectedType = initialType ?? DebtType.owedToMe;
    DateTime? selectedDueDate;

    await showAppBottomSheet<void>(
      context,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (builderContext, setSheetState) {
            return SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Record Debt or Loan',
                            style: Theme.of(builderContext).textTheme.titleLarge),
                        AppSpacing.gapMd,

                        TextField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            labelText: 'Person Name',
                            hintText: 'e.g., Ali, Ahmed',
                          ),
                        ),
                        AppSpacing.gapSm,

                        Row(
                          children: [
                            Expanded(
                              flex: 4,
                              child: TextField(
                                controller: amountController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: InputDecoration(
                                  labelText: 'Amount',
                                  prefixText: '${state.settings.currency} ',
                                ),
                              ),
                            ),
                            AppSpacing.gapSm,
                            Expanded(
                              flex: 5,
                              child: DropdownButtonFormField<DebtType>(
                                initialValue: selectedType,
                                decoration: const InputDecoration(labelText: 'Type'),
                                dropdownColor: Theme.of(builderContext).brightness == Brightness.dark
                                    ? WalletMeltColors.darkSurface
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                items: const [
                                  DropdownMenuItem(
                                    value: DebtType.owedToMe,
                                    child: Text('Owed to me'),
                                  ),
                                  DropdownMenuItem(
                                    value: DebtType.iOwe,
                                    child: Text('I owe'),
                                  ),
                                  DropdownMenuItem(
                                    value: DebtType.loanGiven,
                                    child: Text('Loan Given'),
                                  ),
                                  DropdownMenuItem(
                                    value: DebtType.loanTaken,
                                    child: Text('Loan Taken'),
                                  ),
                                ],
                                onChanged: (val) {
                                  if (val != null) {
                                    setSheetState(() => selectedType = val);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        AppSpacing.gapMd,

                        WMGlassSurface.tier1(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: builderContext,
                              useRootNavigator: true,
                              initialDate: selectedDueDate ?? DateTime.now().add(const Duration(days: 30)),
                              firstDate: DateTime.now().subtract(const Duration(days: 365)),
                              lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                            );
                            if (picked != null) {
                              setSheetState(() => selectedDueDate = picked);
                            }
                          },
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_month_rounded, color: WalletMeltColors.brandDeep, size: 18),
                              AppSpacing.gapSm,
                              Expanded(
                                child: Text(
                                  selectedDueDate == null
                                      ? 'Set Due Date (Optional)'
                                      : 'Due Date: ${selectedDueDate!.toIso8601String().substring(0, 10)}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ),
                              if (selectedDueDate != null)
                                IconButton(
                                  icon: const Icon(Icons.clear_rounded, size: 18),
                                  onPressed: () {
                                    setSheetState(() => selectedDueDate = null);
                                  },
                                )
                              else
                                const Icon(Icons.chevron_right_rounded, size: 18, color: WalletMeltColors.textMuted),
                            ],
                          ),
                        ),
                        AppSpacing.gapSm,

                        TextField(
                          controller: descController,
                          decoration: const InputDecoration(
                            labelText: 'Description / Purpose',
                            hintText: 'e.g., Dinner split, Rent share',
                          ),
                        ),
                        AppSpacing.gapSm,

                        TextField(
                          controller: notesController,
                          minLines: 2,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            labelText: 'Private Notes',
                            hintText: 'Any extra details...',
                          ),
                        ),
                        AppSpacing.gapMd,

                        PrimaryButton(
                          label: 'Record Transaction',
                          onPressed: () async {
                            final name = nameController.text.trim();
                            final amountText = amountController.text.trim();
                            
                            if (name.isEmpty) {
                              showErrorSnackbar(context, 'Please enter a person name');
                              return;
                            }
                            
                            final amount = double.tryParse(amountText);
                            if (amount == null || amount <= 0) {
                              showErrorSnackbar(context, 'Please enter a valid amount greater than 0');
                              return;
                            }

                            final navigator = Navigator.of(sheetContext);

                            final newDebt = DebtRecord(
                              id: const Uuid().v4(),
                              personName: name,
                              type: selectedType,
                              principalAmount: amount,
                              remainingAmount: amount,
                              currency: state.settings.currency,
                              createdAt: DateTime.now().toIso8601String(),
                              status: DebtStatus.active,
                              description: descController.text.trim().isEmpty
                                  ? null
                                  : descController.text.trim(),
                              notes: notesController.text.trim().isEmpty
                                  ? null
                                  : notesController.text.trim(),
                              dueDate: selectedDueDate?.toIso8601String().substring(0, 10),
                            );

                            await state.addDebt(newDebt);
                            navigator.pop();
                            if (context.mounted) {
                              showSuccessSnackbar(context, 'Obligation for "$name" recorded successfully.');
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );

    nameController.dispose();
    amountController.dispose();
    notesController.dispose();
    descController.dispose();
  }

  static Future<void> showDebtDetailSheet(BuildContext context, DebtRecord debt) async {
    final state = context.read<AppState>();
    final payController = TextEditingController();

    await showAppBottomSheet<void>(
      context,
      builder: (sheetContext) {
        return FutureBuilder<List<DebtRepayment>>(
          future: state.repaymentsForDebt(debt.id),
          builder: (futureContext, snapshot) {
            final repayments = snapshot.data ?? const [];

            return StatefulBuilder(
              builder: (stateContext, setSheetState) {
                final isReceivable = debt.type == DebtType.owedToMe || debt.type == DebtType.loanGiven;

                return SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      debt.personName,
                                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w900,
                                          ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      debt.type.name.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: isReceivable
                                            ? WalletMeltColors.positive
                                            : WalletMeltColors.danger,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: debt.isSettled
                                        ? WalletMeltColors.positive.withValues(alpha: 0.12)
                                        : WalletMeltColors.brand.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    debt.status.name.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: debt.isSettled
                                          ? WalletMeltColors.positive
                                          : WalletMeltColors.brand,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),

                            Row(
                              children: [
                                Expanded(
                                  child: WMGlassSurface.tier1(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('PRINCIPAL', style: TextStyle(fontSize: 9, color: WalletMeltColors.textMuted, fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 2),
                                        Text('${debt.principalAmount.toStringAsFixed(debt.principalAmount % 1 == 0 ? 0 : 2)} ${debt.currency}', style: const TextStyle(fontWeight: FontWeight.w900)),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: WMGlassSurface.tier1(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('OUTSTANDING', style: TextStyle(fontSize: 9, color: WalletMeltColors.textMuted, fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 2),
                                        Text('${debt.remainingAmount.toStringAsFixed(debt.remainingAmount % 1 == 0 ? 0 : 2)} ${debt.currency}', style: const TextStyle(fontWeight: FontWeight.w900, color: WalletMeltColors.brandDeep)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),

                            if (debt.description != null) ...[
                              Text(
                                debt.description!,
                                style: const TextStyle(fontSize: 13, height: 1.3),
                              ),
                              const SizedBox(height: 10),
                            ],
                            if (debt.notes != null) ...[
                              const Text('Notes', style: TextStyle(fontSize: 10, color: WalletMeltColors.textMuted, fontWeight: FontWeight.bold)),
                              Text(debt.notes!, style: const TextStyle(fontSize: 12)),
                              const SizedBox(height: 14),
                            ],

                            const Divider(height: 1, color: Color(0x1Fffffff)),
                            const SizedBox(height: 14),

                            const Text(
                              'Payment Timeline',
                              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                            ),
                            const SizedBox(height: 8),

                            () {
                              final List<Widget> items = [];
                              final isReceiv = debt.type == DebtType.owedToMe || debt.type == DebtType.loanGiven;

                              items.add(
                                _buildTimelineItem(
                                  context,
                                  title: 'Created Obligation',
                                  date: debt.createdAt.length >= 10 ? debt.createdAt.substring(0, 10) : debt.createdAt,
                                  amount: '${isReceiv ? "+" : "-"}${debt.principalAmount.toStringAsFixed(debt.principalAmount % 1 == 0 ? 0 : 2)} ${debt.currency}',
                                  icon: Icons.add_circle_outline_rounded,
                                  iconColor: isReceiv ? WalletMeltColors.positive : WalletMeltColors.danger,
                                  isLast: false,
                                ),
                              );

                              for (int i = 0; i < repayments.length; i++) {
                                final pay = repayments[i];
                                items.add(
                                  _buildTimelineItem(
                                    context,
                                    title: pay.notes ?? 'Repayment',
                                    date: pay.createdAt.length >= 10 ? pay.createdAt.substring(0, 10) : pay.createdAt,
                                    amount: '${isReceiv ? "-" : "+"}${pay.amount.toStringAsFixed(pay.amount % 1 == 0 ? 0 : 2)} ${debt.currency}',
                                    icon: Icons.payment_rounded,
                                    iconColor: WalletMeltColors.positive,
                                    isLast: false,
                                  ),
                                );
                              }

                              if (debt.isSettled) {
                                final settledDate = debt.settledAt ?? (repayments.isNotEmpty ? repayments.last.createdAt : debt.createdAt);
                                items.add(
                                  _buildTimelineItem(
                                    context,
                                    title: 'Fully Settled / Paid Off',
                                    date: settledDate.length >= 10 ? settledDate.substring(0, 10) : settledDate,
                                    amount: '0 ${debt.currency}',
                                    icon: Icons.check_circle_rounded,
                                    iconColor: WalletMeltColors.positive,
                                    isLast: true,
                                  ),
                                );
                              }

                              if (!debt.isSettled && items.isNotEmpty) {
                                final lastIdx = items.length - 1;
                                if (lastIdx == 0) {
                                  items[0] = _buildTimelineItem(
                                    context,
                                    title: 'Created Obligation',
                                    date: debt.createdAt.length >= 10 ? debt.createdAt.substring(0, 10) : debt.createdAt,
                                    amount: '${isReceiv ? "+" : "-"}${debt.principalAmount.toStringAsFixed(debt.principalAmount % 1 == 0 ? 0 : 2)} ${debt.currency}',
                                    icon: Icons.add_circle_outline_rounded,
                                    iconColor: isReceiv ? WalletMeltColors.positive : WalletMeltColors.danger,
                                    isLast: true,
                                  );
                                } else {
                                  final lastPay = repayments.last;
                                  items[lastIdx] = _buildTimelineItem(
                                    context,
                                    title: lastPay.notes ?? 'Repayment',
                                    date: lastPay.createdAt.length >= 10 ? lastPay.createdAt.substring(0, 10) : lastPay.createdAt,
                                    amount: '${isReceiv ? "-" : "+"}${lastPay.amount.toStringAsFixed(lastPay.amount % 1 == 0 ? 0 : 2)} ${debt.currency}',
                                    icon: Icons.payment_rounded,
                                    iconColor: WalletMeltColors.positive,
                                    isLast: true,
                                  );
                                }
                              }

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: items,
                              );
                            }(),

                            const SizedBox(height: 18),

                            if (!debt.isSettled) ...[
                              const Text(
                                'Record Repayment',
                                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: payController,
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      decoration: InputDecoration(
                                        labelText: 'Repayment Amount',
                                        prefixText: '${debt.currency} ',
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      minimumSize: const Size(100, 48),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    onPressed: () async {
                                      final amountText = payController.text.trim();
                                      if (amountText.isEmpty) {
                                        showErrorSnackbar(context, 'Please enter a repayment amount');
                                        return;
                                      }
                                      final amount = double.tryParse(amountText);
                                      if (amount == null || amount <= 0) {
                                        showErrorSnackbar(context, 'Please enter a valid repayment amount');
                                        return;
                                      }
                                      if (amount > debt.remainingAmount) {
                                        showErrorSnackbar(context, 'Repayment amount cannot exceed outstanding balance');
                                        return;
                                      }

                                      final navigator = Navigator.of(sheetContext);
                                      await state.addRepayment(
                                        debtId: debt.id,
                                        amount: amount,
                                        notes: 'Partial payment',
                                      );
                                      navigator.pop();
                                      if (context.mounted) {
                                        showSuccessSnackbar(context, 'Repayment of $amount ${debt.currency} recorded successfully.');
                                      }
                                    },
                                    child: const Text('Pay'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(48),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                onPressed: () async {
                                  final navigator = Navigator.of(sheetContext);
                                  await state.addRepayment(
                                    debtId: debt.id,
                                    amount: debt.remainingAmount,
                                    notes: 'Settle remaining',
                                  );
                                  navigator.pop();
                                  if (context.mounted) {
                                    showSuccessSnackbar(context, 'Obligation settled successfully.');
                                  }
                                },
                                child: const Text('Settle Remaining Balance'),
                              ),
                              const SizedBox(height: 10),
                            ],

                            TextButton.icon(
                              style: TextButton.styleFrom(
                                foregroundColor: WalletMeltColors.danger,
                                minimumSize: const Size.fromHeight(48),
                              ),
                              icon: const Icon(Icons.delete_outline_rounded),
                              label: const Text('Delete Obligation'),
                              onPressed: () async {
                                final navigator = Navigator.of(sheetContext);
                                final confirm = await showConfirmDialog(
                                  context,
                                  title: 'Delete Obligation?',
                                  body: 'This will delete this debt record and all its repayment logs permanently.',
                                  confirmLabel: 'Delete',
                                  isDestructive: true,
                                );

                                if (confirm == true) {
                                  await state.deleteDebt(debt.id);
                                  navigator.pop();
                                  if (context.mounted) {
                                    showSuccessSnackbar(context, 'Obligation deleted successfully.');
                                  }
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        );

    payController.dispose();
  }

  static Widget _buildTimelineItem(
    BuildContext context, {
    required String title,
    required String date,
    required String amount,
    required IconData icon,
    required Color iconColor,
    bool isLast = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 16),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 36,
                color: Theme.of(context).brightness == Brightness.dark
                    ? WalletMeltColors.darkBorder
                    : WalletMeltColors.lightBorder,
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                  Text(
                    amount,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                date,
                style: const TextStyle(fontSize: 11, color: WalletMeltColors.textMuted),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ],
    );
  }

  @override
  State<DebtScreen> createState() => _DebtScreenState();
}

class _DebtScreenState extends State<DebtScreen> {
  String _searchQuery = '';
  final List<DebtType> _selectedTypesFilter = [];
  final List<String> _selectedStatusesFilter = [];
  bool _isFiltersExpanded = false;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final currency = state.settings.currency;

    // Calculate Summary Metrics
    double owedToMe = 0.0; // Receivables (owedToMe + loanGiven)
    double iOwe = 0.0;     // Liabilities (iOwe + loanTaken)

    for (final debt in state.debts) {
      if (debt.isSettled) continue;
      if (debt.type == DebtType.owedToMe || debt.type == DebtType.loanGiven) {
        owedToMe += debt.remainingAmount;
      } else {
        iOwe += debt.remainingAmount;
      }
    }

    final netPosition = owedToMe - iOwe;

    // Grouping & Filtering
    final activeDebts = <DebtRecord>[];
    final overdueDebts = <DebtRecord>[];
    final settledDebts = <DebtRecord>[];

    final nowStr = DateTime.now().toIso8601String().substring(0, 10); // yyyy-MM-dd

    final filteredDebts = state.debts.where((debt) {
      // 1. Search Query
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final nameMatches = debt.personName.toLowerCase().contains(query);
        final descMatches = debt.description?.toLowerCase().contains(query) ?? false;
        final notesMatches = debt.notes?.toLowerCase().contains(query) ?? false;
        if (!nameMatches && !descMatches && !notesMatches) {
          return false;
        }
      }

      // 2. Type Filter
      if (_selectedTypesFilter.isNotEmpty) {
        if (!_selectedTypesFilter.contains(debt.type)) {
          return false;
        }
      }

      // 3. Status Filter (Active, Overdue, Settled)
      if (_selectedStatusesFilter.isNotEmpty) {
        String debtStatus;
        if (debt.isSettled) {
          debtStatus = 'settled';
        } else if (debt.dueDate != null && debt.dueDate!.compareTo(nowStr) < 0) {
          debtStatus = 'overdue';
        } else {
          debtStatus = 'active';
        }

        if (!_selectedStatusesFilter.contains(debtStatus)) {
          return false;
        }
      }

      return true;
    }).toList();

    for (final debt in filteredDebts) {
      if (debt.isSettled) {
        settledDebts.add(debt);
      } else if (debt.dueDate != null && debt.dueDate!.compareTo(nowStr) < 0) {
        overdueDebts.add(debt);
      } else {
        activeDebts.add(debt);
      }
    }

    return Scaffold(
      body: AppBackground(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 94), // Extra bottom padding for floating navbar
        child: ListView(
          physics: const BouncingScrollPhysics(),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Debts & Loans',
                      maxLines: 1,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Quick Actions at the top
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      side: const BorderSide(color: WalletMeltColors.brand),
                    ),
                    icon: const Icon(Icons.add_rounded, color: WalletMeltColors.brand),
                    label: const Text(
                      'Add Obligation',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    onPressed: () => DebtScreen.showAddDebtSheet(context),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      side: const BorderSide(color: WalletMeltColors.positive),
                    ),
                    icon: const Icon(Icons.payment_rounded, color: WalletMeltColors.positive),
                    label: const Text(
                      'Record Repayment',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    onPressed: () => DebtScreen.showQuickRepaymentSelector(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Vertically stacked Summary Dashboard Card
            WMGlassSurface.tier3(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildVerticalMetricRow(
                    context,
                    label: 'OWED TO ME (Receivables)',
                    amount: owedToMe,
                    currency: currency,
                    color: WalletMeltColors.positive,
                    icon: Icons.arrow_outward_rounded,
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1, color: Color(0x1Fffffff)),
                  const SizedBox(height: 12),
                  _buildVerticalMetricRow(
                    context,
                    label: 'I OWE (Liabilities)',
                    amount: iOwe,
                    currency: currency,
                    color: WalletMeltColors.danger,
                    icon: Icons.call_received_rounded,
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1, color: Color(0x1Fffffff)),
                  const SizedBox(height: 12),
                  _buildVerticalMetricRow(
                    context,
                    label: 'NET POSITION',
                    amount: netPosition,
                    currency: currency,
                    color: netPosition >= 0 ? WalletMeltColors.positive : WalletMeltColors.danger,
                    icon: Icons.account_balance_wallet_rounded,
                    isBold: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Search Bar & Filter Button
            Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: InputDecoration(
                      hintText: 'Search by person, notes...',
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              onPressed: () {
                                FocusScope.of(context).unfocus();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Filters',
                  style: IconButton.styleFrom(
                    backgroundColor: _selectedTypesFilter.isNotEmpty || _selectedStatusesFilter.isNotEmpty
                        ? WalletMeltColors.brand.withValues(alpha: 0.16)
                        : Colors.transparent,
                  ),
                  icon: Icon(
                    Icons.filter_list_rounded,
                    color: _selectedTypesFilter.isNotEmpty || _selectedStatusesFilter.isNotEmpty
                        ? WalletMeltColors.brand
                        : WalletMeltColors.textSecondary,
                  ),
                  onPressed: () => setState(() => _isFiltersExpanded = !_isFiltersExpanded),
                ),
              ],
            ),

            if (_isFiltersExpanded) ...[
              const SizedBox(height: 10),
              WMGlassSurface.tier1(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Status Filter', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: WalletMeltColors.textMuted)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      children: [
                        _buildFilterChip('Active', _selectedStatusesFilter.contains('active'), () {
                          setState(() {
                            if (_selectedStatusesFilter.contains('active')) {
                              _selectedStatusesFilter.remove('active');
                            } else {
                              _selectedStatusesFilter.add('active');
                            }
                          });
                        }),
                        _buildFilterChip('Overdue', _selectedStatusesFilter.contains('overdue'), () {
                          setState(() {
                            if (_selectedStatusesFilter.contains('overdue')) {
                              _selectedStatusesFilter.remove('overdue');
                            } else {
                              _selectedStatusesFilter.add('overdue');
                            }
                          });
                        }),
                        _buildFilterChip('Settled', _selectedStatusesFilter.contains('settled'), () {
                          setState(() {
                            if (_selectedStatusesFilter.contains('settled')) {
                              _selectedStatusesFilter.remove('settled');
                            } else {
                              _selectedStatusesFilter.add('settled');
                            }
                          });
                        }),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text('Type Filter', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: WalletMeltColors.textMuted)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _buildFilterChip('Owed to me', _selectedTypesFilter.contains(DebtType.owedToMe), () {
                          setState(() {
                            if (_selectedTypesFilter.contains(DebtType.owedToMe)) {
                              _selectedTypesFilter.remove(DebtType.owedToMe);
                            } else {
                              _selectedTypesFilter.add(DebtType.owedToMe);
                            }
                          });
                        }),
                        _buildFilterChip('I owe', _selectedTypesFilter.contains(DebtType.iOwe), () {
                          setState(() {
                            if (_selectedTypesFilter.contains(DebtType.iOwe)) {
                              _selectedTypesFilter.remove(DebtType.iOwe);
                            } else {
                              _selectedTypesFilter.add(DebtType.iOwe);
                            }
                          });
                        }),
                        _buildFilterChip('Loan Given', _selectedTypesFilter.contains(DebtType.loanGiven), () {
                          setState(() {
                            if (_selectedTypesFilter.contains(DebtType.loanGiven)) {
                              _selectedTypesFilter.remove(DebtType.loanGiven);
                            } else {
                              _selectedTypesFilter.add(DebtType.loanGiven);
                            }
                          });
                        }),
                        _buildFilterChip('Loan Taken', _selectedTypesFilter.contains(DebtType.loanTaken), () {
                          setState(() {
                            if (_selectedTypesFilter.contains(DebtType.loanTaken)) {
                              _selectedTypesFilter.remove(DebtType.loanTaken);
                            } else {
                              _selectedTypesFilter.add(DebtType.loanTaken);
                            }
                          });
                        }),
                      ],
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),

            // Empty States & Sections
            if (state.debts.isEmpty) ...[
              const SizedBox(height: 40),
              Center(
                child: Column(
                  children: [
                    const Icon(Icons.handshake_outlined, size: 64, color: WalletMeltColors.textMuted),
                    const SizedBox(height: 16),
                    Text(
                      'No loans tracked yet',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Record money lent, borrowed, or dinner splits here.',
                      style: TextStyle(color: WalletMeltColors.textMuted, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => DebtScreen.showAddDebtSheet(context),
                      icon: const Icon(Icons.add),
                      label: const Text('Record Debt or Loan'),
                    ),
                  ],
                ),
              ),
            ] else if (filteredDebts.isEmpty) ...[
              const SizedBox(height: 40),
              Center(
                child: Column(
                  children: [
                    const Icon(Icons.filter_list_off_rounded, size: 48, color: WalletMeltColors.textMuted),
                    const SizedBox(height: 12),
                    const Text(
                      'No matching obligations found',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 14),
                    OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _searchQuery = '';
                          _selectedTypesFilter.clear();
                          _selectedStatusesFilter.clear();
                        });
                      },
                      child: const Text('Clear Filters'),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Overdue Section
              if (overdueDebts.isNotEmpty) ...[
                _buildSectionHeader(context, 'Overdue Obligations', WalletMeltColors.danger),
                const SizedBox(height: 10),
                for (final debt in overdueDebts) _buildDebtTile(context, debt),
                const SizedBox(height: 18),
              ],

              // Active Section
              if (activeDebts.isNotEmpty) ...[
                _buildSectionHeader(
                  context,
                  'Active Transactions',
                  Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 10),
                for (final debt in activeDebts) _buildDebtTile(context, debt),
                const SizedBox(height: 18),
              ],

              // Settled Section
              if (settledDebts.isNotEmpty) ...[
                _buildSectionHeader(context, 'Settled History', WalletMeltColors.textMuted),
                const SizedBox(height: 10),
                for (final debt in settledDebts) _buildDebtTile(context, debt),
              ],
            ],
          ],
        ),
      ),
    );
  }



  Widget _buildVerticalMetricRow(
    BuildContext context, {
    required String label,
    required double amount,
    required String currency,
    required Color color,
    required IconData icon,
    bool isBold = false,
  }) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 10,
                      letterSpacing: 0.8,
                      fontWeight: FontWeight.w700,
                      color: WalletMeltColors.textMuted,
                    ),
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '${amount >= 0 ? "" : "-"}${amount.abs().toStringAsFixed(amount % 1 == 0 ? 0 : 2)} $currency',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: isBold ? FontWeight.w900 : FontWeight.w800,
                        fontSize: isBold ? 18 : 15,
                        color: isBold ? color : null,
                      ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }



  Widget _buildSectionHeader(BuildContext context, String title, Color color) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
        ),
      ],
    );
  }



  Widget _buildDebtTile(BuildContext context, DebtRecord debt) {
    // Determine type indicators
    final isReceivable = debt.type == DebtType.owedToMe || debt.type == DebtType.loanGiven;
    final typeColor = isReceivable ? WalletMeltColors.positive : WalletMeltColors.danger;

    String typeLabel = '';
    switch (debt.type) {
      case DebtType.owedToMe:
        typeLabel = 'Owed to me';
        break;
      case DebtType.iOwe:
        typeLabel = 'I owe';
        break;
      case DebtType.loanGiven:
        typeLabel = 'Loan Given';
        break;
      case DebtType.loanTaken:
        typeLabel = 'Loan Taken';
        break;
    }

    final nowStr = DateTime.now().toIso8601String().substring(0, 10);
    final isOverdue = !debt.isSettled && debt.dueDate != null && debt.dueDate!.compareTo(nowStr) < 0;

    int? daysOverdue;
    if (isOverdue && debt.dueDate != null) {
      try {
        final due = DateTime.parse(debt.dueDate!);
        final now = DateTime.now();
        final cleanDue = DateTime(due.year, due.month, due.day);
        final cleanNow = DateTime(now.year, now.month, now.day);
        daysOverdue = cleanNow.difference(cleanDue).inDays;
      } catch (_) {}
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: WMGlassSurface.tier2(
        padding: const EdgeInsets.all(14),
        onTap: () => DebtScreen.showDebtDetailSheet(context, debt),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: isOverdue
                    ? WalletMeltColors.danger.withValues(alpha: 0.12)
                    : typeColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: isOverdue
                    ? Border.all(color: WalletMeltColors.danger, width: 1.5)
                    : null,
              ),
              child: Icon(
                isOverdue
                    ? Icons.warning_amber_rounded
                    : (isReceivable ? Icons.arrow_outward_rounded : Icons.call_received_rounded),
                color: isOverdue ? WalletMeltColors.danger : typeColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          debt.personName,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isOverdue) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: WalletMeltColors.danger.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: WalletMeltColors.danger.withValues(alpha: 0.24)),
                          ),
                          child: Text(
                            daysOverdue != null ? '$daysOverdue DAYS OVERDUE' : 'OVERDUE',
                            style: const TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w900,
                              color: WalletMeltColors.danger,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        typeLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: typeColor,
                        ),
                      ),
                      if (debt.dueDate != null && !debt.isSettled) ...[
                        const SizedBox(width: 6),
                        Container(width: 3, height: 3, color: WalletMeltColors.textMuted),
                        const SizedBox(width: 6),
                        Text(
                          'Due: ${debt.dueDate}',
                          style: TextStyle(
                            fontSize: 11,
                            color: isOverdue ? WalletMeltColors.danger : WalletMeltColors.textMuted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${debt.remainingAmount.toStringAsFixed(debt.remainingAmount % 1 == 0 ? 0 : 2)} ${debt.currency}',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    color: isOverdue ? WalletMeltColors.danger : null,
                  ),
                ),
                if (debt.principalAmount != debt.remainingAmount) ...[
                  const SizedBox(height: 2),
                  Text(
                    'of ${debt.principalAmount.toStringAsFixed(debt.principalAmount % 1 == 0 ? 0 : 2)}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: WalletMeltColors.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }





  Widget _buildFilterChip(String label, bool selected, VoidCallback onTap) {
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: selected ? Colors.white : WalletMeltColors.textSecondary,
        ),
      ),
      selected: selected,
      onSelected: (_) => onTap(),
      backgroundColor: Colors.transparent,
      selectedColor: WalletMeltColors.brand,
      checkmarkColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: selected ? WalletMeltColors.brand : const Color(0x1Fffffff),
          width: 1,
        ),
      ),
    );
  }

}
