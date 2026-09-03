import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../components/glass/app_background.dart';
import '../../state/app_state.dart';
import '../../theme/wallet_melt_theme.dart';
import '../../types/essential_expense.dart';
import '../../types/fuel.dart';
import '../../utils/currency_format.dart';
import '../../utils/date_utils.dart';
import '../../utils/number_parser.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/primary_button.dart';
import '../../components/category/category_icon.dart';

class EssentialExpensesScreen extends StatefulWidget {
  final bool isEmbedded;
  const EssentialExpensesScreen({this.isEmbedded = false, super.key});

  static void showAddEssentialSheet(BuildContext context, {EssentialExpenseTemplate? existing}) {
    showAppBottomSheet<void>(
      context,
      builder: (sheetContext) => _AddEditEssentialSheet(existing: existing),
    );
  }

  @override
  State<EssentialExpensesScreen> createState() => _EssentialExpensesScreenState();
}

class _EssentialExpensesScreenState extends State<EssentialExpensesScreen> {
  bool _showInactive = false;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final currency = state.settings.currency;
    final templates = state.essentialTemplates;
    final activeTemplates = templates.where((t) => t.isActive && !t.isDeleted).toList();
    final inactiveTemplates = templates.where((t) => !t.isActive && !t.isDeleted).toList();

    final summary = state.getMonthlyEssentialSummary(state.selectedMonth);
    final expectedTotal = summary['expected'] ?? 0.0;
    final actualTotal = summary['actual'] ?? 0.0;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!widget.isEmbedded) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Essential Expenses',
                    style: Theme.of(context).textTheme.headlineMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  tooltip: 'Add Essential',
                  onPressed: () => EssentialExpensesScreen.showAddEssentialSheet(context),
                  icon: Icon(
                    Icons.add_rounded,
                    size: 28,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ],

        // ── Monthly Essentials Overview Card ────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: WMGlassSurface.tier2(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.account_balance_wallet_rounded,
                        size: 18, color: WalletMeltColors.brand),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'MONTHLY ESSENTIALS (${readableMonth(state.selectedMonth)})',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: WalletMeltColors.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Expected / Budget',
                            style: TextStyle(fontSize: 12, color: WalletMeltColors.textMuted),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            formatMoney(expectedTotal, currency),
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(width: 1, height: 36, color: WalletMeltColors.textMuted.withValues(alpha: 0.2)),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Actual Spent',
                              style: TextStyle(fontSize: 12, color: WalletMeltColors.textMuted),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              formatMoney(actualTotal, currency),
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: actualTotal > expectedTotal && expectedTotal > 0
                                    ? WalletMeltColors.warning
                                    : WalletMeltColors.brand,
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
        ),

        // ── Active Recurring Essentials List ─────────────────────────
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
            children: [
              if (activeTemplates.isEmpty && inactiveTemplates.isEmpty) ...[
                const SizedBox(height: 32),
                Center(
                  child: Column(
                    children: [
                      Icon(Icons.checklist_rtl_rounded,
                          size: 54, color: WalletMeltColors.textMuted.withValues(alpha: 0.5)),
                      const SizedBox(height: 12),
                      const Text(
                        'No recurring essentials added yet',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 6),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          'Track recurring essentials like Rent, Fuel, Electricity, and Internet with clear estimates vs actual spending.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: WalletMeltColors.textMuted),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => EssentialExpensesScreen.showAddEssentialSheet(context),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Add First Essential'),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                for (final template in activeTemplates)
                  _EssentialTemplateTile(
                    template: template,
                    currency: currency,
                    onRecord: () => _recordExpenseForTemplate(context, template, state),
                    onEdit: () => EssentialExpensesScreen.showAddEssentialSheet(context, existing: template),
                    onToggleActive: () => state.toggleEssentialTemplateActive(template.id, false),
                    onDelete: () => _confirmDelete(context, state, template),
                  ),

                if (inactiveTemplates.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => setState(() => _showInactive = !_showInactive),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                      child: Row(
                        children: [
                          Icon(
                            _showInactive ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                            size: 20,
                            color: WalletMeltColors.textMuted,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Paused Essentials (${inactiveTemplates.length})',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: WalletMeltColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_showInactive) ...[
                    const SizedBox(height: 8),
                    for (final template in inactiveTemplates)
                      Opacity(
                        opacity: 0.65,
                        child: _EssentialTemplateTile(
                          template: template,
                          currency: currency,
                          onRecord: () => _recordExpenseForTemplate(context, template, state),
                          onEdit: () => EssentialExpensesScreen.showAddEssentialSheet(context, existing: template),
                          onToggleActive: () => state.toggleEssentialTemplateActive(template.id, true),
                          onDelete: () => _confirmDelete(context, state, template),
                        ),
                      ),
                  ],
                ],
              ],
            ],
          ),
        ),
      ],
    );

    if (widget.isEmbedded) {
      return content;
    }

    return Scaffold(
      body: AppBackground(child: content),
    );
  }

  void _recordExpenseForTemplate(
      BuildContext context, EssentialExpenseTemplate template, AppState state) {
    context.push('/expense/new?categoryId=${template.categoryId}');
  }

  Future<void> _confirmDelete(
      BuildContext context, AppState state, EssentialExpenseTemplate template) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete "${template.name}"?',
      body: 'This removes the recurring estimate template. Existing historical transactions will remain untouched.',
      confirmLabel: 'Delete',
      isDestructive: true,
    );
    if (confirmed == true) {
      await state.deleteEssentialTemplate(template.id);
      if (!context.mounted) return;
      showSuccessSnackbar(context, '${template.name} removed');
    }
  }
}

class _EssentialTemplateTile extends StatelessWidget {
  const _EssentialTemplateTile({
    required this.template,
    required this.currency,
    required this.onRecord,
    required this.onEdit,
    required this.onToggleActive,
    required this.onDelete,
  });

  final EssentialExpenseTemplate template;
  final String currency;
  final VoidCallback onRecord;
  final VoidCallback onEdit;
  final VoidCallback onToggleActive;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final category = state.categoryById(template.categoryId);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: WMGlassSurface.tier2(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Category Icon Avatar
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: category != null
                        ? parseHexColor(category.color).withValues(alpha: 0.16)
                        : WalletMeltColors.brand.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: CategoryIcon(
                      icon: template.isFuel ? 'fuel' : category?.icon,
                      size: 20,
                      color: category != null
                          ? parseHexColor(category.color)
                          : WalletMeltColors.brand,
                      defaultIcon: template.isFuel
                          ? Icons.local_gas_station_rounded
                          : Icons.category_rounded,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        template.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            category?.name ?? 'Essential',
                            style: const TextStyle(fontSize: 12, color: WalletMeltColors.textSecondary),
                          ),
                          if (template.expectedDay != null) ...[
                            const Text(' • ', style: TextStyle(color: WalletMeltColors.textMuted)),
                            Text(
                              'Due: ${_formatDay(template.expectedDay!)}',
                              style: const TextStyle(fontSize: 11, color: WalletMeltColors.textMuted),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${template.isFuel ? '~' : ''}${formatMoney(template.computedExpectedAmount, currency)}',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                    ),
                    Text(
                      '/${template.frequency}',
                      style: const TextStyle(fontSize: 11, color: WalletMeltColors.textMuted),
                    ),
                  ],
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded, size: 20, color: WalletMeltColors.textMuted),
                  padding: EdgeInsets.zero,
                  onSelected: (val) {
                    if (val == 'record') onRecord();
                    if (val == 'edit') onEdit();
                    if (val == 'toggle') onToggleActive();
                    if (val == 'delete') onDelete();
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'record', child: Text('Record expense')),
                    const PopupMenuItem(value: 'edit', child: Text('Edit template')),
                    PopupMenuItem(
                      value: 'toggle',
                      child: Text(template.isActive ? 'Pause' : 'Activate'),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete', style: TextStyle(color: WalletMeltColors.danger)),
                    ),
                  ],
                ),
              ],
            ),

            // If Fuel: Show multi-fuel expected composition
            if (template.isFuel && template.fuelComponents.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final comp in template.fuelComponents)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: WalletMeltColors.brand.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${comp.expectedLitres.toStringAsFixed(comp.expectedLitres % 1 == 0 ? 0 : 1)}L ${comp.fuelType.displayName} @ ${formatMoney(comp.expectedPricePerLitre, currency)}/L',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: WalletMeltColors.brand,
                        ),
                      ),
                    ),
                ],
              ),
            ],

            if (template.notes != null && template.notes!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                template.notes!,
                style: const TextStyle(fontSize: 11, color: WalletMeltColors.textMuted, fontStyle: FontStyle.italic),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDay(int day) {
    if (day >= 11 && day <= 13) return '${day}th';
    return switch (day % 10) {
      1 => '${day}st',
      2 => '${day}nd',
      3 => '${day}rd',
      _ => '${day}th',
    };
  }
}


class _AddEditEssentialSheet extends StatefulWidget {
  final EssentialExpenseTemplate? existing;
  const _AddEditEssentialSheet({this.existing});

  @override
  State<_AddEditEssentialSheet> createState() => _AddEditEssentialSheetState();
}

class _AddEditEssentialSheetState extends State<_AddEditEssentialSheet> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _dayController = TextEditingController();
  final _notesController = TextEditingController();

  String _categoryId = 'electricity';
  String _frequency = 'monthly';
  bool _isFuel = false;
  bool _isActive = true;

  // Multi-fuel expected rows for fuel template
  final List<FuelTemplateComponent> _fuelComponents = [];

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      final t = widget.existing!;
      _nameController.text = t.name;
      _amountController.text = t.expectedAmount > 0
          ? t.expectedAmount.toStringAsFixed(t.expectedAmount % 1 == 0 ? 0 : 2)
          : '';
      _dayController.text = t.expectedDay?.toString() ?? '';
      _notesController.text = t.notes ?? '';
      _categoryId = t.categoryId;
      _frequency = t.frequency;
      _isFuel = t.isFuel;
      _isActive = t.isActive;
      _fuelComponents.addAll(t.fuelComponents);
    } else {
      // Default initial fuel component if fuel is selected
      _fuelComponents.add(
        const FuelTemplateComponent(
          id: '',
          templateId: '',
          fuelType: FuelType.regular,
          expectedLitres: 60.0,
          expectedPricePerLitre: 265.0,
          createdAt: '',
        ),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _dayController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double get _computedFuelTotal {
    return roundToTwoDecimals(
        _fuelComponents.fold(0.0, (sum, c) => sum + c.estimatedAmount));
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final currency = state.settings.currency;
    final isEditing = widget.existing != null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isEditing ? 'Edit Essential Template' : 'Add Essential Expense',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),

            // Name
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Name',
                hintText: _isFuel ? 'e.g. Monthly Fuel' : 'e.g. Electricity Bill, Home Rent',
              ),
            ),
            const SizedBox(height: 14),

            // Category Selector
            DropdownButtonFormField<String>(
              initialValue: state.categories.any((c) => c.id == _categoryId)
                  ? _categoryId
                  : state.categories.firstOrNull?.id,
              decoration: const InputDecoration(labelText: 'Category'),
              items: state.categories.map((c) {
                return DropdownMenuItem<String>(
                  value: c.id,
                  child: Text(c.name),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _categoryId = val;
                    if (val == 'fuel') {
                      _isFuel = true;
                      if (_nameController.text.trim().isEmpty) {
                        _nameController.text = 'Monthly Fuel';
                      }
                    } else {
                      _isFuel = false;
                    }
                  });
                }
              },
            ),
            const SizedBox(height: 14),

            // Frequency
            DropdownButtonFormField<String>(
              initialValue: _frequency,
              decoration: const InputDecoration(labelText: 'Frequency'),
              items: const [
                DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                DropdownMenuItem(value: 'quarterly', child: Text('Quarterly')),
                DropdownMenuItem(value: 'yearly', child: Text('Yearly')),
              ],
              onChanged: (val) => setState(() => _frequency = val ?? 'monthly'),
            ),
            const SizedBox(height: 14),

            // Expected Day of Month (1-31)
            TextField(
              controller: _dayController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Expected Due Day of Month (1–31)',
                hintText: 'e.g. 15',
              ),
            ),
            const SizedBox(height: 14),

            // Fuel specific configuration vs Standard Amount
            if (_isFuel) ...[
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'EXPECTED FUEL BREAKDOWN',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: WalletMeltColors.textMuted,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _fuelComponents.add(
                          const FuelTemplateComponent(
                            id: '',
                            templateId: '',
                            fuelType: FuelType.premium,
                            expectedLitres: 20.0,
                            expectedPricePerLitre: 290.0,
                            createdAt: '',
                          ),
                        );
                      });
                    },
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: const Text('Add Type', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              for (int i = 0; i < _fuelComponents.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: WMGlassSurface.tier1(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            DropdownButton<FuelType>(
                              value: _fuelComponents[i].fuelType,
                              isDense: true,
                              underline: const SizedBox.shrink(),
                              items: FuelType.values.map((ft) {
                                return DropdownMenuItem(
                                  value: ft,
                                  child: Text(ft.displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                );
                              }).toList(),
                              onChanged: (newType) {
                                if (newType != null) {
                                  setState(() {
                                    _fuelComponents[i] = _fuelComponents[i].copyWith(fuelType: newType);
                                  });
                                }
                              },
                            ),
                            const Spacer(),
                            Text(
                              formatMoney(_fuelComponents[i].estimatedAmount, currency),
                              style: const TextStyle(fontWeight: FontWeight.bold, color: WalletMeltColors.brand),
                            ),
                            if (_fuelComponents.length > 1) ...[
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.close_rounded, size: 16),
                                onPressed: () => setState(() => _fuelComponents.removeAt(i)),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                initialValue: _fuelComponents[i].expectedLitres > 0
                                    ? _fuelComponents[i].expectedLitres.toString()
                                    : '',
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: const InputDecoration(
                                  labelText: 'Expected Litres',
                                  isDense: true,
                                  suffixText: 'L',
                                ),
                                onChanged: (val) {
                                  final l = parseTolerantNumber(val) ?? 0.0;
                                  setState(() {
                                    _fuelComponents[i] = _fuelComponents[i].copyWith(expectedLitres: l);
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextFormField(
                                initialValue: _fuelComponents[i].expectedPricePerLitre > 0
                                    ? _fuelComponents[i].expectedPricePerLitre.toString()
                                    : '',
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: InputDecoration(
                                  labelText: 'Expected Price',
                                  isDense: true,
                                  suffixText: currency,
                                ),
                                onChanged: (val) {
                                  final p = parseTolerantNumber(val) ?? 0.0;
                                  setState(() {
                                    _fuelComponents[i] = _fuelComponents[i].copyWith(expectedPricePerLitre: p);
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

              WMGlassSurface.tier2(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Estimated Total / Month', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    Text(
                      formatMoney(_computedFuelTotal, currency),
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: WalletMeltColors.brand),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ] else ...[
              // Standard Amount Field
              TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Expected Amount ($currency)',
                  hintText: 'e.g. 50000',
                ),
              ),
              const SizedBox(height: 14),
            ],

            // Notes
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (Optional)',
                hintText: 'Consumer number, meter ID, or details...',
              ),
            ),
            const SizedBox(height: 20),

            PrimaryButton(
              onPressed: _save,
              label: isEditing ? 'Save Changes' : 'Create Essential Template',
            ),
          ],
        ),
      ),
    );
  }

  void _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      showErrorSnackbar(context, 'Please enter a name for this essential');
      return;
    }

    final double expectedAmt = _isFuel
        ? _computedFuelTotal
        : (parseTolerantNumber(_amountController.text) ?? 0.0);

    if (expectedAmt <= 0 && !_isFuel) {
      showErrorSnackbar(context, 'Please enter a valid expected amount');
      return;
    }

    final day = int.tryParse(_dayController.text.trim());
    if (day != null && (day < 1 || day > 31)) {
      showErrorSnackbar(context, 'Due day must be between 1 and 31');
      return;
    }

    final now = DateTime.now().toIso8601String();
    final templateId = widget.existing?.id ?? const Uuid().v4();

    final template = EssentialExpenseTemplate(
      id: templateId,
      name: name,
      categoryId: _categoryId,
      frequency: _frequency,
      expectedAmount: expectedAmt,
      expectedDay: day,
      isActive: _isActive,
      isFuel: _isFuel,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      createdAt: widget.existing?.createdAt ?? now,
      updatedAt: now,
      fuelComponents: _isFuel ? _fuelComponents : const [],
    );

    final state = context.read<AppState>();
    if (widget.existing != null) {
      await state.updateEssentialTemplate(template, fuelComponents: _isFuel ? _fuelComponents : null);
    } else {
      await state.addEssentialTemplate(template, fuelComponents: _isFuel ? _fuelComponents : null);
    }

    if (!mounted) return;
    Navigator.pop(context);
    showSuccessSnackbar(context, widget.existing != null ? 'Essential template updated' : 'Essential expense created');
  }
}

Color parseHexColor(String hex) {
  final clean = hex.replaceAll('#', '');
  final full = clean.length == 6 ? 'FF$clean' : clean;
  return Color(int.parse(full, radix: 16));
}
