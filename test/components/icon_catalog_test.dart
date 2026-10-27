import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_melt/src/components/category/icon_catalog.dart';
import 'package:wallet_melt/src/services/svg/svg_safeguard_service.dart';

void main() {
  test('every catalog icon exists on disk and passes the SVG safeguard', () {
    const safeguard = SvgSafeguardService();
    for (final p in pickerCatalog) {
      final file = File(p.assetPath);
      expect(file.existsSync(), isTrue, reason: '${p.id}: ${p.assetPath}');
      final result = safeguard.validate(file.readAsStringSync());
      expect(result.isValid, isTrue,
          reason: '${p.id}: ${result.errorMessage}');
    }
  });

  test('ids are unique, grouped, and keep every legacy id', () {
    final ids = pickerCatalog.map((p) => p.id).toList();
    expect(ids.toSet().length, ids.length);
    for (final p in pickerCatalog) {
      expect(iconGroups, contains(p.group), reason: p.id);
    }
    for (final legacy in const [
      'food_dining', 'shopping', 'transport', 'entertainment', 'health',
      'education', 'travel', 'fitness', 'gift', 'pets', 'personal_care',
      'savings', 'coffee', 'smartphone', 'book', 'pencil', 'shirt', 'pill',
      'shield', 'repeat', 'percent', 'heart', 'banknote', 'bicycle', 'bus',
      'car', 'plane', 'bed', 'film', 'music', 'gamepad', 'scissors',
      'landmark', 'credit_card', 'wallet', 'receipt', 'laptop', 'printer',
      'leaf', 'building', 'baby',
    ]) {
      expect(ids, contains(legacy));
    }
  });

  test('search matches labels and keywords; aliases resolve to catalog ids',
      () {
    expect(pickerCatalog.where((p) => p.matches('food')).length,
        greaterThan(4));
    expect(pickerCatalog.where((p) => p.matches('petrol')).map((p) => p.id),
        contains('fuel'));
    expect(canonicalIconId('bolt'), 'electricity');
    expect(canonicalIconId('more_horiz'), 'other');
    expect(canonicalIconId('preset:pizza'), 'pizza');
    expect(emojiChoices.where((e) => e.matches('zakat')), isNotEmpty);
  });
}
