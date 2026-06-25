import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../components/category/category_chip.dart';
import '../../components/expense/expense_list_tile.dart';
import '../../components/glass/app_background.dart';
import '../../state/app_state.dart';
import '../../theme/wallet_melt_theme.dart';
import '../../types/category.dart' as wm;
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
  String _taxFilter = 'all';

  Timer? _debounceTimer;
  String _searchQuery = '';

  // Memoization cache to avoid recalculating sorting/filtering on rebuilds
  List<Expense>? _cachedRawExpenses;
  String? _cachedSearchQuery;
  String? _cachedCategoryId;
  ExpenseSort? _cachedSort;
  String? _cachedTaxFilter;
  List<_ListItem>? _cachedItems;
  List<Expense>? _cachedFilteredList;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 200), () {
      if (mounted) {
        setState(() {
          _searchQuery = _searchController.text.trim().toLowerCase();
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  List<_ListItem> _getOrCreateItems(List<Expense> rawExpenses) {
    if (_cachedRawExpenses == rawExpenses &&
        _cachedSearchQuery == _searchQuery &&
        _cachedCategoryId == _categoryId &&
        _cachedSort == _sort &&
        _cachedTaxFilter == _taxFilter &&
        _cachedItems != null) {
      return _cachedItems!;
    }

    final filtered = rawExpenses.where((expense) {
      final matchesCategory =
          _categoryId == null || expense.categoryId == _categoryId;
      final haystack =
          '${expense.title} ${expense.vendor ?? ''} ${expense.notes ?? ''}'
              .toLowerCase();
      final matchesQuery = _searchQuery.isEmpty || haystack.contains(_searchQuery);
      
      bool matchesTax = true;
      if (_taxFilter == 'taxable') {
        matchesTax = expense.taxAmount != null && expense.taxAmount! > 0;
      } else if (_taxFilter == 'nontaxable') {
        matchesTax = expense.taxAmount == null || expense.taxAmount! <= 0;
      }

      return matchesCategory && matchesQuery && matchesTax;
    }).toList();

    filtered.sort((a, b) {
      return switch (_sort) {
        ExpenseSort.newest => b.date.compareTo(a.date),
        ExpenseSort.oldest => a.date.compareTo(b.date),
        ExpenseSort.amountHigh => b.amount.compareTo(a.amount),
        ExpenseSort.amountLow => a.amount.compareTo(b.amount),
      };
    });

    _cachedFilteredList = filtered;

    final grouped = groupExpensesByMonth(filtered);
    final items = <_ListItem>[];
    for (final entry in grouped.entries) {
      items.add(_HeaderItem(entry.key));
      for (final expense in entry.value) {
        items.add(_ExpenseItem(expense));
      }
    }

    _cachedRawExpenses = rawExpenses;
    _cachedSearchQuery = _searchQuery;
    _cachedCategoryId = _categoryId;
    _cachedSort = _sort;
    _cachedTaxFilter = _taxFilter;
    _cachedItems = items;

    return items;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final expenses = context.select<AppState, List<Expense>>((s) => s.expenses);
    final deletedExpenses = context.select<AppState, List<Expense>>((s) => s.deletedExpenses);
    final categories = context.select<AppState, List<wm.Category>>((s) => s.categories);
    final base = _showRecycleBin ? deletedExpenses : expenses;
    final items = _getOrCreateItems(base);
    final filteredEmpty = _cachedFilteredList?.isEmpty ?? true;

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
                          child: Text(
                            'History',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.headlineMedium,
                          ),
                        ),
                        IconButton(
                          tooltip: _showRecycleBin
                              ? 'Show active expenses'
                              : 'Show recycle bin',
                          onPressed: () {
                            setState(() => _showRecycleBin = !_showRecycleBin);
                            if (_showRecycleBin) {
                              context.read<AppState>().loadDeletedExpenses();
                            }
                          },
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
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    Row(
                      children: [
                        ChoiceChip(
                          label: const Text('All', style: TextStyle(fontSize: 11)),
                          selected: _taxFilter == 'all',
                          onSelected: (val) {
                            if (val) setState(() => _taxFilter = 'all');
                          },
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('Taxable', style: TextStyle(fontSize: 11)),
                          selected: _taxFilter == 'taxable',
                          onSelected: (val) {
                            if (val) setState(() => _taxFilter = 'taxable');
                          },
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('No Tax', style: TextStyle(fontSize: 11)),
                          selected: _taxFilter == 'nontaxable',
                          onSelected: (val) {
                            if (val) setState(() => _taxFilter = 'nontaxable');
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    // ── Category filter chips ─────────────────────────────
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      clipBehavior: Clip.none,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            _CategoryAllChip(
                                selected: _categoryId == null,
                                onTap: () =>
                                    setState(() => _categoryId = null)),
                            const SizedBox(width: AppSpacing.sm),
                            for (final category in categories) ...[
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
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    // ── Sort dropdown ─────────────────────────────────────
                    DropdownButtonFormField<ExpenseSort>(
                      initialValue: _sort,
                      decoration: const InputDecoration(labelText: 'Sort'),
                      dropdownColor: theme.brightness == Brightness.dark
                          ? WalletMeltColors.darkSurface
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
            if (filteredEmpty)
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
                      category: context.read<AppState>().categoryById(expItem.expense.categoryId),
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
            ? WalletMeltColors.darkSurface.withValues(alpha: 0.48)
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
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          constraints: const BoxConstraints(minHeight: 44.0),
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
            border: Border.all(color: border, width: 1.2),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
              onTap: onTap,
              child: Center(
                widthFactor: 1.0,
                heightFactor: 1.0,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Text(
                    'All',
                    style: Theme.of(context).textTheme.labelLarge,
                    textHeightBehavior: const TextHeightBehavior(
                      applyHeightToFirstAscent: false,
                      applyHeightToLastDescent: false,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
