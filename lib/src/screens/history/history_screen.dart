import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../components/category/category_chip.dart';
import '../../components/expense/expense_list_tile.dart';
import '../../components/glass/app_background.dart';
import '../../state/app_state.dart';
import '../../types/expense.dart';
import '../../utils/insights.dart';

enum ExpenseSort { newest, oldest, amountHigh, amountLow }

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _searchController = TextEditingController();
  String? _categoryId;
  ExpenseSort _sort = ExpenseSort.newest;
  bool _showRecycleBin = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final base = _showRecycleBin ? state.deletedExpenses : state.expenses;
    final filtered = _filtered(base);
    final grouped = groupExpensesByMonth(filtered);
    return Scaffold(
      body: AppBackground(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Row(
              children: [
                Expanded(child: Text('History', style: Theme.of(context).textTheme.headlineMedium)),
                IconButton(
                  tooltip: _showRecycleBin ? 'Show active expenses' : 'Show recycle bin',
                  onPressed: () => setState(() => _showRecycleBin = !_showRecycleBin),
                  icon: Icon(_showRecycleBin ? Icons.receipt_long_rounded : Icons.delete_outline_rounded),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(prefixIcon: Icon(Icons.search_rounded), labelText: 'Search vendor, title, notes'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FilterChip(label: const Text('All'), selected: _categoryId == null, onSelected: (_) => setState(() => _categoryId = null)),
                  const SizedBox(width: 8),
                  for (final category in state.categories) ...[
                    WalletCategoryChip(category: category, selected: _categoryId == category.id, onTap: () => setState(() => _categoryId = category.id)),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<ExpenseSort>(
              initialValue: _sort,
              decoration: const InputDecoration(labelText: 'Sort'),
              items: const [
                DropdownMenuItem(value: ExpenseSort.newest, child: Text('Newest')),
                DropdownMenuItem(value: ExpenseSort.oldest, child: Text('Oldest')),
                DropdownMenuItem(value: ExpenseSort.amountHigh, child: Text('Amount high to low')),
                DropdownMenuItem(value: ExpenseSort.amountLow, child: Text('Amount low to high')),
              ],
              onChanged: (value) => setState(() => _sort = value ?? _sort),
            ),
            const SizedBox(height: 18),
            if (filtered.isEmpty)
              Text(_showRecycleBin ? 'The recycle bin is empty.' : 'No expenses match these filters.', style: Theme.of(context).textTheme.bodyMedium)
            else
              for (final entry in grouped.entries) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 14, bottom: 6),
                  child: Text(entry.key, style: Theme.of(context).textTheme.titleMedium),
                ),
                for (final expense in entry.value)
                  ExpenseListTile(
                    expense: expense,
                    category: state.categoryById(expense.categoryId),
                    onTap: () => context.push('/expense/${expense.id}'),
                  ),
              ],
          ],
        ),
      ),
    );
  }

  List<Expense> _filtered(List<Expense> expenses) {
    final query = _searchController.text.trim().toLowerCase();
    final result = expenses.where((expense) {
      final matchesCategory = _categoryId == null || expense.categoryId == _categoryId;
      final haystack = '${expense.title} ${expense.vendor ?? ''} ${expense.notes ?? ''}'.toLowerCase();
      final matchesQuery = query.isEmpty || haystack.contains(query);
      return matchesCategory && matchesQuery;
    }).toList();
    result.sort((a, b) {
      return switch (_sort) {
        ExpenseSort.newest => b.date.compareTo(a.date),
        ExpenseSort.oldest => a.date.compareTo(b.date),
        ExpenseSort.amountHigh => b.amount.compareTo(a.amount),
        ExpenseSort.amountLow => a.amount.compareTo(b.amount),
      };
    });
    return result;
  }
}
