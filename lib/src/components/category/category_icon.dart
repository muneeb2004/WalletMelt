import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../services/svg/svg_customization_service.dart';
import '../../services/svg/svg_colour_info.dart';
import 'icon_catalog.dart';

export 'icon_catalog.dart';

const Map<String, String> _standardCategorySvgMap = standardCategorySvgMap;

class CategoryIcon extends StatelessWidget {
  const CategoryIcon({
    required this.icon,
    this.size = 20.0,
    this.color,
    this.defaultIcon = Icons.category_rounded,
    super.key,
  });

  final String? icon;
  final double size;
  final Color? color;
  final IconData defaultIcon;

  static String? _cachedDocsPath;

  static Future<String> _getDocsPath() async {
    if (_cachedDocsPath != null) return _cachedDocsPath!;
    final dir = await getApplicationDocumentsDirectory();
    _cachedDocsPath = dir.path;
    return _cachedDocsPath!;
  }

  @override
  Widget build(BuildContext context) {
    final raw = (icon ?? '').trim();
    if (raw.isEmpty) {
      return Icon(defaultIcon, size: size, color: color);
    }

    if (raw.startsWith(emojiPrefix)) {
      return SizedBox(
        width: size,
        height: size,
        child: FittedBox(
          fit: BoxFit.contain,
          child: Text(raw.substring(emojiPrefix.length)),
        ),
      );
    }

    final colorFilter = color != null
        ? ColorFilter.mode(color!, BlendMode.srcIn)
        : null;

    return ListenableBuilder(
      listenable: SvgCustomizationService.instance,
      builder: (context, _) {
        // 0. Check for customized override (reflects across the board)
        final overrideSvg = SvgCustomizationService.instance.getOverrideSync(raw);
        if (overrideSvg != null) {
          // Edited icons keep a tint the user baked in; only `currentColor`
          // artwork follows the surrounding colour. A blanket srcIn filter
          // would erase the user's colour edit everywhere.
          return SvgPicture.string(
            overrideSvg,
            width: size,
            height: size,
            theme: SvgTheme(
              currentColor: color ??
                  IconTheme.of(context).color ??
                  Theme.of(context).colorScheme.onSurface,
            ),
            placeholderBuilder: (_) => Icon(defaultIcon, size: size, color: color),
          );
        }

        // 1. Custom uploaded SVG
        if (raw.startsWith('custom:')) {
          final filename = p.basename(raw.substring('custom:'.length));
          if (_cachedDocsPath != null) {
            final file = File(p.join(_cachedDocsPath!, 'custom_icons', filename));
            return _buildFileSvg(file, colorFilter);
          }
          return FutureBuilder<String>(
            future: _getDocsPath(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return SizedBox(width: size, height: size);
              }
              final file = File(p.join(snapshot.data!, 'custom_icons', filename));
              return _buildFileSvg(file, colorFilter);
            },
          );
        }

        // Direct file path
        if (raw.endsWith('.svg') && (raw.contains('/') || raw.contains('\\'))) {
          final file = File(raw);
          return _buildFileSvg(file, colorFilter);
        }

        // 2. Preset custom SVG
        final preset = categoryPresets.cast<CategoryPreset?>().firstWhere(
              (p) => p?.id == raw || raw == 'preset:${p?.id}',
              orElse: () => null,
            );
        if (preset != null) {
          return SvgPicture.asset(
            preset.assetPath,
            width: size,
            height: size,
            colorFilter: colorFilter,
            placeholderBuilder: (_) => Icon(defaultIcon, size: size, color: color),
          );
        }

        // 3. Standard category SVG
        final standardAsset = _standardCategorySvgMap[raw.toLowerCase()];
        if (standardAsset != null) {
          return SvgPicture.asset(
            standardAsset,
            width: size,
            height: size,
            colorFilter: colorFilter,
            placeholderBuilder: (_) => Icon(defaultIcon, size: size, color: color),
          );
        }

        // 4. Legacy fallback to Material IconData
        return Icon(_legacyIconFor(raw), size: size, color: color);
      },
    );
  }

  static final Map<String, bool> _multicolour = {};

  /// Uploads with their own colours (two or more, or a gradient) keep them;
  /// single-colour uploads are tinted to follow the theme.
  static bool _keepsOwnColours(File file) {
    return _multicolour.putIfAbsent(file.path, () {
      try {
        return SvgColourInfo.isMulticolour(file.readAsStringSync());
      } catch (_) {
        return false;
      }
    });
  }

  Widget _buildFileSvg(File file, ColorFilter? colorFilter) {
    if (!file.existsSync()) {
      return Icon(defaultIcon, size: size, color: color);
    }
    return SvgPicture.file(
      file,
      width: size,
      height: size,
      colorFilter: _keepsOwnColours(file) ? null : colorFilter,
      placeholderBuilder: (_) => Icon(defaultIcon, size: size, color: color),
    );
  }

  IconData _legacyIconFor(String name) {
    return switch (name) {
      'bolt' || 'electricity' => Icons.bolt_rounded,
      'local_fire_department' || 'gas' => Icons.local_fire_department_rounded,
      'shopping_basket' || 'grocery' => Icons.shopping_basket_rounded,
      'wifi' || 'internet' => Icons.wifi_rounded,
      'water_drop' || 'water' => Icons.water_drop_rounded,
      'home' || 'rent' => Icons.home_rounded,
      'build' || 'maintenance' => Icons.build_rounded,
      'local_gas_station' || 'fuel' => Icons.local_gas_station_rounded,
      _ => defaultIcon,
    };
  }
}
