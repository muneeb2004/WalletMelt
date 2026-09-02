import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../components/category/category_chip.dart';
import '../../components/expense/expense_list_tile.dart';
import '../../components/glass/app_background.dart';
import '../../state/app_state.dart';
import '../../theme/wallet_melt_theme.dart';
import '../../types/category.dart' as wm;
import '../../types/expense.dart';
import '../../utils/insights.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/state_views.dart';

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

final class _ToggleHistoryItem extends _ListItem {
  _ToggleHistoryItem({required this.showAll, required this.hiddenCount});
  final bool showAll;
  final int hiddenCount;
}

// ── Screen ───────────────────────────────────────────────────────────────────

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({this.initialCategoryId, super.key});

  final String? initialCategoryId;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _searchController = TextEditingController();
  String? _categoryId;
  ExpenseSort _sort = ExpenseSort.newest;
  bool _showRecycleBin = false;
  String _taxFilter = 'all';
  bool _showAllHistory = false;
  int _hiddenOlderCount = 0;

  Timer? _debounceTimer;
  String _searchQuery = '';

  // Memoization cache to avoid recalculating sorting/filtering on rebuilds
  List<Expense>? _cachedRawExpenses;
  String? _cachedSearchQuery;
  String? _cachedCategoryId;
  ExpenseSort? _cachedSort;
  String? _cachedTaxFilter;
  bool? _cachedShowAllHistory;
  List<_ListItem>? _cachedItems;
  List<Expense>? _cachedFilteredList;

  @override
  void initState() {
    super.initState();
    _categoryId = widget.initialCategoryId;
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void didUpdateWidget(covariant HistoryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialCategoryId != oldWidget.initialCategoryId) {
      setState(() {
        _categoryId = widget.initialCategoryId;
      });
    }
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
        _cachedShowAllHistory == _showAllHistory &&
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

    final now = DateTime.now();
    final currentMonthKey = '${now.year}-${now.month.toString().padLeft(2, '0')}';

    List<Expense> displayExpenses;
    if (!_showAllHistory && _searchQuery.isEmpty && !_showRecycleBin) {
      displayExpenses = filtered.where((e) => e.date.startsWith(currentMonthKey)).toList();
      _hiddenOlderCount = filtered.length - displayExpenses.length;
    } else {
      displayExpenses = filtered;
      _hiddenOlderCount = 0;
    }

    final grouped = groupExpensesByMonth(displayExpenses);
    final items = <_ListItem>[];
    for (final entry in grouped.entries) {
      items.add(_HeaderItem(entry.key));
      for (final expense in entry.value) {
        items.add(_ExpenseItem(expense));
      }
    }

    if (_hiddenOlderCount > 0 && !_showAllHistory && _searchQuery.isEmpty && !_showRecycleBin) {
      items.add(_ToggleHistoryItem(showAll: false, hiddenCount: _hiddenOlderCount));
    } else if (_showAllHistory && !_showRecycleBin && filtered.any((e) => !e.date.startsWith(currentMonthKey))) {
      items.add(_ToggleHistoryItem(showAll: true, hiddenCount: 0));
    }

    _cachedRawExpenses = rawExpenses;
    _cachedSearchQuery = _searchQuery;
    _cachedCategoryId = _categoryId;
    _cachedSort = _sort;
    _cachedTaxFilter = _taxFilter;
    _cachedShowAllHistory = _showAllHistory;
    _cachedItems = items;

    return items;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final expenses = context.select<AppState, List<Expense>>((s) => s.expenses);
    final deletedExpenses = context.select<AppState, List<Expense>>((s) => s.deletedExpenses);
    final categories = context.select<AppState, List<wm.Category>>((s) => s.categories);
    final base = _showRecycleBin ? deletedExpenses : expenses;
    final items = _getOrCreateItems(base);
    final filteredEmpty = _cachedFilteredList?.isEmpty ?? true;
    final isLoading = context.select<AppState, bool>((s) => s.isLoading);
    final errorMessage = context.select<AppState, String?>((s) => s.errorMessage);
    final isOffline = context.select<AppState, bool>((s) => s.isOffline);

    if (errorMessage != null) {
      return Scaffold(
        body: AppBackground(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: AppErrorState(
                message: errorMessage,
                onRetry: () => context.read<AppState>().refresh(),
              ),
            ),
          ),
        ),
      );
    }

    if (isOffline) {
      return Scaffold(
        body: AppBackground(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: AppOfflineState(
                onRetry: () => context.read<AppState>().refresh(),
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: AppBackground(
        padding: EdgeInsets.zero,
        child: Skeletonizer(
          enabled: isLoading,
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Title row ─────────────────────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _showRecycleBin ? 'Recycle Bin' : 'Transaction History',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _showRecycleBin
                                    ? 'Restore or permanently delete expenses'
                                    : 'All past expenses and receipts',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: WalletMeltColors.textMuted,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: _showRecycleBin
                                  ? (isDark ? WalletMeltColors.darkSurface : Colors.white)
                                  : WalletMeltColors.danger.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _showRecycleBin
                                    ? (isDark ? WalletMeltColors.darkBorder : WalletMeltColors.lightBorder)
                                    : WalletMeltColors.danger.withValues(alpha: 0.35),
                                width: 1.0,
                              ),
                            ),
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              tooltip: _showRecycleBin
                                  ? 'Show active expenses'
                                  : 'Show recycle bin',
                              onPressed: () {
                                setState(() => _showRecycleBin = !_showRecycleBin);
                                if (_showRecycleBin) {
                                  context.read<AppState>().loadDeletedExpenses();
                                }
                              },
                              icon: Icon(
                                _showRecycleBin
                                    ? Icons.receipt_long_rounded
                                    : Icons.delete_outline_rounded,
                                size: 18,
                                color: _showRecycleBin
                                    ? (isDark ? Colors.white : WalletMeltColors.textPrimary)
                                    : WalletMeltColors.danger,
                              ),
                            ),
                          ),

                        ],
                      ),
                      const SizedBox(height: 16),

                      // ── Search Bar (Directive 2: flat translucent fill, no BackdropFilter) ──
                      Container(
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0C0E14) : Colors.white,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                          border: Border.all(
                            color: isDark ? WalletMeltColors.darkBorder : WalletMeltColors.lightBorder,
                            width: 1.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search merchant, title, notes...',
                            hintStyle: const TextStyle(
                              fontSize: 13.5,
                              color: WalletMeltColors.textMuted,
                              fontWeight: FontWeight.w500,
                            ),
                            prefixIcon: const Icon(Icons.search_rounded, size: 20),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded, size: 18),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _searchQuery = '');
                                    },
                                  )
                                : null,
                            filled: false,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // ── Filter Controls Row ────────────────────────────────
                      Row(
                        children: [
                          // Tax Filter Segmented Pills
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF0C0E14) : const Color(0xFFECEFF3),
                              borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildTaxPill('all', 'All', isDark),
                                _buildTaxPill('taxable', 'Taxed', isDark),
                                _buildTaxPill('nontaxable', 'No Tax', isDark),
                              ],
                            ),
                          ),
                          const Spacer(),
                          // Sort selector
                          Container(
                            height: 36,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: isDark ? WalletMeltColors.darkSurface : Colors.white,
                              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                              border: Border.all(
                                color: isDark ? WalletMeltColors.darkBorder : WalletMeltColors.lightBorder,
                                width: 1.0,
                              ),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<ExpenseSort>(
                                value: _sort,
                                icon: const Icon(Icons.sort_rounded, size: 16),
                                style: TextStyle(
                                  fontFamily: 'PlusJakartaSans',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.white : WalletMeltColors.textPrimary,
                                ),
                                dropdownColor: isDark
                                    ? WalletMeltColors.darkSurface
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                                items: const [
                                  DropdownMenuItem(
                                      value: ExpenseSort.newest, child: Text('Newest')),
                                  DropdownMenuItem(
                                      value: ExpenseSort.oldest, child: Text('Oldest')),
                                  DropdownMenuItem(
                                      value: ExpenseSort.amountHigh,
                                      child: Text('Highest')),
                                  DropdownMenuItem(
                                      value: ExpenseSort.amountLow,
                                      child: Text('Lowest')),
                                ],
                                onChanged: (value) =>
                                    setState(() => _sort = value ?? _sort),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // ── Category filter chips ─────────────────────────────
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        clipBehavior: Clip.none,
                        child: Row(
                          children: [
                            _CategoryAllChip(
                                selected: _categoryId == null,
                                onTap: () =>
                                    setState(() => _categoryId = null)),
                            const SizedBox(width: 8),
                            for (final category in categories) ...[
                              WalletCategoryChip(
                                  category: category,
                                  selected: _categoryId == category.id,
                                  onTap: () =>
                                      setState(() => _categoryId = category.id)),
                              const SizedBox(width: 8),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),

              // ── Empty state ──────────────────────────────────────────────
              if (filteredEmpty)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                  sliver: SliverToBoxAdapter(
                    child: _hiddenOlderCount > 0 && !_showAllHistory
                        ? Padding(
                            padding: const EdgeInsets.symmetric(vertical: 32),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.calendar_today_outlined,
                                    size: 48, color: WalletMeltColors.textMuted),
                                const SizedBox(height: 14),
                                const Text('No expenses this month',
                                    style: TextStyle(
                                        fontSize: 16, fontWeight: FontWeight.w700)),
                                const SizedBox(height: 6),
                                Text(
                                    'You have $_hiddenOlderCount older expenses saved.',
                                    style: const TextStyle(
                                        fontSize: 13,
                                        color: WalletMeltColors.textMuted)),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: () =>
                                      setState(() => _showAllHistory = true),
                                  icon: const Icon(Icons.history_rounded, size: 18),
                                  label: const Text('Show All History'),
                                ),
                              ],
                            ),
                          )
                        : EmptyState(
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
                // ── Lazy expense list with date-group headers and Slidable actions split (Directive 7) ──
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                  sliver: SliverList.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      if (item is _HeaderItem) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 22, bottom: 8, left: 4),
                          child: Text(
                            item.label.toUpperCase(),
                            style: const TextStyle(
                              fontFamily: 'PlusJakartaSans',
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.0,
                              color: WalletMeltColors.textMuted,
                            ),
                          ),
                        );
                      }
                      if (item is _ToggleHistoryItem) {
                        if (!item.showAll) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 16, bottom: 8),
                            child: WMGlassSurface.tier2(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                              onTap: () => setState(() => _showAllHistory = true),
                              child: Row(
                                children: [
                                  Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: WalletMeltColors.brand
                                          .withValues(alpha: 0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.history_rounded,
                                        size: 20,
                                        color: WalletMeltColors.brand),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Showing Current Month',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 13,
                                            color: isDark
                                                ? Colors.white
                                                : WalletMeltColors.textPrimary,
                                          ),
                                        ),
                                        Text(
                                          '${item.hiddenCount} older expense${item.hiddenCount == 1 ? '' : 's'} hidden',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: WalletMeltColors.textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 8),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    onPressed: () =>
                                        setState(() => _showAllHistory = true),
                                    child: const Text('Show All',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w800)),
                                  ),
                                ],
                              ),
                            ),
                          );
                        } else {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.calendar_today_rounded,
                                    size: 16),
                                label: const Text('Show Current Month Only'),
                                onPressed: () =>
                                    setState(() => _showAllHistory = false),
                              ),
                            ),
                          );
                        }
                      }
                      final expItem = item as _ExpenseItem;
                      return ExpenseListTile(
                        expense: expItem.expense,
                        category: context.read<AppState>().categoryById(expItem.expense.categoryId),
                        onTap: () => context.push('/expense/${expItem.expense.id}'),
                        onEdit: () => context.push('/expense/${expItem.expense.id}'),
                        onCategorize: () => _showQuickCategorySheet(context, expItem.expense),
                        onDelete: () async {
                          final appState = context.read<AppState>();
                          await appState.softDeleteExpense(expItem.expense.id);
                        },
                        onRestore: () async {
                          final appState = context.read<AppState>();
                          await appState.restoreExpense(expItem.expense.id);
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showQuickCategorySheet(BuildContext context, Expense expense) {
    final categories = context.read<AppState>().categories;
    showAppBottomSheet<void>(
      context,
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Change Category',
                style: Theme.of(ctx).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final cat in categories)
                    WalletCategoryChip(
                      category: cat,
                      selected: expense.categoryId == cat.id,
                      onTap: () {
                        context.read<AppState>().updateExpense(
                          expense.copyWith(categoryId: cat.id),
                        );
                        Navigator.pop(ctx);
                      },
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTaxPill(String value, String label, bool isDark) {
    final isSelected = _taxFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _taxFilter = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? WalletMeltColors.brand : WalletMeltColors.textPrimary)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isSelected
                ? (isDark ? Colors.black : Colors.white)
                : (isDark ? WalletMeltColors.darkTextSecondary : WalletMeltColors.textSecondary),
          ),
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
