/// Tells whether an SVG carries its own colours, so it should be drawn as is
/// instead of being tinted to the surrounding icon colour.
abstract final class SvgColourInfo {
  static final RegExp _paint = RegExp(
    r'''(?:fill|stroke|stop-color|flood-color)\s*[:=]\s*["']?\s*([^;"'\s>/]+)''',
    caseSensitive: false,
  );
  static final RegExp _gradient =
      RegExp(r'<\s*(linearGradient|radialGradient|image)\b', caseSensitive: false);

  static const Set<String> _notAColour = {
    'none',
    'currentcolor',
    'transparent',
    'inherit',
    'context-fill',
    'context-stroke',
  };

  /// True when the markup uses two or more distinct fixed colours, or a
  /// gradient or embedded image. A single fixed colour (for example plain
  /// black) is not multicolour: those icons keep following the theme.
  static bool isMulticolour(String svg) {
    if (_gradient.hasMatch(svg)) return true;
    final colours = <String>{};
    for (final m in _paint.allMatches(svg)) {
      final v = m.group(1)!.toLowerCase();
      if (_notAColour.contains(v) || v.startsWith('url(')) continue;
      colours.add(_normalise(v));
      if (colours.length > 1) return true;
    }
    return false;
  }

  /// `#fff` and `#ffffff` are the same colour.
  static String _normalise(String v) {
    if (v.length == 4 && v.startsWith('#')) {
      return '#${v[1]}${v[1]}${v[2]}${v[2]}${v[3]}${v[3]}';
    }
    return v;
  }
}
