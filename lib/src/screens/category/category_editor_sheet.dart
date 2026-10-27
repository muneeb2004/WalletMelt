import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../components/category/category_icon.dart';
import '../../state/app_state.dart';
import '../../theme/wallet_melt_theme.dart';
import '../../types/category.dart' as wm;
import '../../widgets/color_picker_sheet.dart';
import '../../widgets/icon_picker_sheet.dart';
import '../../widgets/primary_button.dart';

/// Create a category ([existing] null) or edit one's name, icon and colour.
/// Returns the saved category, or null when dismissed.
Future<wm.Category?> showCategoryEditor(
  BuildContext context, {
  wm.Category? existing,
}) {
  return showAppBottomSheet<wm.Category>(
    context,
    builder: (_) => _CategoryEditor(existing: existing),
  );
}

class _CategoryEditor extends StatefulWidget {
  const _CategoryEditor({this.existing});

  final wm.Category? existing;

  @override
  State<_CategoryEditor> createState() => _CategoryEditorState();
}

class _CategoryEditorState extends State<_CategoryEditor> {
  static const List<String> _colors = [
    '#F4B740',
    '#E8805D',
    '#8FD6B5',
    '#7EA6C8',
    '#77C8D4',
    '#A88CC2',
  ];

  late final TextEditingController _name;
  late String _icon;
  late String _color;
  bool _saving = false;

  bool get _editing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _icon = e?.icon.trim().isNotEmpty == true ? e!.icon : 'food_dining';
    _color = e?.color ?? _colors.first;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _pickIcon() async {
    final picked = await showIconPicker(
      context,
      current: _icon,
      suggestFor: _name.text,
      accent: colorFromHex(_color),
    );
    if (picked != null && mounted) setState(() => _icon = picked);
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty || _saving) return;
    setState(() => _saving = true);
    final state = context.read<AppState>();
    final navigator = Navigator.of(context);
    wm.Category saved;
    final existing = widget.existing;
    if (existing == null) {
      saved = await state.addCategory(name: name, icon: _icon, color: _color);
    } else {
      await state.updateCategory(existing.id,
          name: name, icon: _icon, color: _color);
      saved = existing.copyWith(name: name, icon: _icon, color: _color);
    }
    if (navigator.mounted) navigator.pop(saved);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = context.scheme;
    final accent = colorFromHex(_color);
    final name = _name.text.trim();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_editing ? 'Edit category' : 'New category',
              style: text.titleLarge),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Semantics(
                button: true,
                label: 'Change icon',
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  onTap: _pickIcon,
                  child: Ink(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.16),
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusMd),
                      border: Border.all(color: accent.withValues(alpha: 0.5)),
                    ),
                    child: Center(
                      child: CategoryIcon(icon: _icon, size: 36, color: accent),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _name,
                      autofocus: !_editing,
                      textCapitalization: TextCapitalization.sentences,
                      decoration:
                          const InputDecoration(labelText: 'Category name'),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    TextButton.icon(
                      onPressed: _pickIcon,
                      icon: const Icon(Icons.grid_view_rounded),
                      label: const Text('Change icon'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Colour', style: text.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          WMColorPicker(
            selectedColor: _color,
            presetColors: _colors,
            onColorChanged: (c) => setState(() => _color = c),
          ),
          if (_editing && widget.existing!.isDefault)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.smMd),
              child: Text(
                'Built-in category. Its expenses and budgets stay linked '
                'when you change how it looks.',
                style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ),
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(
            label: _editing
                ? 'Save changes'
                : (name.isEmpty ? 'Create category' : 'Create "$name"'),
            onPressed: name.isEmpty || _saving ? null : _save,
          ),
        ],
      ),
    );
  }
}
