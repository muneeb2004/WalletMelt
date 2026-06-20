import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../components/category/category_chip.dart';
import '../../components/glass/app_background.dart';
import '../../data/repositories/expense_repository.dart';
import '../../state/app_state.dart';
import '../../theme/wallet_melt_theme.dart';
import '../../utils/expense_validation.dart';
import '../../widgets/primary_button.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key, this.expenseId});

  final String? expenseId;

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _amountController = TextEditingController();
  final _titleController = TextEditingController();
  final _vendorController = TextEditingController();
  final _notesController = TextEditingController();
  final _groceryNameController = TextEditingController();
  final _groceryAmountController = TextEditingController();
  final List<GroceryItemDraft> _groceryItems = [];

  String? _categoryId;
  DateTime _date = DateTime.now();
  String? _receiptUri;
  ExpenseValidationResult? _validation;
  bool _saving = false;
  bool _hydrated = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hydrated || widget.expenseId == null) return;
    final state = context.read<AppState>();
    final expense = state.expenses
        .where((expense) => expense.id == widget.expenseId)
        .firstOrNull;
    if (expense != null) {
      _amountController.text =
          expense.amount.toStringAsFixed(expense.amount % 1 == 0 ? 0 : 2);
      _titleController.text = expense.title;
      _vendorController.text = expense.vendor ?? '';
      _notesController.text = expense.notes ?? '';
      _categoryId = expense.categoryId;
      _date = DateTime.parse(expense.date);
      _receiptUri = expense.receiptImageUri;
      _loadGroceryItems(expense.id);
    }
    _hydrated = true;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _titleController.dispose();
    _vendorController.dispose();
    _notesController.dispose();
    _groceryNameController.dispose();
    _groceryAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isEditing = widget.expenseId != null;
    final selectedCategory =
        _categoryId == null ? null : state.categoryById(_categoryId!);
    return Scaffold(
      body: AppBackground(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
        child: ListView(
          children: [
            Row(
              children: [
                IconButton(
                    tooltip: 'Close',
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.close_rounded)),
                const SizedBox(width: 8),
                Text(isEditing ? 'Edit expense' : 'Add expense',
                    style: Theme.of(context).textTheme.headlineMedium),
              ],
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: Theme.of(context).textTheme.displaySmall,
              decoration: InputDecoration(
                labelText: 'Amount',
                prefixText: '${state.settings.currency} ',
                errorText: _validation?.amountError,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
                controller: _titleController,
                decoration:
                    const InputDecoration(labelText: 'Title or bill name')),
            const SizedBox(height: 14),
            TextField(
                controller: _vendorController,
                decoration:
                    const InputDecoration(labelText: 'Vendor or provider')),
            const SizedBox(height: 18),
            _SectionTitle(
                title: 'Category',
                actionLabel: 'New',
                onAction: () => _showAddCategorySheet(context)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final category in state.categories)
                  WalletCategoryChip(
                    category: category,
                    selected: category.id == _categoryId,
                    onTap: () => setState(() => _categoryId = category.id),
                  ),
              ],
            ),
            if (_validation?.categoryError != null)
              Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(_validation!.categoryError!,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.error))),
            const SizedBox(height: 18),
            LiquidGlass(
              onTap: _pickDate,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              child: Row(
                children: [
                  const Icon(Icons.calendar_month_rounded, color: WalletMeltColors.brandDeep),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Date', style: Theme.of(context).textTheme.labelMedium?.copyWith(fontSize: 11)),
                        const SizedBox(height: 2),
                        Text(
                          '${_date.day}/${_date.month}/${_date.year}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.54),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            TextField(
                controller: _notesController,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Notes')),
            const SizedBox(height: 18),
            const _SectionTitle(
                title: 'Receipt or bill', actionLabel: null, onAction: null),
            const SizedBox(height: 10),
            _ReceiptCard(
              receiptUri: _receiptUri,
              onCamera: () => _pickReceipt(fromCamera: true),
              onGallery: () => _pickReceipt(fromCamera: false),
              onRemove: () => setState(() => _receiptUri = null),
            ),
            if (selectedCategory?.id == 'grocery') ...[
              const SizedBox(height: 18),
              _GroceryItemsEditor(
                items: _groceryItems,
                nameController: _groceryNameController,
                amountController: _groceryAmountController,
                onAdd: _addGroceryItem,
                onRemove: (index) =>
                    setState(() => _groceryItems.removeAt(index)),
              ),
            ],
            const SizedBox(height: 24),
            PrimaryButton(
              onPressed: () => _save(state),
              label: isEditing ? 'Save changes' : 'Save expense',
              isLoading: _saving,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
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

  Future<void> _pickReceipt({required bool fromCamera}) async {
    final service = context.read<AppState>().receiptStorage;
    final uri = fromCamera
        ? await service.captureWithCamera()
        : await service.pickFromGallery();
    if (!mounted || uri == null) return;
    setState(() => _receiptUri = uri);
  }

  void _addGroceryItem() {
    final amount = double.tryParse(_groceryAmountController.text.trim());
    final name = _groceryNameController.text.trim();
    if (name.isEmpty || amount == null || amount <= 0) return;
    setState(() {
      _groceryItems.add(GroceryItemDraft(name: name, amount: amount));
      _groceryNameController.clear();
      _groceryAmountController.clear();
    });
  }

  Future<void> _save(AppState state) async {
    final validation = validateExpenseInput(
        amount: _amountController.text, categoryId: _categoryId, date: _date);
    setState(() => _validation = validation);
    if (!validation.isValid) return;

    setState(() => _saving = true);
    final router = GoRouter.of(context);
    final amount = double.parse(_amountController.text.trim());
    final title = _titleController.text.trim().isEmpty
        ? state.categoryById(_categoryId!)?.name ?? 'Household expense'
        : _titleController.text.trim();
    final existing = widget.expenseId == null
        ? null
        : state.expenses
            .where((expense) => expense.id == widget.expenseId)
            .firstOrNull;
    if (existing == null) {
      await state.addExpense(
        ExpenseDraft(
          amount: amount,
          currency: state.settings.currency,
          categoryId: _categoryId!,
          title: title,
          vendor: _vendorController.text,
          date: _date,
          notes: _notesController.text,
          receiptImageUri: _receiptUri,
          groceryItems: _groceryItems,
        ),
      );
    } else {
      await state.updateExpense(
        existing.copyWith(
          amount: amount,
          currency: state.settings.currency,
          categoryId: _categoryId!,
          title: title,
          vendor: _vendorController.text,
          date: DateTime(_date.year, _date.month, _date.day).toIso8601String(),
          notes: _notesController.text,
          receiptImageUri: _receiptUri,
          clearReceipt: _receiptUri == null,
        ),
        groceryItems: _groceryItems,
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
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                    20, 10, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
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
    return LiquidGlass(
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
                    const Expanded(child: SizedBox.shrink()),
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

class _GroceryItemsEditor extends StatelessWidget {
  const _GroceryItemsEditor({
    required this.items,
    required this.nameController,
    required this.amountController,
    required this.onAdd,
    required this.onRemove,
  });

  final List<GroceryItemDraft> items;
  final TextEditingController nameController;
  final TextEditingController amountController;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    return LiquidGlass(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Grocery items', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                  flex: 2,
                  child: TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Item'))),
              const SizedBox(width: 8),
              Expanded(
                  child: TextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(),
                      decoration: const InputDecoration(labelText: 'Amount'))),
              IconButton(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add_circle_rounded),
                  tooltip: 'Add grocery item'),
            ],
          ),
          for (var i = 0; i < items.length; i++)
            Material(
              type: MaterialType.transparency,
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(items[i].name),
                trailing: IconButton(
                    onPressed: () => onRemove(i),
                    icon: const Icon(Icons.close_rounded),
                    tooltip: 'Remove item'),
              ),
            ),
        ],
      ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
