import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../components/category/category_icon.dart';
import '../../components/glass/app_background.dart';
import '../../services/svg/svg_customization_service.dart';
import '../../services/svg/svg_upload.dart';
import '../../state/app_state.dart';
import '../../theme/wallet_melt_theme.dart';
import '../../widgets/app_snackbar.dart';
import 'svg_editor_dialog.dart';

enum _Filter { all, builtIn, yours }

/// Browse every icon, add your own, tweak colours, and delete uploads.
/// Choosing which icon a category uses happens on the Categories screen.
class SvgManagerScreen extends StatefulWidget {
  const SvgManagerScreen({super.key});

  @override
  State<SvgManagerScreen> createState() => _SvgManagerScreenState();
}

class _SvgManagerScreenState extends State<SvgManagerScreen> {
  final TextEditingController _search = TextEditingController();
  List<SvgIconItem> _all = [];
  bool _loading = true;
  bool _uploading = false;
  _Filter _filter = _Filter.all;

  @override
  void initState() {
    super.initState();
    _load();
    SvgCustomizationService.instance.addListener(_load);
  }

  @override
  void dispose() {
    _search.dispose();
    SvgCustomizationService.instance.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    final icons = await SvgCustomizationService.instance.listAllIcons();
    if (mounted) {
      setState(() {
        _all = icons;
        _loading = false;
      });
    }
  }

  /// Names of categories using [iconId], or null when none do (or no
  /// AppState is in scope, as in isolated widget tests).
  String? _usedBy(String iconId) {
    try {
      final state = Provider.of<AppState>(context, listen: false);
      final key = SvgCustomizationService.instance.normalizeKey(iconId);
      final names = state.categories
          .where((c) =>
              c.icon == iconId ||
              SvgCustomizationService.instance.normalizeKey(c.icon) == key)
          .map((c) => c.name)
          .toList();
      return names.isEmpty ? null : names.join(', ');
    } catch (_) {
      return null;
    }
  }

  AppState? _stateOrNull() {
    try {
      return Provider.of<AppState>(context, listen: false);
    } catch (_) {
      return null;
    }
  }

  Future<void> _upload() async {
    setState(() => _uploading = true);
    final result = await pickAndSaveSvg();
    if (!mounted) return;
    setState(() => _uploading = false);
    if (result.error != null) {
      showErrorSnackbar(context, result.error!);
    } else if (result.iconId != null) {
      showSuccessSnackbar(
          context, 'Icon added. Pick it for any category from the Categories screen.');
    }
  }

  Future<void> _delete(SvgIconItem item) async {
    final usedBy = _usedBy(item.id);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete ${item.label}?'),
        content: Text(usedBy == null
            ? 'This removes the icon from your phone.'
            : 'It is used by $usedBy. Those categories will switch to the '
                '"Other" icon so nothing is left blank.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: ctx.scheme.error,
              foregroundColor: ctx.scheme.onError,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete icon'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await context.read<AppState>().deleteUploadedIcon(item.id);
    } catch (_) {
      await SvgCustomizationService.instance.deleteCustomIcon(item.id);
    }
    if (mounted) showSuccessSnackbar(context, 'Icon deleted.');
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = context.scheme;
    final query = _search.text.toLowerCase().trim();
    final filtered = _all.where((item) {
      final yours = item.type == SvgIconType.custom;
      if (_filter == _Filter.builtIn && yours) return false;
      if (_filter == _Filter.yours && !yours) return false;
      if (query.isEmpty) return true;
      return item.label.toLowerCase().contains(query) ||
          item.id.toLowerCase().contains(query);
    }).toList();

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
                  Expanded(child: Text('Icon library', style: text.titleLarge)),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                child: Text(
                  'Add your own icons, or tap one to change its colour or '
                  'shape. Pick which icon a category uses on the '
                  'Categories screen.',
                  style: text.bodyMedium
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ),
              const SizedBox(height: AppSpacing.smMd),
              FilledButton.icon(
                onPressed: _uploading ? null : _upload,
                icon: _uploading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.upload_file_rounded),
                label: const Text('Upload your own SVG'),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _search,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Search icons',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _search.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear search',
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => setState(_search.clear),
                        ),
                ),
              ),
              const SizedBox(height: AppSpacing.smMd),
              SegmentedButton<_Filter>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(
                      value: _Filter.all, label: Text('All (${_all.length})')),
                  const ButtonSegment(
                      value: _Filter.builtIn, label: Text('Built in')),
                  const ButtonSegment(
                      value: _Filter.yours, label: Text('Yours')),
                ],
                selected: {_filter},
                onSelectionChanged: (s) => setState(() => _filter = s.first),
              ),
              const SizedBox(height: AppSpacing.md),
              if (_loading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.xl),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (filtered.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Center(
                    child: Text(
                      _filter == _Filter.yours && query.isEmpty
                          ? 'You have not added any icons yet.'
                          : 'No icons match "$query"',
                      style: text.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              else
                for (final item in filtered)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _row(context, item),
                  ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(BuildContext context, SvgIconItem item) {
    final text = Theme.of(context).textTheme;
    final scheme = context.scheme;
    final edited = SvgCustomizationService.instance.isCustomized(item.id);
    final usedBy = _usedBy(item.id);
    final yours = item.type == SvgIconType.custom;

    return WMCard(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.smMd),
      onTap: () async {
        final state = _stateOrNull();
        final result =
            await SvgEditorDialog.show(context, item, usedBy: usedBy);
        final newId = result?.useIconId;
        if (newId != null && state != null) {
          await state.useIconForCategoriesWith(item.id, newId);
        }
      },
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              border: Border.all(
                color: edited ? scheme.primary : scheme.outlineVariant,
                width: edited ? 2 : 1,
              ),
            ),
            child: CategoryIcon(
              icon: item.id,
              size: 26,
              color: edited ? scheme.primary : scheme.onSurface,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.label, style: text.titleMedium),
                Text(
                  usedBy != null
                      ? 'Used by $usedBy'
                      : (yours ? 'Added by you' : 'Not used yet'),
                  style: text.bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          if (edited)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.xs),
              child: Chip(
                label: const Text('Edited'),
                visualDensity: VisualDensity.compact,
                backgroundColor: scheme.primaryContainer,
                labelStyle: text.labelMedium
                    ?.copyWith(color: scheme.onPrimaryContainer),
                side: BorderSide.none,
              ),
            ),
          if (yours)
            PopupMenuButton<String>(
              tooltip: 'More actions',
              onSelected: (v) {
                if (v == 'delete') _delete(item);
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'delete', child: Text('Delete icon')),
              ],
            )
          else
            Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
        ],
      ),
    );
  }
}
