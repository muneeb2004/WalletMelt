import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../components/glass/app_background.dart';
import '../../state/app_state.dart';
import '../../theme/wallet_melt_theme.dart';
import '../../types/merchant.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/primary_button.dart';

class MerchantsScreen extends StatefulWidget {
  const MerchantsScreen({super.key});

  @override
  State<MerchantsScreen> createState() => _MerchantsScreenState();
}

class _MerchantsScreenState extends State<MerchantsScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  static IconData _iconFor(String? name) {
    return switch (name) {
      'bolt' => Icons.bolt_rounded,
      'local_fire_department' => Icons.local_fire_department_rounded,
      'shopping_basket' => Icons.shopping_basket_rounded,
      'wifi' => Icons.wifi_rounded,
      'water_drop' => Icons.water_drop_rounded,
      'home' => Icons.home_rounded,
      'build' => Icons.build_rounded,
      'local_gas_station' => Icons.local_gas_station_rounded,
      _ => Icons.category_rounded,
    };
  }

  void _showAddEditMerchantSheet(BuildContext context, {Merchant? merchant}) {
    final state = context.read<AppState>();
    final nameController = TextEditingController(text: merchant?.name);
    final notesController = TextEditingController(text: merchant?.notes);
    String? selectedCategoryId = merchant?.defaultCategoryId;
    bool isFavorite = merchant?.isFavorite ?? false;

    showAppBottomSheet<void>(
      context,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final categories = state.categories;

            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      merchant == null ? 'Add Saved Merchant' : 'Edit Merchant',
                      style: Theme.of(sheetContext).textTheme.titleLarge,
                    ),
                    AppSpacing.gapMd,
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Merchant or Place Name',
                        hintText: 'e.g., AutoCare Garage, Subway',
                        prefixIcon: Icon(Icons.storefront_rounded),
                      ),
                    ),
                    AppSpacing.gapSm,
                    DropdownButtonFormField<String?>(
                      initialValue: selectedCategoryId,
                      decoration: const InputDecoration(
                        labelText: 'Default Category (Optional)',
                        prefixIcon: Icon(Icons.category_rounded),
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('None / Unassigned'),
                        ),
                        ...categories.map((c) {
                          return DropdownMenuItem<String?>(
                            value: c.id,
                            child: Row(
                              children: [
                                Icon(_iconFor(c.icon), size: 16, color: WalletMeltColors.brand),
                                const SizedBox(width: 8),
                                Text(c.name),
                              ],
                            ),
                          );
                        }),
                      ],
                      onChanged: (val) {
                        setSheetState(() {
                          selectedCategoryId = val;
                        });
                      },
                    ),
                    AppSpacing.gapSm,
                    TextField(
                      controller: notesController,
                      minLines: 2,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Notes (Optional)',
                        hintText: 'e.g., Preferred car mechanic, discount code...',
                        prefixIcon: Icon(Icons.notes_rounded),
                      ),
                    ),
                    AppSpacing.gapSm,
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Mark as Favorite', style: TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: const Text('Pins merchant to top of suggestions in Add Expense'),
                      value: isFavorite,
                      activeThumbColor: WalletMeltColors.brand,
                      onChanged: (val) {
                        setSheetState(() {
                          isFavorite = val;
                        });
                      },
                    ),
                    AppSpacing.gapMd,
                    PrimaryButton(
                      label: merchant == null ? 'Save Merchant' : 'Save Changes',
                      onPressed: () async {
                        final name = nameController.text.trim();
                        if (name.isEmpty) {
                          showErrorSnackbar(context, 'Please enter a merchant name');
                          return;
                        }

                        if (merchant == null) {
                          await state.saveMerchant(
                            name: name,
                            defaultCategoryId: selectedCategoryId,
                            notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
                            isFavorite: isFavorite,
                          );
                          if (context.mounted) {
                            Navigator.of(sheetContext).pop();
                            showSuccessSnackbar(context, 'Saved merchant "$name"');
                          }
                        } else {
                          final updated = merchant.copyWith(
                            name: name,
                            defaultCategoryId: selectedCategoryId,
                            clearDefaultCategory: selectedCategoryId == null,
                            notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
                            clearNotes: notesController.text.trim().isEmpty,
                            isSaved: true,
                            isFavorite: isFavorite,
                          );
                          await state.updateMerchant(updated);
                          if (context.mounted) {
                            Navigator.of(sheetContext).pop();
                            showSuccessSnackbar(context, 'Updated merchant "$name"');
                          }
                        }
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
  }

  void _confirmArchive(BuildContext context, Merchant merchant) {
    final state = context.read<AppState>();
    showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          title: const Text('Archive Merchant?'),
          content: Text(
            'Archiving "${merchant.name}" will remove it from suggestions and saved merchants. All past expenses will remain safe and untouched.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
              onPressed: () async {
                Navigator.of(dialogCtx).pop();
                await state.archiveMerchant(merchant.id);
                if (context.mounted) {
                  showSuccessSnackbar(context, 'Archived "${merchant.name}"');
                }
              },
              child: const Text('Archive'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = context.watch<AppState>();
    final isDark = theme.brightness == Brightness.dark;

    final allSaved = state.savedMerchants;
    final filtered = allSaved.where((m) {
      if (_searchQuery.isEmpty) return true;
      if (m.normalizedName.contains(_searchQuery) || m.name.toLowerCase().contains(_searchQuery)) {
        return true;
      }
      if (m.defaultCategoryId != null) {
        final cat = state.categoryById(m.defaultCategoryId!);
        if (cat != null && cat.name.toLowerCase().contains(_searchQuery)) {
          return true;
        }
      }
      return false;
    }).toList();

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded),
                      onPressed: () => context.pop(),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Saved Merchants',
                        style: theme.textTheme.headlineMedium,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Add Merchant',
                      icon: const Icon(Icons.add_rounded),
                      onPressed: () => _showAddEditMerchantSheet(context),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search saved merchants & places...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () => _searchController.clear(),
                          )
                        : null,
                  ),
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? EmptyState(
                        icon: Icons.storefront_outlined,
                        title: _searchQuery.isEmpty ? 'No Saved Merchants Yet' : 'No Merchants Found',
                        subtitle: _searchQuery.isEmpty
                            ? 'Save your frequent shops, restaurants, and bill vendors for 1-tap auto-complete and category selection in Add Expense.'
                            : 'No saved merchants match "$_searchQuery".',
                        actionLabel: _searchQuery.isEmpty ? 'Add First Merchant' : null,
                        onActionPressed: _searchQuery.isEmpty ? () => _showAddEditMerchantSheet(context) : null,
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                        itemCount: filtered.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final merchant = filtered[index];
                          final category = merchant.defaultCategoryId != null
                              ? state.categoryById(merchant.defaultCategoryId!)
                              : null;

                          return WMGlassSurface.tier1(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            child: Row(
                              children: [
                                IconButton(
                                  tooltip: merchant.isFavorite ? 'Unpin favorite' : 'Pin to favorites',
                                  icon: Icon(
                                    merchant.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                                    color: merchant.isFavorite ? Colors.amber : WalletMeltColors.textMuted,
                                    size: 24,
                                  ),
                                  onPressed: () => state.toggleMerchantFavorite(merchant.id),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        merchant.name,
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          if (category != null) ...[
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: WalletMeltColors.brand.withValues(alpha: 0.12),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(_iconFor(category.icon), size: 12, color: WalletMeltColors.brand),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    category.name,
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w600,
                                                      color: isDark ? WalletMeltColors.brandSoft : WalletMeltColors.brandDeep,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                          ],
                                          if (merchant.notes != null && merchant.notes!.isNotEmpty)
                                            Expanded(
                                              child: Text(
                                                merchant.notes!,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: theme.textTheme.bodySmall?.copyWith(
                                                  color: WalletMeltColors.textMuted,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert_rounded, size: 20),
                                  onSelected: (val) {
                                    if (val == 'edit') {
                                      _showAddEditMerchantSheet(context, merchant: merchant);
                                    } else if (val == 'archive') {
                                      _confirmArchive(context, merchant);
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          Icon(Icons.edit_outlined, size: 18),
                                          SizedBox(width: 8),
                                          Text('Edit'),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'archive',
                                      child: Row(
                                        children: [
                                          Icon(Icons.archive_outlined, size: 18, color: theme.colorScheme.error),
                                          const SizedBox(width: 8),
                                          Text('Archive', style: TextStyle(color: theme.colorScheme.error)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditMerchantSheet(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Merchant'),
      ),
    );
  }
}
