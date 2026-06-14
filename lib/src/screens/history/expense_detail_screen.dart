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
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
        child: ListView(
          children: [
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
            const SizedBox(height: 18),
            LiquidGlass(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(formatMoney(expense.amount, expense.currency),
                      style: Theme.of(context).textTheme.displaySmall),
                  const SizedBox(height: 8),
                  Text(
                      '${category?.name ?? 'Unknown category'} • ${readableMonth(parseIsoDate(expense.date))}',
                      style: Theme.of(context).textTheme.bodyMedium),
                  if (expense.vendor != null)
                    Text(expense.vendor!,
                        style: Theme.of(context).textTheme.bodyMedium),
                  if (expense.notes != null) ...[
                    const SizedBox(height: 14),
                    Text(expense.notes!,
                        style: Theme.of(context).textTheme.bodyLarge),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (expense.receiptImageUri != null)
              LiquidGlass(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Receipt',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 12),
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
            if (category?.id == 'grocery') ...[
              const SizedBox(height: 16),
              _GroceryItemsCard(
                  expenseId: expense.id, currency: expense.currency),
            ],
            const SizedBox(height: 18),
            if (expense.isDeleted)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final router = GoRouter.of(context);
                        await state.restoreExpense(expense.id);
                        if (!context.mounted) return;
                        router.pop();
                      },
                      child: const Text('Restore'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                      child: OutlinedButton(
                          onPressed: () =>
                              _confirmPermanentDelete(context, state, expense),
                          child: const Text('Delete forever'))),
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Move expense to recycle bin?'),
        content: const Text('You can restore it later from History.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Move')),
        ],
      ),
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete forever?'),
        content:
            const Text('This removes the expense and its local receipt file.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete')),
        ],
      ),
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
        if (items.isEmpty) {
          return const SizedBox.shrink();
        }
        return LiquidGlass(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Grocery items',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 10),
              for (final item in items)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
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
