import 'package:flutter/material.dart';
import '../theme/wallet_melt_theme.dart';

/// Interactive color selector tool that allows picking preset colors,
/// adjusting an interactive hue/saturation slider, or entering custom hex codes.
class WMColorPicker extends StatefulWidget {
  const WMColorPicker({
    super.key,
    required this.selectedColor,
    required this.onColorChanged,
    this.presetColors = defaultPresets,
  });

  final String selectedColor;
  final ValueChanged<String> onColorChanged;
  final List<String> presetColors;

  static const List<String> defaultPresets = [
    '#8FD6B5',
    '#E85D75',
    '#F4B740',
    '#6C5CE7',
    '#4EA8DE',
    '#FF7675',
    '#A29BFE',
    '#55EFC4',
    '#FDCB6E',
    '#E17055',
    '#00B894',
    '#0984E3',
  ];

  @override
  State<WMColorPicker> createState() => _WMColorPickerState();
}

class _WMColorPickerState extends State<WMColorPicker> {
  late TextEditingController _hexController;
  late double _hue;
  late double _saturation;
  late double _value;
  bool _isCustomMode = false;

  @override
  void initState() {
    super.initState();
    _hexController = TextEditingController(text: widget.selectedColor);
    _syncHsvFromHex(widget.selectedColor);
  }

  @override
  void didUpdateWidget(WMColorPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedColor != widget.selectedColor) {
      if (_hexController.text.toUpperCase() != widget.selectedColor.toUpperCase()) {
        _hexController.text = widget.selectedColor;
      }
      _syncHsvFromHex(widget.selectedColor);
    }
  }

  @override
  void dispose() {
    _hexController.dispose();
    super.dispose();
  }

  void _syncHsvFromHex(String hex) {
    final color = colorFromHex(hex);
    final hsv = HSVColor.fromColor(color);
    _hue = hsv.hue;
    _saturation = hsv.saturation > 0.1 ? hsv.saturation : 0.75;
    _value = hsv.value > 0.1 ? hsv.value : 0.90;
  }

  void _onHsvUpdated() {
    final color = HSVColor.fromAHSV(1.0, _hue, _saturation, _value).toColor();
    final hex = hexFromColor(color);
    _hexController.text = hex;
    widget.onColorChanged(hex);
  }

  void _onHexSubmitted(String input) {
    final clean = input.replaceAll(' ', '').trim();
    if (clean.isEmpty) return;
    final color = colorFromHex(clean);
    final hex = hexFromColor(color);
    _syncHsvFromHex(hex);
    widget.onColorChanged(hex);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentColor = colorFromHex(widget.selectedColor);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Preset Palette Swatches
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final color in widget.presetColors)
              GestureDetector(
                onTap: () {
                  _hexController.text = color;
                  _syncHsvFromHex(color);
                  widget.onColorChanged(color);
                  setState(() => _isCustomMode = false);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: colorFromHex(color),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: widget.selectedColor.toUpperCase() == color.toUpperCase()
                          ? (isDark ? Colors.white : Colors.black)
                          : Colors.transparent,
                      width: 2.5,
                    ),
                    boxShadow: widget.selectedColor.toUpperCase() == color.toUpperCase()
                        ? [
                            BoxShadow(
                              color: colorFromHex(color).withValues(alpha: 0.45),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : const [],
                  ),
                  child: widget.selectedColor.toUpperCase() == color.toUpperCase()
                      ? const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 18,
                          shadows: [
                            Shadow(color: Colors.black45, blurRadius: 2, offset: Offset(0, 1)),
                          ],
                        )
                      : null,
                ),
              ),

            // Custom Color Toggle Pill Button
            GestureDetector(
              onTap: () => setState(() => _isCustomMode = !_isCustomMode),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 38,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(19),
                  color: _isCustomMode
                      ? currentColor.withValues(alpha: 0.18)
                      : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
                  border: Border.all(
                    color: _isCustomMode
                        ? currentColor
                        : (isDark ? Colors.white24 : Colors.black12),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.palette_rounded,
                      size: 16,
                      color: _isCustomMode ? currentColor : null,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _isCustomMode ? 'Custom' : 'Custom...',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _isCustomMode ? currentColor : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        // Interactive Color Slider & Hex Code Entry Tool
        if (_isCustomMode) ...[
          const SizedBox(height: 16),
          WMGlassSurface.tier2(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Live Color Preview Circle
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: currentColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark ? Colors.white38 : Colors.black26,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: currentColor.withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Hex Code Text Entry
                    Expanded(
                      child: TextField(
                        controller: _hexController,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Color Hex Code',
                          hintText: '#E85D75',
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          prefixIcon: const Icon(Icons.tag_rounded, size: 16),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                            tooltip: 'Apply hex',
                            onPressed: () => _onHexSubmitted(_hexController.text),
                          ),
                        ),
                        onChanged: (val) {
                          final clean = val.replaceAll('#', '').trim();
                          if (clean.length == 3 || clean.length == 6 || clean.length == 8) {
                            _onHexSubmitted(val);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Interactive Rainbow Hue Slider
                Text(
                  'HUE / COLOR TONE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: WalletMeltColors.textMuted,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  height: 14,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(7),
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFFF0000),
                        Color(0xFFFFFF00),
                        Color(0xFF00FF00),
                        Color(0xFF00FFFF),
                        Color(0xFF0000FF),
                        Color(0xFFFF00FF),
                        Color(0xFFFF0000),
                      ],
                    ),
                  ),
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 2,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
                  ),
                  child: Slider(
                    value: _hue,
                    min: 0,
                    max: 360,
                    onChanged: (newHue) {
                      setState(() {
                        _hue = newHue;
                        _onHsvUpdated();
                      });
                    },
                  ),
                ),

                // Brightness & Saturation Slider
                Text(
                  'SHADE & INTENSITY',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: WalletMeltColors.textMuted,
                  ),
                ),
                const SizedBox(height: 4),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                  ),
                  child: Slider(
                    value: _saturation,
                    min: 0.2,
                    max: 1.0,
                    activeColor: currentColor,
                    onChanged: (newSat) {
                      setState(() {
                        _saturation = newSat;
                        _onHsvUpdated();
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
