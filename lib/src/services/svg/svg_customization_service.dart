import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../components/category/category_icon.dart';
import 'svg_safeguard_service.dart';

enum SvgIconType {
  standard,
  preset,
  custom,
}

class SvgIconItem {
  const SvgIconItem({
    required this.id,
    required this.label,
    required this.type,
    this.assetPath,
    this.isCustomized = false,
  });

  final String id;
  final String label;
  final SvgIconType type;
  final String? assetPath;
  final bool isCustomized;

  SvgIconItem copyWith({bool? isCustomized}) {
    return SvgIconItem(
      id: id,
      label: label,
      type: type,
      assetPath: assetPath,
      isCustomized: isCustomized ?? this.isCustomized,
    );
  }
}

/// Manages SVG customizations and overrides across the application.
///
/// Ensures any edits to standard category icons, preset icons, or custom
/// uploaded icons are persisted to disk and broadcasted immediately to all
/// [CategoryIcon] instances across the board.
class SvgCustomizationService extends ChangeNotifier {
  SvgCustomizationService._();

  static final SvgCustomizationService instance = SvgCustomizationService._();

  final SvgSafeguardService _safeguard = const SvgSafeguardService();
  final Map<String, String> _overrideCache = {};
  bool _isInitialized = false;
  Future<void>? _initializing;
  String? _docsPath;

  /// Visible for testing to configure base directory or mock state
  @visibleForTesting
  void setBaseDirForTesting(String path) {
    _docsPath = path;
    _isInitialized = false;
    _initializing = null;
    _overrideCache.clear();
  }

  /// Visible for testing to reset singleton state
  @visibleForTesting
  void resetForTesting() {
    _overrideCache.clear();
    _isInitialized = false;
    _initializing = null;
    _docsPath = null;
  }

  Future<String> _getDocsPath() async {
    if (_docsPath != null) return _docsPath!;
    final dir = await getApplicationDocumentsDirectory();
    _docsPath = dir.path;
    return _docsPath!;
  }

  Future<Directory> _getOverridesDir() async {
    final docsPath = await _getDocsPath();
    final dir = Directory(p.join(docsPath, 'custom_icons', 'overrides'));
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    return dir;
  }

  Future<Directory> _getCustomIconsDir() async {
    final docsPath = await _getDocsPath();
    final dir = Directory(p.join(docsPath, 'custom_icons'));
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    return dir;
  }

  /// Initializes the service and populates memory cache with existing overrides.
  ///
  /// Must complete before the first [CategoryIcon] renders, otherwise edited
  /// icons show their stock artwork until the manager screen is opened. Safe
  /// to call repeatedly and concurrently.
  Future<void> initialize() {
    if (_isInitialized) return Future.value();
    return _initializing ??= _loadOverrides().whenComplete(() {
      _initializing = null;
    });
  }

  Future<void> _loadOverrides() async {
    try {
      final overridesDir = await _getOverridesDir();
      for (final entity in overridesDir.listSync()) {
        if (entity is File && entity.path.endsWith('.svg')) {
          final key = p.basenameWithoutExtension(entity.path);
          final content = entity.readAsStringSync();
          if (content.isEmpty) continue;
          // Re-validate so stale overrides (for example ones saved without an
          // xmlns declaration) are healed rather than rendered broken.
          final result = _safeguard.validate(content);
          if (result.isValid && result.sanitizedContent != null) {
            _overrideCache[key] = result.sanitizedContent!;
          }
        }
      }
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('SvgCustomizationService init error: $e');
    }
  }

  /// Normalizes icon id into a filesystem-safe override key.
  String normalizeKey(String raw) {
    final trimmed = raw.trim();
    if (trimmed.startsWith('custom:')) {
      return p.basenameWithoutExtension(trimmed.substring('custom:'.length));
    }
    if (trimmed.startsWith('preset:')) {
      return trimmed.substring('preset:'.length);
    }
    final lower = trimmed.toLowerCase();
    // Default categories store Material-style aliases ('bolt', 'wifi', ...).
    // They share one override with the built-in icon the manager edits.
    return _standardAliases[lower] ?? lower;
  }

  static const Map<String, String> _standardAliases = {
    'bolt': 'electricity',
    'local_fire_department': 'gas',
    'shopping_basket': 'grocery',
    'wifi': 'internet',
    'water_drop': 'water',
    'home': 'rent',
    'build': 'maintenance',
    'local_gas_station': 'fuel',
    'more_horiz': 'other',
  };

  /// Synchronously gets overridden SVG XML if cached in memory.
  String? getOverrideSync(String rawId) {
    final key = normalizeKey(rawId);
    return _overrideCache[key];
  }

  /// Checks if an icon has an active override on disk/cache.
  bool isCustomized(String rawId) {
    final key = normalizeKey(rawId);
    return _overrideCache.containsKey(key);
  }

  /// Loads the full SVG string for any icon ID:
  /// 1. Checks active override first.
  /// 2. If custom uploaded SVG, reads file from `custom_icons/`.
  /// 3. If preset SVG, reads from asset bundle.
  /// 4. If standard SVG, reads from asset bundle.
  /// 5. Returns null if unknown.
  Future<String?> loadSvgContent(String rawId) async {
    final key = normalizeKey(rawId);

    // 1. Check override
    if (_overrideCache.containsKey(key)) {
      return _overrideCache[key];
    }

    final overridesDir = await _getOverridesDir();
    final overrideFile = File(p.join(overridesDir.path, '$key.svg'));
    if (overrideFile.existsSync()) {
      final content = overrideFile.readAsStringSync();
      if (content.isNotEmpty) {
        _overrideCache[key] = content;
        return content;
      }
    }

    // 2. Custom icon check
    if (rawId.trim().startsWith('custom:')) {
      final filename = p.basename(rawId.trim().substring('custom:'.length));
      final customDir = await _getCustomIconsDir();
      final file = File(p.join(customDir.path, filename));
      if (file.existsSync()) {
        return file.readAsStringSync();
      }
      return null;
    }

    // 3. Preset icon check
    final preset = categoryPresets.cast<CategoryPreset?>().firstWhere(
          (p) => p?.id == key,
          orElse: () => null,
        );
    if (preset != null) {
      try {
        return await rootBundle.loadString(preset.assetPath);
      } catch (_) {
        return null;
      }
    }

    // 4. Standard category icon check
    final standardAsset = standardCategorySvgMap[key];
    if (standardAsset != null) {
      try {
        return await rootBundle.loadString(standardAsset);
      } catch (_) {
        return null;
      }
    }

    return null;
  }

  /// Saves an edited SVG string as an active override for [rawId].
  ///
  /// Validates and sanitizes the content via [SvgSafeguardService].
  /// Throws [FormatException] if validation fails.
  /// Immediately broadcasts update to listeners so all widgets reflect the edit.
  Future<void> saveOverride({
    required String rawId,
    required String svgContent,
  }) async {
    final val = _safeguard.validate(svgContent);
    if (!val.isValid || val.sanitizedContent == null) {
      throw FormatException(val.errorMessage ?? 'Invalid SVG markup');
    }

    final sanitized = val.sanitizedContent!;
    final key = normalizeKey(rawId);

    // If it's a custom icon, also update the main custom icon file directly
    if (rawId.trim().startsWith('custom:')) {
      final filename = p.basename(rawId.trim().substring('custom:'.length));
      final customDir = await _getCustomIconsDir();
      final file = File(p.join(customDir.path, filename));
      file.writeAsStringSync(sanitized, flush: true);
    }

    // Write to overrides
    final overridesDir = await _getOverridesDir();
    final overrideFile = File(p.join(overridesDir.path, '$key.svg'));
    overrideFile.writeAsStringSync(sanitized, flush: true);

    _overrideCache[key] = sanitized;
    notifyListeners();
  }

  /// Saves [svgContent] as a brand-new custom icon and returns its id
  /// (`custom:<file>.svg`). Used to keep a modified copy of a built-in icon
  /// without touching the original.
  ///
  /// Throws [FormatException] if validation fails.
  Future<String> createCustomIcon(String svgContent) async {
    final val = _safeguard.validate(svgContent);
    if (!val.isValid || val.sanitizedContent == null) {
      throw FormatException(val.errorMessage ?? 'Invalid SVG markup');
    }
    final base = Directory(await _getDocsPath());
    final id = await _safeguard.saveCustomSvg(
      sanitizedSvg: val.sanitizedContent!,
      baseDir: base,
    );
    notifyListeners();
    return id;
  }

  /// Reverts an overridden SVG back to its original built-in asset.
  Future<void> resetToDefault(String rawId) async {
    final key = normalizeKey(rawId);
    final overridesDir = await _getOverridesDir();
    final overrideFile = File(p.join(overridesDir.path, '$key.svg'));
    if (overrideFile.existsSync()) {
      overrideFile.deleteSync();
    }
    _overrideCache.remove(key);
    notifyListeners();
  }

  /// Lists all standard, preset, and custom SVGs with customization status.
  Future<List<SvgIconItem>> listAllIcons() async {
    await initialize();
    final list = <SvgIconItem>[];

    // Standard Category Icons
    const standardDisplayNames = {
      'electricity': 'Electricity / Power',
      'gas': 'Gas / Utility',
      'grocery': 'Grocery / Mart',
      'internet': 'Internet / WiFi',
      'water': 'Water / Utility',
      'rent': 'Rent / Housing',
      'maintenance': 'Maintenance / Repair',
      'fuel': 'Fuel / Gas Station',
      'other': 'Other / General',
    };

    standardDisplayNames.forEach((id, label) {
      final key = normalizeKey(id);
      list.add(
        SvgIconItem(
          id: id,
          label: label,
          type: SvgIconType.standard,
          assetPath: standardCategorySvgMap[id],
          isCustomized: _overrideCache.containsKey(key),
        ),
      );
    });

    // Preset Icons
    for (final preset in categoryPresets) {
      final key = normalizeKey(preset.id);
      list.add(
        SvgIconItem(
          id: preset.id,
          label: preset.label,
          type: SvgIconType.preset,
          assetPath: preset.assetPath,
          isCustomized: _overrideCache.containsKey(key),
        ),
      );
    }

    // Custom Uploaded Icons
    try {
      final customDir = await _getCustomIconsDir();
      if (customDir.existsSync()) {
        final files = customDir.listSync();
        int customIndex = 1;
        for (final entity in files) {
          if (entity is File && entity.path.endsWith('.svg')) {
            final filename = p.basename(entity.path);
            final key = p.basenameWithoutExtension(filename);
            list.add(
              SvgIconItem(
                id: 'custom:$filename',
                label: 'Custom SVG $customIndex',
                type: SvgIconType.custom,
                isCustomized: _overrideCache.containsKey(key),
              ),
            );
            customIndex++;
          }
        }
      }
    } catch (_) {}

    return list;
  }
}
