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
import '../../widgets/fluid_list.dart';
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

enum HistoryRange {
  thisPeriod('This month'),
  last30('Last 30 days'),
  last90('Last 3 months'),
  thisYear('This year'),
  allTime('All time'),
  custom('Custom');

  const HistoryRange(this.label);
  final String label;
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
  HistoryRange _range = HistoryRange.thisPeriod;
  DateTimeRange? _customRange;

  Timer? _debounceTimer;
  String _searchQuery = '';

  // Memoization cache to avoid recalculating sorting/filtering on rebuilds
  List<Expense>? _cachedRawExpenses;
  int? _cachedPeriodStartDay;
  String? _cachedSearchQuery;
  String? _cachedCategoryId;
  ExpenseSort? _cachedSort;
  String? _cachedTaxFilter;
  HistoryRange? _cachedRange;
  DateTimeRange? _cachedCustomRange;
  List<_ListItem>? _cachedItems;
  List<Expense>? _cachedFilteredList;
  int _cachedTotalMatching = 0;

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
    final period = context.read<AppState>().budgetPeriod;
    if (_cachedRawExpenses == rawExpenses &&
        _cachedPeriodStartDay == period.startDay &&
        _cachedSearchQuery == _searchQuery &&
        _cachedCategoryId == _categoryId &&
        _cachedSort == _sort &&
        _cachedTaxFilter == _taxFilter &&
        _cachedRange == _range &&
        _cachedCustomRange == _customRange &&
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

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final currentPeriod = period.periodOf(now);
    bool inRange(DateTime d) {
      final day = DateTime(d.year, d.month, d.day);
      switch (_range) {
        case HistoryRange.thisPeriod:
          // Searching looks through all history, not just this period.
          return _searchQuery.isNotEmpty || period.contains(currentPeriod, d);
        case HistoryRange.last30:
          return !day.isBefore(today.subtract(const Duration(days: 29))) &&
              !day.isAfter(today);
        case HistoryRange.last90:
          return !day.isBefore(DateTime(today.year, today.month - 3, today.day)) &&
              !day.isAfter(today);
        case HistoryRange.thisYear:
          return day.year == today.year;
        case HistoryRange.allTime:
          return true;
        case HistoryRange.custom:
          final r = _customRange;
          if (r == null) return true;
          return !day.isBefore(r.start) && !day.isAfter(r.end);
      }
    }

    // The recycle bin always lists everything so deleted items are never hidden.
    final displayExpenses = _showRecycleBin
        ? filtered
        : filtered.where((e) {
            final d = DateTime.tryParse(e.date);
            return d == null ? _range == HistoryRange.allTime : inRange(d);
          }).toList();
    _cachedFilteredList = displayExpenses;
    _cachedTotalMatching = filtered.length;

    final grouped = groupExpensesByMonth(displayExpenses, period);
    final items = <_ListItem>[];
    for (final entry in grouped.entries) {
      final headerLabel = period.isCalendarMonth
          ? entry.key
          : period.label(DateTime.parse('${entry.key}-01'));
      items.add(_HeaderItem(headerLabel));
      for (final expense in entry.value) {
        items.add(_ExpenseItem(expense));
      }
    }

    _cachedRawExpenses = rawExpenses;
    _cachedPeriodStartDay = period.startDay;
    _cachedSearchQuery = _searchQuery;
    _cachedCategoryId = _categoryId;
    _cachedSort = _sort;
    _cachedTaxFilter = _taxFilter;
    _cachedRange = _range;
    _cachedCustomRange = _customRange;
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
            physics: FluidList.physics,
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.md, 16, AppSpacing.md, 0),
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
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _showRecycleBin
                                    ? 'Restore or permanently delete expenses'
                                    : 'All past expenses and receipts',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: context.scheme.onSurfaceVariant,
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
                                  ? (context.scheme.surfaceContainer)
                                  : context.scheme.error.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _showRecycleBin
                                    ? (context.scheme.outlineVariant)
                                    : context.scheme.error.withValues(alpha: 0.35),
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
                                    ? (context.scheme.onSurface)
                                    : context.scheme.error,
                              ),
                            ),
                          ),

                        ],
                      ),
                      const SizedBox(height: 16),

                      // ── Search Bar (Directive 2: flat translucent fill, no BackdropFilter) ──
                      Container(
                        decoration: BoxDecoration(
                          color: context.scheme.surfaceContainer,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                          border: Border.all(
                            color: context.scheme.outlineVariant,
                            width: 1.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: context.scheme.shadow.withValues(alpha: isDark ? 0.20 : 0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search merchant, title, notes...',
                            hintStyle: TextStyle(
                              fontSize: 14,
                              color: context.scheme.onSurfaceVariant,
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
                              color: context.scheme.surfaceContainerHigh,
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
                              color: context.scheme.surfaceContainer,
                              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                              border: Border.all(
                                color: context.scheme.outlineVariant,
                                width: 1.0,
                              ),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<ExpenseSort>(
                                menuMaxHeight: 320,
                                value: _sort,
                                icon: const Icon(Icons.sort_rounded, size: 16),
                                style: TextStyle(
                                  fontFamily: 'PlusJakartaSans',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: context.scheme.onSurface,
                                ),
                                dropdownColor: context.scheme.surfaceContainer,
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

                      // ── Time range filter ─────────────────────────────────
                      if (!_showRecycleBin) ...[
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          clipBehavior: Clip.none,
                          child: Row(
                            children: [
                              for (final r in HistoryRange.values) ...[
                                ChoiceChip(
                                  key: Key('history_range_${r.name}'),
                                  avatar: r == HistoryRange.custom
                                      ? const Icon(Icons.date_range_rounded,
                                          size: 16)
                                      : null,
                                  label: Text(r == HistoryRange.custom &&
                                          _customRange != null
                                      ? _rangeLabel()
                                      : r.label),
                                  selected: _range == r,
                                  onSelected: (_) => r == HistoryRange.custom
                                      ? _pickCustomRange()
                                      : setState(() => _range = r),
                                ),
                                const SizedBox(width: 8),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

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
                    child: EmptyState(
                      icon: _showRecycleBin
                          ? Icons.delete_sweep_outlined
                          : (_cachedTotalMatching == 0 && expenses.isEmpty
                              ? Icons.receipt_long_outlined
                              : Icons.search_off_rounded),
                      title: _showRecycleBin
                          ? 'Recycle bin is empty'
                          : (expenses.isEmpty
                              ? 'No expenses yet'
                              : 'No expenses in this range'),
                      subtitle: _showRecycleBin
                          ? 'Deleted expenses will appear here.'
                          : (expenses.isEmpty
                              ? 'Expenses you add will show up here.'
                              : (_range != HistoryRange.allTime
                                  ? 'Nothing matches ${_rangeLabel()}. Try a wider time range or clear your filters.'
                                  : 'Try a different search term or category filter.')),
                      actionLabel: !_showRecycleBin &&
                              expenses.isNotEmpty &&
                              _range != HistoryRange.allTime
                          ? 'Show all time'
                          : null,
                      onActionPressed: () =>
                          setState(() => _range = HistoryRange.allTime),
                    ),
                  ),
                )
              else
                // ── Lazy expense list with date-group headers and Slidable actions split (Directive 7) ──
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, 120),
                  sliver: SliverList.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      if (item is _HeaderItem) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 22, bottom: 8, left: 4),
                          child: Text(
                            item.label.toUpperCase(),
                            style: TextStyle(
                              fontFamily: 'PlusJakartaSans',
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.0,
                              color: context.scheme.onSurfaceVariant,
                            ),
                          ),
                        );
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

  String _rangeLabel() {
    final r = _customRange;
    if (_range == HistoryRange.custom && r != null) {
      String d(DateTime x) =>
          '${x.day.toString().padLeft(2, '0')}/${x.month.toString().padLeft(2, '0')}/${x.year}';
      return '${d(r.start)} – ${d(r.end)}';
    }
    return _range.label.toLowerCase();
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 1, 12, 31),
      initialDateRange: _customRange,
    );
    if (picked != null && mounted) {
      setState(() {
        _customRange = picked;
        _range = HistoryRange.custom;
      });
    }
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
              ? (context.scheme.primary)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isSelected
                ? (context.scheme.onPrimary)
                : (context.scheme.onSurfaceVariant),
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
            ? context.scheme.surfaceContainer.withValues(alpha: 0.48)
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
