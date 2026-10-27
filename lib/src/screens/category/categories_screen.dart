import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../components/category/category_icon.dart';
import '../../components/glass/app_background.dart';
import '../../state/app_state.dart';
import '../../theme/wallet_melt_theme.dart';
import '../../types/category.dart' as wm;
import '../../widgets/fluid_list.dart';
import 'category_editor_sheet.dart';

/// Every category in one place: tap one to change its icon, name or colour.
class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final categories = context.select((AppState s) => s.categories);
    final text = Theme.of(context).textTheme;
    final scheme = context.scheme;

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.md, AppSpacing.md, 120),
            children: [
              Row(
                children: [
                  IconButton(
                    tooltip: 'Back',
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  Expanded(
                    child: Text('Categories', style: text.titleLarge),
                  ),
                  IconButton(
                    tooltip: 'Icon library',
                    onPressed: () => context.push('/settings/icons'),
                    icon: const Icon(Icons.palette_outlined),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                child: Text(
                  'Tap a category to change its icon, name or colour. '
                  'Past expenses keep their category.',
                  style:
                      text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              FilledButton.icon(
                onPressed: () => showCategoryEditor(context),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add category'),
              ),
              const SizedBox(height: AppSpacing.md),
              for (var i = 0; i < categories.length; i++)
                FluidItem(
                  index: i,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.smMd),
                    child: _CategoryRow(category: categories[i]),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({required this.category});

  final wm.Category category;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = context.scheme;
    final accent = colorFromHex(category.color);

    return WMCard(
      onTap: () => showCategoryEditor(context, existing: category),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Center(
              child: CategoryIcon(
                  icon: category.icon, size: 26, color: accent),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(category.name,
                    style: text.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                if (category.isDefault)
                  Text('Built in',
                      style: text.bodySmall
                          ?.copyWith(color: scheme.onSurfaceVariant)),
              ],
            ),
          ),
          Icon(Icons.edit_outlined, color: scheme.onSurfaceVariant),
        ],
      ),
    );
  }
}
