import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../components/glass/app_background.dart';
import '../../components/category/category_chip.dart';
import '../../components/category/category_icon.dart';
import '../../state/app_state.dart';
import '../../theme/wallet_melt_theme.dart';
import '../../types/subscription.dart' as wm_sub;
import '../../types/subscription.dart' show SubscriptionStatus;
import '../../types/category.dart' as wm_cat;
import '../../utils/currency_format.dart';
import '../../utils/number_parser.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/app_snackbar.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({this.isEmbedded = false, super.key});

  final bool isEmbedded;

  static void showAddSubscriptionSheet(BuildContext context) {
    showAppBottomSheet(
      context,
      builder: (context) => const _AddSubscriptionSheet(),
    );
  }

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  SubscriptionStatus _selectedFilter = SubscriptionStatus.active;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final currency = state.settings.currency;
    final allSubs = state.subscriptions;

    final filteredSubs = allSubs.where((s) => s.status == _selectedFilter).toList();

    final content = Column(
      children: [
        if (!widget.isEmbedded)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Back',
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Subscriptions',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                IconButton(
                  tooltip: 'Add Subscription',
                  onPressed: () => _showAddSubscriptionSheet(context),
                  icon: const Icon(Icons.add_rounded, size: 28),
                ),
              ],
            ),
          ),

        // Tabs / Filters
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
          child: Row(
            children: [
              _FilterChip(
                label: 'Active',
                selected: _selectedFilter == SubscriptionStatus.active,
                color: WalletMeltColors.positive,
                onTap: () => setState(() => _selectedFilter = SubscriptionStatus.active),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Paused',
                selected: _selectedFilter == SubscriptionStatus.paused,
                color: WalletMeltColors.brand,
                onTap: () => setState(() => _selectedFilter = SubscriptionStatus.paused),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Cancelled',
                selected: _selectedFilter == SubscriptionStatus.cancelled,
                color: WalletMeltColors.danger,
                onTap: () => setState(() => _selectedFilter = SubscriptionStatus.cancelled),
              ),
            ],
          ),
        ),

        // Subscription List Content
        Expanded(
          child: filteredSubs.isEmpty
              ? Center(
                  child: EmptyState(
                    icon: Icons.repeat_rounded,
                    title: _selectedFilter == SubscriptionStatus.active
                        ? 'No active subscriptions'
                        : _selectedFilter == SubscriptionStatus.paused
                            ? 'No paused subscriptions'
                            : 'No cancelled subscriptions',
                    subtitle: _selectedFilter == SubscriptionStatus.active
                        ? 'Create templates for Netflix, gym, rent, etc. to auto-generate expenses.'
                        : 'Subscriptions you pause will appear here.',
                    actionLabel: _selectedFilter == SubscriptionStatus.active ? 'Add Subscription' : null,
                    onActionPressed: _selectedFilter == SubscriptionStatus.active
                        ? () => _showAddSubscriptionSheet(context)
                        : null,
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 120),
                  itemCount: filteredSubs.length,
                  itemBuilder: (context, index) {
                    final sub = filteredSubs[index];
                    final category = state.categoryById(sub.categoryId);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: _SubscriptionCard(
                        subscription: sub,
                        category: category,
                        currency: currency,
                        onTap: () => _showSubscriptionActions(context, sub),
                      ),
                    );
                  },
                ),
        ),
      ],
    );

    if (widget.isEmbedded) {
      return content;
    }

    return Scaffold(
      body: AppBackground(
        child: content,
      ),
    );
  }

  void _showAddSubscriptionSheet(BuildContext context) {
    showAppBottomSheet(
      context,
      builder: (context) => const _AddSubscriptionSheet(),
    );
  }

  void _showSubscriptionActions(BuildContext context, wm_sub.Subscription sub) {
    showAppBottomSheet(
      context,
      builder: (context) => _SubscriptionActionsSheet(subscription: sub),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          constraints: const BoxConstraints(minHeight: 44.0),
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? color.withValues(alpha: 0.18)
                : isDark
                    ? Colors.white.withValues(alpha: 0.04)
                    : Colors.black.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
            border: Border.all(
              color: selected
                  ? color.withValues(alpha: 0.35)
                  : isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.06),
              width: 1.2,
            ),
          ),
          child: Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: selected ? (isDark ? Colors.white : color) : theme.textTheme.bodyMedium?.color,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            ),
            textHeightBehavior: const TextHeightBehavior(
              applyHeightToFirstAscent: false,
              applyHeightToLastDescent: false,
            ),
          ),
        ),
      ),
    );
  }
}

class _SubscriptionCard extends StatelessWidget {
  const _SubscriptionCard({
    required this.subscription,
    required this.category,
    required this.currency,
    required this.onTap,
  });

  final wm_sub.Subscription subscription;
  final wm_cat.Category? category;
  final String currency;
  final VoidCallback onTap;

  String _formatRelativeRenewal(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final target = DateTime(date.year, date.month, date.day);
      final diff = target.difference(today).inDays;
      if (diff == 0) return 'Renews today';
      if (diff == 1) return 'Renews tomorrow';
      if (diff > 1 && diff <= 7) return 'Renews in $diff days';
      if (diff < 0) return 'Renewal due';
      return 'Next: $dateStr';
    } catch (_) {
      return 'Next: $dateStr';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Status color
    final statusColor = switch (subscription.status) {
      SubscriptionStatus.active => WalletMeltColors.positive,
      SubscriptionStatus.paused => WalletMeltColors.brand,
      SubscriptionStatus.cancelled => WalletMeltColors.danger,
    };

    final billingCycleLabel = _getCycleLabel(subscription.billingCycle);
    final totalAmount = subscription.amount + (subscription.taxAmount ?? 0.0);

    return WMGlassSurface.tier2(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category Icon Container
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: category != null
                  ? colorFromHex(category!.color).withValues(alpha: 0.12)
                  : theme.colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: CategoryIcon(
                icon: category?.icon,
                color: category != null ? colorFromHex(category!.color) : theme.colorScheme.primary,
                size: 22,
                defaultIcon: Icons.repeat_rounded,
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Main details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        subscription.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: statusColor.withValues(alpha: 0.25), width: 1),
                      ),
                      child: Text(
                        subscription.status.name.toUpperCase(),
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      billingCycleLabel,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: WalletMeltColors.brandDeep,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(width: 4, height: 4, decoration: BoxDecoration(shape: BoxShape.circle, color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.4))),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _formatRelativeRenewal(subscription.nextOccurrenceDate),
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (subscription.taxAmount != null && subscription.taxAmount! > 0) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Subtotal: ${formatMoney(subscription.amount, currency)} | Tax: ${formatMoney(subscription.taxAmount!, currency)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                      color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Right-aligned Price
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatMoney(totalAmount, currency),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Grand Total',
                style: theme.textTheme.bodySmall?.copyWith(fontSize: 9, color: WalletMeltColors.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getCycleLabel(String cycle) {
    final lower = cycle.toLowerCase().trim();
    if (lower == 'monthly') return 'Monthly';
    if (lower == 'quarterly') return 'Quarterly';
    if (lower == 'semi_annual' || lower == 'semi-annual') return 'Semi-Annual';
    if (lower == 'annual' || lower == 'yearly') return 'Annual';
    if (lower.startsWith('custom_')) {
      final parts = lower.split('_');
      if (parts.length == 2) {
        final days = parts[1];
        return 'Every $days Days';
      }
    }
    return cycle;
  }
}

class _AddSubscriptionSheet extends StatefulWidget {
  const _AddSubscriptionSheet();

  @override
  State<_AddSubscriptionSheet> createState() => _AddSubscriptionSheetState();
}

class _AddSubscriptionSheetState extends State<_AddSubscriptionSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _taxController = TextEditingController();
  final _taxPercentageController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _customDaysController = TextEditingController();
  
  String? _categoryId;
  String _billingCycle = 'Monthly';
  DateTime _startDate = DateTime.now();
  int _notificationOffset = 0; // 0 = same day

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _taxController.dispose();
    _taxPercentageController.dispose();
    _descriptionController.dispose();
    _customDaysController.dispose();
    super.dispose();
  }

  void _calculateTax() {
    final amountText = _amountController.text.trim();
    final pctText = _taxPercentageController.text.trim();
    if (amountText.isEmpty || pctText.isEmpty) return;

    final amount = parseTolerantNumber(amountText);
    final pct = parseTolerantNumber(pctText);
    if (amount != null && pct != null) {
      final tax = amount * (pct / 100.0);
      setState(() {
        _taxController.text = tax.toStringAsFixed(tax % 1 == 0 ? 0 : 2);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    final currency = state.settings.currency;
    final categories = state.categories;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final parsedAmount = parseTolerantNumber(_amountController.text) ?? 0.0;
    final parsedTax = parseTolerantNumber(_taxController.text) ?? 0.0;
    final grandTotal = parsedAmount + parsedTax;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Create Subscription',
                          maxLines: 1,
                          style: theme.textTheme.headlineMedium?.copyWith(fontSize: 22),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Name
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Subscription Name',
                    hintText: 'e.g. Netflix, Rent, Gym',
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter a name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Category Selection
                const Text(
                  'Category',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 48,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    clipBehavior: Clip.none,
                    itemCount: categories.length,
                    separatorBuilder: (context, i) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      final isSelected = category.id == _categoryId;
                      return WalletCategoryChip(
                        category: category,
                        selected: isSelected,
                        onTap: () {
                          setState(() {
                            _categoryId = category.id;
                          });
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Base Amount Field
                TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Base Amount ($currency)*',
                    hintText: '0.00',
                    prefixIcon: const Icon(Icons.payments_outlined),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Required';
                    }
                    if (parseTolerantNumber(val) == null) {
                      return 'Invalid';
                    }
                    return null;
                  },
                  onChanged: (_) {
                    _calculateTax();
                    setState(() {});
                  },
                ),
                const SizedBox(height: 14),

                // Cohesive Fintech Tax & Breakdown Card
                WMGlassSurface.tier2(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'TAX & BILLING SUMMARY',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              color: WalletMeltColors.textMuted,
                            ),
                          ),
                          if (parsedTax > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: WalletMeltColors.brand.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Tax Applied',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? WalletMeltColors.brand : WalletMeltColors.brandDeep,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _taxPercentageController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                labelText: 'Rate (%)',
                                hintText: '0',
                                prefixIcon: Icon(Icons.percent_rounded, size: 16),
                                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                              ),
                              onChanged: (_) {
                                _calculateTax();
                                setState(() {});
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: _taxController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                labelText: 'Tax ($currency)',
                                hintText: '0.00',
                                prefixIcon: const Icon(Icons.receipt_outlined, size: 16),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                              ),
                              onChanged: (val) {
                                final taxVal = parseTolerantNumber(val);
                                final amtVal = parseTolerantNumber(_amountController.text);
                                if (taxVal != null && amtVal != null && amtVal > 0) {
                                  final pct = (taxVal / amtVal) * 100.0;
                                  _taxPercentageController.text = pct.toStringAsFixed(pct % 1 == 0 ? 0 : 1);
                                } else if (val.trim().isEmpty) {
                                  _taxPercentageController.clear();
                                }
                                setState(() {});
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total per cycle',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark ? WalletMeltColors.darkTextPrimary : WalletMeltColors.textPrimary,
                              ),
                            ),
                            Text(
                              formatMoney(grandTotal, currency),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: isDark ? WalletMeltColors.brand : WalletMeltColors.brandDeep,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),


                // Billing Cycle Dropdown
                DropdownButtonFormField<String>(
                  initialValue: _billingCycle,
                  decoration: const InputDecoration(labelText: 'Billing Cycle'),
                  dropdownColor: isDark ? WalletMeltColors.darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  items: const [
                    DropdownMenuItem(value: 'Monthly', child: Text('Monthly')),
                    DropdownMenuItem(value: 'Quarterly', child: Text('Quarterly')),
                    DropdownMenuItem(value: 'Semi-Annual', child: Text('Semi-Annual')),
                    DropdownMenuItem(value: 'Annual', child: Text('Annual')),
                    DropdownMenuItem(value: 'Custom Days', child: Text('Custom Days Interval')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _billingCycle = val;
                      });
                    }
                  },
                ),
                if (_billingCycle == 'Custom Days') ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _customDaysController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Interval in Days',
                      hintText: 'e.g. 45',
                    ),
                    validator: (val) {
                      if (_billingCycle == 'Custom Days') {
                        if (val == null || val.trim().isEmpty) return 'Required';
                        final parsed = int.tryParse(val);
                        if (parsed == null || parsed <= 0) return 'Must be positive';
                      }
                      return null;
                    },
                  ),
                ],
                const SizedBox(height: 16),

                // Start Date Picker
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      useRootNavigator: true,
                      initialDate: _startDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setState(() {
                        _startDate = picked;
                      });
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Start Date',
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${_startDate.year}-${_startDate.month.toString().padLeft(2, '0')}-${_startDate.day.toString().padLeft(2, '0')}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const Icon(Icons.calendar_today_rounded, size: 18),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Notification Offset Dropdown
                DropdownButtonFormField<int>(
                  initialValue: _notificationOffset,
                  decoration: const InputDecoration(labelText: 'Notification Reminder'),
                  dropdownColor: isDark ? WalletMeltColors.darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  items: const [
                    DropdownMenuItem(value: 0, child: Text('On renewal day')),
                    DropdownMenuItem(value: 1, child: Text('1 day before')),
                    DropdownMenuItem(value: 2, child: Text('2 days before')),
                    DropdownMenuItem(value: 3, child: Text('3 days before')),
                    DropdownMenuItem(value: 7, child: Text('1 week before')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _notificationOffset = val;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Description
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Description (Optional)',
                    hintText: 'Account number, reference, or details',
                  ),
                ),
                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: PrimaryButton(
                        label: 'Create',
                        onPressed: () async {
                          if (_formKey.currentState?.validate() ?? false) {
                            if (_categoryId == null) {
                              showErrorSnackbar(context, 'Please select a category');
                              return;
                            }

                            final name = _nameController.text.trim();
                            final amount = parseTolerantNumber(_amountController.text) ?? 0.0;
                            final tax = parseTolerantNumber(_taxController.text);
                            final desc = _descriptionController.text.trim();

                            String cycleValue = _billingCycle;
                            if (_billingCycle == 'Custom Days') {
                              final days = int.parse(_customDaysController.text.trim());
                              cycleValue = 'custom_$days';
                            }

                            final startDateStr = _startDate.toIso8601String().substring(0, 10);
                            
                            // Initialize nextOccurrenceDate equal to startDate or now.
                            // If startDate is in the future, nextOccurrence is startDate.
                            // If startDate is in the past, renewals engine will auto-process it.
                            final sub = wm_sub.Subscription(
                              id: const Uuid().v4(),
                              name: name,
                              categoryId: _categoryId!,
                              amount: amount,
                              taxAmount: tax,
                              currency: currency,
                              description: desc.isEmpty ? null : desc,
                              startDate: startDateStr,
                              nextOccurrenceDate: startDateStr,
                              billingCycle: cycleValue,
                              status: SubscriptionStatus.active,
                              createdAt: DateTime.now().toIso8601String(),
                              updatedAt: DateTime.now().toIso8601String(),
                              notificationOffset: _notificationOffset,
                            );

                            await state.addSubscription(sub);

                            if (!context.mounted) return;
                            Navigator.pop(context);
                            showSuccessSnackbar(context, 'Subscription "$name" created successfully.');
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
  }
}

class _SubscriptionActionsSheet extends StatelessWidget {
  const _SubscriptionActionsSheet({required this.subscription});

  final wm_sub.Subscription subscription;

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            subscription.name,
            style: theme.textTheme.headlineMedium?.copyWith(fontSize: 20),
          ),
          const SizedBox(height: 4),
          Text(
            'Created on: ${subscription.createdAt.substring(0, 10)}',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 20),

          // Actions List
          if (subscription.status == SubscriptionStatus.active) ...[
            _ActionButton(
              icon: Icons.pause_rounded,
              label: 'Pause Subscription',
              color: WalletMeltColors.brand,
              onTap: () async {
                final updated = subscription.copyWith(
                  status: SubscriptionStatus.paused,
                  updatedAt: DateTime.now().toIso8601String(),
                );
                await state.updateSubscription(updated);
                if (!context.mounted) return;
                Navigator.pop(context);
              },
            ),
          ] else if (subscription.status == SubscriptionStatus.paused) ...[
            _ActionButton(
              icon: Icons.play_arrow_rounded,
              label: 'Resume Subscription',
              color: WalletMeltColors.positive,
              onTap: () async {
                final updated = subscription.copyWith(
                  status: SubscriptionStatus.active,
                  updatedAt: DateTime.now().toIso8601String(),
                );
                await state.updateSubscription(updated);
                if (!context.mounted) return;
                Navigator.pop(context);
              },
            ),
          ],

          if (subscription.status != SubscriptionStatus.cancelled) ...[
            _ActionButton(
              icon: Icons.cancel_outlined,
              label: 'Cancel Subscription',
              color: WalletMeltColors.danger,
              onTap: () async {
                final updated = subscription.copyWith(
                  status: SubscriptionStatus.cancelled,
                  cancelledAt: DateTime.now().toIso8601String(),
                  updatedAt: DateTime.now().toIso8601String(),
                );
                await state.updateSubscription(updated);
                if (!context.mounted) return;
                Navigator.pop(context);
              },
            ),
          ],

          _ActionButton(
            icon: Icons.edit_outlined,
            label: 'Update Amount',
            color: theme.colorScheme.primary,
            onTap: () {
              Navigator.pop(context);
              _showUpdateAmountDialog(context, state);
            },
          ),

          Divider(
            height: 24,
            color: isDark ? WalletMeltColors.darkBorder : WalletMeltColors.lightBorder,
          ),

          _ActionButton(
            icon: Icons.delete_forever_rounded,
            label: 'Delete Template',
            color: WalletMeltColors.danger,
            isDestructive: true,
            onTap: () async {
              final confirm = await showConfirmDialog(
                context,
                title: 'Delete Subscription Template?',
                body: 'This will delete the subscription template completely. Historical expenses generated from this template will not be affected.',
                confirmLabel: 'Delete',
                isDestructive: true,
              );

              if (confirm == true) {
                await state.deleteSubscription(subscription.id);
                if (!context.mounted) return;
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
    );
  }

  void _showUpdateAmountDialog(BuildContext context, AppState state) {
    final currency = state.settings.currency;
    final amountController = TextEditingController(
      text: subscription.amount.toStringAsFixed(subscription.amount % 1 == 0 ? 0 : 2),
    );
    final taxController = TextEditingController(
      text: subscription.taxAmount != null
          ? subscription.taxAmount!.toStringAsFixed(subscription.taxAmount! % 1 == 0 ? 0 : 2)
          : '',
    );
    final taxPercentageController = TextEditingController();

    showDialog(
      context: context,
      useRootNavigator: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final amount = parseTolerantNumber(amountController.text) ?? 0.0;
            final tax = parseTolerantNumber(taxController.text) ?? 0.0;
            final total = amount + tax;


            void calculateTax() {
              final amountText = amountController.text.trim();
              final pctText = taxPercentageController.text.trim();
              if (amountText.isEmpty || pctText.isEmpty) return;

              final amt = parseTolerantNumber(amountText);
              final pct = parseTolerantNumber(pctText);
              if (amt != null && pct != null) {
                final tx = amt * (pct / 100.0);
                taxController.text = tx.toStringAsFixed(tx % 1 == 0 ? 0 : 2);
                setState(() {});
              }
            }

            return AlertDialog(
              title: const Text('Update Subscription Price'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Base Amount ($currency)',
                        prefixIcon: const Icon(Icons.payments_outlined),
                      ),
                      onChanged: (_) {
                        calculateTax();
                        setState(() {});
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: taxPercentageController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Rate (%)',
                              hintText: '0',
                              prefixIcon: Icon(Icons.percent_rounded, size: 16),
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                            ),
                            onChanged: (_) => calculateTax(),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: taxController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              labelText: 'Tax ($currency)',
                              hintText: '0.00',
                              prefixIcon: const Icon(Icons.receipt_outlined, size: 16),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                            ),
                            onChanged: (val) {
                              final taxVal = parseTolerantNumber(val);
                              final amtVal = parseTolerantNumber(amountController.text);
                              if (taxVal != null && amtVal != null && amtVal > 0) {
                                final pct = (taxVal / amtVal) * 100.0;
                                taxPercentageController.text = pct.toStringAsFixed(pct % 1 == 0 ? 0 : 1);
                              } else if (val.trim().isEmpty) {
                                taxPercentageController.clear();
                              }
                              setState(() {});
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total per cycle:',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          Text(
                            formatMoney(total, currency),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: isDark ? WalletMeltColors.brand : WalletMeltColors.brandDeep,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    final newAmount = parseTolerantNumber(amountController.text);
                    final newTax = parseTolerantNumber(taxController.text);
                    if (newAmount != null && newAmount >= 0) {
                      final updated = subscription.copyWith(
                        amount: newAmount,
                        taxAmount: newTax,
                        clearTax: newTax == null,
                        updatedAt: DateTime.now().toIso8601String(),
                      );
                      await state.updateSubscription(updated);
                      if (!context.mounted) return;
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Update'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.isDestructive = false,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isDestructive
                ? color.withValues(alpha: 0.08)
                : theme.brightness == Brightness.dark
                    ? Colors.white.withValues(alpha: 0.03)
                    : Colors.black.withValues(alpha: 0.02),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDestructive
                  ? color.withValues(alpha: 0.18)
                  : theme.brightness == Brightness.dark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.black.withValues(alpha: 0.04),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontSize: 14,
                    color: isDestructive ? color : null,
                    fontWeight: isDestructive ? FontWeight.bold : FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.3),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

