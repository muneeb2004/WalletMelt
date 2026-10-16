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

class SvgEditorDialog extends StatefulWidget {
  const SvgEditorDialog({
    required this.iconItem,
    super.key,
  });

  final SvgIconItem iconItem;

  static Future<bool?> show(BuildContext context, SvgIconItem item) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SvgEditorDialog(iconItem: item),
    );
  }

  @override
  State<SvgEditorDialog> createState() => _SvgEditorDialogState();
}

class _SvgEditorDialogState extends State<SvgEditorDialog> {
  final TextEditingController _codeController = TextEditingController();
  final SvgSafeguardService _safeguard = const SvgSafeguardService();

  bool _isLoading = true;
  bool _isSaving = false;
  String? _validationError;
  String _currentSvgCode = '';
  Color? _selectedColorOverride;
  final List<String> _undo = [];
  final List<String> _redo = [];
  static const int _historyLimit = 50;

  final List<Color> _presetColors = const [
    Color(0xFF38BDF8), // Sky Blue
    Color(0xFF34D399), // Emerald Green
    Color(0xFFFBBF24), // Amber
    Color(0xFFF87171), // Rose / Red
    Color(0xFFA78BFA), // Purple
    Color(0xFFFB923C), // Orange
    Color(0xFF2DD4BF), // Teal
    Color(0xFFF1F5F9), // Off White
  ];

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
    setState(() => _isLoading = true);
    final content = await SvgCustomizationService.instance
        .loadSvgContent(widget.iconItem.id);

    if (mounted) {
      setState(() {
        _currentSvgCode = content ?? _fallbackSvg(widget.iconItem.id);
        _codeController.text = _currentSvgCode;
        _isLoading = false;
        _validateCode(_currentSvgCode);
      });
    }
  }

  String _fallbackSvg(String id) {
    return '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24">'
        '<circle cx="12" cy="12" r="9" fill="none" stroke="currentColor" stroke-width="2"/>'
        '</svg>';
  }

  void _validateCode(String code) {
    final result = _safeguard.validate(code);
    setState(() {
      _validationError = result.isValid ? null : result.errorMessage;
      if (result.isValid) {
        _currentSvgCode = code;
      }
    });
  }

  void _applyColorToXml(Color color) {
    final hex =
        '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
    _applyOp((svg) => SvgEditOps.setColor(svg, hex));
    setState(() => _selectedColorOverride = color);
  }

  /// Applies [op] to the current markup and records an undo step. Does
  /// nothing while the markup is invalid.
  void _applyOp(String Function(String svg) op) {
    if (_validationError != null) return;
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

  Future<void> _saveAsNew() async {
    if (_validationError != null) return;
    setState(() => _isSaving = true);
    try {
      await SvgCustomizationService.instance
          .createCustomIcon(_codeController.text);
      if (!mounted) return;
      setState(() => _isSaving = false);
      showSuccessSnackbar(
          context, 'Saved as a new custom icon. The original is unchanged.');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _validationError = 'Save error: $e';
        _isSaving = false;
      });
    }
  }

  Future<void> _pickReplacementFile() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['svg'],
      );

      // ignore: unnecessary_null_comparison
      if (result != null && result.isNotEmpty) {
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
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _validationError = 'File import failed: $e');
    }
  }

  Future<void> _save() async {
    if (_validationError != null) return;
    setState(() => _isSaving = true);

    try {
      await SvgCustomizationService.instance.saveOverride(
        rawId: widget.iconItem.id,
        svgContent: _codeController.text,
      );
      if (mounted) {
        Navigator.of(context).pop(true);
        showSuccessSnackbar(context, 'SVG updated and applied across the board!');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _validationError = 'Save error: $e';
        _isSaving = false;
      });
    }
  }

  Future<void> _resetToDefault() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset to Default?'),
        content: Text(
          'This will remove custom modifications to "${widget.iconItem.label}" and restore the original icon.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: context.scheme.error,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await SvgCustomizationService.instance.resetToDefault(widget.iconItem.id);
      if (mounted) {
        Navigator.of(context).pop(true);
        showSuccessSnackbar(context, 'Reset to original SVG icon.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: BoxDecoration(
        color: context.scheme.surfaceContainer,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(
          color: context.scheme.outlineVariant,
          width: 1.0,
        ),
      ),
      child: _isLoading
          ? const SizedBox(
              height: 250,
              child: Center(child: CircularProgressIndicator()),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Drag Handle
                Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: context.scheme.onSurface.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.iconItem.label,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: context.scheme.onSurface.withValues(alpha: 0.06),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    widget.iconItem.type.name.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: context.scheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                                if (SvgCustomizationService.instance
                                    .isCustomized(widget.iconItem.id)) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: context.scheme.primary
                                          .withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'CUSTOMIZED',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: context.scheme.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Close',
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1),

                // Scrollable Content
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    children: [
                      // Multi-Scale Live Preview Panel
                      Text(
                        'LIVE PREVIEW (SCALED RENDERING)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: context.scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),

                      WMGlassSurface.tier1(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildPreviewScale(
                              size: 24,
                              label: '24px (Inline)',
                              isDark: isDark,
                            ),
                            _buildPreviewScale(
                              size: 40,
                              label: '40px (Tile)',
                              isDark: isDark,
                            ),
                            _buildPreviewScale(
                              size: 64,
                              label: '64px (Hero)',
                              isDark: isDark,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Quick Palette Selector
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'QUICK COLOR ACCENT',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              color: context.scheme.onSurfaceVariant,
                            ),
                          ),
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                            ),
                            icon: const Icon(Icons.upload_file_rounded, size: 16),
                            label: const Text('Replace SVG File', style: TextStyle(fontSize: 12)),
                            onPressed: _pickReplacementFile,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        height: 38,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _presetColors.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final color = _presetColors[index];
                            final isSelected = _selectedColorOverride == color;
                            return GestureDetector(
                              onTap: () => _applyColorToXml(color),
                              child: Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected
                                        ? (context.scheme.onSurface)
                                        : Colors.white.withValues(alpha: 0.3),
                                    width: isSelected ? 2.5 : 1.0,
                                  ),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: color.withValues(alpha: 0.4),
                                            blurRadius: 6,
                                          )
                                        ]
                                      : null,
                                ),
                                child: isSelected
                                    ? Icon(
                                        Icons.check_rounded,
                                        size: 18,
                                        color: color.computeLuminance() > 0.5
                                            ? Colors.black
                                            : Colors.white,
                                      )
                                    : null,
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 18),

                      const SizedBox(height: 16),

                      // Modify tools
                      Text(
                        'MODIFY',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: context.scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _toolChip(Icons.undo_rounded, 'Undo',
                              _undo.isEmpty ? null : _undoOp),
                          _toolChip(Icons.redo_rounded, 'Redo',
                              _redo.isEmpty ? null : _redoOp),
                          _toolChip(Icons.rotate_left_rounded, 'Rotate left',
                              () => _applyOp(SvgEditOps.rotateLeft)),
                          _toolChip(Icons.rotate_right_rounded, 'Rotate right',
                              () => _applyOp(SvgEditOps.rotateRight)),
                          _toolChip(Icons.flip_rounded, 'Flip horizontal',
                              () => _applyOp(SvgEditOps.flipHorizontal)),
                          _toolChip(Icons.flip_rounded, 'Flip vertical',
                              () => _applyOp(SvgEditOps.flipVertical),
                              turns: 0.25),
                          _toolChip(Icons.zoom_out_rounded, 'Smaller',
                              () => _applyOp((s) => SvgEditOps.zoom(s, 0.9))),
                          _toolChip(Icons.zoom_in_rounded, 'Larger',
                              () => _applyOp((s) => SvgEditOps.zoom(s, 1.1))),
                          _toolChip(
                            SvgEditOps.isFilled(_codeController.text)
                                ? Icons.crop_square_rounded
                                : Icons.square_rounded,
                            SvgEditOps.isFilled(_codeController.text)
                                ? 'Outline'
                                : 'Filled',
                            SvgEditOps.hasStroke(_codeController.text) ||
                                    !SvgEditOps.isFilled(_codeController.text)
                                ? () => _applyOp(SvgEditOps.toggleFilled)
                                : null,
                          ),
                          _toolChip(Icons.format_color_reset_rounded,
                              'Theme colour', () {
                            _applyOp(SvgEditOps.useThemeColor);
                            setState(() => _selectedColorOverride = null);
                          }),
                          _toolChip(
                            Icons.restart_alt_rounded,
                            'Reset position',
                            SvgEditOps.hasTransform(_codeController.text)
                                ? () => _applyOp(SvgEditOps.resetTransform)
                                : null,
                          ),
                        ],
                      ),
                      if (SvgEditOps.hasStroke(_codeController.text)) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Text(
                              'Line weight',
                              style: Theme.of(context).textTheme.labelMedium,
                            ),
                            Expanded(
                              child: Slider(
                                min: SvgEditOps.minStrokeWidth,
                                max: SvgEditOps.maxStrokeWidth,
                                divisions: 10,
                                label: (SvgEditOps.strokeWidthOf(
                                            _codeController.text) ??
                                        2)
                                    .toStringAsFixed(2),
                                value: (SvgEditOps.strokeWidthOf(
                                            _codeController.text) ??
                                        2)
                                    .clamp(SvgEditOps.minStrokeWidth,
                                        SvgEditOps.maxStrokeWidth)
                                    .toDouble(),
                                onChangeStart: (_) {
                                  if (_validationError == null) {
                                    _pushUndo(_codeController.text);
                                    _redo.clear();
                                  }
                                },
                                onChanged: (v) {
                                  if (_validationError != null) return;
                                  final next = SvgEditOps.setStrokeWidth(
                                      _codeController.text, v);
                                  _codeController.text = next;
                                  _validateCode(next);
                                },
                              ),
                            ),
                            SizedBox(
                              width: 36,
                              child: Text(
                                (SvgEditOps.strokeWidthOf(
                                            _codeController.text) ??
                                        2)
                                    .toStringAsFixed(2),
                                textAlign: TextAlign.end,
                                style: Theme.of(context).textTheme.labelMedium,
                              ),
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 16),

                      // Markup Code Editor
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'SVG MARKUP (XML EDITOR)',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              color: context.scheme.onSurfaceVariant,
                            ),
                          ),
                          if (_validationError == null)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle_rounded,
                                    size: 14, color: context.money.incomeText),
                                SizedBox(width: 4),
                                Text(
                                  'Valid SVG',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: context.money.incomeText,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      Container(
                        decoration: BoxDecoration(
                          color: context.scheme.surfaceContainer,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _validationError != null
                                ? context.scheme.error
                                : (context.scheme.outlineVariant),
                            width: 1.0,
                          ),
                        ),
                        child: TextField(
                          controller: _codeController,
                          maxLines: 8,
                          onChanged: _validateCode,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: context.scheme.onSurface,
                            height: 1.35,
                          ),
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.all(12),
                            border: InputBorder.none,
                            hintText: '<svg ...> ... </svg>',
                          ),
                        ),
                      ),

                      if (_validationError != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: context.scheme.error.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: context.scheme.error.withValues(alpha: 0.3),
                              width: 1.0,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.warning_amber_rounded,
                                  size: 16, color: context.scheme.error),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _validationError!,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: context.scheme.error,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const Divider(height: 1),

                // Bottom Action Buttons
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      if (SvgCustomizationService.instance
                          .isCustomized(widget.iconItem.id)) ...[
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: context.scheme.error,
                            side: BorderSide(
                              color: context.scheme.error.withValues(alpha: 0.5),
                            ),
                          ),
                          onPressed: _isSaving ? null : _resetToDefault,
                          child: const Text('Reset Default'),
                        ),
                        const SizedBox(width: 10),
                      ],
                      OutlinedButton(
                        onPressed: (_validationError != null || _isSaving)
                            ? null
                            : _saveAsNew,
                        child: const Text('Save as new'),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: context.scheme.primary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: (_validationError != null || _isSaving)
                              ? null
                              : _save,
                          child: _isSaving
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: context.scheme.onPrimary,
                                  ),
                                )
                              : Text(
                                  'Save & Reflect Everywhere',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                    color: context.scheme.onPrimary,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _toolChip(IconData icon, String label, VoidCallback? onPressed,
      {double turns = 0}) {
    return ActionChip(
      avatar: RotatedBox(
        quarterTurns: (turns * 4).round(),
        child: Icon(icon, size: 18),
      ),
      label: Text(label),
      onPressed: onPressed,
      tooltip: label,
    );
  }

  Widget _buildPreviewScale({
    required double size,
    required String label,
    required bool isDark,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size + 20,
          height: size + 20,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: context.scheme.surfaceContainer,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: context.scheme.outlineVariant,
              width: 0.8,
            ),
          ),
          child: _validationError != null
              ? Icon(Icons.broken_image_rounded, size: 20, color: context.scheme.onSurfaceVariant)
              : SvgPicture.string(
                  _currentSvgCode,
                  width: size,
                  height: size,
                  theme: SvgTheme(currentColor: context.scheme.onSurface),
                  placeholderBuilder: (_) =>
                      SizedBox(width: size, height: size),
                ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: context.scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
