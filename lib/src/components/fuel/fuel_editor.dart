import 'package:flutter/material.dart';

import '../../theme/wallet_melt_theme.dart';
import '../../types/fuel.dart';
import '../../utils/currency_format.dart';

class FuelEditor extends StatefulWidget {
  const FuelEditor({
    super.key,
    required this.initialDraft,
    required this.currency,
    required this.onChanged,
  });

  final FuelTransactionDraft? initialDraft;
  final String currency;
  final ValueChanged<FuelTransactionDraft> onChanged;

  @override
  State<FuelEditor> createState() => _FuelEditorState();
}

class _FuelRowData {
  _FuelRowData({
    required this.fuelType,
    required this.litresController,
    required this.priceController,
    required this.litresFocusNode,
    required this.priceFocusNode,
  });

  FuelType fuelType;
  final TextEditingController litresController;
  final TextEditingController priceController;
  final FocusNode litresFocusNode;
  final FocusNode priceFocusNode;

  double get litres => double.tryParse(litresController.text.trim()) ?? 0.0;
  double get price => double.tryParse(priceController.text.trim()) ?? 0.0;
  double get subtotal => roundToTwoDecimals(litres * price);

  void dispose() {
    litresController.dispose();
    priceController.dispose();
    litresFocusNode.dispose();
    priceFocusNode.dispose();
  }
}

class _FuelEditorState extends State<FuelEditor> {
  final List<_FuelRowData> _rows = [];
  final TextEditingController _odometerController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialDraft != null &&
        widget.initialDraft!.components.isNotEmpty) {
      if (widget.initialDraft!.odometerReading != null) {
        final odo = widget.initialDraft!.odometerReading!;
        _odometerController.text =
            odo % 1 == 0 ? odo.toInt().toString() : odo.toString();
      }
      for (final comp in widget.initialDraft!.components) {
        _addRow(
          fuelType: comp.fuelType,
          litres: comp.quantityLitres > 0
              ? (comp.quantityLitres % 1 == 0
                  ? comp.quantityLitres.toInt().toString()
                  : comp.quantityLitres.toString())
              : '',
          price: comp.pricePerLitre > 0
              ? (comp.pricePerLitre % 1 == 0
                  ? comp.pricePerLitre.toInt().toString()
                  : comp.pricePerLitre.toString())
              : '',
        );
      }
    } else {
      _addRow();
    }
  }

  void _addRow({
    FuelType fuelType = FuelType.regular,
    String litres = '',
    String price = '',
  }) {
    // If regular already exists and we are adding another row, pick next unused fuel type by default
    if (widget.initialDraft == null && _rows.isNotEmpty) {
      final usedTypes = _rows.map((r) => r.fuelType).toSet();
      for (final type in FuelType.values) {
        if (!usedTypes.contains(type)) {
          fuelType = type;
          break;
        }
      }
    }

    final litresCtrl = TextEditingController(text: litres);
    final priceCtrl = TextEditingController(text: price);

    final rowData = _FuelRowData(
      fuelType: fuelType,
      litresController: litresCtrl,
      priceController: priceCtrl,
      litresFocusNode: FocusNode(),
      priceFocusNode: FocusNode(),
    );

    _rows.add(rowData);
  }

  void _removeRow(int index) {
    if (_rows.length <= 1) return;
    setState(() {
      final removed = _rows.removeAt(index);
      removed.dispose();
    });
    _notifyParent();
  }

  void _notifyParent() {
    final components = _rows.map((row) {
      return FuelComponentDraft(
        fuelType: row.fuelType,
        quantityLitres: row.litres,
        pricePerLitre: row.price,
      );
    }).toList();

    final odo = double.tryParse(_odometerController.text.trim());

    final draft = FuelTransactionDraft(
      odometerReading: odo,
      components: components,
    );

    widget.onChanged(draft);
  }

  double get _totalLitres =>
      _rows.fold(0.0, (sum, row) => sum + row.litres);

  double get _totalAmount =>
      roundToTwoDecimals(_rows.fold(0.0, (sum, row) => sum + row.subtotal));

  @override
  void dispose() {
    for (final row in _rows) {
      row.dispose();
    }
    _odometerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Odometer Optional Input (Spacious Fintech Entry Field)
        WMGlassSurface.tier1(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: WalletMeltColors.brand.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.speed_rounded,
                  size: 20,
                  color: WalletMeltColors.brand,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'ODOMETER READING (OPTIONAL)',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: WalletMeltColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _odometerController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : WalletMeltColors.textPrimary,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'e.g. 45200',
                        hintStyle: TextStyle(
                          fontSize: 14,
                          color: WalletMeltColors.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 4),
                      ),
                      onChanged: (_) {
                        setState(() {});
                        _notifyParent();
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'km',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: isDark ? WalletMeltColors.darkTextPrimary : WalletMeltColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),


        // Section Title & Add Component Button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'FUEL COMPONENTS (${_rows.length})',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                    color: WalletMeltColors.textMuted,
                  ),
            ),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _addRow();
                });
                _notifyParent();
              },
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add Fuel Type',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Fuel Component Rows
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _rows.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final row = _rows[index];
            final duplicateCount =
                _rows.where((r) => r.fuelType == row.fuelType).length;

            return WMGlassSurface.tier2(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Fuel Type Selector Dropdown
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 2),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.06)
                              : Colors.black.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.12)
                                : Colors.black.withValues(alpha: 0.08),
                          ),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<FuelType>(
                            value: row.fuelType,
                            isDense: true,
                            icon: const Icon(Icons.arrow_drop_down_rounded,
                                size: 20),
                            items: FuelType.values.map((type) {
                              return DropdownMenuItem<FuelType>(
                                value: type,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(type.icon,
                                        size: 16,
                                        color: WalletMeltColors.brand),
                                    const SizedBox(width: 8),
                                    Text(
                                      type.displayName,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (newType) {
                              if (newType != null) {
                                setState(() {
                                  row.fuelType = newType;
                                });
                                _notifyParent();
                              }
                            },
                          ),
                        ),
                      ),
                      const Spacer(),
                      // Subtotal for this component
                      Text(
                        formatMoney(row.subtotal, widget.currency),
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: WalletMeltColors.brand,
                        ),
                      ),
                      if (_rows.length > 1) ...[
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.close_rounded,
                              size: 18, color: WalletMeltColors.textMuted),
                          tooltip: 'Remove',
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                              minWidth: 28, minHeight: 28),
                          onPressed: () => _removeRow(index),
                        ),
                      ],
                    ],
                  ),
                  if (duplicateCount > 1) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Note: Multiple ${row.fuelType.displayName} entries in this purchase',
                      style: const TextStyle(
                          fontSize: 11, color: WalletMeltColors.warning),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      // Litres Field
                      Expanded(
                        child: TextField(
                          controller: row.litresController,
                          focusNode: row.litresFocusNode,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: InputDecoration(
                            labelText: 'Litres (L)',
                            hintText: '0.00',
                            isDense: true,
                            suffixText: 'L',
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onChanged: (_) {
                            setState(() {});
                            _notifyParent();
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Price per Litre Field
                      Expanded(
                        child: TextField(
                          controller: row.priceController,
                          focusNode: row.priceFocusNode,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: InputDecoration(
                            labelText: 'Price / Litre',
                            hintText: '0.00',
                            isDense: true,
                            suffixText: widget.currency,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onChanged: (_) {
                            setState(() {});
                            _notifyParent();
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),

        const SizedBox(height: 12),

        // Fuel Total Summary Banner
        WMGlassSurface.tier1(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total Fuel Volume',
                      style: TextStyle(
                          fontSize: 11, color: WalletMeltColors.textMuted)),
                  const SizedBox(height: 2),
                  Text(
                    '${_totalLitres.toStringAsFixed(_totalLitres % 1 == 0 ? 0 : 2)} Litres',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Fuel Subtotal',
                      style: TextStyle(
                          fontSize: 11, color: WalletMeltColors.textMuted)),
                  const SizedBox(height: 2),
                  Text(
                    formatMoney(_totalAmount, widget.currency),
                    style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        color: WalletMeltColors.brand),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
