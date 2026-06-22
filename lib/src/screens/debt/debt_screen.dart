import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../components/glass/app_background.dart';
import '../../state/app_state.dart';
import '../../theme/wallet_melt_theme.dart';
import '../../types/debt.dart';
import '../../widgets/primary_button.dart';

class DebtScreen extends StatefulWidget {
  const DebtScreen({super.key});

  @override
  State<DebtScreen> createState() => _DebtScreenState();
}

class _DebtScreenState extends State<DebtScreen> {
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

    // Grouping
    final activeDebts = <DebtRecord>[];
    final overdueDebts = <DebtRecord>[];
    final settledDebts = <DebtRecord>[];

    final nowStr = DateTime.now().toIso8601String().substring(0, 10); // yyyy-MM-dd

    for (final debt in state.debts) {
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
                Text(
                  'Debts & Loans',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                IconButton(
                  tooltip: 'Record Debt or Loan',
                  icon: const Icon(Icons.add_circle_outline_rounded, size: 28),
                  onPressed: () => _showAddDebtSheet(context),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Summary Dashboard Card
            WMGlassSurface.tier3(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    'NET POSITION',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${netPosition >= 0 ? "+" : ""}${netPosition.toStringAsFixed(netPosition % 1 == 0 ? 0 : 2)} $currency',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: netPosition >= 0
                              ? WalletMeltColors.positive
                              : WalletMeltColors.danger,
                          fontWeight: FontWeight.w900,
                          fontSize: 30,
                        ),
                  ),
                  const SizedBox(height: 18),
                  const Divider(height: 1, color: Color(0x1Fffffff)),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildSummaryStat(
                        context,
                        label: 'OWED TO ME',
                        amount: owedToMe,
                        currency: currency,
                        color: WalletMeltColors.positive,
                      ),
                      Container(width: 1, height: 32, color: const Color(0x1Fffffff)),
                      _buildSummaryStat(
                        context,
                        label: 'I OWE',
                        amount: iOwe,
                        currency: currency,
                        color: WalletMeltColors.danger,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Overdue Section
            if (overdueDebts.isNotEmpty) ...[
              _buildSectionHeader(context, 'Overdue Obligations', WalletMeltColors.danger),
              const SizedBox(height: 10),
              for (final debt in overdueDebts) _buildDebtTile(context, debt),
              const SizedBox(height: 18),
            ],

            // Active Section
            _buildSectionHeader(
              context,
              'Active Transactions',
              Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 10),
            if (activeDebts.isEmpty)
              _buildEmptyState('No active loans or repayments.')
            else
              for (final debt in activeDebts) _buildDebtTile(context, debt),
            const SizedBox(height: 18),

            // Settled Section
            if (settledDebts.isNotEmpty) ...[
              _buildSectionHeader(context, 'Settled History', WalletMeltColors.textMuted),
              const SizedBox(height: 10),
              for (final debt in settledDebts) _buildDebtTile(context, debt),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryStat(
    BuildContext context, {
    required String label,
    required double amount,
    required String currency,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 10,
                letterSpacing: 0.8,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 2),
        Text(
          '${amount.toStringAsFixed(amount % 1 == 0 ? 0 : 2)} $currency',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: color,
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

  Widget _buildEmptyState(String message) {
    return WMGlassSurface.tier1(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Center(
        child: Text(
          message,
          style: const TextStyle(
            color: WalletMeltColors.textMuted,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
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

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: WMGlassSurface.tier2(
        padding: const EdgeInsets.all(14),
        onTap: () => _showDebtDetailSheet(context, debt),
        child: Row(
          children: [
            // Circular Type icon
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: typeColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isReceivable
                    ? Icons.arrow_outward_rounded
                    : Icons.call_received_rounded,
                color: typeColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),

            // Person and description
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    debt.personName,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
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

            // Balances
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${debt.remainingAmount.toStringAsFixed(debt.remainingAmount % 1 == 0 ? 0 : 2)} ${debt.currency}',
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
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

  Future<void> _showAddDebtSheet(BuildContext context) async {
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    final notesController = TextEditingController();
    final descController = TextEditingController();
    final state = context.read<AppState>();

    DebtType selectedType = DebtType.owedToMe;
    DateTime? selectedDueDate;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      constraints: const BoxConstraints(maxWidth: 600),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  10,
                  20,
                  20 + MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Record Debt or Loan',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 14),

                    // Person Name
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Person Name',
                        hintText: 'e.g., Ali, Ahmed',
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Principal Amount
                    TextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Principal Amount',
                        prefixText: '${state.settings.currency} ',
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Debt Type Dropdown
                    DropdownButtonFormField<DebtType>(
                      initialValue: selectedType,
                      decoration: const InputDecoration(labelText: 'Transaction Type'),
                      dropdownColor: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF1E1E24)
                          : Colors.white,
                      items: const [
                        DropdownMenuItem(
                          value: DebtType.owedToMe,
                          child: Text('Ali owes me (Receivable)'),
                        ),
                        DropdownMenuItem(
                          value: DebtType.iOwe,
                          child: Text('I owe Ahmed (Liability)'),
                        ),
                        DropdownMenuItem(
                          value: DebtType.loanGiven,
                          child: Text('Loan Given (Lent money)'),
                        ),
                        DropdownMenuItem(
                          value: DebtType.loanTaken,
                          child: Text('Loan Taken (Borrowed money)'),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setSheetState(() => selectedType = val);
                        }
                      },
                    ),
                    const SizedBox(height: 12),

                    // Due Date Picker
                    WMGlassSurface.tier1(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now().add(const Duration(days: 30)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 3650)),
                        );
                        if (picked != null) {
                          setSheetState(() => selectedDueDate = picked);
                        }
                      },
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            selectedDueDate == null
                                ? 'No due date set'
                                : 'Due Date: ${selectedDueDate!.toIso8601String().substring(0, 10)}',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const Icon(Icons.calendar_month_rounded),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Notes / Description
                    TextField(
                      controller: descController,
                      decoration: const InputDecoration(
                        labelText: 'Description (optional)',
                        hintText: 'e.g., Dinner splitting, Car repair loan',
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: notesController,
                      minLines: 2,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Additional Notes',
                      ),
                    ),
                    const SizedBox(height: 20),

                    PrimaryButton(
                      label: 'Save Transaction',
                      onPressed: () async {
                        final name = nameController.text.trim();
                        final amount = double.tryParse(amountController.text.trim());
                        if (name.isEmpty || amount == null || amount <= 0) return;

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

  Future<void> _showDebtDetailSheet(BuildContext context, DebtRecord debt) async {
    final state = context.read<AppState>();
    final payController = TextEditingController();

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      constraints: const BoxConstraints(maxWidth: 600),
      builder: (sheetContext) {
        return FutureBuilder<List<DebtRepayment>>(
          future: state.repaymentsForDebt(debt.id),
          builder: (context, snapshot) {
            final repayments = snapshot.data ?? const [];

            return StatefulBuilder(
              builder: (context, setSheetState) {
                final isReceivable = debt.type == DebtType.owedToMe || debt.type == DebtType.loanGiven;

                return SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      20,
                      10,
                      20,
                      20 + MediaQuery.of(context).viewInsets.bottom,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Person Name and Type badge
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

                        // Balance cards
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

                        // Payments history timeline
                        const Text(
                          'Payment Timeline',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                        ),
                        const SizedBox(height: 8),

                        if (repayments.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Text(
                              'No payments recorded yet.',
                              style: TextStyle(fontSize: 12, color: WalletMeltColors.textMuted),
                            ),
                          )
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: repayments.length,
                            itemBuilder: (ctx, index) {
                              final pay = repayments[index];
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.check_circle_rounded, size: 14, color: WalletMeltColors.positive),
                                        const SizedBox(width: 6),
                                        Text(
                                          pay.createdAt.substring(0, 10),
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                        if (pay.notes != null) ...[
                                          Text(' (${pay.notes})', style: const TextStyle(fontSize: 11, color: WalletMeltColors.textMuted)),
                                        ],
                                      ],
                                    ),
                                    Text(
                                      '-${pay.amount.toStringAsFixed(pay.amount % 1 == 0 ? 0 : 2)} ${debt.currency}',
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),

                        const SizedBox(height: 18),

                        // Repayment input form (only if not settled!)
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
                                  final amount = double.tryParse(payController.text.trim());
                                  if (amount == null || amount <= 0) return;

                                  final navigator = Navigator.of(sheetContext);
                                  await state.addRepayment(
                                    debtId: debt.id,
                                    amount: amount,
                                    notes: 'Partial payment',
                                  );
                                  navigator.pop();
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
                            },
                            child: const Text('Settle Remaining Balance'),
                          ),
                          const SizedBox(height: 10),
                        ],

                        // Delete button
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            foregroundColor: WalletMeltColors.danger,
                            minimumSize: const Size.fromHeight(48),
                          ),
                          icon: const Icon(Icons.delete_outline_rounded),
                          label: const Text('Delete Obligation'),
                          onPressed: () async {
                            final navigator = Navigator.of(sheetContext);
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Delete Obligation?'),
                                content: const Text('This will delete this debt record and all its repayment logs permanently.'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text('Cancel'),
                                  ),
                                  FilledButton(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: WalletMeltColors.danger,
                                    ),
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true) {
                              await state.deleteDebt(debt.id);
                              navigator.pop();
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
}
