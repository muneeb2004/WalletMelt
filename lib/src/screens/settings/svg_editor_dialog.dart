import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../services/svg/svg_customization_service.dart';
import '../../services/svg/svg_edit_ops.dart';
import '../../services/svg/svg_safeguard_service.dart';
import '../../theme/wallet_melt_theme.dart';
import '../../widgets/app_snackbar.dart';

/// What the editor hands back when it closes with a change.
class SvgEditorResult {
  const SvgEditorResult({this.changed = false, this.useIconId});

  /// An override was saved or removed for the edited icon.
  final bool changed;

  /// Id of a freshly saved copy the caller should apply (only set when the
  /// editor was opened from a category and the user chose to use the copy).
  final String? useIconId;
}

enum _Section { style, transform }

/// Full-height icon editor. Opens from the effective SVG (override or asset)
/// and saves either over the icon or as a new custom copy.
class SvgEditorDialog extends StatefulWidget {
  const SvgEditorDialog({
    required this.iconItem,
    this.usedBy,
    super.key,
  });

  final SvgIconItem iconItem;

  /// Name of the category (or categories) using this icon, shown under the
  /// title. When set the editor also offers "Use for this category" after
  /// saving a copy.
  final String? usedBy;

  static Future<SvgEditorResult?> show(
    BuildContext context,
    SvgIconItem item, {
    String? usedBy,
  }) {
    return Navigator.of(context).push<SvgEditorResult>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => SvgEditorDialog(iconItem: item, usedBy: usedBy),
      ),
    );
  }

  @override
  State<SvgEditorDialog> createState() => _SvgEditorDialogState();
}

class _SvgEditorDialogState extends State<SvgEditorDialog> {
  static const int _historyLimit = 50;
  static const String _fallbackSvg =
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24">'
      '<circle cx="12" cy="12" r="9" fill="none" stroke="currentColor" stroke-width="2"/>'
      '</svg>';

  final TextEditingController _codeController = TextEditingController();
  final SvgSafeguardService _safeguard = const SvgSafeguardService();
  final List<String> _undo = [];
  final List<String> _redo = [];

  bool _isLoading = true;
  bool _isSaving = false;
  bool _healed = false;
  String? _validationError;
  String _currentSvgCode = '';
  String _original = '';
  String? _selectedHex;
  _Section _section = _Section.style;

  bool get _isCustomized =>
      SvgCustomizationService.instance.isCustomized(widget.iconItem.id);
  bool get _dirty => _codeController.text != _original;
  bool get _valid => _validationError == null;

  @override
  void initState() {
    super.initState();
    _loadInitialContent();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialContent() async {
    final service = SvgCustomizationService.instance;
    var content = await service.loadSvgContent(widget.iconItem.id);
    var healed = false;
    if (content == null || !_safeguard.validate(content).isValid) {
      healed = content != null;
      // A broken override must never block editing: drop it and fall back
      // to the bundled asset.
      if (!widget.iconItem.id.startsWith('custom:') && _isCustomized) {
        await service.resetToDefault(widget.iconItem.id);
        content = await service.loadSvgContent(widget.iconItem.id);
      } else {
        content = null;
      }
      if (content == null || !_safeguard.validate(content).isValid) {
        content = _fallbackSvg;
      }
    }
    if (!mounted) return;
    setState(() {
      _original = content!;
      _currentSvgCode = content;
      _codeController.text = content;
      _healed = healed;
      _isLoading = false;
      _validationError = null;
    });
  }

  void _validateCode(String code) {
    final result = _safeguard.validate(code);
    setState(() {
      _validationError = result.isValid ? null : result.errorMessage;
      if (result.isValid) _currentSvgCode = code;
    });
  }

  String _hex(Color color) =>
      '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';

  void _applyColor(Color color) {
    final hex = _hex(color);
    _applyOp((svg) => SvgEditOps.setColor(svg, hex));
    setState(() => _selectedHex = hex);
  }

  void _applyOp(String Function(String svg) op) {
    if (!_valid) return;
    final before = _codeController.text;
    final after = op(before);
    if (after == before) return;
    _pushUndo(before);
    _redo.clear();
    _codeController.text = after;
    _validateCode(after);
  }

  void _pushUndo(String code) {
    _undo.add(code);
    if (_undo.length > _historyLimit) _undo.removeAt(0);
  }

  void _undoOp() {
    if (_undo.isEmpty) return;
    _redo.add(_codeController.text);
    final previous = _undo.removeLast();
    _codeController.text = previous;
    _validateCode(previous);
  }

  void _redoOp() {
    if (_redo.isEmpty) return;
    _pushUndo(_codeController.text);
    final next = _redo.removeLast();
    _codeController.text = next;
    _validateCode(next);
  }

  Future<void> _pickReplacementFile() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['svg'],
      );
      // ignore: unnecessary_null_comparison
      if (result == null || result.isEmpty) return;
      final file = result.first;
      String? content;
      final bytes = await file.readAsBytes();
      if (bytes.isNotEmpty) {
        content = utf8.decode(bytes);
      } else if (file.path != null) {
        content = await File(file.path!).readAsString();
      }
      if (content != null && content.isNotEmpty) {
        _pushUndo(_codeController.text);
        _redo.clear();
        _codeController.text = content;
        _validateCode(content);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _validationError = 'File import failed: $e');
    }
  }

  Future<void> _save() async {
    if (!_valid || _isSaving) return;
    setState(() => _isSaving = true);
    try {
      await SvgCustomizationService.instance.saveOverride(
        rawId: widget.iconItem.id,
        svgContent: _codeController.text,
      );
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      _original = _codeController.text;
      Navigator.of(context).pop(const SvgEditorResult(changed: true));
      messenger.showSnackBar(
          const SnackBar(content: Text('Icon updated everywhere it is used.')));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _validationError = 'Save error: $e';
        _isSaving = false;
      });
    }
  }

  Future<void> _saveAsCopy() async {
    if (!_valid || _isSaving) return;
    setState(() => _isSaving = true);
    try {
      final newId = await SvgCustomizationService.instance
          .createCustomIcon(_codeController.text);
      if (!mounted) return;
      setState(() => _isSaving = false);
      if (widget.usedBy == null) {
        showSuccessSnackbar(context, 'Saved as a new icon. The original is unchanged.');
        return;
      }
      final use = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Copy saved'),
          content: Text(
              'Use the new icon for ${widget.usedBy}? The original icon stays unchanged.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Keep editing'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Use for this category'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      if (use == true) {
        _original = _codeController.text;
        Navigator.of(context)
            .pop(SvgEditorResult(changed: true, useIconId: newId));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _validationError = 'Save error: $e';
        _isSaving = false;
      });
    }
  }

  Future<void> _resetToOriginal() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset to original?'),
        content: Text(
          'This removes your edits to "${widget.iconItem.label}" and restores the original icon.',
        ),
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
            child: const Text('Reset icon'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await SvgCustomizationService.instance.resetToDefault(widget.iconItem.id);
    if (!mounted) return;
    _original = _codeController.text;
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop(const SvgEditorResult(changed: true));
    messenger.showSnackBar(
        const SnackBar(content: Text('Icon reset to the original.')));
  }

  Future<void> _confirmDiscard() async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text('Your edits to this icon have not been saved.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Keep editing'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    if (discard == true && mounted) {
      _original = _codeController.text;
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    final text = Theme.of(context).textTheme;

    return PopScope(
      canPop: !_dirty || _isLoading,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmDiscard();
      },
      child: Scaffold(
        backgroundColor: scheme.surface,
        body: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(context),
                    const Divider(height: 1),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        children: [
                          _buildTitleBlock(context, text),
                          const SizedBox(height: AppSpacing.md),
                          _buildPreview(context, text),
                          const SizedBox(height: AppSpacing.md),
                          SegmentedButton<_Section>(
                            segments: const [
                              ButtonSegment(
                                value: _Section.style,
                                icon: Icon(Icons.palette_outlined),
                                label: Text('Style'),
                              ),
                              ButtonSegment(
                                value: _Section.transform,
                                icon: Icon(Icons.transform_rounded),
                                label: Text('Transform'),
                              ),
                            ],
                            selected: {_section},
                            onSelectionChanged: (s) =>
                                setState(() => _section = s.first),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          if (_section == _Section.style)
                            _buildStyle(context, text)
                          else
                            _buildTransform(context),
                          const SizedBox(height: AppSpacing.sm),
                          _buildAdvanced(context, text),
                          if (_validationError != null) _buildError(context, text),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final canSave = _valid && !_isSaving && (_dirty || _healed);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Close',
            icon: const Icon(Icons.close_rounded),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          Expanded(
            child: Text(
              'Edit icon',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          IconButton(
            tooltip: 'Undo',
            icon: const Icon(Icons.undo_rounded),
            onPressed: _undo.isEmpty ? null : _undoOp,
          ),
          IconButton(
            tooltip: 'Redo',
            icon: const Icon(Icons.redo_rounded),
            onPressed: _redo.isEmpty ? null : _redoOp,
          ),
          FilledButton(
            onPressed: canSave ? _save : null,
            child: _isSaving
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: context.scheme.onPrimary,
                    ),
                  )
                : const Text('Save'),
          ),
          PopupMenuButton<String>(
            tooltip: 'More actions',
            onSelected: (value) {
              switch (value) {
                case 'copy':
                  _saveAsCopy();
                case 'reset':
                  _resetToOriginal();
                case 'file':
                  _pickReplacementFile();
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'copy',
                enabled: _valid && !_isSaving,
                child: const Text('Save as copy'),
              ),
              if (_isCustomized)
                const PopupMenuItem(
                  value: 'reset',
                  child: Text('Reset to original'),
                ),
              const PopupMenuItem(
                value: 'file',
                child: Text('Replace from file'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTitleBlock(BuildContext context, TextTheme text) {
    final scheme = context.scheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                widget.iconItem.label,
                style: text.titleLarge,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (_isCustomized) ...[
              const SizedBox(width: AppSpacing.sm),
              Chip(
                label: const Text('Edited'),
                visualDensity: VisualDensity.compact,
                backgroundColor: scheme.primaryContainer,
                labelStyle:
                    text.labelMedium?.copyWith(color: scheme.onPrimaryContainer),
                side: BorderSide.none,
              ),
            ],
          ],
        ),
        if (widget.usedBy != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Text(
              'Used by: ${widget.usedBy}',
              style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
        if (_healed)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Text(
              'The saved edit was damaged, so the original icon was restored.',
              style: text.bodySmall?.copyWith(color: context.money.cautionText),
            ),
          ),
      ],
    );
  }

  Widget _svg(double size, Color tint) {
    if (!_valid) {
      return Icon(Icons.broken_image_rounded,
          size: size * 0.7, color: context.scheme.onSurfaceVariant);
    }
    return SvgPicture.string(
      _currentSvgCode,
      width: size,
      height: size,
      theme: SvgTheme(currentColor: tint),
      placeholderBuilder: (_) => SizedBox(width: size, height: size),
    );
  }

  Widget _buildPreview(BuildContext context, TextTheme text) {
    final scheme = context.scheme;
    final light = WMPalette.light;
    final dark = WMPalette.dark;
    return Semantics(
      label: 'Live preview',
      child: Column(
        children: [
          Container(
            height: 160,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: scheme.surfaceContainer,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              border: Border.all(color: scheme.outlineVariant),
            ),
            child: _svg(112, scheme.onSurface),
          ),
          const SizedBox(height: AppSpacing.smMd),
          Row(
            children: [
              Expanded(child: _tilePanel(context, text, 'Light', light)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: _tilePanel(context, text, 'Dark', dark)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tilePanel(
      BuildContext context, TextTheme text, String label, ColorScheme surface) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: surface.surfaceContainer,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: context.scheme.outlineVariant),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final size in const [24.0, 40.0, 64.0])
                _svg(size, surface.onSurface),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '$label · 24 / 40 / 64',
            style: text.labelSmall?.copyWith(color: surface.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildStyle(BuildContext context, TextTheme text) {
    final scheme = context.scheme;
    final money = context.money;
    final swatches = <(String, Color)>[
      ('Brand', scheme.primary),
      ('Secondary', scheme.secondary),
      ('Accent', scheme.tertiary),
      ('Income', money.income),
      ('Caution', money.caution),
      ('Over budget', money.over),
      ('Error', scheme.error),
      ('Text', scheme.onSurface),
    ];
    final svg = _codeController.text;
    final hasStroke = SvgEditOps.hasStroke(svg);
    final filled = SvgEditOps.isFilled(svg);
    final weight = (SvgEditOps.strokeWidthOf(svg) ?? 2)
        .clamp(SvgEditOps.minStrokeWidth, SvgEditOps.maxStrokeWidth)
        .toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Colour', style: text.titleSmall),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            for (final (name, color) in swatches)
              _swatch(context, name, color, _selectedHex == _hex(color)),
            Semantics(
              button: true,
              selected: _selectedHex == null,
              label: 'Theme colour',
              child: SizedBox(
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: _valid
                      ? () {
                          _applyOp(SvgEditOps.useThemeColor);
                          setState(() => _selectedHex = null);
                        }
                      : null,
                  icon: const Icon(Icons.format_color_reset_rounded),
                  label: const Text('Theme colour'),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Text('Fill', style: text.titleSmall),
        const SizedBox(height: AppSpacing.sm),
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: false, label: Text('Outline')),
            ButtonSegment(value: true, label: Text('Filled')),
          ],
          selected: {filled},
          onSelectionChanged: _valid && (hasStroke || !filled)
              ? (s) {
                  if (s.first != filled) _applyOp(SvgEditOps.toggleFilled);
                }
              : null,
        ),
        if (hasStroke) ...[
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Text('Line weight', style: text.titleSmall),
              const Spacer(),
              Text(weight.toStringAsFixed(2), style: text.labelLarge),
            ],
          ),
          Slider(
            min: SvgEditOps.minStrokeWidth,
            max: SvgEditOps.maxStrokeWidth,
            divisions: 10,
            label: weight.toStringAsFixed(2),
            value: weight,
            onChangeStart: (_) {
              if (_valid) {
                _pushUndo(_codeController.text);
                _redo.clear();
              }
            },
            onChanged: (v) {
              if (!_valid) return;
              final next = SvgEditOps.setStrokeWidth(_codeController.text, v);
              _codeController.text = next;
              _validateCode(next);
            },
          ),
        ],
      ],
    );
  }

  Widget _swatch(BuildContext context, String name, Color color, bool selected) {
    final scheme = context.scheme;
    final onSwatch = color.computeLuminance() > 0.5
        ? (scheme.surface.computeLuminance() < scheme.onSurface.computeLuminance()
            ? scheme.surface
            : scheme.onSurface)
        : (scheme.surface.computeLuminance() > scheme.onSurface.computeLuminance()
            ? scheme.surface
            : scheme.onSurface);
    return Semantics(
      button: true,
      selected: selected,
      label: '$name colour',
      child: InkResponse(
        onTap: _valid ? () => _applyColor(color) : null,
        radius: 24,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Center(
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? scheme.onSurface : scheme.outlineVariant,
                  width: selected ? 2.5 : 1,
                ),
              ),
              child: selected
                  ? Icon(Icons.check_rounded, size: 18, color: onSwatch)
                  : null,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTransform(BuildContext context) {
    final svg = _codeController.text;
    Widget tool(IconData icon, String label, VoidCallback? onPressed,
        {int quarterTurns = 0}) {
      return Semantics(
        button: true,
        label: label,
        excludeSemantics: true,
        enabled: onPressed != null,
        child: OutlinedButton.icon(
          style: OutlinedButton.styleFrom(minimumSize: const Size(48, 48)),
          onPressed: _valid ? onPressed : null,
          icon: RotatedBox(quarterTurns: quarterTurns, child: Icon(icon)),
          label: Text(label),
        ),
      );
    }

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        tool(Icons.rotate_left_rounded, 'Rotate left',
            () => _applyOp(SvgEditOps.rotateLeft)),
        tool(Icons.rotate_right_rounded, 'Rotate right',
            () => _applyOp(SvgEditOps.rotateRight)),
        tool(Icons.flip_rounded, 'Flip horizontal',
            () => _applyOp(SvgEditOps.flipHorizontal)),
        tool(Icons.flip_rounded, 'Flip vertical',
            () => _applyOp(SvgEditOps.flipVertical),
            quarterTurns: 1),
        tool(Icons.zoom_out_rounded, 'Smaller',
            () => _applyOp((s) => SvgEditOps.zoom(s, 0.9))),
        tool(Icons.zoom_in_rounded, 'Larger',
            () => _applyOp((s) => SvgEditOps.zoom(s, 1.1))),
        tool(
          Icons.restart_alt_rounded,
          'Reset position',
          SvgEditOps.hasTransform(svg)
              ? () => _applyOp(SvgEditOps.resetTransform)
              : null,
        ),
      ],
    );
  }

  Widget _buildAdvanced(BuildContext context, TextTheme text) {
    final scheme = context.scheme;
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        title: Row(
          children: [
            Text('Advanced', style: text.titleSmall),
            const SizedBox(width: AppSpacing.sm),
            Icon(
              _valid ? Icons.check_circle_rounded : Icons.error_rounded,
              size: 16,
              color: _valid ? context.money.incomeText : scheme.error,
            ),
          ],
        ),
        subtitle: const Text('SVG markup'),
        children: [
          Container(
            decoration: BoxDecoration(
              color: scheme.surfaceContainer,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              border: Border.all(
                  color: _valid ? scheme.outlineVariant : scheme.error),
            ),
            child: TextField(
              controller: _codeController,
              maxLines: 8,
              onChanged: _validateCode,
              style: text.bodySmall?.copyWith(fontFamily: 'monospace'),
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.all(AppSpacing.smMd),
                border: InputBorder.none,
                hintText: '<svg ...> ... </svg>',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context, TextTheme text) {
    final scheme = context.scheme;
    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.smMd),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: scheme.onErrorContainer),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              _validationError!,
              style: text.bodySmall?.copyWith(color: scheme.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}
