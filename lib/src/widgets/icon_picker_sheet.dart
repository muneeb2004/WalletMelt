import 'package:flutter/material.dart';

import '../components/category/category_icon.dart';
import '../services/svg/svg_customization_service.dart';
import '../services/svg/svg_upload.dart';
import '../theme/wallet_melt_theme.dart';

/// Opens the icon picker and returns the chosen icon id (a bank icon id,
/// `emoji:<glyph>` or `custom:<file>.svg`), or null when dismissed.
///
/// [current] is highlighted. [suggestFor] is usually the category name; icons
/// that match it are offered first.
Future<String?> showIconPicker(
  BuildContext context, {
  String? current,
  String? suggestFor,
  Color? accent,
}) {
  return showAppBottomSheet<String>(
    context,
    builder: (_) => _IconPickerSheet(
      current: current,
      suggestFor: suggestFor,
      accent: accent,
    ),
  );
}

enum _Tab { icons, emoji, mine }

class _IconPickerSheet extends StatefulWidget {
  const _IconPickerSheet({this.current, this.suggestFor, this.accent});

  final String? current;
  final String? suggestFor;
  final Color? accent;

  @override
  State<_IconPickerSheet> createState() => _IconPickerSheetState();
}

class _IconPickerSheetState extends State<_IconPickerSheet> {
  final TextEditingController _search = TextEditingController();
  _Tab _tab = _Tab.icons;
  List<SvgIconItem> _mine = const [];
  bool _uploading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMine();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _loadMine() async {
    final list = await SvgCustomizationService.instance.listCustomIcons();
    if (mounted) setState(() => _mine = list);
  }

  Future<void> _upload() async {
    setState(() {
      _uploading = true;
      _error = null;
    });
    final result = await pickAndSaveSvg();
    if (!mounted) return;
    if (result.iconId != null) {
      Navigator.of(context).pop(result.iconId);
      return;
    }
    setState(() {
      _uploading = false;
      _error = result.error;
    });
  }

  /// Words from the category name that should surface matching icons first.
  List<CategoryPreset> _suggestions() {
    final name = (widget.suggestFor ?? '').toLowerCase();
    final words = name
        .split(RegExp(r'[^a-z]+'))
        .where((w) => w.length >= 3)
        .toList();
    if (words.isEmpty) return const [];
    return pickerCatalog
        .where((p) => words.any(p.matches))
        .take(8)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = context.scheme;
    final media = MediaQuery.of(context);
    // The sheet wrapper already lifts content above the keyboard, so only the
    // space that is left may be used.
    final height = (media.size.height * 0.82)
        .clamp(0.0, media.size.height - media.viewInsets.bottom - 96)
        .toDouble();
    final query = _search.text;

    return SizedBox(
      height: height,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Choose an icon', style: text.titleLarge),
            const SizedBox(height: AppSpacing.smMd),
            SegmentedButton<_Tab>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: _Tab.icons, label: Text('Icons')),
                ButtonSegment(value: _Tab.emoji, label: Text('Emoji')),
                ButtonSegment(value: _Tab.mine, label: Text('Yours')),
              ],
              selected: {_tab},
              onSelectionChanged: (s) => setState(() {
                _tab = s.first;
                _error = null;
              }),
            ),
            const SizedBox(height: AppSpacing.smMd),
            if (_tab != _Tab.mine)
              TextField(
                controller: _search,
                onChanged: (_) => setState(() {}),
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: _tab == _Tab.icons
                      ? 'Search icons, e.g. food or fuel'
                      : 'Search emoji, e.g. pizza',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: query.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear search',
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => setState(_search.clear),
                        ),
                ),
              ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: Text(_error!,
                    style: text.bodySmall?.copyWith(color: scheme.error)),
              ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: switch (_tab) {
                _Tab.icons => _buildIcons(context, query),
                _Tab.emoji => _buildEmoji(context, query),
                _Tab.mine => _buildMine(context),
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            _uploadButton(),
          ],
        ),
      ),
    );
  }

  bool _isCurrent(String id) {
    final cur = widget.current;
    if (cur == null) return false;
    return canonicalIconId(cur) == canonicalIconId(id);
  }

  Widget _cell({
    required String id,
    required String label,
    required Widget child,
  }) {
    final scheme = context.scheme;
    final selected = _isCurrent(id);
    final accent = widget.accent ?? scheme.primary;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: Tooltip(
        message: label,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          onTap: () => Navigator.of(context).pop(id),
          child: Ink(
            decoration: BoxDecoration(
              color: selected
                  ? accent.withValues(alpha: 0.16)
                  : scheme.surfaceContainer,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              border: Border.all(
                color: selected ? accent : scheme.outlineVariant,
                width: selected ? 2 : 1,
              ),
            ),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }

  static const SliverGridDelegate _grid = SliverGridDelegateWithMaxCrossAxisExtent(
    maxCrossAxisExtent: 64,
    mainAxisSpacing: AppSpacing.sm,
    crossAxisSpacing: AppSpacing.sm,
  );

  Widget _iconCell(CategoryPreset p) {
    final selected = _isCurrent(p.id);
    return _cell(
      id: p.id,
      label: p.label,
      child: CategoryIcon(
        icon: p.id,
        size: 28,
        color: selected ? (widget.accent ?? context.scheme.primary) : null,
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(
          top: AppSpacing.smMd, bottom: AppSpacing.sm),
      child: Text(title, style: Theme.of(context).textTheme.titleSmall),
    );
  }

  Widget _buildIcons(BuildContext context, String query) {
    final slivers = <Widget>[];
    void section(String title, List<CategoryPreset> items) {
      if (items.isEmpty) return;
      slivers.add(SliverToBoxAdapter(child: _sectionTitle(title)));
      slivers.add(SliverGrid.builder(
        gridDelegate: _grid,
        itemCount: items.length,
        itemBuilder: (_, i) => _iconCell(items[i]),
      ));
    }

    if (query.trim().isEmpty) {
      section('Suggested for you', _suggestions());
      for (final group in iconGroups) {
        section(group, [
          for (final p in pickerCatalog)
            if (p.group == group) p
        ]);
      }
    } else {
      final hits = [
        for (final p in pickerCatalog)
          if (p.matches(query)) p
      ];
      if (hits.isEmpty) {
        return _empty('No icons match "${query.trim()}"',
            'Try another word, or upload your own.');
      }
      section('Results', hits);
    }
    return CustomScrollView(slivers: slivers);
  }

  Widget _buildEmoji(BuildContext context, String query) {
    final hits = [
      for (final e in emojiChoices)
        if (e.matches(query)) e
    ];
    if (hits.isEmpty) {
      return _empty('No emoji match "${query.trim()}"', 'Try another word.');
    }
    return GridView.builder(
      gridDelegate: _grid,
      itemCount: hits.length,
      itemBuilder: (_, i) => _cell(
        id: hits[i].id,
        label: hits[i].label,
        child: CategoryIcon(icon: hits[i].id, size: 30),
      ),
    );
  }

  Widget _buildMine(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return ListView(
      children: [
        if (_mine.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
            child: Text(
              'Icons you upload show up here, ready to use on any category. '
              'Any SVG file works.',
              style: text.bodyMedium
                  ?.copyWith(color: context.scheme.onSurfaceVariant),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: _grid,
            itemCount: _mine.length,
            itemBuilder: (_, i) => _cell(
              id: _mine[i].id,
              label: _mine[i].label,
              child: CategoryIcon(icon: _mine[i].id, size: 28),
            ),
          ),
      ],
    );
  }

  Widget _uploadButton() {
    return OutlinedButton.icon(
      onPressed: _uploading ? null : _upload,
      icon: _uploading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.upload_file_rounded),
      label: const Text('Upload your own SVG'),
    );
  }

  Widget _empty(String title, String body) {
    final text = Theme.of(context).textTheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off_rounded,
              size: 40, color: context.scheme.onSurfaceVariant),
          const SizedBox(height: AppSpacing.sm),
          Text(title, style: text.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(body,
              style: text.bodyMedium
                  ?.copyWith(color: context.scheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}
