import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:wallet_melt/src/components/category/category_icon.dart';
import 'package:wallet_melt/src/services/svg/svg_customization_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('walletmelt_svg_test_');
    SvgCustomizationService.instance.setBaseDirForTesting(tempDir.path);
  });

  tearDown(() async {
    SvgCustomizationService.instance.resetForTesting();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('SvgCustomizationService - Unit Tests', () {
    test('normalizeKey normalizes different icon ID schemes', () {
      final service = SvgCustomizationService.instance;
      expect(service.normalizeKey('custom:uuid-1234.svg'), equals('uuid-1234'));
      expect(service.normalizeKey('preset:food_dining'), equals('food_dining'));
      expect(service.normalizeKey('Food_Dining'), equals('food_dining'));
      expect(service.normalizeKey('ELECTRICITY'), equals('electricity'));
    });

    test('saves valid SVG override and notifies listeners', () async {
      final service = SvgCustomizationService.instance;
      bool notified = false;
      service.addListener(() => notified = true);

      const testSvg =
          '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24">'
          '<circle cx="12" cy="12" r="10" fill="#38BDF8"/>'
          '</svg>';

      await service.saveOverride(rawId: 'electricity', svgContent: testSvg);

      expect(notified, isTrue);
      expect(service.isCustomized('electricity'), isTrue);
      expect(service.getOverrideSync('electricity'), contains('fill="#38BDF8"'));

      // Check on disk
      final diskFile =
          File(p.join(tempDir.path, 'custom_icons', 'overrides', 'electricity.svg'));
      expect(diskFile.existsSync(), isTrue);
    });

    test('rejects malicious or invalid SVG override', () async {
      final service = SvgCustomizationService.instance;
      const maliciousSvg =
          '<svg xmlns="http://www.w3.org/2000/svg"><script>alert("hack")</script></svg>';

      expect(
        () => service.saveOverride(rawId: 'food_dining', svgContent: maliciousSvg),
        throwsA(isA<FormatException>()),
      );
      expect(service.isCustomized('food_dining'), isFalse);
    });

    test('resetToDefault deletes override and notifies listeners', () async {
      final service = SvgCustomizationService.instance;
      const testSvg =
          '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><rect width="20" height="20"/></svg>';
      await service.saveOverride(rawId: 'gas', svgContent: testSvg);
      expect(service.isCustomized('gas'), isTrue);

      int notifyCount = 0;
      service.addListener(() => notifyCount++);

      await service.resetToDefault('gas');

      expect(service.isCustomized('gas'), isFalse);
      expect(service.getOverrideSync('gas'), isNull);
      expect(notifyCount, greaterThan(0));

      final diskFile =
          File(p.join(tempDir.path, 'custom_icons', 'overrides', 'gas.svg'));
      expect(diskFile.existsSync(), isFalse);
    });
  });

  group('CategoryIcon - Across-the-Board Override Reflection', () {
    testWidgets('CategoryIcon dynamically re-renders when override is saved and reverted',
        (tester) async {
      final service = SvgCustomizationService.instance;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CategoryIcon(
              icon: 'electricity',
              size: 32,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Initially renders standard asset
      expect(find.byType(CategoryIcon), findsOneWidget);

      // Now save a customized SVG override
      const customColorSvg =
          '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24">'
          '<path d="M12 2L2 22h20L12 2z" fill="#FF5722"/>'
          '</svg>';

      await service.saveOverride(rawId: 'electricity', svgContent: customColorSvg);

      // Pump to trigger ListenableBuilder rebuild
      await tester.pump();

      expect(service.isCustomized('electricity'), isTrue);
      expect(service.getOverrideSync('electricity'), contains('#FF5722'));

      // Revert back
      await service.resetToDefault('electricity');
      await tester.pump();

      expect(service.isCustomized('electricity'), isFalse);
    });
  });
}
