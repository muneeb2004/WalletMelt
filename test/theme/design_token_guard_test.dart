import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_melt/src/theme/wallet_melt_theme.dart';

/// Design-system guard (ADR-0010).
///
/// Raw colours and tiny fonts outside `lib/src/theme/` are legacy debt
/// (TD-010). The baselines below are a ratchet: lower them when you migrate
/// code, never raise them. New code must use `colorScheme`, `context.money`
/// and `textTheme`.
const int kRawColorBaseline = 69;
const int kSmallFontBaseline = 2;

final _rawColor = RegExp(r'Color\(\s*0x[0-9A-Fa-f]{6,8}\s*\)|Colors\.(?!transparent\b)\w+');
final _fontSize = RegExp(r'fontSize:\s*(\d+(?:\.\d+)?)');

Iterable<File> _dartFiles() sync* {
  final root = Directory('lib/src');
  for (final entity in root.listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    final path = entity.path.replaceAll('\\', '/');
    if (path.contains('/theme/')) continue;
    yield entity;
  }
}

String _stripComments(String source) => source
    .split('\n')
    .where((l) => !l.trimLeft().startsWith('//'))
    .join('\n');

void main() {
  test('raw colour literals outside theme/ never increase', () {
    var count = 0;
    for (final file in _dartFiles()) {
      count += _rawColor.allMatches(_stripComments(file.readAsStringSync())).length;
    }
    expect(count, lessThanOrEqualTo(kRawColorBaseline),
        reason: 'Use Theme.of(context).colorScheme / context.money instead of '
            'raw colours. Found $count, baseline $kRawColorBaseline.');
  });

  test('font sizes below 11 outside theme/ never increase', () {
    var count = 0;
    for (final file in _dartFiles()) {
      for (final m in _fontSize.allMatches(_stripComments(file.readAsStringSync()))) {
        if (double.parse(m.group(1)!) < WMType.captionSize) count++;
      }
    }
    expect(count, lessThanOrEqualTo(kSmallFontBaseline),
        reason: 'The type scale floor is ${WMType.captionSize}. '
            'Found $count, baseline $kSmallFontBaseline.');
  });

  test('type scale has exactly six distinct sizes', () {
    final scheme = WMPalette.light;
    final t = WMType.textTheme(scheme);
    final sizes = {
      t.displaySmall,
      t.headlineMedium,
      t.titleLarge,
      t.titleMedium,
      t.titleSmall,
      t.bodyLarge,
      t.bodyMedium,
      t.bodySmall,
      t.labelLarge,
      t.labelMedium,
      t.labelSmall,
    }.map((s) => s!.fontSize).toSet();
    expect(sizes, {34.0, 22.0, 17.0, 14.0, 12.0, 11.0});
  });

  test('brand is indigo and both modes use the same role set', () {
    expect(WMPalette.light.primary, const Color(0xFF4B45C9));
    expect(WMPalette.dark.surface, const Color(0xFF000000));
    final light = WalletMeltTheme.light();
    final dark = WalletMeltTheme.dark();
    expect(light.extension<WMMoneyColors>(), isNotNull);
    expect(dark.extension<WMMoneyColors>(), isNotNull);
    expect(light.colorScheme.primary, isNot(dark.colorScheme.primary));
  });

  test('status text colours meet 4.5:1 on their surfaces', () {
    double ratio(Color a, Color b) {
      final la = a.computeLuminance();
      final lb = b.computeLuminance();
      final hi = la > lb ? la : lb;
      final lo = la > lb ? lb : la;
      return (hi + 0.05) / (lo + 0.05);
    }

    for (final (money, scheme) in [
      (WMMoneyColors.light, WMPalette.light),
      (WMMoneyColors.dark, WMPalette.dark),
    ]) {
      for (final fg in [money.incomeText, money.cautionText, money.overText]) {
        expect(ratio(fg, scheme.surface), greaterThanOrEqualTo(4.5));
        expect(ratio(fg, scheme.surfaceContainer), greaterThanOrEqualTo(4.5));
        expect(ratio(fg, scheme.primaryContainer), greaterThanOrEqualTo(4.5));
      }
      expect(ratio(scheme.onSurfaceVariant, scheme.surface),
          greaterThanOrEqualTo(4.5));
      expect(ratio(scheme.primary, scheme.primaryContainer),
          greaterThanOrEqualTo(4.5));
    }
  });
}
