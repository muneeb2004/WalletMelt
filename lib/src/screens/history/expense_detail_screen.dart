import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../components/glass/app_background.dart';
import '../../state/app_state.dart';
import '../../theme/wallet_melt_theme.dart';
import '../../types/expense.dart';
import '../../utils/currency_format.dart';
import '../../utils/date_utils.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/section_header.dart';

class ExpenseDetailScreen extends StatelessWidget {
  const ExpenseDetailScreen({required this.expenseId, super.key});

  final String expenseId;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final expense = [...state.expenses, ...state.deletedExpenses]
        .where((item) => item.id == expenseId)
        .firstOrNull;
    if (expense == null) {
      return const Scaffold(body: Center(child: Text('Expense not found')));
    }
    final category = state.categoryById(expense.categoryId);
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
            LiquidGlass(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(formatMoney(expense.amount, expense.currency),
                      style: Theme.of(context).textTheme.displaySmall),
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

            // ── Receipt image ─────────────────────────────────────────
            if (expense.receiptImageUri != null)
              LiquidGlass(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeader(
                        title: 'Receipt', icon: Icons.receipt_rounded),
                    const SizedBox(height: AppSpacing.sm),
                    Hero(
                      tag: expense.receiptImageUri!,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: Image.file(
                          File(
                              Uri.parse(expense.receiptImageUri!).toFilePath()),
                          height: 320,
                          width: double.infinity,
                          fit: BoxFit.cover,
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
                  ],
                ),
              ),

            // ── Grocery items ─────────────────────────────────────────
            if (category?.id == 'grocery') ...[
              const SizedBox(height: AppSpacing.md),
              _GroceryItemsCard(
                  expenseId: expense.id, currency: expense.currency),
            ],
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

class _GroceryItemsCard extends StatelessWidget {
  const _GroceryItemsCard({required this.expenseId, required this.currency});

  final String expenseId;
  final String currency;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: context.read<AppState>().groceryItemsForExpense(expenseId),
      builder: (context, snapshot) {
        final items = snapshot.data ?? [];
        if (items.isEmpty) return const SizedBox.shrink();
        return LiquidGlass(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(
                  title: 'Grocery items', icon: Icons.shopping_cart_outlined),
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
                      Text(formatMoney(item.amount, currency),
                          style: Theme.of(context).textTheme.bodyLarge),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
