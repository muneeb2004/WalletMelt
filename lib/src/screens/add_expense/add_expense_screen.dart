import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../components/category/category_chip.dart';
import '../../components/fuel/fuel_editor.dart';
import '../../components/glass/app_background.dart';
import '../../types/expense.dart';
import '../../types/fuel.dart';
import '../../types/grocery_item.dart';
import '../../state/app_state.dart';
import '../../theme/wallet_melt_theme.dart';
import '../../utils/expense_validation.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/state_views.dart';
import '../../types/grocery_template.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key, this.expenseId, this.initialCategoryId});

  final String? expenseId;
  final String? initialCategoryId;

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _amountController = TextEditingController();
  final _taxController = TextEditingController();
  final _taxPercentageController = TextEditingController();
  final _titleController = TextEditingController();
  final _vendorController = TextEditingController();
  final _notesController = TextEditingController();
  final List<GroceryItemDraft> _groceryItems = [];
  FuelTransactionDraft? _fuelTransactionDraft;

  String? _categoryId;
  String? _pendingInitialCategoryId;
  bool _initialCategoryResolved = false;
  DateTime _date = DateTime.now();
  String? _receiptUri;
  ExpenseValidationResult? _validation;
  bool _saving = false;
  bool _hydrated = false;
  bool _showAdditionalDetails = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialCategoryId != null) {
      _pendingInitialCategoryId = widget.initialCategoryId;
      _categoryId = widget.initialCategoryId;
    }
  }

  void _resolveInitialCategory(AppState state) {
    if (_initialCategoryResolved || _pendingInitialCategoryId == null) return;
    if (state.categories.isEmpty) return;

    final param = _pendingInitialCategoryId!;
    final byId = state.categoryById(param);
    if (byId != null) {
      _categoryId = byId.id;
      _initialCategoryResolved = true;
    } else {
      final byNameOrSlug = state.categories.where(
        (c) =>
            c.id.toLowerCase() == param.toLowerCase() ||
            c.name.toLowerCase() == param.toLowerCase(),
      ).firstOrNull;
      if (byNameOrSlug != null) {
        _categoryId = byNameOrSlug.id;
        _initialCategoryResolved = true;
      }
    }

    if (_initialCategoryResolved) {
      if (_titleController.text.trim().isEmpty) {
        if (param.toLowerCase() == 'fuel' || _categoryId == 'fuel') {
          _titleController.text = 'Fuel Refill';
        } else if (param.toLowerCase() == 'grocery' || _categoryId == 'grocery') {
          _titleController.text = 'Groceries';
        }
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final state = context.read<AppState>();
    _resolveInitialCategory(state);

    if (_hydrated || widget.expenseId == null) return;
    final expense = state.expenses
        .where((expense) => expense.id == widget.expenseId)
        .firstOrNull;
    if (expense != null) {
      final sub = expense.subtotalAmount ?? expense.amount;
      final tax = expense.taxAmount ?? 0.0;
      _amountController.text = sub.toStringAsFixed(sub % 1 == 0 ? 0 : 2);
      _taxController.text = tax > 0 ? tax.toStringAsFixed(tax % 1 == 0 ? 0 : 2) : '';
      _titleController.text = expense.title;
      _vendorController.text = expense.vendor ?? '';
      _notesController.text = expense.notes ?? '';
      _categoryId = expense.categoryId;
      _date = DateTime.parse(expense.date);
      _receiptUri = expense.receiptImageUri;
      if ((expense.vendor != null && expense.vendor!.isNotEmpty) ||
          (expense.notes != null && expense.notes!.isNotEmpty) ||
          (expense.taxAmount != null && expense.taxAmount! > 0) ||
          expense.receiptImageUri != null) {
        _showAdditionalDetails = true;
      }
      _loadGroceryItems(expense.id);
      _loadFuelTransaction(expense.id);
    }
    _hydrated = true;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _taxController.dispose();
    _taxPercentageController.dispose();
    _titleController.dispose();
    _vendorController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = context.read<AppState>();
    final currency = context.select((AppState s) => s.settings.currency);
    final categories = context.select((AppState s) => s.categories);
    final isEditing = widget.expenseId != null;

    if (!_initialCategoryResolved && _pendingInitialCategoryId != null && categories.isNotEmpty) {
      _resolveInitialCategory(state);
    }

    final selectedCategory =
        _categoryId == null ? null : state.categoryById(_categoryId!);
    final isGroceryMode = selectedCategory?.id == 'grocery' ||
        selectedCategory?.name.toLowerCase() == 'grocery';
    final isFuelMode = selectedCategory?.id == 'fuel' ||
        selectedCategory?.name.toLowerCase() == 'fuel';
    final isDark = theme.brightness == Brightness.dark;
    final errorMessage = context.select((AppState s) => s.errorMessage);
    final isOffline = context.select((AppState s) => s.isOffline);

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
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            16.0 /* AppSpacing.md */,
            18.0,
            16.0 /* AppSpacing.md */,
            (isGroceryMode || isFuelMode) ? 140.0 : 24.0 /* AppSpacing.lg */,
          ),
          children: [
            Row(
              children: [
                IconButton(
                    tooltip: 'Close',
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.close_rounded)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isFuelMode
                        ? 'Fuel Purchase Entry'
                        : (isGroceryMode
                            ? 'Bulk Grocery Entry'
                            : (isEditing ? 'Edit expense' : 'Add expense')),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.headlineMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Category Selector chips at the top
            _SectionTitle(
                title: 'Category',
                actionLabel: 'New',
                onAction: () => _showAddCategorySheet(context)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final category in categories)
                  WalletCategoryChip(
                    category: category,
                    selected: category.id == _categoryId,
                    onTap: () {
                      setState(() {
                        _categoryId = category.id;
                      });
                    },
                  ),
              ],
            ),
            if (_validation?.categoryError != null)
              Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(_validation!.categoryError!,
                      style: TextStyle(
                          color: theme.colorScheme.error))),
            const SizedBox(height: 20),

            if (isGroceryMode) ...[
              // ── Dedicated Bulk Grocery Mode ──────────────────────
              BulkGroceryEditor(
                items: _groceryItems,
                currency: currency,
                onChanged: (newItems) {
                  setState(() {
                    _groceryItems.clear();
                    _groceryItems.addAll(newItems);
                  });
                  double sum = 0.0;
                  for (final item in newItems) {
                    sum += item.amount;
                  }
                  _amountController.text = sum.toStringAsFixed(sum % 1 == 0 ? 0 : 2);
                },
              ),
              const SizedBox(height: 14),
              _buildTaxSection(context, _getGrocerySubtotal()),
              const SizedBox(height: 18),

              // Collapsible Details Card
              WMGlassSurface.tier2(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    InkWell(
                      onTap: () => setState(() => _showAdditionalDetails = !_showAdditionalDetails),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.tune_rounded, size: 20, color: WalletMeltColors.brandDeep),
                              const SizedBox(width: 8),
                              Text(
                                'Additional Details',
                                style: theme.textTheme.titleMedium?.copyWith(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      ),
                              ),
                            ],
                          ),
                          Icon(
                            _showAdditionalDetails
                                ? Icons.expand_less_rounded
                                : Icons.expand_more_rounded,
                            color: WalletMeltColors.textMuted,
                          ),
                        ],
                      ),
                    ),
                    if (_showAdditionalDetails) ...[
                      const SizedBox(height: 14),
                      TextField(
                        controller: _vendorController,
                        decoration: const InputDecoration(
                          labelText: 'Vendor or store',
                          hintText: 'e.g., Imtiaz, Metro',
                        ),
                      ),
                      const SizedBox(height: 12),
                      WMGlassSurface.tier1(
                        onTap: _pickDate,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_month_rounded, color: WalletMeltColors.brandDeep, size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Date: ${_date.day}/${_date.month}/${_date.year}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded, size: 18, color: WalletMeltColors.textMuted),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _notesController,
                        minLines: 2,
                        maxLines: 4,
                        decoration: const InputDecoration(labelText: 'Notes'),
                      ),
                      const SizedBox(height: 14),
                      const _SectionTitle(title: 'Receipt or bill', actionLabel: null, onAction: null),
                      const SizedBox(height: 8),
                      _ReceiptCard(
                        receiptUri: _receiptUri,
                        onCamera: () => _pickReceipt(fromCamera: true),
                        onGallery: () => _pickReceipt(fromCamera: false),
                        onRemove: () => setState(() => _receiptUri = null),
                      ),
                    ],
                  ],
                ),
              ),
            ] else if (isFuelMode) ...[
              // ── Dedicated Fuel Mode ──────────────────────────────
              FuelEditor(
                initialDraft: _fuelTransactionDraft,
                currency: currency,
                onChanged: (draft) {
                  setState(() {
                    _fuelTransactionDraft = draft;
                  });
                  final sum = draft.totalAmount;
                  _amountController.text = sum > 0
                      ? sum.toStringAsFixed(sum % 1 == 0 ? 0 : 2)
                      : '';
                },
              ),
              const SizedBox(height: 14),
              _buildTaxSection(context, _getFuelSubtotal()),
              const SizedBox(height: 18),

              // Collapsible Details Card
              WMGlassSurface.tier2(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    InkWell(
                      onTap: () => setState(() => _showAdditionalDetails = !_showAdditionalDetails),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.tune_rounded, size: 20, color: WalletMeltColors.brandDeep),
                              const SizedBox(width: 8),
                              Text(
                                'Additional Details',
                                style: theme.textTheme.titleMedium?.copyWith(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                          Icon(
                            _showAdditionalDetails
                                ? Icons.expand_less_rounded
                                : Icons.expand_more_rounded,
                            color: WalletMeltColors.textMuted,
                          ),
                        ],
                      ),
                    ),
                    if (_showAdditionalDetails) ...[
                      const SizedBox(height: 14),
                      TextField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Title',
                          hintText: 'e.g., Shell Station, Monthly Refill',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _vendorController,
                        decoration: const InputDecoration(
                          labelText: 'Station / Vendor',
                          hintText: 'e.g., Total Parco, PSO, Shell',
                        ),
                      ),
                      const SizedBox(height: 12),
                      WMGlassSurface.tier1(
                        onTap: _pickDate,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_month_rounded, color: WalletMeltColors.brandDeep, size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Date: ${_date.day}/${_date.month}/${_date.year}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded, size: 18, color: WalletMeltColors.textMuted),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _notesController,
                        minLines: 2,
                        maxLines: 4,
                        decoration: const InputDecoration(labelText: 'Notes'),
                      ),
                      const SizedBox(height: 14),
                      const _SectionTitle(title: 'Receipt or bill', actionLabel: null, onAction: null),
                      const SizedBox(height: 8),
                      _ReceiptCard(
                        receiptUri: _receiptUri,
                        onCamera: () => _pickReceipt(fromCamera: true),
                        onGallery: () => _pickReceipt(fromCamera: false),
                        onRemove: () => setState(() => _receiptUri = null),
                      ),
                    ],
                  ],
                ),
              ),
            ] else ...[
              // ── Standard Expense Form ────────────────────────────
              WMGlassSurface.tier2(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'AMOUNT',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                            color: WalletMeltColors.textMuted,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDark ? WalletMeltColors.darkBackgroundContainer : const Color(0xFFF1F3F7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            currency,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      autofocus: !isEditing,
                      style: TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        fontFeatures: const [FontFeature.tabularFigures()],
                        color: isDark ? Colors.white : WalletMeltColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                      decoration: InputDecoration(
                        hintText: '0.00',
                        hintStyle: TextStyle(
                          fontFamily: 'PlusJakartaSans',
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          fontFeatures: const [FontFeature.tabularFigures()],
                          color: WalletMeltColors.textMuted.withValues(alpha: 0.4),
                          letterSpacing: -0.5,
                        ),
                        filled: false,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        errorText: _validation?.amountError,
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              WMGlassSurface.tier1(
                onTap: _pickDate,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_month_rounded, color: WalletMeltColors.brand, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Date', style: theme.textTheme.labelMedium?.copyWith(fontSize: 11)),
                          const SizedBox(height: 2),
                          Text(
                            '${_date.day}/${_date.month}/${_date.year}',
                            style: theme.textTheme.titleMedium?.copyWith(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: WalletMeltColors.textMuted,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              if (!_showAdditionalDetails) ...[
                InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => setState(() => _showAdditionalDetails = true),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.tune_rounded, size: 16, color: WalletMeltColors.brand),
                        const SizedBox(width: 8),
                        Text(
                          'Add merchant, notes, tax & receipt',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isDark ? WalletMeltColors.brandSoft : WalletMeltColors.brandDeep,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: WalletMeltColors.brand),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title or bill name (optional)',
                    hintText: 'e.g., Dinner with team, Office supplies',
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _vendorController,
                  decoration: const InputDecoration(
                    labelText: 'Vendor or merchant (optional)',
                    hintText: 'e.g., Amazon, Uber, Local Cafe',
                  ),
                ),
                const SizedBox(height: 14),
                _buildTaxSection(context, double.tryParse(_amountController.text.trim()) ?? 0.0),
                const SizedBox(height: 14),
                TextField(
                  controller: _notesController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'Notes (optional)'),
                ),
                const SizedBox(height: 16),
                const _SectionTitle(
                    title: 'Receipt or bill', actionLabel: null, onAction: null),
                const SizedBox(height: 10),
                _ReceiptCard(
                  receiptUri: _receiptUri,
                  onCamera: () => _pickReceipt(fromCamera: true),
                  onGallery: () => _pickReceipt(fromCamera: false),
                  onRemove: () => setState(() => _receiptUri = null),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.center,
                  child: TextButton.icon(
                    onPressed: () => setState(() => _showAdditionalDetails = false),
                    icon: const Icon(Icons.keyboard_arrow_up_rounded, size: 18),
                    label: const Text('Hide extra details', style: TextStyle(fontSize: 12)),
                  ),
                ),
              ],
            ],
            if (!isGroceryMode && !isFuelMode) ...[
              const SizedBox(height: 24),
              PrimaryButton(
                onPressed: () => _save(state),
                label: isEditing ? 'Save changes' : 'Save expense',
                isLoading: _saving,
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: (isGroceryMode || isFuelMode)
          ? SafeArea(
              child: WMGlassSurface.tier3(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                radius: 24,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isGroceryMode) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildSummaryItem(context, 'Items', '$_totalGroceryItemsCount'),
                          _buildSummaryItem(context, 'Qty', _totalGroceryQty.toStringAsFixed(_totalGroceryQty % 1 == 0 ? 0 : 1)),
                          _buildSummaryItem(context, 'Subtotal', '${_getGrocerySubtotal().toStringAsFixed(_getGrocerySubtotal() % 1 == 0 ? 0 : 2)} $currency'),
                          _buildSummaryItem(context, 'Tax', '${_getTaxAmount().toStringAsFixed(_getTaxAmount() % 1 == 0 ? 0 : 2)} $currency'),
                          _buildSummaryItem(context, 'Total', '${_getGroceryGrandTotal().toStringAsFixed(_getGroceryGrandTotal() % 1 == 0 ? 0 : 2)} $currency', isHighlight: true),
                        ],
                      ),
                    ] else if (isFuelMode) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildSummaryItem(context, 'Types', '$_totalFuelComponentsCount'),
                          _buildSummaryItem(context, 'Litres', '${_totalFuelLitres.toStringAsFixed(_totalFuelLitres % 1 == 0 ? 0 : 2)} L'),
                          _buildSummaryItem(context, 'Subtotal', '${_getFuelSubtotal().toStringAsFixed(_getFuelSubtotal() % 1 == 0 ? 0 : 2)} $currency'),
                          _buildSummaryItem(context, 'Tax', '${_getTaxAmount().toStringAsFixed(_getTaxAmount() % 1 == 0 ? 0 : 2)} $currency'),
                          _buildSummaryItem(context, 'Total', '${_getFuelGrandTotal().toStringAsFixed(_getFuelGrandTotal() % 1 == 0 ? 0 : 2)} $currency', isHighlight: true),
                        ],
                      ),
                    ],
                    const SizedBox(height: 12),
                    PrimaryButton(
                      onPressed: () => _save(state),
                      label: isEditing ? 'Save changes' : 'Save expense',
                      isLoading: _saving,
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  int get _totalGroceryItemsCount {
    return _groceryItems.where((item) => item.name.trim().isNotEmpty).length;
  }

  double get _totalGroceryQty {
    return _groceryItems
        .where((item) => item.name.trim().isNotEmpty)
        .fold(0.0, (sum, item) => sum + (item.quantity ?? 1.0));
  }

  int get _totalFuelComponentsCount {
    return _fuelTransactionDraft?.components.length ?? 0;
  }

  double get _totalFuelLitres {
    return _fuelTransactionDraft?.totalLitres ?? 0.0;
  }

  double _getFuelSubtotal() {
    return _fuelTransactionDraft?.totalAmount ?? double.tryParse(_amountController.text.trim()) ?? 0.0;
  }

  double _getFuelGrandTotal() {
    return _getFuelSubtotal() + _getTaxAmount();
  }

  double _getTaxAmount() {
    return double.tryParse(_taxController.text.trim()) ?? 0.0;
  }

  double _getGroceryGrandTotal() {
    return _getGrocerySubtotal() + _getTaxAmount();
  }

  Widget _buildSummaryItem(BuildContext context, String label, String value, {bool isHighlight = false}) {
    return Column(
      children: [
        Text(
          label.toUpperCase(),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 8,
                letterSpacing: 0.8,
                fontWeight: FontWeight.w700,
                color: WalletMeltColors.textMuted,
              ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: isHighlight ? 13 : 11,
                color: isHighlight ? WalletMeltColors.brandDeep : null,
              ),
        ),
      ],
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      useRootNavigator: true,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(DateTime.now().year + 5),
    );
    if (!mounted || picked == null) return;
    setState(() => _date = picked);
  }

  Future<void> _loadGroceryItems(String expenseId) async {
    final items =
        await context.read<AppState>().groceryItemsForExpense(expenseId);
    if (!mounted) return;
    setState(() {
      _groceryItems
        ..clear()
        ..addAll(items.map(
            (item) => GroceryItemDraft(name: item.name, amount: item.amount)));
    });
  }

  Future<void> _loadFuelTransaction(String expenseId) async {
    final tx =
        await context.read<AppState>().fuelTransactionForExpense(expenseId);
    if (!mounted || tx == null) return;
    setState(() {
      _fuelTransactionDraft = FuelTransactionDraft(
        id: tx.id,
        odometerReading: tx.odometerReading,
        components: tx.components
            .map((c) => FuelComponentDraft(
                  id: c.id,
                  fuelType: c.fuelType,
                  quantityLitres: c.quantityLitres,
                  pricePerLitre: c.pricePerLitre,
                ))
            .toList(),
      );
    });
  }

  Future<void> _pickReceipt({required bool fromCamera}) async {
    final service = context.read<AppState>().receiptStorage;
    final uri = fromCamera
        ? await service.captureWithCamera()
        : await service.pickFromGallery();
    if (!mounted || uri == null) return;
    setState(() => _receiptUri = uri);
  }

  Future<void> _save(AppState state) async {
    final isFuelMode = _categoryId == 'fuel' ||
        state.categoryById(_categoryId ?? '')?.name.toLowerCase() == 'fuel';

    if (isFuelMode &&
        _fuelTransactionDraft != null &&
        _fuelTransactionDraft!.components.isNotEmpty) {
      final fuelSub = _fuelTransactionDraft!.totalAmount;
      _amountController.text =
          fuelSub.toStringAsFixed(fuelSub % 1 == 0 ? 0 : 2);
    }

    final validation = validateExpenseInput(
        amount: _amountController.text, categoryId: _categoryId, date: _date);
    setState(() => _validation = validation);
    if (!validation.isValid) return;

    setState(() => _saving = true);
    final router = GoRouter.of(context);
    final subtotalVal = double.tryParse(_amountController.text.trim()) ?? 0.0;
    final taxVal = _taxController.text.trim().isEmpty ? null : double.tryParse(_taxController.text.trim());
    final totalAmount = subtotalVal + (taxVal ?? 0.0);

    final isGroceryMode = _categoryId == 'grocery';
    final title = _titleController.text.trim().isEmpty
        ? (isGroceryMode
            ? (_vendorController.text.trim().isNotEmpty
                ? 'Groceries at ${_vendorController.text.trim()}'
                : 'Grocery Shopping')
            : (isFuelMode
                ? (_vendorController.text.trim().isNotEmpty
                    ? 'Fuel at ${_vendorController.text.trim()}'
                    : 'Fuel Purchase')
                : state.categoryById(_categoryId!)?.name ?? 'Household expense'))
        : _titleController.text.trim();
    final existing = widget.expenseId == null
        ? null
        : state.expenses
            .where((expense) => expense.id == widget.expenseId)
            .firstOrNull;
    if (existing == null) {
      await state.addExpense(
        ExpenseDraft(
          amount: totalAmount,
          currency: state.settings.currency,
          categoryId: _categoryId!,
          title: title,
          vendor: _vendorController.text,
          date: _date,
          notes: _notesController.text,
          receiptImageUri: _receiptUri,
          groceryItems: _groceryItems,
          fuelTransaction: isFuelMode ? _fuelTransactionDraft : null,
          subtotalAmount: subtotalVal,
          taxAmount: taxVal,
        ),
      );
    } else {
      await state.updateExpense(
        existing.copyWith(
          amount: totalAmount,
          currency: state.settings.currency,
          categoryId: _categoryId!,
          title: title,
          vendor: _vendorController.text,
          date: DateTime(_date.year, _date.month, _date.day).toIso8601String(),
          notes: _notesController.text,
          receiptImageUri: _receiptUri,
          clearReceipt: _receiptUri == null,
          subtotalAmount: subtotalVal,
          taxAmount: taxVal,
        ),
        groceryItems: _groceryItems,
        fuelTransaction: isFuelMode ? _fuelTransactionDraft : null,
      );
    }
    router.go(existing == null ? '/' : '/expense/${existing.id}');
  }

  Future<void> _showAddCategorySheet(BuildContext context) async {
    final nameController = TextEditingController();
    final appState = context.read<AppState>();
    final colors = [
      '#F4B740',
      '#E8805D',
      '#8FD6B5',
      '#7EA6C8',
      '#77C8D4',
      '#A88CC2'
    ];
    var selectedColor = colors.first;
    await showAppBottomSheet<void>(
      context,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Custom category',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 14),
                    TextField(
                        controller: nameController,
                        autofocus: true,
                        decoration: const InputDecoration(labelText: 'Name')),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        for (final color in colors)
                          GestureDetector(
                            onTap: () => setSheetState(() => selectedColor = color),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeOutBack,
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: colorFromHex(color),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: selectedColor == color
                                      ? (Theme.of(context).brightness == Brightness.dark
                                          ? Colors.white
                                          : Colors.black)
                                      : Colors.transparent,
                                  width: 2.5,
                                ),
                                boxShadow: selectedColor == color
                                    ? [
                                        BoxShadow(
                                          color: colorFromHex(color).withValues(alpha: 0.4),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ]
                                    : [],
                              ),
                              child: selectedColor == color
                                  ? Icon(
                                      Icons.check_rounded,
                                      color: Colors.white,
                                      size: 20,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black.withValues(alpha: 0.5),
                                          offset: const Offset(0, 1),
                                          blurRadius: 2,
                                        ),
                                      ],
                                    )
                                  : null,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    PrimaryButton(
                      label: 'Create category',
                      onPressed: () async {
                        if (nameController.text.trim().isEmpty) return;
                        final navigator = Navigator.of(sheetContext);
                        final category = await appState.addCategory(
                            name: nameController.text,
                            icon: 'more_horiz',
                            color: selectedColor);
                        if (!mounted || !sheetContext.mounted) return;
                        setState(() => _categoryId = category.id);
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
  }

  double _getGrocerySubtotal() {
    double sum = 0.0;
    for (final item in _groceryItems) {
      sum += item.amount;
    }
    return sum;
  }

  Widget _buildTaxSection(BuildContext context, double subtotal) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currency = context.read<AppState>().settings.currency;
    final tax = double.tryParse(_taxController.text.trim()) ?? 0.0;
    final grandTotal = subtotal + tax;

    return WMGlassSurface.tier1(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TAX & TOTALS',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                  color: WalletMeltColors.brandDeep,
                ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _taxController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Tax Amount (Total)',
              prefixText: '$currency ',
              helperText: 'Enter the total tax amount directly',
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            onChanged: (val) {
              setState(() {
                _taxPercentageController.clear();
              });
            },
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _taxPercentageController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Calculate via Tax Percentage',
              suffixText: '%',
              helperText: 'Or enter percentage to calculate tax',
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            onChanged: (val) {
              final pct = double.tryParse(val.trim());
              if (pct != null && pct >= 0) {
                final calculatedTax = subtotal * (pct / 100.0);
                setState(() {
                  _taxController.text = calculatedTax.toStringAsFixed(
                    calculatedTax % 1 == 0 ? 0 : 2,
                  );
                });
              } else if (val.trim().isEmpty) {
                setState(() {
                  _taxController.clear();
                });
              }
            },
          ),
          AppSpacing.gapMd,
          Divider(height: 1, color: isDark ? WalletMeltColors.darkBorder : WalletMeltColors.lightBorder),
          AppSpacing.gapSm,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Subtotal:', style: TextStyle(fontSize: 13, color: WalletMeltColors.textSecondary)),
              Text(
                '${subtotal.toStringAsFixed(subtotal % 1 == 0 ? 0 : 2)} $currency',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Tax:', style: TextStyle(fontSize: 13, color: WalletMeltColors.textSecondary)),
              Text(
                '${tax.toStringAsFixed(tax % 1 == 0 ? 0 : 2)} $currency',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: WalletMeltColors.danger),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Grand Total:',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              Text(
                '${grandTotal.toStringAsFixed(grandTotal % 1 == 0 ? 0 : 2)} $currency',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: WalletMeltColors.brandDeep,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(
      {required this.title, required this.actionLabel, required this.onAction});

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
            child: Text(title, style: Theme.of(context).textTheme.titleLarge)),
        if (actionLabel != null)
          TextButton(onPressed: onAction, child: Text(actionLabel!)),
      ],
    );
  }
}

class _ReceiptCard extends StatelessWidget {
  const _ReceiptCard(
      {required this.receiptUri,
      required this.onCamera,
      required this.onGallery,
      required this.onRemove});

  final String? receiptUri;
  final VoidCallback onCamera;
  final VoidCallback onGallery;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final uri = receiptUri;
    return WMGlassSurface.tier2(
      child: uri == null
          ? Row(
              children: [
                Expanded(
                    child: OutlinedButton.icon(
                        onPressed: onCamera,
                        icon: const Icon(Icons.photo_camera_rounded),
                        label: const Text('Camera'))),
                const SizedBox(width: 10),
                Expanded(
                    child: OutlinedButton.icon(
                        onPressed: onGallery,
                        icon: const Icon(Icons.photo_library_rounded),
                        label: const Text('Gallery'))),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.file(File(Uri.parse(uri).toFilePath()),
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover, errorBuilder: (_, __, ___) {
                    return Container(
                      height: 150,
                      alignment: Alignment.center,
                      color: Colors.black.withValues(alpha: 0.08),
                      child: const Text('Receipt file is unavailable'),
                    );
                  }),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    TextButton.icon(
                        onPressed: onCamera,
                        icon: const Icon(Icons.sync_rounded),
                        label: const Text('Replace')),
                    const Spacer(),
                    TextButton.icon(
                        onPressed: onRemove,
                        icon: const Icon(Icons.delete_outline_rounded),
                        label: const Text('Remove')),
                  ],
                ),
              ],
            ),
    );
  }
}

class BulkGroceryEditor extends StatefulWidget {
  const BulkGroceryEditor({
    super.key,
    required this.items,
    required this.currency,
    required this.onChanged,
  });

  final List<GroceryItemDraft> items;
  final String currency;
  final ValueChanged<List<GroceryItemDraft>> onChanged;

  @override
  State<BulkGroceryEditor> createState() => _BulkGroceryEditorState();
}

class _BulkGroceryRowData {
  _BulkGroceryRowData({
    required this.nameController,
    required this.qtyController,
    required this.priceController,
    required this.nameFocusNode,
    required this.qtyFocusNode,
    required this.priceFocusNode,
  });

  final TextEditingController nameController;
  final TextEditingController qtyController;
  final TextEditingController priceController;
  final FocusNode nameFocusNode;
  final FocusNode qtyFocusNode;
  final FocusNode priceFocusNode;
}

class _BulkGroceryEditorState extends State<BulkGroceryEditor> {
  final List<_BulkGroceryRowData> _rows = [];

  @override
  void initState() {
    super.initState();
    if (widget.items.isEmpty) {
      _addRow();
    } else {
      for (final item in widget.items) {
        _addRowFromItem(item);
      }
    }
  }

  void _addRow() {
    _rows.add(
      _BulkGroceryRowData(
        nameController: TextEditingController(),
        qtyController: TextEditingController(text: '1'),
        priceController: TextEditingController(),
        nameFocusNode: FocusNode(),
        qtyFocusNode: FocusNode(),
        priceFocusNode: FocusNode(),
      ),
    );
  }

  void _addRowFromItem(GroceryItemDraft item) {
    final qtyStr = item.quantity?.toStringAsFixed(item.quantity! % 1 == 0 ? 0 : 2) ?? '1';
    final priceStr = item.unitPrice != null
        ? item.unitPrice!.toStringAsFixed(item.unitPrice! % 1 == 0 ? 0 : 2)
        : '';
    _rows.add(
      _BulkGroceryRowData(
        nameController: TextEditingController(text: item.name),
        qtyController: TextEditingController(text: qtyStr),
        priceController: TextEditingController(text: priceStr),
        nameFocusNode: FocusNode(),
        qtyFocusNode: FocusNode(),
        priceFocusNode: FocusNode(),
      ),
    );
  }

  void _removeRow(int index) {
    setState(() {
      final row = _rows.removeAt(index);
      row.nameController.dispose();
      row.qtyController.dispose();
      row.priceController.dispose();
      row.nameFocusNode.dispose();
      row.qtyFocusNode.dispose();
      row.priceFocusNode.dispose();
      if (_rows.isEmpty) {
        _addRow();
      }
    });
    _notifyChanges();
  }

  void _notifyChanges() {
    final drafts = <GroceryItemDraft>[];
    for (final row in _rows) {
      final name = row.nameController.text.trim();
      final qty = double.tryParse(row.qtyController.text.trim()) ?? 1.0;
      final price = double.tryParse(row.priceController.text.trim()) ?? 0.0;
      final total = qty * price;
      if (name.isNotEmpty) {
        drafts.add(
          GroceryItemDraft(
            name: name,
            amount: total,
            quantity: qty,
            unitPrice: price,
          ),
        );
      }
    }
    widget.onChanged(drafts);
  }

  @override
  void dispose() {
    for (final row in _rows) {
      row.nameController.dispose();
      row.qtyController.dispose();
      row.priceController.dispose();
      row.nameFocusNode.dispose();
      row.qtyFocusNode.dispose();
      row.priceFocusNode.dispose();
    }
    super.dispose();
  }

  Future<void> _saveAsTemplate() async {
    final names = _rows
        .map((r) => r.nameController.text.trim())
        .where((name) => name.isNotEmpty)
        .toList();
    if (names.isEmpty) {
      showErrorSnackbar(context, 'Cannot save empty list as template');
      return;
    }

    final nameController = TextEditingController();
    final state = context.read<AppState>();
    final result = await showDialog<String>(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => AlertDialog(
        title: const Text('Save Shopping Template'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Template Name',
            hintText: 'e.g., Weekly Essentials',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, nameController.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      await state.saveGroceryTemplate(result, names);
      if (mounted) {
        showSuccessSnackbar(context, 'Template "$result" saved successfully');
      }
    }
    nameController.dispose();
  }

  Future<void> _loadTemplate() async {
    final state = context.read<AppState>();
    if (state.groceryTemplates.isEmpty) {
      showDialog(
        context: context,
        useRootNavigator: true,
        builder: (ctx) => AlertDialog(
          title: const Text('No Templates'),
          content: const Text('You haven\'t saved any shopping list templates yet. Add items and tap "Save as Template" to create one.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    final selected = await showDialog<GroceryTemplate>(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => AlertDialog(
        title: const Text('Load Grocery Template'),
        content: SizedBox(
          width: 450,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: state.groceryTemplates.length,
            itemBuilder: (context, idx) {
              final t = state.groceryTemplates[idx];
              return ListTile(
                title: Text(t.name),
                subtitle: Text('${t.items.length} items'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Update/Save Button
                    IconButton(
                      icon: const Icon(Icons.save_rounded, size: 20, color: WalletMeltColors.positive),
                      tooltip: 'Overwrite template',
                      onPressed: () async {
                        final names = _rows
                            .map((r) => r.nameController.text.trim())
                            .where((name) => name.isNotEmpty)
                            .toList();
                        if (names.isEmpty) {
                          if (ctx.mounted) {
                            showErrorSnackbar(ctx, 'Cannot update with an empty list');
                          }
                          return;
                        }
                        final updated = t.copyWith(items: names);
                        await state.updateGroceryTemplate(updated);
                        if (ctx.mounted) {
                          showSuccessSnackbar(ctx, 'Template "${t.name}" updated successfully');
                        }
                      },
                    ),
                    // Rename Button
                    IconButton(
                      icon: const Icon(Icons.edit_rounded, size: 20, color: WalletMeltColors.brandDeep),
                      tooltip: 'Rename template',
                      onPressed: () async {
                        final renameController = TextEditingController(text: t.name);
                        final newName = await showDialog<String>(
                          context: context,
                          useRootNavigator: true,
                          builder: (renameCtx) => AlertDialog(
                            title: const Text('Rename Template'),
                            content: TextField(
                              controller: renameController,
                              autofocus: true,
                              decoration: const InputDecoration(labelText: 'New Name'),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(renameCtx),
                                child: const Text('Cancel'),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.pop(renameCtx, renameController.text.trim()),
                                child: const Text('Rename'),
                              ),
                            ],
                          ),
                        );
                        renameController.dispose();
                        if (newName != null && newName.isNotEmpty) {
                          final updated = t.copyWith(name: newName);
                          await state.updateGroceryTemplate(updated);
                          if (ctx.mounted) {
                            Navigator.pop(ctx); // Close list
                            _loadTemplate(); // Re-open list to show changes
                          }
                        }
                      },
                    ),
                    // Delete Button
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 20, color: WalletMeltColors.danger),
                      tooltip: 'Delete template',
                      onPressed: () async {
                        await state.deleteGroceryTemplate(t.id);
                        if (ctx.mounted) {
                          Navigator.pop(ctx); // Close list
                          _loadTemplate(); // Re-open list to show changes
                        }
                      },
                    ),
                  ],
                ),
                onTap: () => Navigator.pop(ctx, t),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (selected != null) {
      setState(() {
        // Clean old rows
        for (final row in _rows) {
          row.nameController.dispose();
          row.qtyController.dispose();
          row.priceController.dispose();
          row.nameFocusNode.dispose();
          row.qtyFocusNode.dispose();
          row.priceFocusNode.dispose();
        }
        _rows.clear();

        for (final itemName in selected.items) {
          _rows.add(
            _BulkGroceryRowData(
              nameController: TextEditingController(text: itemName),
              qtyController: TextEditingController(text: '1'),
              priceController: TextEditingController(),
              nameFocusNode: FocusNode(),
              qtyFocusNode: FocusNode(),
              priceFocusNode: FocusNode(),
            ),
          );
        }
        if (_rows.isEmpty) {
          _addRow();
        }
      });
      _notifyChanges();
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth > 700;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Quick Grocery Entry',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.save_as_rounded, size: 20),
                      tooltip: 'Save as Template',
                      onPressed: _saveAsTemplate,
                    ),
                    IconButton(
                      icon: const Icon(Icons.folder_open_rounded, size: 20),
                      tooltip: 'Load/Manage Templates',
                      onPressed: _loadTemplate,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),

            if (isTablet)
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 0,
                  mainAxisExtent: 175,
                ),
                itemCount: _rows.length,
                itemBuilder: (context, idx) => _buildMobileCard(idx, _rows[idx]),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _rows.length,
                itemBuilder: (context, idx) => _buildMobileCard(idx, _rows[idx]),
              ),

            const SizedBox(height: 12),
            Center(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(160, 44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add Item'),
                onPressed: () {
                  setState(() {
                    _addRow();
                  });
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _rows.last.nameFocusNode.requestFocus();
                  });
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMobileCard(int idx, _BulkGroceryRowData row) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final qty = double.tryParse(row.qtyController.text.trim()) ?? 1.0;
    final price = double.tryParse(row.priceController.text.trim()) ?? 0.0;
    final total = qty * price;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: WMGlassSurface.tier1(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ITEM #${idx + 1}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: WalletMeltColors.brandDeep.withValues(alpha: 0.8),
                    letterSpacing: 1.0,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, size: 18, color: WalletMeltColors.danger),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Delete item',
                  onPressed: () => _removeRow(idx),
                ),
              ],
            ),
            const SizedBox(height: 4),

            TextField(
              controller: row.nameController,
              focusNode: row.nameFocusNode,
              decoration: const InputDecoration(
                labelText: 'Item Name',
                hintText: 'e.g., Milk, Eggs',
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              onSubmitted: (_) {
                row.qtyFocusNode.requestFocus();
              },
              onChanged: (_) => _notifyChanges(),
            ),
            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: row.qtyController,
                    focusNode: row.qtyFocusNode,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Qty',
                      hintText: '1',
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    ),
                    onSubmitted: (_) {
                      row.priceFocusNode.requestFocus();
                    },
                    onChanged: (_) {
                      setState(() {});
                      _notifyChanges();
                    },
                  ),
                ),
                const SizedBox(width: 8),

                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: row.priceController,
                    focusNode: row.priceFocusNode,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Price',
                      hintText: '0',
                      prefixText: '${widget.currency} ',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    ),
                    onSubmitted: (_) {
                      final isLast = idx == _rows.length - 1;
                      if (isLast) {
                        setState(() {
                          _addRow();
                        });
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          _rows.last.nameFocusNode.requestFocus();
                        });
                      } else {
                        _rows[idx + 1].nameFocusNode.requestFocus();
                      }
                      _notifyChanges();
                    },
                    onChanged: (_) {
                      setState(() {});
                      _notifyChanges();
                    },
                  ),
                ),
                const SizedBox(width: 8),

                Expanded(
                  flex: 3,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    height: 48,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0x0Affffff) : const Color(0x0A000000),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? WalletMeltColors.darkBorder : WalletMeltColors.lightBorder,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'TOTAL',
                          style: TextStyle(fontSize: 8, color: WalletMeltColors.textMuted, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 1),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            total > 0 ? '${total.toStringAsFixed(total % 1 == 0 ? 0 : 2)} ${widget.currency}' : '0',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: WalletMeltColors.brandDeep),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
