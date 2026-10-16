import 'package:xml/xml.dart';

/// Pure, side-effect free edit operations for SVG markup.
///
/// Every operation takes SVG text and returns new SVG text. If the input is
/// not parseable, or the operation does not apply, the input is returned
/// unchanged. Results still go through `SvgSafeguardService` before saving.
abstract final class SvgEditOps {
  SvgEditOps._();

  /// Id of the single `<g>` that holds geometric transforms (rotate, flip,
  /// zoom). Edits compose onto it instead of nesting new groups.
  static const String transformGroupId = 'wm-transform';

  static const double minStrokeWidth = 0.5;
  static const double maxStrokeWidth = 3.0;
  static const double minZoom = 0.5;
  static const double maxZoom = 1.6;

  // ── Colour ────────────────────────────────────────────────────────────────

  /// Paints every visible `fill` and `stroke` with [hex] (for example
  /// `#4B45C9`). Works on `currentColor` icons as well as hex-coloured ones.
  /// Gradients (`url(...)`) and `none` are left alone.
  static String setColor(String svg, String hex) =>
      _edit(svg, (root) {
        var touched = false;
        for (final e in _elements(root)) {
          for (final name in const ['fill', 'stroke']) {
            if (_isPaint(e.getAttribute(name))) {
              e.setAttribute(name, hex);
              touched = true;
            }
          }
        }
        if (!touched) root.setAttribute('fill', hex);
      });

  /// Restores `currentColor` so the icon follows the surrounding text colour.
  static String useThemeColor(String svg) => setColor(svg, 'currentColor');

  // ── Line weight and fill ──────────────────────────────────────────────────

  /// Whether any element draws a stroke.
  static bool hasStroke(String svg) {
    final root = _root(svg);
    if (root == null) return false;
    return _elements(root).any((e) => _isPaint(e.getAttribute('stroke')));
  }

  /// First `stroke-width` found, or null when the icon declares none.
  static double? strokeWidthOf(String svg) {
    final root = _root(svg);
    if (root == null) return null;
    for (final e in _elements(root)) {
      final v = double.tryParse(e.getAttribute('stroke-width') ?? '');
      if (v != null) return v;
    }
    return null;
  }

  /// Sets the line weight on every element that already declares one, or on
  /// the root when none does. Clamped to [minStrokeWidth]..[maxStrokeWidth].
  static String setStrokeWidth(String svg, double width) {
    final w = _fmt(width.clamp(minStrokeWidth, maxStrokeWidth).toDouble());
    return _edit(svg, (root) {
      var touched = false;
      for (final e in _elements(root)) {
        if (e.getAttribute('stroke-width') != null) {
          e.setAttribute('stroke-width', w);
          touched = true;
        }
      }
      if (!touched) root.setAttribute('stroke-width', w);
    });
  }

  /// True when the icon is drawn filled rather than as an outline.
  static bool isFilled(String svg) {
    final root = _root(svg);
    if (root == null) return false;
    final fill = root.getAttribute('fill');
    return fill == null || fill.toLowerCase() != 'none';
  }

  /// Switches between outline and filled. Only icons that have a stroke can be
  /// switched to outline; filled-only glyphs are returned unchanged.
  static String toggleFilled(String svg) => _edit(svg, (root) {
        if (isFilled(svg)) {
          if (!hasStroke(svg)) return;
          root.setAttribute('fill', 'none');
        } else {
          root.setAttribute('fill', 'currentColor');
          for (final e in _elements(root)) {
            if (e.getAttribute('fill')?.toLowerCase() == 'none') {
              e.removeAttribute('fill');
            }
          }
        }
      });

  // ── Geometry ──────────────────────────────────────────────────────────────

  static String rotateRight(String svg) => _transform(svg, (c) => 'rotate(90 ${_fmt(c.$1)} ${_fmt(c.$2)})');

  static String rotateLeft(String svg) => _transform(svg, (c) => 'rotate(-90 ${_fmt(c.$1)} ${_fmt(c.$2)})');

  static String flipHorizontal(String svg) =>
      _transform(svg, (c) => 'translate(${_fmt(c.$1 * 2)} 0) scale(-1 1)');

  static String flipVertical(String svg) =>
      _transform(svg, (c) => 'translate(0 ${_fmt(c.$2 * 2)}) scale(1 -1)');

  /// Multiplies the drawing size about the centre by [factor] (for example
  /// 1.1 grows it by 10%).
  static String zoom(String svg, double factor) => _transform(
        svg,
        (c) => 'translate(${_fmt(c.$1)} ${_fmt(c.$2)}) scale(${_fmt(factor)}) '
            'translate(${_fmt(-c.$1)} ${_fmt(-c.$2)})',
      );

  /// True once any rotate, flip or zoom has been applied.
  static bool hasTransform(String svg) {
    final root = _root(svg);
    return root != null && _group(root) != null;
  }

  /// Removes every rotate, flip and zoom, restoring the original geometry.
  static String resetTransform(String svg) => _edit(svg, (root) {
        final group = _group(root);
        if (group == null) return;
        final index = root.children.indexOf(group);
        final moved = List<XmlNode>.of(group.children);
        group.children.clear();
        root.children.removeAt(index);
        root.children.insertAll(index, moved);
      });

  // ── Internals ─────────────────────────────────────────────────────────────

  static String _transform(String svg, String Function((double, double)) op) =>
      _edit(svg, (root) {
        var group = _group(root);
        if (group == null) {
          group = XmlElement(XmlName('g'), [XmlAttribute(XmlName('id'), transformGroupId)]);
          final keep = <XmlNode>[];
          final move = <XmlNode>[];
          for (final child in root.children) {
            if (child is XmlElement && const {'defs', 'title', 'desc'}.contains(child.name.local)) {
              keep.add(child);
            } else {
              move.add(child);
            }
          }
          for (final node in List<XmlNode>.of(move)) {
            root.children.remove(node);
          }
          group.children.addAll(move);
          root.children.add(group);
        }
        final existing = group.getAttribute('transform') ?? '';
        final next = op(_center(root));
        // The newest operation is outermost, so it acts on the current look.
        group.setAttribute('transform', existing.isEmpty ? next : '$next $existing');
      });

  static XmlElement? _group(XmlElement root) {
    for (final child in root.childElements) {
      if (child.getAttribute('id') == transformGroupId) return child;
    }
    return null;
  }

  static (double, double) _center(XmlElement root) {
    final box = (root.getAttribute('viewBox') ?? '')
        .split(RegExp(r'[\s,]+'))
        .map(double.tryParse)
        .toList();
    if (box.length == 4 && box.every((v) => v != null)) {
      return (box[0]! + box[2]! / 2, box[1]! + box[3]! / 2);
    }
    final w = double.tryParse(root.getAttribute('width') ?? '') ?? 24;
    final h = double.tryParse(root.getAttribute('height') ?? '') ?? 24;
    return (w / 2, h / 2);
  }

  static bool _isPaint(String? value) {
    if (value == null) return false;
    final v = value.trim().toLowerCase();
    return v.isNotEmpty && v != 'none' && !v.startsWith('url(');
  }

  static Iterable<XmlElement> _elements(XmlElement root) sync* {
    yield root;
    yield* root.descendantElements;
  }

  static XmlElement? _root(String svg) {
    try {
      final root = XmlDocument.parse(svg).rootElement;
      return root.name.local.toLowerCase() == 'svg' ? root : null;
    } catch (_) {
      return null;
    }
  }

  static String _edit(String svg, void Function(XmlElement root) change) {
    try {
      final doc = XmlDocument.parse(svg);
      final root = doc.rootElement;
      if (root.name.local.toLowerCase() != 'svg') return svg;
      change(root);
      return doc.toXmlString();
    } catch (_) {
      return svg;
    }
  }

  static String _fmt(double v) {
    final s = v.toStringAsFixed(3);
    return s.contains('.') ? s.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '') : s;
  }
}
