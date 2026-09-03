import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_melt/src/services/svg/svg_safeguard_service.dart';

void main() {
  const service = SvgSafeguardService();

  group('SvgSafeguardService validation and security tests', () {
    test('valid clean SVG passes validation', () {
      const validSvg = '''
<svg viewBox="0 0 24 24" fill="none" stroke="currentColor">
  <path d="M12 2L2 7l10 5 10-5-10-5zM2 17l10 5 10-5M2 12l10 5 10-5"/>
</svg>
''';
      final result = service.validate(validSvg);
      expect(result.isValid, isTrue);
      expect(result.errorMessage, isNull);
      expect(result.sanitizedContent, contains('svg'));
      expect(result.sanitizedContent, contains('viewBox="0 0 24 24"'));
    });

    test('empty or whitespace SVG fails validation', () {
      final res1 = service.validate('');
      expect(res1.isValid, isFalse);
      expect(res1.errorMessage, contains('empty'));

      final res2 = service.validate('   ');
      expect(res2.isValid, isFalse);
    });

    test('SVG exceeding 64 KB fails validation', () {
      final bigSvg = '<svg viewBox="0 0 24 24"><!-- ${'A' * (65 * 1024)} --></svg>';
      final result = service.validate(bigSvg);
      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('64 KB'));
    });

    test('SVG with <script> tag is rejected', () {
      const scriptSvg = '''
<svg viewBox="0 0 24 24">
  <script>alert("xss")</script>
  <circle cx="12" cy="12" r="10" />
</svg>
''';
      final result = service.validate(scriptSvg);
      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('executable script'));
    });

    test('SVG with javascript: URL is rejected', () {
      const jsUrlSvg = '''
<svg viewBox="0 0 24 24">
  <a href="javascript:alert(1)"><rect width="10" height="10"/></a>
</svg>
''';
      final result = service.validate(jsUrlSvg);
      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('executable script'));
    });

    test('SVG with XXE / <!DOCTYPE / <!ENTITY is rejected', () {
      const xxeSvg = '''<?xml version="1.0" standalone="no"?>
<!DOCTYPE svg [
  <!ELEMENT svg ANY >
  <!ENTITY xxe SYSTEM "file:///etc/passwd" >]>
<svg>&xxe;</svg>
''';
      final result = service.validate(xxeSvg);
      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('DOCTYPE or entity'));
    });

    test('SVG with inline event handlers has attributes stripped', () {
      const eventSvg = '''
<svg viewBox="0 0 24 24">
  <circle cx="12" cy="12" r="10" onload="alert(1)" onclick="steal()" />
</svg>
''';
      final result = service.validate(eventSvg);
      expect(result.isValid, isTrue);
      expect(result.sanitizedContent, isNot(contains('onload')));
      expect(result.sanitizedContent, isNot(contains('onclick')));
      expect(result.sanitizedContent, contains('circle'));
    });

    test('disallowed elements (<foreignObject>, <iframe>, <object>) are stripped', () {
      const dangerousSvg = '''
<svg viewBox="0 0 24 24">
  <foreignObject width="100" height="100">
    <body xmlns="http://www.w3.org/1999/xhtml">
      <p>Injected</p>
    </body>
  </foreignObject>
  <rect width="10" height="10" />
</svg>
''';
      final result = service.validate(dangerousSvg);
      expect(result.isValid, isTrue);
      expect(result.sanitizedContent, isNot(contains('foreignObject')));
      expect(result.sanitizedContent, contains('rect'));
    });

    test('saveCustomSvg saves file and resolveCustomFile resolves it safely', () async {
      final tempDir = await Directory.systemTemp.createTemp('svg_test_');
      try {
        const svgContent = '<svg viewBox="0 0 24 24"><circle cx="12" cy="12" r="8"/></svg>';
        final validation = service.validate(svgContent);
        expect(validation.isValid, isTrue);

        final iconId = await service.saveCustomSvg(
          sanitizedSvg: validation.sanitizedContent!,
          baseDir: tempDir,
        );

        expect(iconId, startsWith('custom:'));
        expect(iconId, endsWith('.svg'));

        final resolved = service.resolveCustomFile(iconId, tempDir);
        expect(resolved, isNotNull);
        expect(await resolved!.exists(), isTrue);
        expect(await resolved.readAsString(), contains('circle'));

        // Path traversal attack check
        final traversalResolved = service.resolveCustomFile('custom:../../etc/passwd', tempDir);
        expect(traversalResolved!.path, endsWith('passwd'));
        expect(traversalResolved.path, contains('custom_icons'));
      } finally {
        await tempDir.delete(recursive: true);
      }
    });
  });
}
