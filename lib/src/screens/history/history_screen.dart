import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../components/category/category_chip.dart';
import '../../components/expense/expense_list_tile.dart';
import '../../components/glass/app_background.dart';
import '../../state/app_state.dart';
import '../../theme/wallet_melt_theme.dart';
import '../../types/expense.dart';
import '../../utils/insights.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/section_header.dart';

enum ExpenseSort { newest, oldest, amountHigh, amountLow }

// ── Sealed list-item types for ListView.builder ──────────────────────────────

sealed class _ListItem {}

final class _HeaderItem extends _ListItem {
  _HeaderItem(this.label);
  final String label;
}

final class _ExpenseItem extends _ListItem {
  _ExpenseItem(this.expense);
  final Expense expense;
}

// ── Screen ───────────────────────────────────────────────────────────────────

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

  List<_ListItem> _buildItems(Map<String, List<Expense>> grouped) {
    final items = <_ListItem>[];
    for (final entry in grouped.entries) {
      items.add(_HeaderItem(entry.key));
      for (final expense in entry.value) {
        items.add(_ExpenseItem(expense));
      }
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final base = _showRecycleBin ? state.deletedExpenses : state.expenses;
    final filtered = _filtered(base);
    final grouped = groupExpensesByMonth(filtered);
    final items = _buildItems(grouped);

    return Scaffold(
      body: AppBackground(
        padding: EdgeInsets.zero,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Title row ─────────────────────────────────────────
                    Row(
                      children: [
                        Expanded(
                            child: Text('History',
                                style:
                                    Theme.of(context).textTheme.headlineMedium)),
                        IconButton(
                          tooltip: _showRecycleBin
                              ? 'Show active expenses'
                              : 'Show recycle bin',
                          onPressed: () =>
                              setState(() => _showRecycleBin = !_showRecycleBin),
                          icon: Icon(_showRecycleBin
                              ? Icons.receipt_long_rounded
                              : Icons.delete_outline_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // ── Search ────────────────────────────────────────────
                    TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.search_rounded),
                          labelText: 'Search vendor, title, notes'),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    // ── Category filter chips ─────────────────────────────
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _CategoryAllChip(
                              selected: _categoryId == null,
                              onTap: () =>
                                  setState(() => _categoryId = null)),
                          const SizedBox(width: AppSpacing.sm),
                          for (final category in state.categories) ...[
                            WalletCategoryChip(
                                category: category,
                                selected: _categoryId == category.id,
                                onTap: () =>
                                    setState(() => _categoryId = category.id)),
                            const SizedBox(width: AppSpacing.sm),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    // ── Sort dropdown ─────────────────────────────────────
                    DropdownButtonFormField<ExpenseSort>(
                      initialValue: _sort,
                      decoration: const InputDecoration(labelText: 'Sort'),
                      dropdownColor: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF1E1E24)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      items: const [
                        DropdownMenuItem(
                            value: ExpenseSort.newest, child: Text('Newest')),
                        DropdownMenuItem(
                            value: ExpenseSort.oldest, child: Text('Oldest')),
                        DropdownMenuItem(
                            value: ExpenseSort.amountHigh,
                            child: Text('Amount high to low')),
                        DropdownMenuItem(
                            value: ExpenseSort.amountLow,
                            child: Text('Amount low to high')),
                      ],
                      onChanged: (value) =>
                          setState(() => _sort = value ?? _sort),
                    ),
                    const SizedBox(height: AppSpacing.md + 2),
                  ],
                ),
              ),
            ),

            // ── Empty state ──────────────────────────────────────────────
            if (filtered.isEmpty)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                sliver: SliverToBoxAdapter(
                  child: EmptyState(
                    icon: _showRecycleBin
                        ? Icons.delete_sweep_outlined
                        : Icons.search_off_rounded,
                    title: _showRecycleBin
                        ? 'Recycle bin is empty'
                        : 'No expenses found',
                    subtitle: _showRecycleBin
                        ? 'Deleted expenses will appear here.'
                        : 'Try a different search term or category filter.',
                  ),
                ),
              )
            else
              // ── Lazy expense list with date-group headers ───────────────
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                sliver: SliverList.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    if (item is _HeaderItem) {
                      return SectionHeader(
                        title: item.label,
                        padding: const EdgeInsets.only(
                            top: AppSpacing.md, bottom: AppSpacing.xs),
                      );
                    }
                    final expItem = item as _ExpenseItem;
                    return ExpenseListTile(
                      expense: expItem.expense,
                      category: state.categoryById(expItem.expense.categoryId),
                      onTap: () => context.push('/expense/${expItem.expense.id}'),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<Expense> _filtered(List<Expense> expenses) {
    final query = _searchController.text.trim().toLowerCase();
    final result = expenses.where((expense) {
      final matchesCategory =
          _categoryId == null || expense.categoryId == _categoryId;
      final haystack =
          '${expense.title} ${expense.vendor ?? ''} ${expense.notes ?? ''}'
              .toLowerCase();
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

class _CategoryAllChip extends StatelessWidget {
  const _CategoryAllChip({required this.selected, required this.onTap});

  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = Theme.of(context).colorScheme.primary;
    final fill = selected
        ? color.withValues(alpha: 0.28)
        : (isDark
            ? const Color(0xFF1E1E24).withValues(alpha: 0.48)
            : Colors.white.withValues(alpha: 0.42));
    final border = selected
        ? color
        : (isDark
            ? const Color.fromRGBO(255, 255, 255, 0.12)
            : Colors.white.withValues(alpha: 0.4));
    return Semantics(
      button: true,
      selected: selected,
      label: 'All categories',
      child: AnimatedScale(
        duration: const Duration(milliseconds: 160),
        scale: selected ? 1.03 : 1.0,
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: border),
            ),
            child: Text('All', style: Theme.of(context).textTheme.labelLarge),
          ),
        ),
      ),
    );
  }
}
