import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../services/svg/svg_customization_service.dart';

class CategoryPreset {
  const CategoryPreset({
    required this.id,
    required this.label,
    required this.assetPath,
  });

  final String id;
  final String label;
  final String assetPath;
}

const List<CategoryPreset> categoryPresets = [
  CategoryPreset(
    id: 'food_dining',
    label: 'Food & Dining',
    assetPath: 'assets/icons/categories/presets/food_dining.svg',
  ),
  CategoryPreset(
    id: 'shopping',
    label: 'Shopping',
    assetPath: 'assets/icons/categories/presets/shopping.svg',
  ),
  CategoryPreset(
    id: 'transport',
    label: 'Transport',
    assetPath: 'assets/icons/categories/presets/transport.svg',
  ),
  CategoryPreset(
    id: 'entertainment',
    label: 'Entertainment',
    assetPath: 'assets/icons/categories/presets/entertainment.svg',
  ),
  CategoryPreset(
    id: 'health',
    label: 'Health',
    assetPath: 'assets/icons/categories/presets/health.svg',
  ),
  CategoryPreset(
    id: 'education',
    label: 'Education',
    assetPath: 'assets/icons/categories/presets/education.svg',
  ),
  CategoryPreset(
    id: 'travel',
    label: 'Travel',
    assetPath: 'assets/icons/categories/presets/travel.svg',
  ),
  CategoryPreset(
    id: 'fitness',
    label: 'Fitness',
    assetPath: 'assets/icons/categories/presets/fitness.svg',
  ),
  CategoryPreset(
    id: 'gift',
    label: 'Gifts',
    assetPath: 'assets/icons/categories/presets/gift.svg',
  ),
  CategoryPreset(
    id: 'pets',
    label: 'Pets',
    assetPath: 'assets/icons/categories/presets/pets.svg',
  ),
  CategoryPreset(
    id: 'personal_care',
    label: 'Self Care',
    assetPath: 'assets/icons/categories/presets/personal_care.svg',
  ),
  CategoryPreset(
    id: 'savings',
    label: 'Savings',
    assetPath: 'assets/icons/categories/presets/savings.svg',
  ),
  CategoryPreset(
    id: 'coffee',
    label: 'Coffee & Tea',
    assetPath: 'assets/icons/categories/presets/coffee.svg',
  ),
  CategoryPreset(
    id: 'smartphone',
    label: 'Mobile & Data',
    assetPath: 'assets/icons/categories/presets/smartphone.svg',
  ),
  CategoryPreset(
    id: 'book',
    label: 'Books',
    assetPath: 'assets/icons/categories/presets/book.svg',
  ),
  CategoryPreset(
    id: 'pencil',
    label: 'Stationery',
    assetPath: 'assets/icons/categories/presets/pencil.svg',
  ),
  CategoryPreset(
    id: 'shirt',
    label: 'Clothing',
    assetPath: 'assets/icons/categories/presets/shirt.svg',
  ),
  CategoryPreset(
    id: 'pill',
    label: 'Medicine',
    assetPath: 'assets/icons/categories/presets/pill.svg',
  ),
  CategoryPreset(
    id: 'shield',
    label: 'Insurance',
    assetPath: 'assets/icons/categories/presets/shield.svg',
  ),
  CategoryPreset(
    id: 'repeat',
    label: 'Subscriptions',
    assetPath: 'assets/icons/categories/presets/repeat.svg',
  ),
  CategoryPreset(
    id: 'percent',
    label: 'Tax & Fees',
    assetPath: 'assets/icons/categories/presets/percent.svg',
  ),
  CategoryPreset(
    id: 'heart',
    label: 'Charity',
    assetPath: 'assets/icons/categories/presets/heart.svg',
  ),
  CategoryPreset(
    id: 'banknote',
    label: 'Cash',
    assetPath: 'assets/icons/categories/presets/banknote.svg',
  ),
  CategoryPreset(
    id: 'bicycle',
    label: 'Bike',
    assetPath: 'assets/icons/categories/presets/bicycle.svg',
  ),
  CategoryPreset(
    id: 'bus',
    label: 'Bus & Metro',
    assetPath: 'assets/icons/categories/presets/bus.svg',
  ),
  CategoryPreset(
    id: 'car',
    label: 'Ride & Taxi',
    assetPath: 'assets/icons/categories/presets/car.svg',
  ),
  CategoryPreset(
    id: 'plane',
    label: 'Flights',
    assetPath: 'assets/icons/categories/presets/plane.svg',
  ),
  CategoryPreset(
    id: 'bed',
    label: 'Hotel & Stay',
    assetPath: 'assets/icons/categories/presets/bed.svg',
  ),
  CategoryPreset(
    id: 'film',
    label: 'Movies',
    assetPath: 'assets/icons/categories/presets/film.svg',
  ),
  CategoryPreset(
    id: 'music',
    label: 'Music',
    assetPath: 'assets/icons/categories/presets/music.svg',
  ),
  CategoryPreset(
    id: 'gamepad',
    label: 'Games',
    assetPath: 'assets/icons/categories/presets/gamepad.svg',
  ),
  CategoryPreset(
    id: 'scissors',
    label: 'Haircut',
    assetPath: 'assets/icons/categories/presets/scissors.svg',
  ),
  CategoryPreset(
    id: 'landmark',
    label: 'Bank',
    assetPath: 'assets/icons/categories/presets/landmark.svg',
  ),
  CategoryPreset(
    id: 'credit_card',
    label: 'Cards',
    assetPath: 'assets/icons/categories/presets/credit_card.svg',
  ),
  CategoryPreset(
    id: 'wallet',
    label: 'Wallet',
    assetPath: 'assets/icons/categories/presets/wallet.svg',
  ),
  CategoryPreset(
    id: 'receipt',
    label: 'Bills',
    assetPath: 'assets/icons/categories/presets/receipt.svg',
  ),
  CategoryPreset(
    id: 'laptop',
    label: 'Tech',
    assetPath: 'assets/icons/categories/presets/laptop.svg',
  ),
  CategoryPreset(
    id: 'printer',
    label: 'Printing',
    assetPath: 'assets/icons/categories/presets/printer.svg',
  ),
  CategoryPreset(
    id: 'leaf',
    label: 'Garden',
    assetPath: 'assets/icons/categories/presets/leaf.svg',
  ),
  CategoryPreset(
    id: 'building',
    label: 'Hostel',
    assetPath: 'assets/icons/categories/presets/building.svg',
  ),
  CategoryPreset(
    id: 'baby',
    label: 'Kids',
    assetPath: 'assets/icons/categories/presets/baby.svg',
  ),
];

const Map<String, String> standardCategorySvgMap = {
  'electricity': 'assets/icons/categories/electricity.svg',
  'bolt': 'assets/icons/categories/electricity.svg',
  'gas': 'assets/icons/categories/gas.svg',
  'local_fire_department': 'assets/icons/categories/gas.svg',
  'grocery': 'assets/icons/categories/grocery.svg',
  'shopping_basket': 'assets/icons/categories/grocery.svg',
  'internet': 'assets/icons/categories/internet.svg',
  'wifi': 'assets/icons/categories/internet.svg',
  'water': 'assets/icons/categories/water.svg',
  'water_drop': 'assets/icons/categories/water.svg',
  'rent': 'assets/icons/categories/rent.svg',
  'home': 'assets/icons/categories/rent.svg',
  'maintenance': 'assets/icons/categories/maintenance.svg',
  'build': 'assets/icons/categories/maintenance.svg',
  'fuel': 'assets/icons/categories/fuel.svg',
  'local_gas_station': 'assets/icons/categories/fuel.svg',
  'other': 'assets/icons/categories/other.svg',
  'more_horiz': 'assets/icons/categories/other.svg',
};

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

  Widget _buildFileSvg(File file, ColorFilter? colorFilter) {
    if (!file.existsSync()) {
      return Icon(defaultIcon, size: size, color: color);
    }
    return SvgPicture.file(
      file,
      width: size,
      height: size,
      colorFilter: colorFilter,
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
