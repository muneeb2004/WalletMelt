import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../components/glass/app_background.dart';
import '../../state/app_state.dart';
import '../../theme/wallet_melt_theme.dart';
import '../../types/expense.dart';
import '../../types/fuel.dart';
import '../../types/grocery_item.dart';
import '../../utils/currency_format.dart';
import '../../utils/date_utils.dart';
import '../../widgets/section_header.dart';

class ExpenseDetailScreen extends StatelessWidget {
  const ExpenseDetailScreen({required this.expenseId, super.key});

  final String expenseId;

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    final expense = context.select((AppState s) {
      return s.expenses.where((item) => item.id == expenseId).firstOrNull ??
          s.deletedExpenses.where((item) => item.id == expenseId).firstOrNull;
    });
    if (expense == null) {
      return const Scaffold(body: Center(child: Text('Expense not found')));
    }
    final category = context.select((AppState s) => s.categoryById(expense.categoryId));
    return Scaffold(
      body: AppBackground(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.md, AppSpacing.md + 2, AppSpacing.md, AppSpacing.lg),
        child: ListView(
          children: [
            // ── Title row ─────────────────────────────────────────────
            Row(
              children: [
                IconButton(
                    tooltip: 'Back',
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back_rounded)),
                Expanded(
                    child: Text(expense.title,
                        style: Theme.of(context).textTheme.headlineMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis)),
                if (!expense.isDeleted)
                  IconButton(
                      tooltip: 'Edit',
                      onPressed: () =>
                          context.push('/expense/${expense.id}/edit'),
                      icon: const Icon(Icons.edit_rounded)),
              ],
            ),
            const SizedBox(height: AppSpacing.md + 2),

            // ── Amount + meta card ─────────────────────────────────────
            WMGlassSurface.tier2(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (expense.taxAmount != null && expense.taxAmount! > 0) ...[
                    Text(formatMoney(expense.amount, expense.currency),
                        style: Theme.of(context).textTheme.displaySmall),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Subtotal: ${formatMoney(expense.subtotalAmount ?? (expense.amount - expense.taxAmount!), expense.currency)}',
                      style: const TextStyle(fontSize: 13, color: WalletMeltColors.textSecondary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Tax: ${formatMoney(expense.taxAmount!, expense.currency)}',
                      style: const TextStyle(fontSize: 13, color: WalletMeltColors.danger),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Grand Total: ${formatMoney(expense.amount, expense.currency)}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: WalletMeltColors.brandDeep),
                    ),
                  ] else ...[
                    Text(formatMoney(expense.amount, expense.currency),
                        style: Theme.of(context).textTheme.displaySmall),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                      '${category?.name ?? 'Unknown category'} • ${readableMonth(parseIsoDate(expense.date))}',
                      style: Theme.of(context).textTheme.bodyMedium),
                  if (expense.vendor != null)
                    Text(expense.vendor!,
                        style: Theme.of(context).textTheme.bodyMedium),
                  if (expense.notes != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text(expense.notes!,
                        style: Theme.of(context).textTheme.bodyLarge),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            if (expense.receiptImageUri != null) ...[
              WMGlassSurface.tier2(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeader(
                        title: 'Receipt',
                        icon: Icons.receipt_rounded,
                        padding: EdgeInsets.only(bottom: AppSpacing.xs)),
                    const SizedBox(height: AppSpacing.sm),
                    Semantics(
                      button: true,
                      label: 'View full receipt image',
                      child: GestureDetector(
                        onTap: () => context.push('/receipt/${expense.id}'),
                        child: Hero(
                          tag: expense.receiptImageUri!,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(22),
                            child: Image.file(
                              File(
                                  Uri.parse(expense.receiptImageUri!).toFilePath()),
                              height: 320,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              cacheHeight: (320 * MediaQuery.devicePixelRatioOf(context)).round(),
                              errorBuilder: (_, __, ___) => Container(
                                height: 180,
                                alignment: Alignment.center,
                                color: Colors.black.withValues(alpha: 0.08),
                                child: const Text(
                                    'Receipt file is missing or unreadable.'),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],

            // ── Grocery items ─────────────────────────────────────────
            if (category?.id == 'grocery') ...[
              _GroceryItemsCard(
                  expenseId: expense.id, currency: expense.currency),
            ],

            // ── Fuel details ──────────────────────────────────────────
            _FuelDetailsCard(
                expenseId: expense.id, currency: expense.currency),
            const SizedBox(height: AppSpacing.md + 2),

            // ── Soft delete / restore actions ─────────────────────────
            if (expense.isDeleted)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final router = GoRouter.of(context);
                        await state.restoreExpense(expense.id);
                        if (!context.mounted) return;
                        router.pop();
                      },
                      icon: const Icon(Icons.restore_rounded),
                      label: const Text('Restore'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: WalletMeltColors.danger,
                      ),
                      onPressed: () =>
                          _confirmPermanentDelete(context, state, expense),
                      icon: const Icon(Icons.delete_forever_rounded),
                      label: const Text('Delete forever'),
                    ),
                  ),
                ],
              )
            else
              OutlinedButton.icon(
                onPressed: () => _confirmSoftDelete(context, state, expense),
                icon: const Icon(Icons.delete_outline_rounded),
                label: const Text('Move to recycle bin'),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmSoftDelete(
      BuildContext context, AppState state, Expense expense) async {
    final router = GoRouter.of(context);
    final confirmed = await showConfirmDialog(
      context,
      title: 'Move expense to recycle bin?',
      body: 'You can restore it later from History.',
      confirmLabel: 'Move',
      isDestructive: true,
    );
    if (confirmed == true) {
      await state.softDeleteExpense(expense.id);
      if (!context.mounted) return;
      router.pop();
    }
  }

  Future<void> _confirmPermanentDelete(
      BuildContext context, AppState state, Expense expense) async {
    final router = GoRouter.of(context);
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete forever?',
      body: 'This removes the expense and its local receipt file.',
      confirmLabel: 'Delete',
      isDestructive: true,
    );
    if (confirmed == true) {
      await state.permanentlyDeleteExpense(expense.id);
      if (!context.mounted) return;
      router.pop();
    }
  }
}

class _FuelDetailsCard extends StatefulWidget {
  const _FuelDetailsCard({required this.expenseId, required this.currency});

  final String expenseId;
  final String currency;

  @override
  State<_FuelDetailsCard> createState() => _FuelDetailsCardState();
}

class _FuelDetailsCardState extends State<_FuelDetailsCard> {
  late final Future<FuelTransaction?> _fuelFuture;

  @override
  void initState() {
    super.initState();
    _fuelFuture =
        context.read<AppState>().fuelTransactionForExpense(widget.expenseId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<FuelTransaction?>(
      future: _fuelFuture,
      builder: (context, snapshot) {
        final tx = snapshot.data;
        if (tx == null || tx.components.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.only(top: 16.0),
          child: WMGlassSurface.tier2(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(
                  title: 'Fuel breakdown',
                  icon: Icons.local_gas_station_rounded,
                  padding: EdgeInsets.only(bottom: AppSpacing.xs),
                ),
                const SizedBox(height: AppSpacing.sm),
                for (final comp in tx.components)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      children: [
                        Icon(comp.fuelType.icon, size: 18, color: WalletMeltColors.brand),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                comp.fuelType.displayName,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              Text(
                                '${comp.quantityLitres.toStringAsFixed(comp.quantityLitres % 1 == 0 ? 0 : 2)} L @ ${formatMoney(comp.pricePerLitre, widget.currency)}/L',
                                style: const TextStyle(fontSize: 12, color: WalletMeltColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          formatMoney(comp.subtotal, widget.currency),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total: ${tx.totalLitres.toStringAsFixed(tx.totalLitres % 1 == 0 ? 0 : 2)} L',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    if (tx.odometerReading != null)
                      Text(
                        'Odometer: ${tx.odometerReading! % 1 == 0 ? tx.odometerReading!.toInt() : tx.odometerReading} km',
                        style: const TextStyle(fontSize: 12, color: WalletMeltColors.textSecondary),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _GroceryItemsCard extends StatefulWidget {
  const _GroceryItemsCard({required this.expenseId, required this.currency});

  final String expenseId;
  final String currency;

  @override
  State<_GroceryItemsCard> createState() => _GroceryItemsCardState();
}

class _GroceryItemsCardState extends State<_GroceryItemsCard> {
  late final Future<List<GroceryItem>> _itemsFuture;

  @override
  void initState() {
    super.initState();
    _itemsFuture =
        context.read<AppState>().groceryItemsForExpense(widget.expenseId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<GroceryItem>>(
      future: _itemsFuture,
      builder: (context, snapshot) {
        final items = snapshot.data ?? [];
        if (items.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(top: 16.0 /* AppSpacing.md */),
          child: WMGlassSurface.tier2(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(
                    title: 'Grocery items',
                    icon: Icons.shopping_cart_outlined,
                    padding: EdgeInsets.only(bottom: AppSpacing.xs)),
                const SizedBox(height: AppSpacing.sm),
                for (final item in items)
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: AppSpacing.xs + 2),
                    child: Row(
                      children: [
                        Expanded(
                            child: Text(item.name,
                                style: Theme.of(context).textTheme.bodyLarge)),
                        Text(formatMoney(item.amount, widget.currency),
                            style: Theme.of(context).textTheme.bodyLarge),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
