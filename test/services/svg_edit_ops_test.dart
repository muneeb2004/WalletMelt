import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_melt/src/components/category/category_icon.dart';
import 'package:wallet_melt/src/services/svg/svg_customization_service.dart';
import 'package:wallet_melt/src/services/svg/svg_edit_ops.dart';
import 'package:wallet_melt/src/services/svg/svg_safeguard_service.dart';

const _outline =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24" '
    'fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round">'
    '<path d="M3 3h18v18H3z"/><circle cx="12" cy="12" r="4"/></svg>';

const _solid =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">'
    '<circle cx="12" cy="12" r="9" fill="#38BDF8"/></svg>';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const safeguard = SvgSafeguardService();

  group('SvgEditOps colour', () {
    test('setColor tints currentColor icons without touching fill none', () {
      final out = SvgEditOps.setColor(_outline, '#4B45C9');
      expect(out, contains('stroke="#4B45C9"'));
      expect(out, contains('fill="none"'));
      expect(out, isNot(contains('currentColor')));
    });

    test('setColor recolours hex-filled icons', () {
      final out = SvgEditOps.setColor(_solid, '#F59E0B');
      expect(out, contains('fill="#F59E0B"'));
      expect(out, isNot(contains('#38BDF8')));
    });

    test('useThemeColor restores currentColor', () {
      final tinted = SvgEditOps.setColor(_outline, '#4B45C9');
      expect(SvgEditOps.useThemeColor(tinted), contains('stroke="currentColor"'));
    });

    test('gradients are preserved', () {
      const g = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">'
          '<rect width="24" height="24" fill="url(#g)"/></svg>';
      expect(SvgEditOps.setColor(g, '#000000'), contains('url(#g)'));
    });
  });

  group('SvgEditOps line weight and fill', () {
    test('reads and sets stroke width within limits', () {
      expect(SvgEditOps.strokeWidthOf(_outline), 2);
      expect(SvgEditOps.strokeWidthOf(SvgEditOps.setStrokeWidth(_outline, 1.25)), 1.25);
      expect(SvgEditOps.strokeWidthOf(SvgEditOps.setStrokeWidth(_outline, 99)), SvgEditOps.maxStrokeWidth);
      expect(SvgEditOps.strokeWidthOf(SvgEditOps.setStrokeWidth(_outline, 0)), SvgEditOps.minStrokeWidth);
    });

    test('hasStroke distinguishes outline and solid icons', () {
      expect(SvgEditOps.hasStroke(_outline), isTrue);
      expect(SvgEditOps.hasStroke(_solid), isFalse);
    });

    test('toggleFilled switches outline to filled and back', () {
      expect(SvgEditOps.isFilled(_outline), isFalse);
      final filled = SvgEditOps.toggleFilled(_outline);
      expect(SvgEditOps.isFilled(filled), isTrue);
      expect(SvgEditOps.isFilled(SvgEditOps.toggleFilled(filled)), isFalse);
    });

    test('toggleFilled leaves fill-only glyphs unchanged', () {
      expect(SvgEditOps.toggleFilled(_solid), SvgEditOps.toggleFilled(_solid));
      expect(SvgEditOps.isFilled(SvgEditOps.toggleFilled(_solid)), isTrue);
    });
  });

  group('SvgEditOps geometry', () {
    test('operations compose onto a single transform group', () {
      var svg = SvgEditOps.rotateRight(_outline);
      svg = SvgEditOps.flipHorizontal(svg);
      svg = SvgEditOps.zoom(svg, 1.1);
      expect('id="${SvgEditOps.transformGroupId}"'.allMatches(svg).length, 1);
      expect(svg, contains('rotate(90 12 12)'));
      expect(svg, contains('scale(-1 1)'));
      expect(svg, contains('scale(1.1)'));
      expect(SvgEditOps.hasTransform(svg), isTrue);
    });

    test('newest operation is outermost', () {
      final svg = SvgEditOps.flipHorizontal(SvgEditOps.rotateRight(_outline));
      final t = RegExp(r'transform="([^"]+)"').firstMatch(svg)!.group(1)!;
      expect(t.indexOf('scale(-1 1)'), lessThan(t.indexOf('rotate(90 12 12)')));
    });

    test('resetTransform restores the original shapes', () {
      final edited = SvgEditOps.zoom(SvgEditOps.rotateLeft(_outline), 0.9);
      final reset = SvgEditOps.resetTransform(edited);
      expect(SvgEditOps.hasTransform(reset), isFalse);
      expect(reset, contains('<path d="M3 3h18v18H3z"'));
      expect(reset, contains('<circle cx="12" cy="12" r="4"'));
    });

    test('flip uses the viewBox centre', () {
      const wide = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 24">'
          '<path d="M0 0h10v10z"/></svg>';
      expect(SvgEditOps.flipHorizontal(wide), contains('translate(48 0)'));
      expect(SvgEditOps.flipVertical(wide), contains('translate(0 24)'));
    });

    test('invalid input is returned unchanged', () {
      expect(SvgEditOps.rotateRight('not svg'), 'not svg');
      expect(SvgEditOps.setColor('<html/>', '#000000'), '<html/>');
    });

    test('every edited result still passes the safeguard', () {
      var svg = _outline;
      svg = SvgEditOps.setColor(svg, '#4B45C9');
      svg = SvgEditOps.setStrokeWidth(svg, 1.5);
      svg = SvgEditOps.rotateRight(svg);
      svg = SvgEditOps.flipVertical(svg);
      svg = SvgEditOps.zoom(svg, 1.1);
      svg = SvgEditOps.toggleFilled(svg);
      expect(safeguard.validate(svg).isValid, isTrue);
    });
  });

  group('Default icon library', () {
    test('ids are unique and do not collide with standard icons', () {
      final ids = categoryPresets.map((p) => p.id).toList();
      expect(ids.toSet().length, ids.length);
      expect(ids.where(standardCategorySvgMap.containsKey), isEmpty);
      expect(ids.length, greaterThanOrEqualTo(40));
    });

    test('every preset file exists, is registered and passes the safeguard', () {
      final onDisk = Directory('assets/icons/categories/presets')
          .listSync()
          .whereType<File>()
          .map((f) => f.uri.pathSegments.last)
          .toSet();
      final registered =
          categoryPresets.map((p) => p.assetPath.split('/').last).toSet();
      expect(onDisk, registered);

      for (final preset in categoryPresets) {
        final svg = File(preset.assetPath).readAsStringSync();
        final result = safeguard.validate(svg);
        expect(result.isValid, isTrue, reason: preset.id);
        expect(SvgEditOps.hasStroke(svg), isTrue, reason: preset.id);
      }
    });

    testWidgets('every preset renders and survives every edit', (tester) async {
      final widgets = <Widget>[];
      for (final preset in categoryPresets) {
        final raw = await rootBundle.loadString(preset.assetPath);
        var edited = SvgEditOps.setColor(raw, '#4B45C9');
        edited = SvgEditOps.rotateRight(edited);
        edited = SvgEditOps.toggleFilled(edited);
        edited = SvgEditOps.setStrokeWidth(edited, 1.5);
        widgets.add(SvgPicture.string(raw, width: 24, height: 24));
        widgets.add(SvgPicture.string(edited, width: 24, height: 24));
      }
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: Wrap(children: widgets))),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  group('SvgCustomizationService.createCustomIcon', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('walletmelt_svg_copy_');
      SvgCustomizationService.instance.setBaseDirForTesting(tempDir.path);
    });

    tearDown(() async {
      SvgCustomizationService.instance.resetForTesting();
      if (await tempDir.exists()) await tempDir.delete(recursive: true);
    });

    test('saves a modified copy as a new custom icon and notifies', () async {
      final service = SvgCustomizationService.instance;
      var notified = false;
      service.addListener(() => notified = true);

      final id = await service.createCustomIcon(SvgEditOps.rotateRight(_outline));
      expect(id, startsWith('custom:'));
      expect(notified, isTrue);
      final loaded = await service.loadSvgContent(id);
      expect(loaded, contains('rotate(90 12 12)'));
    });

    test('editing a built-in icon also restyles its default-category alias', () async {
      final service = SvgCustomizationService.instance;
      await service.saveOverride(
        rawId: 'electricity',
        svgContent: SvgEditOps.setColor(_outline, '#F59E0B'),
      );
      // Default "Electricity" category stores the id 'bolt'.
      expect(service.isCustomized('bolt'), isTrue);
      expect(service.getOverrideSync('bolt'), contains('#F59E0B'));

      await service.saveOverride(rawId: 'wifi', svgContent: _outline);
      expect(service.isCustomized('internet'), isTrue);

      await service.resetToDefault('bolt');
      expect(service.isCustomized('electricity'), isFalse);
    });

    test('rejects invalid markup', () async {
      expect(
        () => SvgCustomizationService.instance.createCustomIcon('<svg><script/></svg>x'),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
